/**
 * Renders the Ivy 16-bit pixel kit as PNGs.
 * Native canvas is 160×240 (portrait). Sprites stay on the locked palette.
 */
import { deflateSync } from "node:zlib";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT = join(__dirname, "../public/pixels");

/** Locked 16-bit night-cottage palette. Index 0 is transparent. */
const C = {
  none: [0, 0, 0, 0],
  night: [18, 16, 28, 255],
  dusk: [32, 38, 62, 255],
  ivyDk: [36, 58, 42, 255],
  ivyMd: [62, 110, 64, 255],
  ivyLt: [122, 176, 98, 255],
  ivyNew: [186, 216, 140, 255],
  stoneDk: [58, 52, 48, 255],
  stoneMd: [98, 90, 82, 255],
  stoneLt: [148, 140, 128, 255],
  paper: [228, 220, 200, 255],
  wood: [92, 58, 44, 255],
  woodLt: [140, 92, 60, 255],
  clay: [176, 72, 58, 255],
  lamp: [232, 160, 72, 255],
  lampHot: [248, 220, 120, 255],
  glass: [72, 96, 132, 255],
};

const FONT = {
  0: ["111", "101", "101", "101", "111"],
  1: ["010", "110", "010", "010", "111"],
  2: ["111", "001", "111", "100", "111"],
  3: ["111", "001", "111", "001", "111"],
  4: ["101", "101", "111", "001", "001"],
  5: ["111", "100", "111", "001", "111"],
  6: ["111", "100", "111", "101", "111"],
  7: ["111", "001", "001", "001", "001"],
  8: ["111", "101", "111", "101", "111"],
  9: ["111", "101", "111", "001", "111"],
  ".": ["000", "000", "000", "000", "010"],
  S: ["111", "100", "111", "001", "111"],
  K: ["101", "110", "100", "110", "101"],
  I: ["111", "010", "010", "010", "111"],
  P: ["111", "101", "111", "100", "100"],
  " ": ["000", "000", "000", "000", "000"],
};

/**
 * @param {number} seed
 * @returns {() => number}
 */
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * @param {number} width
 * @param {number} height
 */
function surface(width, height) {
  return { width, height, data: new Uint8ClampedArray(width * height * 4) };
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number[]} color
 */
function put(pix, x, y, color) {
  if (x < 0 || y < 0 || x >= pix.width || y >= pix.height) return;
  const i = (y * pix.width + x) * 4;
  pix.data[i] = color[0];
  pix.data[i + 1] = color[1];
  pix.data[i + 2] = color[2];
  pix.data[i + 3] = color[3];
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number} w
 * @param {number} h
 * @param {number[]} color
 */
function fillRect(pix, x, y, w, h, color) {
  for (let yy = y; yy < y + h; yy += 1) {
    for (let xx = x; xx < x + w; xx += 1) put(pix, xx, yy, color);
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x0
 * @param {number} y0
 * @param {number} x1
 * @param {number} y1
 * @param {number[]} color
 */
function line(pix, x0, y0, x1, y1, color) {
  const dx = Math.abs(x1 - x0);
  const sx = x0 < x1 ? 1 : -1;
  const dy = -Math.abs(y1 - y0);
  const sy = y0 < y1 ? 1 : -1;
  let err = dx + dy;
  let x = x0;
  let y = y0;
  for (;;) {
    put(pix, x, y, color);
    if (x === x1 && y === y1) break;
    const e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {string} text
 * @param {number[]} color
 */
function text(pix, x, y, text, color) {
  let cx = x;
  for (const ch of text) {
    const glyph = FONT[ch] ?? FONT[" "];
    for (let row = 0; row < 5; row += 1) {
      for (let col = 0; col < 3; col += 1) {
        if (glyph[row][col] === "1") put(pix, cx + col, y + row, color);
      }
    }
    cx += 4;
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number} w
 * @param {number} h
 * @param {number[]} a
 * @param {number[]} b
 */
function dither(pix, x, y, w, h, a, b) {
  for (let yy = y; yy < y + h; yy += 1) {
    for (let xx = x; xx < x + w; xx += 1) {
      put(pix, xx, yy, (xx + yy) % 2 === 0 ? a : b);
    }
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number} w
 * @param {number} h
 */
function stoneBlock(pix, x, y, w, h) {
  fillRect(pix, x, y, w, h, C.stoneMd);
  const brickW = 10;
  const brickH = 6;
  let row = 0;
  for (let yy = y; yy < y + h; yy += brickH) {
    const offset = (row % 2) * Math.floor(brickW / 2);
    for (let xx = x - offset; xx < x + w + brickW; xx += brickW) {
      const x0 = Math.max(xx, x);
      const y1 = Math.min(yy + brickH, y + h - 1);
      const x1 = Math.min(xx + brickW - 1, x + w - 1);
      line(pix, x0, yy, x1, yy, C.stoneDk);
      line(pix, xx, yy, xx, y1, C.stoneDk);
      if (yy + 1 < y + h && x0 + 1 < x1) {
        line(pix, x0 + 1, yy + 1, x1 - 1, yy + 1, C.stoneLt);
      }
    }
    row += 1;
  }
}

/**
 * @param {ReturnType<typeof surface>} dest
 * @param {ReturnType<typeof surface>} src
 * @param {number} dx
 * @param {number} dy
 */
function blit(dest, src, dx, dy) {
  for (let y = 0; y < src.height; y += 1) {
    for (let x = 0; x < src.width; x += 1) {
      const i = (y * src.width + x) * 4;
      if (src.data[i + 3] === 0) continue;
      put(dest, dx + x, dy + y, [
        src.data[i],
        src.data[i + 1],
        src.data[i + 2],
        src.data[i + 3],
      ]);
    }
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number[]} stem
 * @param {number[]} leaf
 */
function leaf(pix, x, y, stem, leafColor) {
  put(pix, x, y, stem);
  put(pix, x, y - 1, leafColor);
  put(pix, x + 1, y - 1, leafColor);
  put(pix, x - 1, y - 1, leafColor);
  put(pix, x, y - 2, leafColor);
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {number} len
 * @param {number} seed
 * @param {number} density
 */
function vine(pix, x, y, len, seed, density) {
  const rand = rng(seed);
  let cx = x;
  let cy = y;
  for (let i = 0; i < len; i += 1) {
    const stem = rand() > 0.35 ? C.ivyMd : C.ivyDk;
    put(pix, cx, cy, stem);
    put(pix, cx + 1, cy, C.ivyDk);
    if (rand() < density) {
      const side = rand() > 0.5 ? 1 : -1;
      leaf(
        pix,
        cx + side * 2,
        cy,
        C.ivyDk,
        rand() > 0.72 ? C.ivyNew : C.ivyLt,
      );
    }
    cx += rand() > 0.7 ? 1 : rand() > 0.35 ? 0 : -1;
    cy -= 1;
  }
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {1 | 2 | 3 | 4} stage
 */
function drawIvy(pix, stage) {
  const count = stage * 3;
  const starts = [
    [44, 186],
    [52, 188],
    [60, 187],
    [70, 188],
    [88, 186],
    [98, 188],
    [108, 187],
    [48, 170],
    [100, 168],
    [56, 150],
    [96, 148],
    [80, 140],
  ];
  for (let i = 0; i < count; i += 1) {
    const [x, y] = starts[i];
    vine(pix, x, y, 18 + stage * 8, 400 + i * 17 + stage * 9, 0.28 + stage * 0.08);
  }
  if (stage >= 3) {
    vine(pix, 46, 130, 36, 901, 0.4);
    vine(pix, 108, 128, 34, 902, 0.4);
  }
  if (stage >= 4) {
    vine(pix, 62, 112, 40, 903, 0.5);
    vine(pix, 90, 108, 42, 904, 0.5);
    vine(pix, 78, 96, 28, 905, 0.55);
  }
}

/**
 * Draws the exterior cottage into a full-screen canvas.
 * @param {ReturnType<typeof surface>} pix
 */
function drawHouse(pix) {
  fillRect(pix, 0, 0, 160, 240, C.night);
  for (let y = 0; y < 36; y += 1) {
    fillRect(pix, 0, y, 160, 1, y < 18 ? C.night : C.dusk);
  }
  const stars = [
    [12, 10],
    [28, 18],
    [48, 8],
    [70, 14],
    [96, 6],
    [118, 16],
    [140, 9],
    [152, 22],
    [8, 40],
    [132, 36],
  ];
  for (const [sx, sy] of stars) put(pix, sx, sy, C.paper);

  fillRect(pix, 0, 188, 160, 52, C.ivyDk);
  dither(pix, 0, 188, 160, 8, C.ivyDk, C.stoneDk);
  for (let x = 0; x < 160; x += 1) {
    if ((x * 5 + 3) % 7 === 0) put(pix, x, 186, C.ivyMd);
  }

  stoneBlock(pix, 44, 118, 72, 72);
  for (let i = 0; i < 40; i += 1) {
    line(pix, 80 - i, 78 + Math.floor(i * 0.95), 80 + i, 78 + Math.floor(i * 0.95), i % 3 === 0 ? C.clay : C.wood);
  }
  fillRect(pix, 108, 72, 10, 22, C.stoneDk);
  fillRect(pix, 110, 70, 6, 4, C.stoneMd);

  fillRect(pix, 70, 148, 20, 42, C.wood);
  fillRect(pix, 72, 150, 16, 38, C.woodLt);
  put(pix, 86, 170, C.lampHot);

  drawWindow(pix, 52, 132, true);
  drawWindow(pix, 96, 132, true);
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @param {number} x
 * @param {number} y
 * @param {boolean} lit
 */
function drawWindow(pix, x, y, lit) {
  fillRect(pix, x, y, 14, 16, C.stoneDk);
  fillRect(pix, x + 2, y + 2, 10, 12, lit ? C.lamp : C.glass);
  if (lit) {
    fillRect(pix, x + 4, y + 4, 6, 6, C.lampHot);
    put(pix, x + 5, y + 5, C.paper);
  }
  line(pix, x + 7, y + 2, x + 7, y + 13, C.stoneDk);
  line(pix, x + 2, y + 8, x + 11, y + 8, C.stoneDk);
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeRoom() {
  const pix = surface(160, 240);
  fillRect(pix, 0, 0, 160, 240, C.night);
  fillRect(pix, 0, 0, 160, 18, C.wood);
  for (let x = 8; x < 160; x += 24) {
    fillRect(pix, x, 0, 4, 18, C.woodLt);
  }
  stoneBlock(pix, 8, 18, 144, 118);
  fillRect(pix, 0, 18, 8, 118, C.stoneDk);
  fillRect(pix, 152, 18, 8, 118, C.stoneDk);

  for (let y = 136; y < 240; y += 1) {
    const t = (y - 136) / 104;
    fillRect(pix, 0, y, 160, 1, t < 0.5 ? C.wood : C.woodLt);
  }
  for (let y = 136; y < 240; y += 5) {
    line(pix, 0, y, 159, y, C.wood);
  }

  drawWindow(pix, 24, 48, true);
  fillRect(pix, 22, 64, 18, 3, C.wood);
  vine(pix, 18, 128, 70, 77, 0.35);
  vine(pix, 14, 128, 54, 78, 0.3);

  fillRect(pix, 118, 44, 28, 22, C.stoneDk);
  fillRect(pix, 120, 46, 24, 18, C.paper);
  text(pix, 124, 52, "9.29", C.clay);
  line(pix, 120, 46, 143, 46, C.stoneLt);

  fillRect(pix, 48, 196, 64, 28, C.clay);
  fillRect(pix, 50, 198, 60, 24, C.wood);
  dither(pix, 52, 200, 56, 20, C.wood, C.woodLt);

  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeBed() {
  const pix = surface(72, 36);
  fillRect(pix, 0, 2, 10, 30, C.wood);
  fillRect(pix, 2, 4, 6, 26, C.woodLt);
  fillRect(pix, 8, 16, 62, 16, C.wood);
  fillRect(pix, 10, 12, 56, 14, C.paper);
  fillRect(pix, 24, 10, 42, 16, C.clay);
  fillRect(pix, 26, 12, 38, 4, C.lamp);
  fillRect(pix, 10, 8, 16, 12, C.paper);
  fillRect(pix, 12, 10, 12, 8, C.lampHot);
  line(pix, 8, 31, 69, 31, C.stoneDk);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeTicket() {
  const pix = surface(36, 18);
  fillRect(pix, 0, 0, 36, 18, C.paper);
  fillRect(pix, 0, 0, 36, 3, C.clay);
  fillRect(pix, 0, 15, 36, 3, C.clay);
  for (let y = 4; y < 15; y += 2) put(pix, 2, y, C.stoneMd);
  line(pix, 8, 0, 8, 17, C.stoneMd);
  text(pix, 12, 7, "8.17", C.night);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeTable() {
  const pix = surface(44, 26);
  fillRect(pix, 0, 8, 44, 8, C.woodLt);
  fillRect(pix, 0, 8, 44, 2, C.paper);
  fillRect(pix, 4, 16, 5, 10, C.wood);
  fillRect(pix, 35, 16, 5, 10, C.wood);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makePlaque() {
  const pix = surface(32, 24);
  fillRect(pix, 0, 0, 32, 24, C.stoneDk);
  fillRect(pix, 2, 2, 28, 20, C.paper);
  text(pix, 6, 9, "9.29", C.clay);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeDialogue() {
  const pix = surface(152, 48);
  fillRect(pix, 0, 0, 152, 48, C.night);
  fillRect(pix, 2, 2, 148, 44, C.paper);
  fillRect(pix, 4, 4, 144, 40, C.night);
  fillRect(pix, 6, 6, 140, 36, C.paper);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeSkip() {
  const pix = surface(40, 14);
  fillRect(pix, 0, 0, 40, 14, C.night);
  fillRect(pix, 1, 1, 38, 12, C.paper);
  text(pix, 8, 4, "SKIP", C.night);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeHand() {
  const pix = surface(16, 16);
  fillRect(pix, 6, 8, 5, 6, C.paper);
  fillRect(pix, 5, 4, 3, 6, C.paper);
  fillRect(pix, 8, 3, 2, 6, C.paper);
  fillRect(pix, 10, 5, 2, 5, C.paper);
  fillRect(pix, 7, 12, 3, 3, C.woodLt);
  put(pix, 6, 3, C.paper);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makeFrame() {
  const pix = surface(64, 64);
  stoneBlock(pix, 0, 0, 64, 64);
  fillRect(pix, 6, 6, 52, 52, C.none);
  fillRect(pix, 6, 6, 52, 2, C.lamp);
  fillRect(pix, 6, 56, 52, 2, C.wood);
  return pix;
}

/**
 * @returns {ReturnType<typeof surface>}
 */
function makePalette() {
  const pix = surface(128, 16);
  const colors = [
    C.night,
    C.dusk,
    C.ivyDk,
    C.ivyMd,
    C.ivyLt,
    C.ivyNew,
    C.stoneDk,
    C.stoneMd,
    C.stoneLt,
    C.paper,
    C.wood,
    C.woodLt,
    C.clay,
    C.lamp,
    C.lampHot,
    C.glass,
  ];
  colors.forEach((color, i) => fillRect(pix, i * 8, 0, 8, 16, color));
  return pix;
}

/**
 * @param {ReturnType<typeof surface>} pix
 * @returns {Buffer}
 */
function encodePng(pix) {
  const raw = Buffer.alloc((pix.width * 4 + 1) * pix.height);
  for (let y = 0; y < pix.height; y += 1) {
    const row = y * (pix.width * 4 + 1);
    raw[row] = 0;
    for (let x = 0; x < pix.width; x += 1) {
      const s = (y * pix.width + x) * 4;
      const d = row + 1 + x * 4;
      raw[d] = pix.data[s];
      raw[d + 1] = pix.data[s + 1];
      raw[d + 2] = pix.data[s + 2];
      raw[d + 3] = pix.data[s + 3];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(pix.width, 0);
  ihdr.writeUInt32BE(pix.height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  const chunks = [
    pngChunk("IHDR", ihdr),
    pngChunk("IDAT", deflateSync(raw)),
    pngChunk("IEND", Buffer.alloc(0)),
  ];
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    ...chunks,
  ]);
}

/**
 * @param {string} type
 * @param {Buffer} data
 * @returns {Buffer}
 */
function pngChunk(type, data) {
  const payload = Buffer.concat([Buffer.from(type), data]);
  const chunk = Buffer.alloc(8 + payload.length);
  chunk.writeUInt32BE(data.length, 0);
  payload.copy(chunk, 4);
  chunk.writeUInt32BE(crc32(payload), 4 + payload.length);
  return chunk;
}

/**
 * @param {Buffer} buf
 * @returns {number}
 */
function crc32(buf) {
  let crc = 0xffffffff;
  for (const byte of buf) {
    crc ^= byte;
    for (let i = 0; i < 8; i += 1) {
      crc = crc & 1 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

/**
 * @param {string} name
 * @param {ReturnType<typeof surface>} pix
 */
function save(name, pix) {
  writeFileSync(join(OUT, name), encodePng(pix));
}

/**
 * @param {ReturnType<typeof surface>} a
 * @param {ReturnType<typeof surface>} b
 * @returns {ReturnType<typeof surface>}
 */
function composite(a, b) {
  const out = surface(a.width, a.height);
  out.data.set(a.data);
  for (let i = 0; i < b.data.length; i += 4) {
    if (b.data[i + 3] === 0) continue;
    out.data[i] = b.data[i];
    out.data[i + 1] = b.data[i + 1];
    out.data[i + 2] = b.data[i + 2];
    out.data[i + 3] = b.data[i + 3];
  }
  return out;
}

mkdirSync(OUT, { recursive: true });

const house = surface(160, 240);
drawHouse(house);
save("intro-house.png", house);

for (const stage of [1, 2, 3, 4]) {
  const ivy = surface(160, 240);
  drawIvy(ivy, stage);
  save(`intro-ivy-${stage}.png`, ivy);
}

save("intro-covered.png", composite(house, (() => {
  const ivy = surface(160, 240);
  drawIvy(ivy, 4);
  return ivy;
})()));

const room = makeRoom();
const bed = makeBed();
const ticket = makeTicket();
const table = makeTable();
blit(room, bed, 8, 168);
blit(room, table, 78, 158);
blit(room, ticket, 82, 148);
save("room.png", room);
save("obj-bed.png", bed);
save("obj-ticket.png", ticket);
save("obj-table.png", table);
save("obj-plaque.png", makePlaque());
save("ui-dialogue.png", makeDialogue());
save("ui-skip.png", makeSkip());
save("ui-hand.png", makeHand());
save("frame-photo.png", makeFrame());
save("palette.png", makePalette());

writeFileSync(
  join(OUT, "palette.json"),
  `${JSON.stringify(
    {
      canvas: { width: 160, height: 240, scale: 4 },
      colors: Object.fromEntries(
        Object.entries(C).map(([name, rgba]) => [name, rgba]),
      ),
    },
    null,
    2,
  )}\n`,
);

console.log(`Wrote pixel kit to ${OUT}`);

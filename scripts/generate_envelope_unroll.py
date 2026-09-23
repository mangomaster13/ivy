#!/usr/bin/env python3
"""Rules letter: a parchment roll unfurls into an irregular sheet.

Eight 320x160 cells, packed 4x2 as `rules-envelope-sheet`.
Frame 0 is bound with ivy twine. Frame 7 is readable, still not a rectangle.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from sprite_sheet import pack_row_major, scene_dir, write_imageset

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
ASSETS = ROOT / "ios/Ivy/Assets.xcassets"
YARD = scene_dir("Yard")
PREVIEW = ROOT / ".impeccable/mocks/envelope-unroll"

W, H = 320, 160
FRAMES = 8
COLUMNS = 4
NIGHT = (18, 16, 28, 255)
SHADOW = (12, 11, 18, 255)
PAPER = (228, 220, 200, 255)
PAPER_DIM = (206, 196, 174, 255)
PAPER_DEEP = (186, 174, 150, 255)
UNDER = (168, 154, 128, 255)
OUTLINE = (18, 16, 28, 255)
INK = (67, 39, 27, 255)
INK_FAINT = (120, 96, 78, 255)
WAX = (36, 58, 42, 255)
WAX_MID = (62, 110, 64, 255)
WAX_LIT = (122, 176, 98, 255)

FACE: dict[str, tuple[str, str, str, str, str]] = {
    "A": ("01110", "10001", "11111", "10001", "10001"),
    "B": ("11110", "10001", "11110", "10001", "11110"),
    "C": ("01111", "10000", "10000", "10000", "01111"),
    "D": ("11110", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "11110", "10000", "11111"),
    "F": ("11111", "10000", "11110", "10000", "10000"),
    "G": ("01110", "10000", "10111", "10001", "01110"),
    "H": ("10001", "10001", "11111", "10001", "10001"),
    "I": ("01110", "00100", "00100", "00100", "01110"),
    "K": ("10001", "10010", "11100", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001"),
    "O": ("01110", "10001", "10001", "10001", "01110"),
    "R": ("11110", "10001", "11110", "10010", "10001"),
    "S": ("01111", "10000", "01110", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "01110"),
    "V": ("10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10101", "11011", "10001"),
    "Y": ("10001", "10001", "01110", "00100", "00100"),
    "'": ("1", "1", "0", "0", "0"),
    ".": ("00000", "00000", "00000", "00000", "00100"),
    " ": ("000", "000", "000", "000", "000"),
}

LINES = [
    "THIS HOUSE HOLDS",
    "THIRTEEN THINGS FOR YOU.",
    "",
    "THE DOOR WILL",
    "LISTEN NOW.",
]


def hash32(x: int, y: int, seed: int) -> int:
    n = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
    n = (n ^ (n >> 13)) & 0xFFFFFFFF
    return n


def glyph_width(ch: str) -> int:
    return len(FACE.get(ch.upper() if ch != "'" else "'", FACE[" "])[0])


def text_width(text: str) -> int:
    if not text:
        return 0
    return sum(glyph_width(ch) for ch in text) + max(0, len(text) - 1)


def blit_text(im: Image.Image, text: str, origin: tuple[int, int], color: tuple[int, int, int, int]) -> None:
    x, y = origin
    w, h = im.size
    for ch in text:
        key = ch if ch == "'" else ch.upper()
        glyph = FACE.get(key, FACE[" "])
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit != "1":
                    continue
                px, py = x + col, y + row
                if 0 <= px < w and 0 <= py < h:
                    im.putpixel((px, py), color)
        x += glyph_width(ch) + 1


def put(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < W and 0 <= y < H:
        im.putpixel((x, y), color)


def ease(frame: int) -> float:
    """Spend more time on the open sheet than on the bound roll."""
    u = frame / (FRAMES - 1)
    return 1 - (1 - u) ** 1.65


def roll_pose(t: float) -> tuple[int, int, int, int]:
    """Horizontal cylinder across the top. Shrinks as the sheet falls open."""
    cx = 160 + int(4 * math.sin(t * math.pi))
    cy = int(36 + 10 * (1 - t))
    rx = max(22, int(58 - 28 * t))
    ry = max(5, int(13 - 6 * t))
    return cx, cy, rx, ry


def deckle(x: int, seed: int, amp: int) -> int:
    return (hash32(x, seed, 11) % (amp * 2 + 1)) - amp


def left_at(y: int, t: float, cx: int, cy: int, rx: int) -> int:
    """Left deckle. Narrow under the curl, then opens enough to hold the copy."""
    v = max(0.0, min(1.0, (y - cy) / 108.0))
    flare = int(82 * t * math.sqrt(max(v, 0.12)))
    base = cx - rx - flare
    wave = int(6 * t * math.sin(y / 11.0 + 0.3))
    tuck = int(8 * t * v * v)
    return base + wave + tuck + deckle(y, 5, 2 if t > 0.25 else 0)


def right_at(y: int, t: float, cx: int, cy: int, rx: int) -> int:
    """Right deckle. Longer and heavier, with a torn bite that never eats the copy."""
    v = max(0.0, min(1.0, (y - cy) / 108.0))
    flare = int(78 * t * math.sqrt(max(v, 0.12)))
    base = cx + rx + flare
    wave = int(7 * t * math.sin(y / 13.0 + 0.9))
    bite = -int(8 * t * max(0.0, v - 0.55)) if v > 0.55 else 0
    return base + wave + bite + deckle(y, 6, 2 if t > 0.25 else 0)


def bot_at(x: int, t: float, cy: int, ry: int) -> int:
    closed = cy + ry + 1
    wave = int(6 * math.sin(x / 14.0 + 1.1)) + deckle(x, 8, 3)
    droop = int(max(0, x - 150) ** 2 / 900 * t)
    lift = -int(max(0, 120 - x) / 10 * t)
    opened = 144 + wave + droop + lift
    return closed + int((opened - closed) * t)


def in_roll(x: int, y: int, cx: int, cy: int, rx: int, ry: int) -> bool:
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0


def in_sheet(x: int, y: int, t: float, cx: int, cy: int, rx: int, ry: int) -> bool:
    if t <= 0.04:
        return False
    if y < cy:
        return False
    if x < left_at(y, t, cx, cy, rx) or x > right_at(y, t, cx, cy, rx):
        return False
    return y <= bot_at(x, t, cy, ry)


def paper_color(
    x: int, y: int, t: float, cx: int, cy: int, rx: int, ry: int
) -> tuple[int, int, int, int]:
    if in_roll(x, y, cx, cy, rx, ry):
        return roll_color(x, y, cx, cy, rx, ry)
    d = y - (cy + int(ry * 0.6))
    near_curl = abs(x - cx) < rx + 8
    if near_curl and 0 <= d < 4:
        return PAPER_DEEP if d < 2 else PAPER_DIM
    if hash32(x, y, 19) % 23 == 0:
        return PAPER_DIM
    if bot_at(x, t, cy, ry) - y < 5 and x > right_at(y, t, cx, cy, rx) - 10:
        return UNDER
    return PAPER


def roll_color(x: int, y: int, cx: int, cy: int, rx: int, ry: int) -> tuple[int, int, int, int]:
    """Concentric rings so the lying cylinder reads as wound paper."""
    nx = (x - cx) / max(1, rx)
    ny = (y - cy) / max(1, ry)
    ring = int(abs(ny) * 8 + abs(nx) * 1.5)
    if ny < -0.2:
        return (236, 228, 206, 255) if ring % 2 == 0 else PAPER
    if ny > 0.35:
        return UNDER if ring % 2 == 0 else PAPER_DEEP
    return PAPER_DIM if ring % 2 else PAPER


def paint_twine(im: Image.Image, t: float, cx: int, cy: int, rx: int, ry: int) -> None:
    if t > 0.38:
        return
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if not in_roll(x, y, cx, cy, rx, ry):
                continue
            if abs(x - cx) <= 2 or (abs(x - cx) == 3 and abs(y - cy) < ry - 1):
                put(im, x, y, WAX if abs(y - cy) > 2 else WAX_MID)
    put(im, cx, cy - 1, WAX_LIT)
    put(im, cx - 1, cy, WAX_LIT)
    if 0.1 < t <= 0.38:
        fall = int(22 * ((t - 0.1) / 0.28))
        for i, dx in enumerate((-2, 1, 3)):
            put(im, cx + dx, cy + ry + fall + i, WAX_MID)
            put(im, cx + dx + 1, cy + ry + 1 + fall + i, WAX)


def paint_ivy_mark(im: Image.Image, t: float, cx: int, cy: int, ry: int) -> None:
    """Ivy wax rides the cylinder, then rests on the curl like a seal."""
    ox, oy = cx + (8 if t > 0.5 else 0), cy - (0 if t < 0.5 else 1)
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            if dx * dx + dy * dy <= 7:
                put(im, ox + dx, oy + dy, WAX)
    put(im, ox, oy - 1, WAX_LIT)
    put(im, ox + 1, oy, WAX_MID)


def outline_mask(mask: list[list[bool]], im: Image.Image) -> None:
    for y in range(H):
        for x in range(W):
            if not mask[y][x]:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < W and 0 <= ny < H) or not mask[ny][nx]:
                    edge = True
                    break
            if edge:
                put(im, x, y, OUTLINE)


def drop_shadow(mask: list[list[bool]], im: Image.Image) -> None:
    for y in range(H - 1, -1, -1):
        for x in range(W - 1, -1, -1):
            if mask[y][x]:
                continue
            if y >= 2 and x >= 2 and mask[y - 2][x - 2]:
                put(im, x, y, SHADOW)
            elif y >= 1 and x >= 1 and mask[y - 1][x - 1]:
                put(im, x, y, SHADOW)


def span_at(mask: list[list[bool]], y: int) -> tuple[int, int] | None:
    if not (0 <= y < H):
        return None
    xs = [x for x in range(W) if mask[y][x]]
    if len(xs) < 8:
        return None
    return xs[0], xs[-1]


def paint_copy(im: Image.Image, t: float, mask: list[list[bool]]) -> None:
    if t < 0.62:
        return
    color = INK if t >= 0.86 else INK_FAINT
    shown = LINES if t >= 0.78 else LINES[:2]
    y = 62
    for line in shown:
        if line:
            width = text_width(line)
            span = span_at(mask, y + 2)
            if span:
                left, right = span
                ox = max(left + 4, (left + right - width) // 2)
            else:
                ox = 160 - width // 2
            blit_text(im, line, (ox, y), color)
        y += 12


def make_frame(frame: int) -> Image.Image:
    t = ease(frame)
    cx, cy, rx, ry = roll_pose(t)
    im = Image.new("RGBA", (W, H), NIGHT)
    mask = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if in_roll(x, y, cx, cy, rx, ry) or in_sheet(x, y, t, cx, cy, rx, ry):
                mask[y][x] = True
    drop_shadow(mask, im)
    for y in range(H):
        for x in range(W):
            if mask[y][x]:
                put(im, x, y, paper_color(x, y, t, cx, cy, rx, ry))
    outline_mask(mask, im)
    paint_twine(im, t, cx, cy, rx, ry)
    paint_ivy_mark(im, t, cx, cy, ry)
    paint_copy(im, t, mask)
    return im


def write_gif(frames: list[Image.Image]) -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    hold = [frame.convert("P", palette=Image.ADAPTIVE) for frame in frames]
    hold[0].save(
        PREVIEW / "envelope-unroll.gif",
        save_all=True,
        append_images=hold[1:] + [hold[-1], hold[-1]],
        duration=150,
        loop=0,
        disposal=2,
    )


def write_contact(frames: list[Image.Image]) -> None:
    pad = 8
    cols = 4
    rows = 2
    sheet = Image.new("RGB", (pad + cols * (W + pad), pad + 16 + rows * (H + pad + 12)), NIGHT[:3])
    draw = ImageDraw.Draw(sheet)
    for i, frame in enumerate(frames):
        c, r = i % cols, i // cols
        x = pad + c * (W + pad)
        y = 18 + r * (H + pad + 12)
        sheet.paste(frame.convert("RGB"), (x, y))
        draw.text((x, y - 12), f"{i}", fill=(214, 206, 186))
    sheet.save(PREVIEW / "contact-sheet.png")
    for i, frame in enumerate(frames):
        frame.save(PREVIEW / f"preview-{i}.png")


def main() -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    frames = [make_frame(i) for i in range(FRAMES)]
    write_imageset(
        YARD / "rules-envelope-sheet.imageset",
        "rules-envelope-sheet",
        pack_row_major(frames, COLUMNS),
    )
    write_imageset(YARD / "rules-envelope.imageset", "rules-envelope", frames[-1])
    write_gif(frames)
    write_contact(frames)
    print("wrote rules-envelope-sheet", FRAMES, "frames", COLUMNS, "cols")
    print("previews", PREVIEW)


if __name__ == "__main__":
    main()

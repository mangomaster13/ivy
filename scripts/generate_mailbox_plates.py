#!/usr/bin/env python3
"""Mailbox lock plates in the living lock-bg pixel language.

mailbox-bg: same oak door, 3x3 wells, handwritten `the date we met` on the iron header.
mailbox-ivy-sheet: living clump covering that line; 3 sway cells in one row.
icon-letter / icon-letter-off: 16x16 bar marks.
The rules letter unroll lives in generate_envelope_unroll.py.
Dust plates stay unused; do not ship a wipe.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from sprite_sheet import (
    SHARED_LOCK,
    crop_cell,
    egg_dir,
    pack_row_major,
    remove_imageset,
    scene_dir,
    write_imageset,
)

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
ASSETS = ROOT / "ios/Ivy/Assets.xcassets"
LOCK = SHARED_LOCK
YARD = scene_dir("Yard")
PREVIEW = ROOT / ".impeccable/mocks/mailbox-lock"

NIGHT = (18, 16, 28, 255)
IRON = (32, 30, 38, 255)
GROOVE = (22, 20, 28, 255)
CREAM = (214, 206, 186, 255)
PAPER = (228, 220, 200, 255)
INK = (67, 39, 27, 255)
WAX = (36, 58, 42, 255)
WAX_MID = (62, 110, 64, 255)
WAX_LIT = (122, 176, 98, 255)
OUTLINE = (18, 16, 28, 255)
OFF_FILL = (40, 46, 70, 255)
DUST_A = (92, 58, 44, 255)
DUST_B = (67, 39, 27, 255)
DUST_C = (48, 28, 20, 255)
ENGRAVE = (196, 186, 162, 255)
ENGRAVE_LIT = (228, 220, 200, 255)
ENGRAVE_SHADOW = (18, 16, 28, 255)
IVY_DARK = (36, 58, 42, 255)
IVY_MID = (62, 110, 64, 255)
IVY_LIT = (90, 148, 78, 255)
IVY_TIP = (140, 186, 110, 255)
IVY_LINE = (28, 42, 28, 255)

WELL_ORIGIN_4 = (106, 40)
WELL_ORIGIN_3 = (120, 54)
PITCH = 28
TILE = 24

# 5x5 caps so M / N / W stay distinct on iron and paper.
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
    "-": ("00000", "00000", "11111", "00000", "00000"),
    " ": ("000", "000", "000", "000", "000"),
}


def hash32(x: int, y: int, seed: int) -> int:
    n = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
    n = (n ^ (n >> 13)) & 0xFFFFFFFF
    return n


def glyph_width(ch: str) -> int:
    return len(FACE.get(ch.upper(), FACE[" "])[0])


def blit_text(
    im: Image.Image,
    text: str,
    origin: tuple[int, int],
    color: tuple[int, int, int, int],
    shadow: tuple[int, int, int, int] | None = None,
) -> None:
    x, y = origin
    w, h = im.size
    for ch in text.upper():
        glyph = FACE.get(ch, FACE[" "])
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit != "1":
                    continue
                px, py = x + col, y + row
                if not (0 <= px < w and 0 <= py < h):
                    continue
                if shadow is not None and 0 <= py + 1 < h:
                    im.putpixel((px, py + 1), shadow)
                im.putpixel((px, py), color)
        x += glyph_width(ch) + 1


def text_width(text: str) -> int:
    if not text:
        return 0
    return sum(glyph_width(ch) for ch in text.upper()) + max(0, len(text) - 1)


def put(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    w, h = im.size
    if 0 <= x < w and 0 <= y < h:
        im.putpixel((x, y), color)


def brush(im: Image.Image, x: float, y: float, color: tuple[int, int, int, int], thick: int = 1) -> None:
    xi, yi = int(round(x)), int(round(y))
    for dy in range(-thick, thick + 1):
        for dx in range(-thick, thick + 1):
            if dx * dx + dy * dy <= thick * thick + 1:
                put(im, xi + dx, yi + dy, color)


def stroke(im: Image.Image, pts: list[tuple[float, float]], color: tuple[int, int, int, int], thick: int = 1) -> None:
    if len(pts) < 2:
        return
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        steps = max(2, int(max(abs(x1 - x0), abs(y1 - y0)) * 3))
        for s in range(steps + 1):
            t = s / steps
            brush(im, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, color, thick)


# Local 8x10 skeletons unused; handwriting is Snell Roundhand quantized onto iron.


def italicize(x: float, y: float) -> tuple[float, float]:
    return x + (8 - y) / 4.5, y


SNELL = Path("/System/Library/Fonts/Supplemental/SnellRoundhand.ttc")
IVY_SHEET = YARD / "ivy-left-sheet.imageset/ivy-left-sheet.png"
IVY_LEGACY = YARD / "ivy-left-2-0.imageset/ivy-left-2-0.png"


def load_yard_ivy() -> Image.Image:
    """Stage-2 rest pose of the left vine, from the packed sheet or a leftover cell."""
    if IVY_SHEET.exists():
        sheet = Image.open(IVY_SHEET).convert("RGBA")
        return crop_cell(sheet, index=2 * 3 + 0, cell=(320, 160), columns=3)
    return Image.open(IVY_LEGACY).convert("RGBA")


def blit_cursive(im: Image.Image, text: str, origin: tuple[int, int]) -> None:
    """Quantize a real script face onto the iron so the line reads as handwriting, not caps."""
    font = ImageFont.truetype(str(SNELL), 18)
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = origin
    draw.text((x + 1, y + 1), text, font=font, fill=ENGRAVE_SHADOW)
    draw.text((x, y), text, font=font, fill=ENGRAVE_LIT)
    for py in range(im.height):
        for px in range(im.width):
            r, g, b, a = layer.getpixel((px, py))
            if a < 48:
                continue
            luma = r * 2 + g * 3 + b
            if r < 40 and g < 40 and b < 40:
                put(im, px, py, ENGRAVE_SHADOW)
            elif luma > 1100:
                put(im, px, py, ENGRAVE_LIT)
            else:
                put(im, px, py, ENGRAVE)


def well_rects() -> list[tuple[int, int, int, int]]:
    return [
        (
            WELL_ORIGIN_3[0] + col * PITCH,
            WELL_ORIGIN_3[1] + row * PITCH,
            WELL_ORIGIN_3[0] + col * PITCH + TILE,
            WELL_ORIGIN_3[1] + row * PITCH + TILE,
        )
        for row in range(3)
        for col in range(3)
    ]


def in_well(x: int, y: int) -> bool:
    return any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in well_rects())


def stamp_rgba(dst: Image.Image, src: Image.Image, ox: int, oy: int, sway: int = 0) -> None:
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src.getpixel((x, y))
            if a == 0:
                continue
            px = ox + x + (sway if y < src.height // 2 else 0)
            py = oy + y - (1 if sway == 2 and y < 8 else 0)
            if in_well(px, py):
                continue
            put(dst, px, py, (r, g, b, a))


def collect_clusters(sprite: Image.Image) -> list[Image.Image]:
    """Cut leafy patches from the yard ivy overlay so the plate vine shares its plant."""
    boxes = [
        (104, 18, 148, 78),
        (132, 22, 182, 88),
        (118, 40, 168, 96),
        (140, 18, 184, 64),
    ]
    clusters = []
    for box in boxes:
        crop = sprite.crop(box)
        if any(px[3] for px in crop.getdata()):
            clusters.append(crop)
    return clusters


def punch_reserved(im: Image.Image) -> None:
    """Wells and stave stay readable; ivy may kiss their edges, never sit on them."""
    for x0, y0, x1, y1 in well_rects():
        for y in range(y0, y1):
            for x in range(x0, x1):
                put(im, x, y, (0, 0, 0, 0))
    # Exact stave groove, not the oak to its left.
    for y in range(12, 26):
        for x in range(50, 214):
            put(im, x, y, (0, 0, 0, 0))


def make_plate_ivy(sway: int, clusters: list[Image.Image]) -> Image.Image:
    """Living clump from the left vine across the iron header. Wells stay open."""
    im = Image.new("RGBA", (320, 160), (0, 0, 0, 0))
    path = [
        (4, 92),
        (14, 74),
        (28, 58),
        (44, 46),
        (64, 40),
        (86, 34),
        (110, 30),
        (136, 28),
        (162, 30),
        (186, 34),
    ]
    for i, (x, y) in enumerate(path):
        cluster = clusters[i % len(clusters)]
        stamp_rgba(im, cluster, x - 10, y - 18 + (0 if i < 4 else sway), sway if i > 4 else 0)

    for i, x in enumerate(range(100, 208, 7)):
        cluster = clusters[(i + 1) % len(clusters)]
        y = 18 + (hash32(x, 22, 4) % 4) + (sway if i % 2 else 0)
        stamp_rgba(im, cluster, x - 14, y, sway)

    for y in range(28, 50):
        for x in range(104, 214):
            r, g, b, a = im.getpixel((x, y))
            if a:
                continue
            n = hash32(x + sway, y, 21)
            if n % 5:
                put(im, x, y, IVY_MID if n % 3 else IVY_DARK)
                if n % 9 == 0:
                    put(im, x + sway, y - 1, IVY_LIT)

    for x in range(108, 210, 2):
        drop = 48 + (hash32(x, 3, 8) % 8) + (1 if sway == 2 else 0)
        for y in range(46, drop):
            n = hash32(x, y, 5)
            put(im, x + (sway if n % 2 else 0), y, IVY_DARK if n % 3 else IVY_MID)
            if n % 7 == 0:
                put(im, x + 1, y + 1, IVY_LIT)

    punch_reserved(im)
    return im


def stamp_well(dst: Image.Image, well: Image.Image, origin: tuple[int, int]) -> None:
    x0, y0 = origin
    dst.paste(well, (x0, y0))


def make_mailbox_bg(lock_bg: Image.Image, well: Image.Image) -> Image.Image:
    im = lock_bg.copy()
    for row in range(4):
        for col in range(4):
            x = WELL_ORIGIN_4[0] + col * PITCH
            y = WELL_ORIGIN_4[1] + row * PITCH
            for yy in range(y, y + TILE):
                for xx in range(x, x + TILE):
                    im.putpixel((xx, yy), IRON)
    for row in range(3):
        for col in range(3):
            stamp_well(
                im,
                well,
                (WELL_ORIGIN_3[0] + col * PITCH, WELL_ORIGIN_3[1] + row * PITCH),
            )
    # Taller iron header so the handwritten line has a private band above the wells.
    for y in range(32, 40):
        for x in range(WELL_ORIGIN_4[0], WELL_ORIGIN_4[0] + 108):
            im.putpixel((x, y), IRON)
    line = "the date we met"
    # ~90px of chained script, centered on the 108px plate.
    blit_cursive(im, line, (WELL_ORIGIN_4[0] + 2, 33))
    return im


def make_dust(bg: Image.Image) -> Image.Image:
    dust = Image.new("RGBA", bg.size, (0, 0, 0, 0))
    # Engraving band — this is what the finger has to clear.
    band = (116, 39, 206, 52)
    for y in range(band[1], band[3] + 1):
        for x in range(band[0], band[2] + 1):
            n = hash32(x, y, 11) % 100
            if n < 55:
                c = DUST_B
                a = 230
            elif n < 82:
                c = DUST_A
                a = 210
            else:
                c = DUST_C
                a = 190
            dust.putpixel((x, y), (c[0], c[1], c[2], a))
    # Light film on the iron frame, never inside a well.
    wells = well_rects()

    def covered(x: int, y: int) -> bool:
        return any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in wells)

    for y in range(36, 150):
        for x in range(100, 214):
            if covered(x, y):
                continue
            n = hash32(x, y, 29) % 100
            if n > 11:
                continue
            c = DUST_A if n % 2 == 0 else DUST_C
            dust.putpixel((x, y), (c[0], c[1], c[2], 70 + n * 4))
    return dust


def rect(im: Image.Image, box: tuple[int, int, int, int], color: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        for x in range(x0, x1):
            im.putpixel((x, y), color)


def hline(im: Image.Image, x0: int, x1: int, y: int, color: tuple[int, int, int, int]) -> None:
    for x in range(x0, x1):
        im.putpixel((x, y), color)


def vline(im: Image.Image, x: int, y0: int, y1: int, color: tuple[int, int, int, int]) -> None:
    for y in range(y0, y1):
        im.putpixel((x, y), color)


def make_envelope() -> Image.Image:
    im = Image.new("RGBA", (320, 160), NIGHT)
    # Opened letter on the oak-night table: paper owns the cartridge.
    paper = (52, 18, 268, 142)
    rect(im, paper, PAPER)
    hline(im, 52, 268, 18, OUTLINE)
    hline(im, 52, 268, 141, OUTLINE)
    vline(im, 52, 18, 142, OUTLINE)
    vline(im, 267, 18, 142, OUTLINE)
    # Flap fold across the top third.
    hline(im, 53, 267, 42, (200, 188, 164, 255))
    for x in range(53, 267):
        t = abs((x - 160) / 108)
        y = 18 + int(24 * (1 - t * t))
        if 19 <= y <= 42:
            im.putpixel((x, y), (200, 188, 164, 255))
            if y + 1 <= 41:
                im.putpixel((x, y + 1), PAPER)
    # Ivy wax over the fold.
    cx, cy = 160, 41
    for y in range(cy - 6, cy + 7):
        for x in range(cx - 6, cx + 7):
            d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy)
            if d2 <= 32:
                im.putpixel((x, y), WAX)
            if d2 <= 12:
                im.putpixel((x, y), WAX_MID)
    im.putpixel((cx, cy - 2), WAX_LIT)
    im.putpixel((cx - 1, cy - 1), WAX_LIT)
    im.putpixel((cx + 1, cy - 1), WAX_MID)
    # Body copy. No 817, no chorus.
    lines = [
        "THIS HOUSE HOLDS",
        "NINE THINGS FOR YOU.",
        "",
        "YOU'VE UNLOCKED",
        "THE FIRST.",
    ]
    y = 58
    for line in lines:
        if line:
            w = text_width(line)
            blit_text(im, line, (160 - w // 2, y), INK)
        y += 12
    return im


def make_icon(on: bool) -> Image.Image:
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    fill = PAPER if on else OFF_FILL
    ink = OUTLINE
    wax = WAX_LIT if on else OFF_FILL
    # Closed envelope, same weight as the mailbox icon.
    for y in range(4, 13):
        for x in range(1, 15):
            im.putpixel((x, y), fill)
    for x in range(1, 15):
        im.putpixel((x, 4), ink)
        im.putpixel((x, 12), ink)
    for y in range(4, 13):
        im.putpixel((1, y), ink)
        im.putpixel((14, y), ink)
    for i in range(0, 7):
        left = 2 + i
        right = 13 - i
        im.putpixel((left, 5 + i), ink)
        im.putpixel((right, 5 + i), ink)
    im.putpixel((7, 8), wax)
    im.putpixel((8, 8), wax)
    im.putpixel((7, 9), wax)
    im.putpixel((8, 9), wax)
    return im


def preview(name: str, image: Image.Image) -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    image.resize((image.width * 3, image.height * 3), Image.NEAREST).save(PREVIEW / f"{name}.png")


def contact_sheet(plates: list[tuple[str, Image.Image]], filename: str = "contact-sheet.png") -> None:
    pad = 8
    cell_w, cell_h = 320, 160
    cols = 2
    rows = (len(plates) + 1) // 2
    sheet = Image.new("RGBA", (cols * (cell_w + pad) + pad, rows * (cell_h + pad) + 28), NIGHT)
    draw = ImageDraw.Draw(sheet)
    for i, (label, image) in enumerate(plates):
        c, r = i % cols, i // cols
        x = pad + c * (cell_w + pad)
        y = 20 + r * (cell_h + pad)
        sheet.paste(image, (x, y), image if image.mode == "RGBA" else None)
        draw.text((x, y - 12), label, fill=CREAM)
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(PREVIEW / filename)


def main() -> None:
    lock_bg = Image.open(LOCK / "lock-bg.imageset" / "lock-bg.png").convert("RGBA")
    well = lock_bg.crop(
        (WELL_ORIGIN_4[0], WELL_ORIGIN_4[1], WELL_ORIGIN_4[0] + TILE, WELL_ORIGIN_4[1] + TILE)
    )
    mailbox = make_mailbox_bg(lock_bg, well)
    sprite = load_yard_ivy()
    clusters = collect_clusters(sprite)
    ivy_frames = [make_plate_ivy(sway, clusters) for sway in range(3)]
    covered = [Image.alpha_composite(mailbox, frame) for frame in ivy_frames]
    icon_on = make_icon(True)
    icon_off = make_icon(False)

    write_imageset(YARD / "mailbox-bg.imageset", "mailbox-bg", mailbox)
    write_imageset(YARD / "mailbox-ivy-sheet.imageset", "mailbox-ivy-sheet", pack_row_major(ivy_frames, columns=3))
    for sway in range(3):
        remove_imageset(YARD / f"mailbox-ivy-{sway}.imageset")
    # rules-envelope-sheet is owned by generate_envelope_unroll.py
    letter = egg_dir("letter")
    write_imageset(letter / "icon-letter.imageset", "icon-letter", icon_on)
    write_imageset(letter / "icon-letter-off.imageset", "icon-letter-off", icon_off)

    preview("mailbox-bg", mailbox)
    for sway, (frame, plate) in enumerate(zip(ivy_frames, covered)):
        preview(f"mailbox-ivy-{sway}", frame)
        preview(f"mailbox-covered-{sway}", plate)
    preview("icon-letter", icon_on)
    preview("icon-letter-off", icon_off)
    contact_sheet(
        [
            ("mailbox-bg · handwriting", mailbox),
            ("ivy 0 covering the line", covered[0]),
            ("ivy 1", covered[1]),
            ("ivy 2", covered[2]),
        ]
    )
    gif_frames = [plate.convert("P", palette=Image.ADAPTIVE) for plate in covered + [covered[1], covered[0]]]
    PREVIEW.mkdir(parents=True, exist_ok=True)
    gif_frames[0].save(
        PREVIEW / "mailbox-ivy-play.gif",
        save_all=True,
        append_images=gif_frames[1:],
        duration=400,
        loop=0,
        disposal=2,
    )
    print("wrote mailbox plates and plate ivy")


if __name__ == "__main__":
    main()

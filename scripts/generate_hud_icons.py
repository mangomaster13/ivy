#!/usr/bin/env python3
"""Legacy cottage-night 32x32 HUD marks; perfume has approved standalone art.

16-bit world stays on the 320x160 plate. These marks are 32-pixel HUD only:
same silhouette on/off, nearest-neighbor @3x, cottage palette.
Living 16x16 marks (letter, vuori, noodle, cinema, keycard) are doubled so the
bar keeps their silhouette. New eggs and gelato (pistachio + stracciatella)
are drawn at 32 with the same 1px iron outline.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from sprite_sheet import egg_dir, write_imageset

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
PREVIEW = ROOT / ".impeccable/mocks/hud-icons"

NIGHT = (18, 16, 28, 255)
IRON = (32, 30, 38, 255)
CREAM = (214, 206, 186, 255)
IVY = (90, 140, 78, 255)
IVY_DK = (48, 88, 52, 255)
PAPER = (228, 220, 200, 255)
ROSE = (168, 72, 88, 255)
ROSE_DK = (112, 44, 58, 255)
ORANGE = (196, 120, 64, 255)
GOLD = (196, 164, 92, 255)
PISTACHIO = (150, 176, 88, 255)
STRAW = (236, 230, 214, 255)
NAVY = (46, 44, 62, 255)
WAX = (72, 108, 70, 255)
BROWN = (92, 64, 48, 255)
LAMP = (196, 64, 56, 255)

EGGS = [
    "letter",
    "vuori",
    "plane",
    "keycard",
    "city",
    "rose",
    "gelato",
    "noodle",
    "cinema",
    "sunset",
    "ferris",
    "taxi",
]

# Keep the living cottage silhouettes; only 16x16 sources are doubled.
UPSCALE = {"letter", "vuori", "noodle", "cinema", "keycard"}


def blank() -> Image.Image:
    """Transparent 32x32 HUD cell."""
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def put(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    """Plot one texel if it sits on the cell."""
    if 0 <= x < 32 and 0 <= y < 32:
        im.putpixel((x, y), color)


def fill(im: Image.Image, x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
    """Inclusive rectangle."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(im, x, y, color)


def outline(im: Image.Image, color: tuple[int, int, int, int] = IRON) -> None:
    """1px iron ring on transparent neighbors of opaque texels."""
    ring: list[tuple[int, int]] = []
    for y in range(32):
        for x in range(32):
            if im.getpixel((x, y))[3]:
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 32 and 0 <= ny < 32 and im.getpixel((nx, ny))[3]:
                    ring.append((x, y))
                    break
    for x, y in ring:
        put(im, x, y, color)


def off_of(src: Image.Image) -> Image.Image:
    """Night-navy cutout of the same silhouette."""
    out = blank()
    for y in range(32):
        for x in range(32):
            _, _, _, a = src.getpixel((x, y))
            if a:
                out.putpixel((x, y), NAVY)
    return out


def plane() -> Image.Image:
    """Boarding-pass stub, cream paper, ivy wax."""
    im = blank()
    fill(im, 5, 9, 26, 23, PAPER)
    fill(im, 5, 9, 26, 10, CREAM)
    fill(im, 7, 13, 16, 15, IRON)
    fill(im, 7, 18, 18, 19, IVY_DK)
    fill(im, 21, 13, 24, 20, WAX)
    outline(im)
    return im


def city() -> Image.Image:
    """Harbour window: iron frame, cream glass, orange waterline."""
    im = blank()
    fill(im, 7, 6, 24, 25, IRON)
    fill(im, 9, 8, 22, 23, (36, 48, 72, 255))
    fill(im, 10, 16, 14, 23, CREAM)
    fill(im, 16, 12, 20, 23, CREAM)
    fill(im, 9, 21, 22, 23, ORANGE)
    fill(im, 15, 8, 16, 23, IRON)
    fill(im, 9, 14, 22, 15, IRON)
    outline(im)
    return im


def rose() -> Image.Image:
    """Jellycat rose head plus one held petal."""
    im = blank()
    fill(im, 10, 7, 21, 20, ROSE)
    fill(im, 12, 9, 19, 17, ROSE_DK)
    fill(im, 14, 11, 17, 14, CREAM)
    fill(im, 15, 20, 16, 27, IVY_DK)
    fill(im, 22, 18, 28, 24, ROSE)
    fill(im, 24, 20, 26, 22, CREAM)
    outline(im)
    return im


def gelato() -> Image.Image:
    """Cup with pistachio and stracciatella scoops."""
    im = blank()
    fill(im, 9, 18, 22, 28, CREAM)
    fill(im, 11, 20, 20, 26, PAPER)
    fill(im, 8, 10, 16, 19, PISTACHIO)
    fill(im, 15, 8, 24, 19, STRAW)
    put(im, 18, 12, IRON)
    put(im, 21, 14, IRON)
    put(im, 17, 16, IRON)
    put(im, 20, 11, IRON)
    fill(im, 14, 4, 16, 10, IVY_DK)
    outline(im)
    return im


def sunset() -> Image.Image:
    """Orange disc on a harbour bar."""
    im = blank()
    fill(im, 10, 7, 21, 18, ORANGE)
    fill(im, 12, 5, 19, 20, GOLD)
    fill(im, 5, 20, 26, 22, ROSE_DK)
    fill(im, 7, 23, 24, 26, IRON)
    outline(im)
    return im


def ferris() -> Image.Image:
    """Night wheel."""
    im = blank()
    fill(im, 8, 5, 23, 20, IRON)
    fill(im, 10, 7, 21, 18, (36, 48, 72, 255))
    fill(im, 14, 11, 17, 14, GOLD)
    for cx, cy in ((9, 6), (21, 6), (9, 18), (21, 18), (15, 4), (15, 19)):
        fill(im, cx, cy, cx + 1, cy + 1, CREAM)
    fill(im, 15, 20, 16, 27, IRON)
    fill(im, 10, 27, 21, 29, IRON)
    outline(im)
    return im


def taxi() -> Image.Image:
    """Cab in cream and iron, one lamp."""
    im = blank()
    fill(im, 5, 14, 26, 22, CREAM)
    fill(im, 9, 10, 22, 14, CREAM)
    fill(im, 11, 11, 15, 14, IRON)
    fill(im, 17, 11, 21, 14, IRON)
    fill(im, 7, 21, 10, 25, IRON)
    fill(im, 21, 21, 24, 25, IRON)
    fill(im, 14, 7, 17, 10, GOLD)
    outline(im)
    return im


# Fallbacks if a living 16x16 is missing; should not run for UPSCALE names.
def ivy() -> Image.Image:
    """Two climbing leaves."""
    im = blank()
    fill(im, 6, 16, 16, 27, IVY_DK)
    fill(im, 8, 14, 18, 25, IVY)
    fill(im, 16, 5, 26, 16, IVY_DK)
    fill(im, 18, 3, 28, 14, IVY)
    outline(im)
    return im


def vuori() -> Image.Image:
    """Hanger chevron."""
    im = blank()
    for i in range(11):
        fill(im, 6 + i, 8 + i, 25 - i, 10 + i, CREAM)
    outline(im)
    return im


def keycard() -> Image.Image:
    """Hotel card with a gold chip."""
    im = blank()
    fill(im, 5, 10, 26, 22, CREAM)
    fill(im, 5, 10, 26, 13, IRON)
    fill(im, 8, 16, 12, 18, NAVY)
    fill(im, 20, 15, 24, 19, GOLD)
    outline(im)
    return im


def noodle() -> Image.Image:
    """Bowl plus chopsticks and a BIGTOP lamp."""
    im = blank()
    fill(im, 6, 16, 24, 26, BROWN)
    fill(im, 8, 18, 22, 24, GOLD)
    fill(im, 16, 8, 26, 12, CREAM)
    fill(im, 12, 6, 19, 12, LAMP)
    outline(im)
    return im


def cinema() -> Image.Image:
    """Two overlapping tickets."""
    im = blank()
    fill(im, 6, 8, 20, 20, NAVY)
    fill(im, 8, 10, 18, 18, PAPER)
    fill(im, 10, 14, 22, 26, BROWN)
    fill(im, 12, 16, 20, 24, PAPER)
    fill(im, 14, 18, 16, 20, ORANGE)
    outline(im)
    return im


DRAW = {
    "letter": ivy,
    "vuori": vuori,
    "plane": plane,
    "keycard": keycard,
    "city": city,
    "rose": rose,
    "gelato": gelato,
    "noodle": noodle,
    "cinema": cinema,
    "sunset": sunset,
    "ferris": ferris,
    "taxi": taxi,
}


def mark_for(name: str) -> Image.Image:
    """Prefer a doubled living 16x16; otherwise draw at 32."""
    path = egg_dir(name) / f"icon-{name}.imageset" / f"icon-{name}.png"
    if name in UPSCALE and path.exists():
        src = Image.open(path).convert("RGBA")
        if src.size == (16, 16):
            return src.resize((32, 32), Image.NEAREST)
    return DRAW[name]()


def main() -> None:
    """Write on/off imagesets and a contact sheet."""
    PREVIEW.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (32 * 13, 32 * 2), NIGHT)
    for index, name in enumerate(EGGS):
        on = mark_for(name)
        dark = off_of(on)
        dest = egg_dir(name)
        write_imageset(dest / f"icon-{name}.imageset", f"icon-{name}", on)
        write_imageset(dest / f"icon-{name}-off.imageset", f"icon-{name}-off", dark)
        sheet.paste(on, (index * 32, 0))
        sheet.paste(dark, (index * 32, 32))
    sheet.save(PREVIEW / "contact-sheet.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(PREVIEW / "contact-sheet@4x.png")
    print(f"wrote {len(EGGS)} HUD pairs")


if __name__ == "__main__":
    main()

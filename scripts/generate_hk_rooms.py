#!/usr/bin/env python3
"""16-bit Wonderland HK room plates.

Same cottage night as the yard and hall: iron, cream, paper, ivy, harbour orange.
Each plate is 320x160. Diegetic walk objects sit on the hotspot rects in RoomGraph.
No HUD marks, no room titles, no prev/next chrome.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

from sprite_sheet import room_dir, write_imageset

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
PREVIEW = ROOT / ".impeccable/mocks/hk-rooms"

NIGHT = (18, 16, 28, 255)
IRON = (32, 30, 38, 255)
STONE = (52, 48, 62, 255)
STONE_LIT = (72, 66, 80, 255)
GROOVE = (22, 20, 28, 255)
WOOD = (78, 52, 38, 255)
WOOD_DK = (54, 36, 28, 255)
CREAM = (214, 206, 186, 255)
PAPER = (228, 220, 200, 255)
IVY = (90, 140, 78, 255)
IVY_DK = (48, 88, 52, 255)
ORANGE = (196, 120, 64, 255)
GOLD = (196, 164, 92, 255)
ROSE = (168, 72, 88, 255)
ROSE_DK = (112, 44, 58, 255)
SEA = (36, 48, 72, 255)
LAMP = (220, 160, 80, 255)
NAVY = (46, 44, 62, 255)
WAX = (72, 108, 70, 255)
RED = (196, 64, 56, 255)
RAIN = (70, 78, 98, 255)

# Must match RoomGraph hotspot rects.
BACK = (8, 56, 44, 48)
FWD = (268, 56, 44, 48)
FLOOR = (138, 116, 44, 36)

FACE: dict[str, tuple[str, str, str, str, str]] = {
    "A": ("01110", "10001", "11111", "10001", "10001"),
    "B": ("11110", "10001", "11110", "10001", "11110"),
    "D": ("11110", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "11110", "10000", "11111"),
    "G": ("01110", "10000", "10111", "10001", "01110"),
    "I": ("01110", "00100", "00100", "00100", "01110"),
    "O": ("01110", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "11110", "10000", "10000"),
    "R": ("11110", "10001", "11110", "10010", "10001"),
    "S": ("01111", "10000", "01110", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100"),
    "X": ("10001", "01010", "00100", "01010", "10001"),
    "Y": ("10001", "10001", "01110", "00100", "00100"),
    "0": ("01110", "10001", "10001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "01110"),
    "6": ("01110", "10000", "11110", "10001", "01110"),
    "8": ("01110", "10001", "01110", "10001", "01110"),
}


def blank() -> Image.Image:
    """Night 320x160 plate."""
    return Image.new("RGBA", (320, 160), NIGHT)


def put(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    """Plot one texel."""
    if 0 <= x < 320 and 0 <= y < 160:
        im.putpixel((x, y), color)


def fill(im: Image.Image, x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
    """Inclusive rectangle."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(im, x, y, color)


def frame(im: Image.Image, x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
    """1px rectangle outline."""
    fill(im, x0, y0, x1, y0, color)
    fill(im, x0, y1, x1, y1, color)
    fill(im, x0, y0, x0, y1, color)
    fill(im, x1, y0, x1, y1, color)


def glyph(im: Image.Image, ch: str, x: int, y: int, color: tuple[int, int, int, int]) -> int:
    """Blit a 5x5 iron-language cap. Returns advance."""
    rows = FACE.get(ch.upper())
    if not rows:
        return 4
    width = len(rows[0])
    for row, bits in enumerate(rows):
        for col, bit in enumerate(bits):
            if bit == "1":
                put(im, x + col, y + row, color)
    return width + 1


def word(im: Image.Image, text: str, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    """Blit a short diegetic label."""
    cursor = x
    for ch in text:
        cursor += glyph(im, ch, cursor, y, color)


def wood_floor(im: Image.Image, y0: int = 88) -> None:
    """Hall-like boards across the plate."""
    fill(im, 0, y0, 319, 159, WOOD)
    for y in range(y0, 160, 6):
        fill(im, 0, y, 319, y, WOOD_DK)


def stone_wall(im: Image.Image, y0: int, y1: int) -> None:
    """Brick band behind furniture."""
    fill(im, 0, y0, 319, y1, STONE)
    for y in range(y0, y1, 8):
        fill(im, 0, y, 319, y, GROOVE)
        shift = 6 if ((y - y0) // 8) % 2 else 0
        for x in range(shift, 320, 12):
            fill(im, x, y, x, min(y1, y + 7), GROOVE)


def ceiling(im: Image.Image) -> None:
    """Dark beams."""
    fill(im, 0, 0, 319, 18, IRON)
    fill(im, 0, 18, 319, 19, GROOVE)
    for x in range(20, 320, 48):
        fill(im, x, 0, x + 3, 18, WOOD_DK)


def stars(im: Image.Image, y1: int = 70) -> None:
    """Sparse night dots, same as the yard sky."""
    for x, y in ((12, 8), (40, 18), (90, 6), (140, 14), (200, 9), (248, 20), (300, 7), (70, 28), (170, 24), (280, 30)):
        if y < y1:
            put(im, x, y, CREAM)


def hole(im: Image.Image, box: tuple[int, int, int, int] = FLOOR) -> None:
    """Arrival void in the boards."""
    x, y, w, h = box
    fill(im, x, y, x + w - 1, y + h - 1, GROOVE)
    frame(im, x, y, x + w - 1, y + h - 1, IRON)
    fill(im, x + 4, y + 4, x + w - 5, y + h - 5, NIGHT)
    fill(im, x + 8, y + 8, x + 14, y + 10, IVY_DK)


def pass_stub(im: Image.Image, box: tuple[int, int, int, int] = FWD) -> None:
    """DEPART boarding-pass on a stand."""
    x, y, w, h = box
    fill(im, x + 18, y + 30, x + 22, y + h - 1, IRON)
    fill(im, x + 2, y + 4, x + w - 3, y + 28, PAPER)
    frame(im, x + 2, y + 4, x + w - 3, y + 28, IRON)
    fill(im, x + w - 10, y + 8, x + w - 6, y + 22, WAX)
    word(im, "DEPART", x + 5, y + 12, IRON)


def door(im: Image.Image, box: tuple[int, int, int, int], lit: bool = False) -> None:
    """Wooden door in a stone jamb."""
    x, y, w, h = box
    fill(im, x, y, x + w - 1, y + h - 1, WOOD_DK)
    frame(im, x, y, x + w - 1, y + h - 1, IRON)
    fill(im, x + 3, y + 4, x + w - 4, y + h - 4, WOOD)
    if lit:
        fill(im, x + 8, y + 10, x + w - 9, y + 22, LAMP)
    put(im, x + w - 8, y + h // 2, GOLD)


def plane() -> Image.Image:
    """Arrivals hall: hole you fell through, DEPART stub, night glass."""
    im = blank()
    stars(im, 50)
    fill(im, 0, 40, 319, 87, STONE)
    fill(im, 40, 28, 200, 78, SEA)
    frame(im, 40, 28, 200, 78, IRON)
    fill(im, 48, 50, 90, 78, CREAM)
    fill(im, 100, 44, 130, 78, CREAM)
    fill(im, 40, 70, 200, 78, ORANGE)
    wood_floor(im, 88)
    fill(im, 16, 70, 36, 87, IRON)
    fill(im, 220, 64, 250, 87, IRON)
    hole(im, FLOOR)
    pass_stub(im, FWD)
    ceiling(im)
    return im


def corridor() -> Image.Image:
    """Hotel hall: elevator back, bedroom door with four dark wheels."""
    im = blank()
    stone_wall(im, 20, 100)
    wood_floor(im, 100)
    ceiling(im)
    fill(im, 0, 100, 319, 102, CARPET := (92, 44, 48, 255))
    fill(im, 40, 104, 280, 112, CARPET)
    door(im, BACK, lit=True)
    fill(im, BACK[0] + 10, BACK[1] + 8, BACK[0] + 16, BACK[1] + 18, LAMP)
    door(im, FWD)
    wx, wy = FWD[0] + 6, FWD[1] + 8
    for i in range(4):
        fill(im, wx + i * 8, wy, wx + i * 8 + 6, wy + 10, IRON)
        frame(im, wx + i * 8, wy, wx + i * 8 + 6, wy + 10, GOLD)
    word(im, "1608", wx, wy + 14, CREAM)
    fill(im, 150, 40, 170, 99, IRON)
    fill(im, 154, 48, 166, 58, LAMP)
    return im


def bedroom() -> Image.Image:
    """Seaview room: harbour window, rose on the bed, umbrella to the stall."""
    im = blank()
    stone_wall(im, 20, 96)
    wood_floor(im, 96)
    ceiling(im)
    fill(im, 108, 28, 210, 92, SEA)
    frame(im, 108, 28, 210, 92, IRON)
    fill(im, 108, 58, 210, 59, IRON)
    fill(im, 158, 28, 159, 92, IRON)
    fill(im, 120, 64, 148, 92, CREAM)
    fill(im, 170, 50, 198, 92, CREAM)
    fill(im, 108, 82, 210, 92, ORANGE)
    door(im, BACK)
    fill(im, 40, 100, 130, 132, ROSE_DK)
    fill(im, 48, 104, 122, 126, PAPER)
    fill(im, 78, 92, 98, 112, ROSE)
    fill(im, 84, 96, 92, 104, CREAM)
    fill(im, 132, 112, 144, 128, ROSE)
    x, y, w, h = FWD
    fill(im, x + 18, y + 8, x + 22, y + h - 1, IRON)
    fill(im, x + 4, y, x + w - 4, y + 16, NAVY)
    fill(im, x + 6, y + 2, x + w - 6, y + 14, SEA)
    return im


def gelato() -> Image.Image:
    """Rain stall, six cups, Big Top neon in the wet distance."""
    im = blank()
    stars(im, 40)
    fill(im, 0, 40, 319, 90, RAIN)
    for x in range(0, 320, 3):
        put(im, x, 44 + (x * 3) % 20, CREAM)
    fill(im, 20, 36, 300, 52, IRON)
    fill(im, 24, 38, 296, 50, NAVY)
    wood_floor(im, 90)
    fill(im, 220, 28, 300, 88, ROSE)
    word(im, "BIGTOP", 232, 48, PAPER)
    door(im, BACK)
    cups = [
        (70, IVY),
        (96, PAPER),
        (122, CREAM),
        (148, WAX),
        (174, GOLD),
        (200, WOOD_DK),
    ]
    for x, color in cups:
        fill(im, x, 100, x + 18, 128, CREAM)
        fill(im, x + 2, 88, x + 16, 104, color)
    x, y, w, h = FWD
    fill(im, x + 8, y, x + w - 8, y + h - 1, RED)
    frame(im, x + 8, y, x + w - 8, y + h - 1, IRON)
    return im


def noodle() -> Image.Image:
    """Big Top stall and rain on glass."""
    im = blank()
    stone_wall(im, 20, 92)
    wood_floor(im, 92)
    ceiling(im)
    fill(im, 80, 24, 200, 70, IRON)
    fill(im, 84, 28, 196, 66, RED)
    word(im, "BIGTOP", 110, 40, PAPER)
    fill(im, 70, 88, 210, 120, WOOD_DK)
    fill(im, 80, 96, 200, 114, GOLD)
    for x in range(30, 310, 4):
        put(im, x, 50 + (x % 12), RAIN)
    door(im, BACK)
    x, y, w, h = FWD
    fill(im, x, y, x + w - 1, y + h - 1, CREAM)
    frame(im, x, y, x + w - 1, y + h - 1, IRON)
    fill(im, x + 8, y + 10, x + w - 9, y + 28, IVY)
    return im


def cinema() -> Image.Image:
    """Lobby, bag back, EXIT to sunset, iron kiosk."""
    im = blank()
    stone_wall(im, 20, 96)
    wood_floor(im, 96)
    ceiling(im)
    fill(im, 110, 36, 210, 88, IRON)
    fill(im, 118, 44, 202, 80, GROOVE)
    fill(im, 126, 52, 170, 56, CREAM)
    fill(im, 126, 64, 154, 68, CREAM)
    x, y, w, h = BACK
    fill(im, x + 6, y + 10, x + w - 6, y + h - 1, CREAM)
    fill(im, x + 12, y, x + 18, y + 12, IRON)
    fill(im, x + w - 18, y, x + w - 12, y + 12, IRON)
    x, y, w, h = FWD
    fill(im, x, y + 8, x + w - 1, y + h - 8, RED)
    frame(im, x, y + 8, x + w - 1, y + h - 8, IRON)
    word(im, "EXIT", x + 8, y + 22, PAPER)
    return im


def sunset() -> Image.Image:
    """Harbour dusk, cinema doors behind, wheel on the skyline."""
    im = blank()
    fill(im, 0, 0, 319, 110, ROSE_DK)
    fill(im, 0, 40, 319, 80, ORANGE)
    fill(im, 0, 70, 319, 100, GOLD)
    fill(im, 120, 36, 200, 78, ORANGE)
    fill(im, 140, 24, 180, 78, GOLD)
    fill(im, 0, 100, 319, 110, SEA)
    wood_floor(im, 110)
    door(im, BACK)
    x, y, w, h = FWD
    fill(im, x + 8, y, x + w - 8, y + 28, IRON)
    fill(im, x + 12, y + 4, x + w - 12, y + 24, SEA)
    fill(im, x + 18, y + 12, x + 24, y + 16, GOLD)
    fill(im, x + 20, y + 28, x + 22, y + h - 1, IRON)
    return im


def ferris() -> Image.Image:
    """Night wheel, orange glass behind, taxi queue."""
    im = blank()
    stars(im)
    fill(im, 0, 100, 319, 110, SEA)
    wood_floor(im, 110)
    fill(im, 90, 20, 210, 108, IRON)
    fill(im, 100, 30, 200, 98, SEA)
    fill(im, 140, 54, 160, 74, GOLD)
    for cx, cy in ((96, 24), (198, 24), (96, 96), (198, 96), (144, 16), (144, 104)):
        fill(im, cx, cy, cx + 6, cy + 6, CREAM)
    x, y, w, h = BACK
    fill(im, x, y + 4, x + w - 1, y + 28, ORANGE)
    frame(im, x, y + 4, x + w - 1, y + 28, IRON)
    x, y, w, h = FWD
    fill(im, x, y + 16, x + w - 1, y + h - 4, CREAM)
    fill(im, x + 6, y + 8, x + w - 7, y + 18, CREAM)
    fill(im, x + 8, y + 10, x + 16, y + 16, IRON)
    fill(im, x + w - 18, y + 10, x + w - 10, y + 16, IRON)
    fill(im, x + 16, y + 4, x + 24, y + 8, GOLD)
    return im


def taxi() -> Image.Image:
    """Cab interior, meter, ferris in the rear glass, door out."""
    im = blank()
    fill(im, 0, 0, 319, 70, IRON)
    fill(im, 40, 12, 200, 70, SEA)
    frame(im, 40, 12, 200, 70, IRON)
    fill(im, 120, 20, 170, 60, IRON)
    fill(im, 130, 28, 160, 52, GOLD)
    fill(im, 0, 70, 319, 90, WOOD_DK)
    fill(im, 0, 90, 319, 159, WOOD)
    fill(im, 210, 24, 300, 80, IRON)
    fill(im, 218, 32, 292, 54, GROOVE)
    word(im, "STAY", 236, 38, GOLD)
    x, y, w, h = BACK
    fill(im, x, y + 4, x + w - 1, y + 28, ORANGE)
    frame(im, x, y + 4, x + w - 1, y + 28, IRON)
    door(im, (FLOOR[0], 70, FLOOR[2], 80), lit=True)
    fill(im, FLOOR[0] + 8, FLOOR[1] + 4, FLOOR[0] + FLOOR[2] - 8, FLOOR[1] + 12, NIGHT)
    return im


DRAW = {
    "hk-plane": plane,
    "hk-corridor": corridor,
    "hk-bedroom": bedroom,
    "hk-gelato": gelato,
    "hk-noodle": noodle,
    "hk-cinema": cinema,
    "hk-sunset": sunset,
    "hk-ferris": ferris,
    "hk-taxi": taxi,
}


def main() -> None:
    """Write imagesets and a contact sheet."""
    PREVIEW.mkdir(parents=True, exist_ok=True)
    names = list(DRAW)
    cols, rows = 2, 5
    sheet = Image.new("RGBA", (320 * cols, 160 * rows), NIGHT)
    for index, name in enumerate(names):
        plate = DRAW[name]()
        write_imageset(room_dir(name) / f"{name}.imageset", name, plate)
        sheet.paste(plate, ((index % cols) * 320, (index // cols) * 160))
    sheet.save(PREVIEW / "contact-sheet.png")
    print(f"wrote {len(names)} HK plates")


if __name__ == "__main__":
    main()

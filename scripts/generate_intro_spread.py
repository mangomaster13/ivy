#!/usr/bin/env python3
"""First-run intro: a living night, then one vine writes the tap line.

No cottage, no stems from the ground. Stars twinkle on their own sheet so the
vine stroke stays a cut-frame overlay. Letter skeletons are the 3x5 face from
intro-title; the trail is colored from intro-ivy-4.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

from sprite_sheet import pack_row_major, remove_imageset, write_imageset as write_sheet_imageset

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
ASSETS = ROOT / "ios/Ivy/Assets.xcassets/Intro"
PREVIEW = ROOT / ".impeccable/mocks/intro-spread"

W, H = 400, 176
NIGHT = (18, 16, 28, 255)
DIM_STAR = (78, 74, 90, 255)
MID_STAR = (148, 140, 124, 255)
STAR = (228, 220, 200, 255)
GLINT = (236, 228, 208, 255)
DARK = (36, 58, 42, 255)
MID = (62, 110, 64, 255)
LIT = (122, 176, 98, 255)
HI = (186, 216, 140, 255)
LINE = "TAP TO START THE ADVENTURE"
SCALE = 2
FRAMES = 20
STAR_FRAMES = 4
STAR_COLUMNS = 4

# Stroke order on the 3x5 grid (col 0-2, row 0-4). Each letter is one continuous polyline.
STROKES: dict[str, list[tuple[int, int]]] = {
    "A": [(0, 4), (0, 2), (0, 1), (1, 0), (2, 1), (2, 2), (0, 2), (2, 2), (2, 4)],
    "D": [(0, 4), (0, 0), (1, 0), (2, 1), (2, 3), (1, 4), (0, 4)],
    "E": [(2, 0), (0, 0), (0, 2), (1, 2), (0, 2), (0, 4), (2, 4)],
    "H": [(0, 4), (0, 0), (0, 2), (2, 2), (2, 0), (2, 4)],
    "N": [(0, 4), (0, 0), (1, 1), (2, 2), (2, 4)],
    "O": [(1, 0), (2, 1), (2, 3), (1, 4), (0, 3), (0, 1), (1, 0)],
    "P": [(0, 4), (0, 0), (1, 0), (2, 1), (1, 2), (0, 2)],
    "R": [(0, 4), (0, 0), (1, 0), (2, 1), (1, 2), (0, 2), (2, 4)],
    "S": [(2, 0), (1, 0), (0, 1), (1, 2), (2, 3), (1, 4), (0, 4)],
    "T": [(0, 0), (2, 0), (1, 0), (1, 4)],
    "U": [(0, 0), (0, 3), (1, 4), (2, 4), (2, 0)],
    "V": [(0, 0), (0, 2), (1, 4), (2, 2), (2, 0)],
}


def src(name: str) -> Path:
    return ASSETS / f"{name}.imageset" / f"{name}.png"


def vine_color(x: int, y: int) -> tuple[int, int, int, int]:
    rng = random.Random((x * 73856093) ^ (y * 19349663) ^ 11)
    return rng.choices([DARK, MID, LIT, HI], weights=[5, 4, 2, 1])[0]


def bresenham(x0: int, y0: int, x1: int, y1: int) -> list[tuple[int, int]]:
    pts: list[tuple[int, int]] = []
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        pts.append((x, y))
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy
    return pts


def measure_text(text: str) -> int:
    width = 0
    for i, ch in enumerate(text):
        if ch == " ":
            width += 3 * SCALE
            continue
        width += 3 * SCALE
        if i < len(text) - 1 and text[i + 1] != " ":
            width += SCALE
    return width


def cell_origin(letter_x: int, letter_y: int, col: int, row: int) -> tuple[int, int]:
    return letter_x + col * SCALE, letter_y + row * SCALE


def cell_center(letter_x: int, letter_y: int, col: int, row: int) -> tuple[int, int]:
    x, y = cell_origin(letter_x, letter_y, col, row)
    return x + SCALE // 2, y + SCALE // 2


def fill_cell(cells: dict[tuple[int, int], list[tuple[int, int]]], letter_x: int, letter_y: int, col: int, row: int) -> None:
    x0, y0 = cell_origin(letter_x, letter_y, col, row)
    pix = [(x0 + ox, y0 + oy) for oy in range(SCALE) for ox in range(SCALE)]
    cells.setdefault((letter_x, letter_y, col, row), pix)


def polyline(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    if not points:
        return []
    out: list[tuple[int, int]] = [points[0]]
    for i in range(1, len(points)):
        step = bresenham(points[i - 1][0], points[i - 1][1], points[i][0], points[i][1])
        out.extend(step[1:])
    return out


def wander(x0: int, y0: int, x1: int, y1: int, seed: int, amp: int = 2) -> list[tuple[int, int]]:
    """A single tendril with a little give, not a ruled line."""
    rng = random.Random(seed)
    x, y = x0, y0
    pts = [(x, y)]
    guard = 0
    while guard < 800:
        guard += 1
        if abs(x - x1) <= 1 and abs(y - y1) <= 1:
            break
        if abs(x - x1) >= abs(y - y1):
            x += 1 if x1 > x else -1
            if rng.random() < 0.4:
                y += rng.choice((-1, 0, 1))
        else:
            y += 1 if y1 > y else -1
            if rng.random() < 0.25:
                x += rng.choice((-1, 0, 1))
        y = max(y1 - amp, min(y1 + amp, y))
        pts.append((x, y))
    if pts[-1] != (x1, y1):
        pts.extend(bresenham(pts[-1][0], pts[-1][1], x1, y1)[1:])
    return pts


def build_path(text: str, origin_x: int, origin_y: int) -> tuple[list[tuple[int, int]], list[set[tuple[int, int]]], int]:
    """One continuous vine path, plus the letter cells unlocked at each path index."""
    mid_y = origin_y + 2 * SCALE
    path: list[tuple[int, int]] = []
    unlocked_at: list[set[tuple[int, int]]] = []

    def append_segment(pts: list[tuple[int, int]], extra_cells: set[tuple[int, int]] | None = None) -> None:
        for pt in pts:
            path.append(pt)
            unlocked_at.append(set(extra_cells or ()))

    first = cell_center(origin_x, origin_y, 0, 0)
    append_segment(wander(0, mid_y, first[0], first[1], seed=17, amp=3))
    entrance_len = len(path)

    cursor = origin_x
    prev_end: tuple[int, int] | None = None
    for i, ch in enumerate(text):
        if ch == " ":
            if prev_end is not None:
                gap_x = cursor + 3 * SCALE - 1
                append_segment(wander(prev_end[0], prev_end[1], gap_x, mid_y, seed=40 + i, amp=1))
                prev_end = (gap_x, mid_y)
            cursor += 3 * SCALE
            continue

        letter_x, letter_y = cursor, origin_y
        stroke = STROKES[ch]
        centers = [cell_center(letter_x, letter_y, c, r) for c, r in stroke]
        if prev_end is not None:
            append_segment(wander(prev_end[0], prev_end[1], centers[0][0], centers[0][1], seed=80 + i, amp=1))
        letter_poly = polyline(centers)
        for pt in letter_poly:
            cells: set[tuple[int, int]] = set()
            for r in range(5):
                for c in range(3):
                    x0, y0 = cell_origin(letter_x, letter_y, c, r)
                    if x0 <= pt[0] < x0 + SCALE and y0 <= pt[1] < y0 + SCALE:
                        if FONT_ON[ch][r][c] == "#":
                            for oy in range(SCALE):
                                for ox in range(SCALE):
                                    cells.add((x0 + ox, y0 + oy))
            path.append(pt)
            unlocked_at.append(cells)
        prev_end = letter_poly[-1]
        cursor += 3 * SCALE
        if i < len(text) - 1 and text[i + 1] != " ":
            cursor += SCALE

    return path, unlocked_at, entrance_len


FONT_ON = {
    ch: rows
    for ch, rows in {
        "A": [".#.", "#.#", "###", "#.#", "#.#"],
        "D": ["##.", "#.#", "#.#", "#.#", "##."],
        "E": ["###", "#..", "##.", "#..", "###"],
        "H": ["#.#", "#.#", "###", "#.#", "#.#"],
        "N": ["#.#", "##.", "#.#", "#.#", "#.#"],
        "O": [".#.", "#.#", "#.#", "#.#", ".#."],
        "P": ["##.", "#.#", "##.", "#..", "#.."],
        "R": ["##.", "#.#", "##.", "#.#", "#.#"],
        "S": [".##", "#..", ".#.", "..#", "##."],
        "T": ["###", ".#.", ".#.", ".#.", ".#."],
        "U": ["#.#", "#.#", "#.#", "#.#", ".##"],
        "V": ["#.#", "#.#", "#.#", ".#.", ".#."],
    }.items()
}


def put(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < W and 0 <= y < H:
        im.putpixel((x, y), color)


def in_quiet_band(x: int, y: int) -> bool:
    """Keep the tap line readable; stars live in the rest of the night."""
    return 70 <= y <= 106 and 48 <= x <= 352


def paint_base() -> Image.Image:
    """Full night and dust stars that never blink. No ground bar — the sky is the card."""
    canvas = Image.new("RGBA", (W, H), NIGHT)
    rng = random.Random(17)
    for _ in range(110):
        x = rng.randint(1, W - 2)
        y = rng.randint(3, H - 3)
        if in_quiet_band(x, y):
            continue
        canvas.putpixel((x, y), DIM_STAR)
    for i in range(70):
        x = 28 + i * 5 + rng.randint(-2, 2)
        y = 10 + i // 5 + rng.randint(-5, 5)
        if in_quiet_band(x, y) or not (0 <= x < W and 0 <= y < 70):
            continue
        if rng.random() < 0.55:
            canvas.putpixel((x, y), DIM_STAR)
    return canvas


def twinkle_catalog() -> list[tuple[int, int, int, int]]:
    """Bright stars: x, y, phase, glint size (0 = point, 1 = plus)."""
    rng = random.Random(29)
    placed: list[tuple[int, int, int, int]] = [
        (24, 12, 0, 1),
        (88, 8, 1, 1),
        (156, 14, 2, 0),
        (212, 6, 3, 1),
        (268, 18, 0, 0),
        (332, 10, 2, 1),
        (376, 22, 1, 0),
        (48, 34, 3, 0),
        (118, 28, 1, 1),
        (198, 36, 0, 0),
        (294, 32, 2, 1),
        (358, 44, 3, 0),
        (12, 52, 1, 0),
        (72, 48, 2, 0),
        (318, 56, 0, 1),
        (388, 38, 3, 0),
        (40, 118, 0, 0),
        (110, 128, 2, 1),
        (250, 122, 1, 0),
        (340, 132, 3, 1),
        (20, 140, 1, 0),
        (180, 148, 0, 0),
        (300, 144, 2, 0),
        (370, 118, 3, 0),
    ]
    used = {(x, y) for x, y, _, _ in placed}
    while len(placed) < 38:
        x = rng.randint(3, W - 4)
        y = rng.randint(4, 154)
        if in_quiet_band(x, y) or (x, y) in used:
            continue
        used.add((x, y))
        placed.append((x, y, rng.randint(0, 3), 1 if rng.random() < 0.22 else 0))
    return placed


def star_level(phase: int, frame: int) -> tuple[int, int, int, int]:
    cycle = (phase + frame) % 4
    return (DIM_STAR, MID_STAR, STAR, MID_STAR)[cycle]


def paint_glint(im: Image.Image, x: int, y: int, color: tuple[int, int, int, int], peak: bool) -> None:
    put(im, x, y, color)
    if not peak:
        return
    arm = MID_STAR if color == STAR else DIM_STAR
    put(im, x - 1, y, arm)
    put(im, x + 1, y, arm)
    put(im, x, y - 1, arm)
    put(im, x, y + 1, arm)
    put(im, x, y, GLINT)


def paint_star_frame(frame: int, catalog: list[tuple[int, int, int, int]]) -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for x, y, phase, size in catalog:
        color = star_level(phase, frame)
        peak = size == 1 and color == STAR
        if peak:
            paint_glint(layer, x, y, color, True)
        else:
            put(layer, x, y, color)
    return layer


def ink(dest: Image.Image, x: int, y: int, head: bool) -> None:
    if not (0 <= x < W and 0 <= y < H):
        return
    color = HI if head else vine_color(x, y)
    dest.putpixel((x, y), color)
    for dx, dy in ((1, 0), (0, 1), (-1, 0)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < W and 0 <= ny < H and dest.getpixel((nx, ny))[3] == 0:
            dest.putpixel((nx, ny), DARK if not head else LIT)


def frame_progress(frame: int) -> float:
    """Spend extra time on the side entrance, then write the line."""
    t = frame / FRAMES
    if t < 0.2:
        return 0.1 * (t / 0.2)
    return 0.1 + 0.9 * ((t - 0.2) / 0.8)


def write_imageset(name: str, image: Image.Image) -> None:
    write_sheet_imageset(ASSETS / f"{name}.imageset", name, image)


def prune_numbered_frames() -> None:
    """Drop leftover per-beat imagesets; playback uses packed sheets."""
    keep = {"intro-spread-base", "intro-spread-sheet", "intro-star-sheet"}
    for folder in ASSETS.glob("intro-spread-*.imageset"):
        name = folder.name.removesuffix(".imageset")
        if name in keep:
            continue
        suffix = name.removeprefix("intro-spread-")
        if suffix.isdigit():
            remove_imageset(folder)


def main() -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    tw = measure_text(LINE)
    th = 5 * SCALE
    ox = (W - tw) // 2
    oy = (H - th) // 2
    path, unlocked_at, _entrance_len = build_path(LINE, ox, oy)
    assert path, "empty vine path"

    base = paint_base()
    catalog = twinkle_catalog()
    star_layers = [paint_star_frame(i, catalog) for i in range(STAR_FRAMES)]
    layers: list[Image.Image] = []
    for frame in range(1, FRAMES + 1):
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        filled: set[tuple[int, int]] = set()
        if frame == FRAMES:
            for cells in unlocked_at:
                filled |= cells
            for x, y in filled:
                if 0 <= x < W and 0 <= y < H:
                    layer.putpixel((x, y), vine_color(x, y))
        else:
            u = frame_progress(frame)
            count = max(1, int(len(path) * u))
            for i in range(count):
                filled |= unlocked_at[i]
                x, y = path[i]
                ink(layer, x, y, head=(i == count - 1))
            for x, y in filled:
                if 0 <= x < W and 0 <= y < H and layer.getpixel((x, y))[3] == 0:
                    layer.putpixel((x, y), vine_color(x, y))
        layers.append(layer)

    write_imageset("intro-spread-base", base)
    write_imageset("intro-spread-sheet", pack_row_major(layers, columns=5))
    write_imageset("intro-star-sheet", pack_row_major(star_layers, columns=STAR_COLUMNS))
    prune_numbered_frames()

    contact = Image.new("RGB", (W, H * (FRAMES + 1)), NIGHT[:3])
    night0 = Image.alpha_composite(base, star_layers[1]).convert("RGB")
    contact.paste(night0, (0, 0))
    night0.save(PREVIEW / "preview-base.png")
    for i, layer in enumerate(layers, start=1):
        sky = star_layers[(i - 1) % STAR_FRAMES]
        frame = Image.alpha_composite(Image.alpha_composite(base, sky), layer).convert("RGB")
        contact.paste(frame, (0, i * H))
        frame.save(PREVIEW / f"preview-{i}.png")
    contact.save(PREVIEW / "contact-sheet.png")
    gif_hold = []
    last = layers[-1]
    for i, sky in enumerate(star_layers + star_layers[-2:0:-1]):
        plate = Image.alpha_composite(Image.alpha_composite(base, sky), last).convert("P", palette=Image.ADAPTIVE)
        gif_hold.append(plate)
        Image.alpha_composite(Image.alpha_composite(base, sky), last).save(PREVIEW / f"preview-star-{i}.png")
    gif_hold[0].save(
        PREVIEW / "preview-play.gif",
        save_all=True,
        append_images=gif_hold[1:],
        duration=320,
        loop=0,
        disposal=2,
    )
    print("wrote", FRAMES, "stroke frames, path length", len(path))
    print("wrote", STAR_FRAMES, "star twinkle frames")
    print("previews", PREVIEW)


if __name__ == "__main__":
    main()

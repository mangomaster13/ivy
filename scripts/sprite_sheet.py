#!/usr/bin/env python3
"""Pack pixel plates into a row-major sprite sheet and write an Xcode imageset."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

ASSETS = Path("/Users/liangzixuan/Desktop/ivy/ios/Ivy/Assets.xcassets")
"""Xcode catalog root."""
SCENES = ASSETS / "Scenes"
"""One folder per playable room."""
SHARED_LOCK = ASSETS / "Shared" / "Lock"
"""Iron assemble tiles shared by the mailbox and the door."""
SHARED_UI = ASSETS / "Shared" / "UI"
"""Chrome that is not a room: dialogue, help."""
INTRO = ASSETS / "Intro"
"""First-run spread. Not a playable room."""

EGG_SCENE = {
    "letter": "Yard",
    "ivy": "Yard",
    "vuori": "Hall",
    "plane": "Plane",
    "keycard": "Corridor",
    "city": "Bedroom",
    "rose": "Bedroom",
    "gelato": "Gelato",
    "noodle": "Noodle",
    "cinema": "Cinema",
    "sunset": "Sunset",
    "ferris": "Ferris",
    "taxi": "Taxi",
}

ROOM_SCENE = {
    "yard-base": "Yard",
    "yard-cloud": "Yard",
    "sky-lyric": "Yard",
    "hall": "Hall",
    "hk-plane": "Plane",
    "hk-corridor": "Corridor",
    "hk-bedroom": "Bedroom",
    "hk-gelato": "Gelato",
    "hk-noodle": "Noodle",
    "hk-cinema": "Cinema",
    "hk-sunset": "Sunset",
    "hk-ferris": "Ferris",
    "hk-taxi": "Taxi",
}


def scene_dir(scene: str) -> Path:
    """Catalog folder for one playable room."""
    return SCENES / scene


def egg_dir(egg: str) -> Path:
    """Catalog folder that owns this egg's HUD marks."""
    return scene_dir(EGG_SCENE[egg])


def room_dir(plate: str) -> Path:
    """Catalog folder that owns this 320×160 plate."""
    return scene_dir(ROOM_SCENE[plate])


def pack_row_major(frames: list[Image.Image], columns: int) -> Image.Image:
    """Tile frames left-to-right, wrapping after `columns`. Empty cells stay transparent."""
    if not frames:
        raise ValueError("no frames to pack")
    if columns < 1:
        raise ValueError("columns must be >= 1")
    width, height = frames[0].size
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (width * columns, height * rows), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        if frame.size != (width, height):
            raise ValueError(f"frame {index} is {frame.size}, expected {(width, height)}")
        col, row = index % columns, index // columns
        sheet.paste(frame.convert("RGBA"), (col * width, row * height))
    return sheet


def write_imageset(folder: Path, name: str, image: Image.Image) -> None:
    """Write 1x + nearest-neighbor @3x with original (untinted) rendering."""
    folder.mkdir(parents=True, exist_ok=True)
    one = folder / f"{name}.png"
    three = folder / f"{name}@3x.png"
    rgba = image.convert("RGBA")
    rgba.save(one)
    rgba.resize((rgba.width * 3, rgba.height * 3), Image.NEAREST).save(three)
    (folder / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"filename": f"{name}.png", "idiom": "universal", "scale": "1x"},
                    {"idiom": "universal", "scale": "2x"},
                    {"filename": f"{name}@3x.png", "idiom": "universal", "scale": "3x"},
                ],
                "info": {"author": "xcode", "version": 1},
                "properties": {"template-rendering-intent": "original"},
            },
            indent=2,
        )
        + "\n"
    )


def remove_imageset(folder: Path) -> None:
    """Delete a catalog imageset folder if it exists."""
    if folder.exists():
        shutil.rmtree(folder)


def load_cell(imageset: Path, name: str) -> Image.Image | None:
    """Open the 1x PNG from an imageset, or None when the plate is already gone."""
    path = imageset / f"{name}.png"
    if not path.exists():
        return None
    return Image.open(path).convert("RGBA")


def crop_cell(sheet: Image.Image, index: int, cell: tuple[int, int], columns: int) -> Image.Image:
    """Cut one packed cell out of a sheet (game pixels)."""
    width, height = cell
    col, row = index % columns, index // columns
    x0, y0 = col * width, row * height
    return sheet.crop((x0, y0, x0 + width, y0 + height))

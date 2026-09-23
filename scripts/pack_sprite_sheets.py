#!/usr/bin/env python3
"""Pack existing per-frame plates into catalog sprite sheets, then drop the old imagesets.

Intro: 20 × 400×176 in a 5×4 grid (index 0 = first vine beat).
Yard ivy: 3 stages × 3 sway frames, row = stage, column = sway, 320×160 cells.
Mailbox ivy: 3 sway frames in one row of 320×160 cells.

Cloud drift stays a wrapping strip; it is not a frame cycle.
"""

from __future__ import annotations

from pathlib import Path

from sprite_sheet import INTRO, load_cell, pack_row_major, remove_imageset, scene_dir, write_imageset

ROOT = Path("/Users/liangzixuan/Desktop/ivy")
YARD = scene_dir("Yard")

INTRO_FRAMES = 20
INTRO_COLUMNS = 5
IVY_STAGES = 3
IVY_SWAY = 3
MAILBOX_FRAMES = 3


def pack_intro() -> None:
    """Replace intro-spread-1...20 with intro-spread-sheet."""
    frames: list = []
    for index in range(1, INTRO_FRAMES + 1):
        name = f"intro-spread-{index}"
        cell = load_cell(INTRO / f"{name}.imageset", name)
        if cell is None:
            if index == 1:
                print("intro sheet already packed")
                return
            raise SystemExit(f"missing {name}")
        frames.append(cell)
    write_imageset(INTRO / "intro-spread-sheet.imageset", "intro-spread-sheet", pack_row_major(frames, INTRO_COLUMNS))
    for index in range(1, INTRO_FRAMES + 1):
        remove_imageset(INTRO / f"intro-spread-{index}.imageset")
    print("packed intro-spread-sheet", INTRO_FRAMES, "frames")


def pack_yard_ivy(side: str) -> None:
    """Replace ivy-{side}-{stage}-{sway} with ivy-{side}-sheet."""
    frames: list = []
    for stage in range(IVY_STAGES):
        for sway in range(IVY_SWAY):
            name = f"ivy-{side}-{stage}-{sway}"
            cell = load_cell(YARD / f"{name}.imageset", name)
            if cell is None:
                if stage == 0 and sway == 0:
                    print(f"ivy-{side}-sheet already packed")
                    return
                raise SystemExit(f"missing {name}")
            frames.append(cell)
    write_imageset(YARD / f"ivy-{side}-sheet.imageset", f"ivy-{side}-sheet", pack_row_major(frames, IVY_SWAY))
    for stage in range(IVY_STAGES):
        for sway in range(IVY_SWAY):
            remove_imageset(YARD / f"ivy-{side}-{stage}-{sway}.imageset")
    print(f"packed ivy-{side}-sheet", len(frames), "frames")


def pack_mailbox_ivy() -> None:
    """Replace mailbox-ivy-0/1/2 with mailbox-ivy-sheet."""
    frames: list = []
    for sway in range(MAILBOX_FRAMES):
        name = f"mailbox-ivy-{sway}"
        cell = load_cell(YARD / f"{name}.imageset", name)
        if cell is None:
            if sway == 0:
                print("mailbox-ivy-sheet already packed")
                return
            raise SystemExit(f"missing {name}")
        frames.append(cell)
    write_imageset(YARD / "mailbox-ivy-sheet.imageset", "mailbox-ivy-sheet", pack_row_major(frames, MAILBOX_FRAMES))
    for sway in range(MAILBOX_FRAMES):
        remove_imageset(YARD / f"mailbox-ivy-{sway}.imageset")
    print("packed mailbox-ivy-sheet", MAILBOX_FRAMES, "frames")


def main() -> None:
    pack_intro()
    pack_yard_ivy("left")
    pack_yard_ivy("right")
    pack_mailbox_ivy()


if __name__ == "__main__":
    main()

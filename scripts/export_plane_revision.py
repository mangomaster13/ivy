"""Export plane backgrounds directly from retained generated originals."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
for source, name in [("travel-book-open.png", "memory-travel-book"), ("plane-no-ticket.png", "hk-plane-no-ticket")]:
    image = Image.open(ROOT / "art/plane-revision" / source)
    folder = ROOT / "ios/Ivy/Assets.xcassets/Scenes/Plane" / (name + ".imageset")
    folder.mkdir(parents=True, exist_ok=True)
    entries = []
    for scale in (1, 2, 3):
        filename = name + ("" if scale == 1 else f"@{scale}x") + ".png"
        image.resize((960 * scale, 480 * scale), Image.Resampling.LANCZOS).save(folder / filename)
        entries.append(dict(filename=filename, idiom="universal", scale=f"{scale}x"))
    (folder / "Contents.json").write_text(json.dumps(dict(images=entries, info=dict(author="xcode", version=1)), indent=2))

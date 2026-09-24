# Closeup content coverage · 2026-09-24

User-reported Dictionary handwriting and Gelato note screenshots exposed a second aspect-fit inside the root's 2:1 content. This fix keeps the root viewport, navigation gutters, footer, saves and 13 collectibles unchanged.

## Runtime changes and existing artwork

- Dictionary: the open-book background, printed overlay and normalized ink share `DictionaryCamera.artworkFrame`. The background covers content; the writing camera reserves the bottom 88 pt within the scene for actions and feedback. No stroke coordinates or save fields change. The existing transparent English lyric card rests over a camera view of bare stall timber (320×160 source bounds 125,95,64,32), clear of the pen stand and table edge.
- Gelato note: the 512×341 original is proportionally filled into 2:1. The visible source height is 256 pixels (y=42.5–298.5); the complete paper and leaf remain inside this region. The transparent order paper uses bare tasting-counter timber (70,110,64,32), clear of the saucer. Both keep their original lettering. The word menu now retains its complete 2:1 scene on narrow stages instead of putting a cropped rectangle beside controls on Night; compact actions use 92 pt widths.
- Big Top drawer and mirror, plus the existing Gelato gutter detail: `SceneDetailStage` expands the requested camera bounds to the viewport aspect and clamps its origin within the 320×160 source. Painted scenery, overlaid evidence and hit regions use one transform. No object or clue is cropped out of the requested detail bounds.
- Big Top order menu: reuse the existing full 2:1 `bt3-menu` tabletop instead of the 12:5 `bt3-menu-compact`. Ten persistent shuffled dishes reflow into two, three or four rows according to content height; hit targets remain at least 48 pt. The paper and bell retain their original scale and aspect. Narrow-screen label readability still needs device acceptance.
- Bathroom mirror: cover content with the existing 2.17:1 scene, cropping only the outer wall edges; transform glass and rubbing surface together.

Other shared physical backgrounds (containers, travel book, Vuori desk, bedroom and corridor) already match 2:1. Individual transparent tools, inventory icons, ticket paper and notebook evidence continue to fit their physical surfaces; these are not full-scene backgrounds and must not be stretched.

## Evidence and remaining acceptance

`python3 scripts/check_closeup_layout.py` executes the production Swift camera expressions and menu sizing at content heights 160–480 pt. It checks full coverage, preserved detail bounds, proportional book rendering, writing clearance and menu row bounds. Swift syntax parsing is a separate narrow check, not an app build or type check.

No app build, simulator/device launch, gameplay screenshot or gesture acceptance is claimed. On-device acceptance should cover Dictionary existing strokes/Undo/Enter/Back, both Gelato clues and word-menu input, Big Top evidence/menu/bell, and mirror rubbing. Original artwork is reused; no image generation or save reset is involved.

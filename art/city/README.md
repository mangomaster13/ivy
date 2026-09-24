# City overhead puzzle · approved 2026-09-24

The user approved `approved-overhead.png` and requested implementation using it.
`overhead-empty.png` is the production background derived with the built-in imagegen tool: remove the nine loose tiles and their shadows, then remove the painted grid lines. Preserve the approved tray, wood, ivy, lighting and top-down camera. Grid seams are rendered alongside the interactive slots rather than baked into the background.

## Asset and placement contract

- Background: `overhead-empty.png` → `city-puzzle-overhead`, exported directly at every scale by `swift scripts/export_city.swift`.
- Approved reference: original generated `exec-cc9d2636-137d-4c1e-a4f7-efa3fe286939.png`; production edit: `exec-e730609a-18b9-4993-a113-10245fe1a5e1.png`.
- Reference canvas: 1774 × 887, strict overhead tabletop. Runtime artwork and interactions share the same 2:1 fitted stage.
- Owning surface: wood tabletop for loose tiles; teal recessed tray for assembled tiles. Recess approximately x=178...850, y=125...740. Square board x=208, y=128, width=height=612, with side clearance to avoid stretching the square Hong Kong image into the slightly wider painted recess.
- Nine square tiles use the existing `city-jigsaw-master` in nine exact crops, preserving the finished collectible. They have 204-unit edges and no alpha padding. Each loose position and angle is defined in `CityGridLayout`; index order is back-to-front, selected tile rises above the pile, dragged tile above all others.
- The existing saved `cityLooseOrder` maps pieces to those stable positions. Removing a piece leaves its position empty. Existing board occupancy, swaps, returns, completed saves and reward logic remain unchanged.
- Board pieces are upright; loose pieces rotate as complete visual/hit-target assemblies. Dragging uses the same named coordinate space and retains the original center offset, straightening the lifted tile for placement. Invalid drops return to the source.
- Back and footer remain root-owned. No controls or removable pieces are baked into the backdrop.

## Generation prompts

1. Production clean background extraction from the approved scene: remove all nine loose photo tiles and their shadows on the right, reconstruct matching uninterrupted wood grain. Preserve the exact left teal tray, size, position, rim, contact shadow, ivy, warm upper-left lighting, tabletop, strict overhead camera and matte painted style. No new objects, photo fragments, residual shadows, UI or text. Landscape 2:1.
2. Remove only the four thin internal grid lines, seamlessly filling with matching matte teal material. Keep tray rim, location, scale, canvas, tabletop, ivy, lighting, shadow and overhead camera unchanged. Empty right tabletop; no new objects or text.

Generated artwork was inspected directly. No game build, device launch, screenshot or gesture test was run; runtime acceptance remains user-owned.

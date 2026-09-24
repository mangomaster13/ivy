# Vuori cloth connection

Approved 2026-09-23: [composition](review/vuori-cloth-approved.png). The existing `vuori-desk` is the full closeup background and camera reference; `memory-shirt-final` stays a separate object on its left. Yard is the painting-style reference only. The navy cloth rests flat on the desk at right. No tag or pre-drawn route appears.

`source/vuori-letter-cloth.png` is the transparent high-resolution cloth and embroidered lettering. Its nine anchor centers, measured on its 1268×1241 canvas, are columns `0.272, 0.505, 0.744` and rows `0.254, 0.471, 0.699`; `VuoriGridLayout` uses the same coordinates for touch and live thread. Letters are `A R L / V O I / E U T`.

`source/vuori-thread.png` is the approved warm copper two-ply thread isolated from the generated strip. Each runtime segment rotates between selected anchors and is trimmed back from the embroidered letters. Both sprites are exported directly from these sources at 1x, 2x and 3x in the Hall asset catalog. The approved composition is a design reference, not a runtime screenshot or a baked interface.

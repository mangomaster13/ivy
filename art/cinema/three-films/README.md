# Approved Cinema three-film artwork

`approved-design.png` is the user's approved before/after concept, including three film strips. It is not a runtime screenshot or a source of mechanically verified puzzle fragments.

Production sources were generated with the built-in `image_gen` tool. Exact prompts and reference roles are in [prompts.md](prompts.md).

- `ink-source.png`: the complete 4 × 5 seating diagram, labels and asymmetric aisle geometry, with **no heart**. It has an alpha channel. `CinemaInkLayer` partitions this one image so the three layers can actually reassemble into it. The same fragments print onto the film sprites.
- `film-source.png`: separate blank amber film material; the game adds each layer's real ink. No heart, notch clue or baked interaction text.
- `heart-source.png`: independent completion reveal, never part of the movable ink.
- `case-source.png`: three films laid on the existing case lining, preserving the empty case's camera, box and table. Pickup uses the existing empty-case image.

`swift scripts/export_cinema_three.swift` packages each original into its 1x/2x/3x catalog resources without upsampling. The exporter was run for asset production, not as an app build or validation pass.

Source art was inspected for the heart-free initial pattern, 20-seat diagram, English labels, visible three-film stack, containment on the box lining and consistency with the approved style. The diagram alpha was inspected to distinguish its transparent backdrop from the dark image-tool preview. Runtime masks, physical gestures and rendered layouts have not been tested. The case uses a camera-specific painting; inventory uses a face-on film assembly instead of stretching it into the case's perspective.

Gameplay and bounds: [Cinema integration](../../../docs/gameplay/cinema/IMPLEMENTATION.md).

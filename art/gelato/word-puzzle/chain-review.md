# Word chain design review · 2026-09-24

The user approved the word-chain direction, then identified an answer leak in the proposed art: visible marked letters can be unscrambled without solving the chain, especially with four distinct flavour choices. The v2 menu is superseded, not approved for integration. The user suggested typed flavour input instead of choosing among flavours. Input alone does not eliminate the marked-letter anagram shortcut; the proposed follow-up is to expose extraction marks only after a correct complete chain, then require typed JASMINE. No revised artwork or implementation of that follow-up has been completed.

Generated with built-in image_gen:
- `chain-menu-superseded-v2.png`: seven word layout, accurate letter marks, but leaks answer letters; do not ship.
- `chain-order-design-v2.png`: CUP → PEACH with linked P letters. Review image has a dark surrounding background; it is not a verified transparent production sprite.
- `chain-note-design-v2.png`: bench note reading “Follow the chain. Read the leaves.”

References: prior flavour-sheet-design-v1 for counter geometry and paper palette; current story-yard-base@3x catalog art for style on the clue sheets; current explore-gelato-bench@3x was inspected for context. The v2 menu inherits the prior Yard-referenced composition. All generated writing is concept lettering, not an exact production Juniper layer. Generated images were visually inspected for wording, support and marker positions. No game tests, builds or device checks ran; no game code or saves changed.

Intended chain: JAR → RAIN → NUTS → STEAM → MINT → TANGERINE → EGG. Extracted indices (one-based): 1, 2, 4, 5, 2, 3, 1 → JASMINE.

Generation prompts: `chain-prompts.txt`.

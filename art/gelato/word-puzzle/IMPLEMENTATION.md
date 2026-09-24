# Approved word-chain assets · 2026-09-24

User approved the artwork and requested implementation after requiring delayed marks and typed flavour input. The v1 anagrams are retired. `chain-menu-superseded-v2.png` is now approved **only as the post-chain state**, never the initial menu. Its historical filename is retained for provenance.

| Source | Runtime image | Visibility |
| --- | --- | --- |
| chain-menu-unmarked.png | gelato-words-unmarked | Before full chain submission succeeds |
| chain-menu-superseded-v2.png | gelato-words-marked | After full chain succeeds |
| chain-order-design-v2.png | gelato-word-order | Order on service-side backing; independent clue |
| chain-note-design-v2.png | gelato-word-note | Bench note; independent clue |

The built-in image_gen produced the unmarked image by removing only the seven sprouts from the approved marked design. Words, paper, camera and countertop are preserved. See `unmarked-prompt.txt`. The original v2 generation prompts are in `chain-prompts.txt`; the Yard catalog art supplied the visual anchor. `scripts/export_gelato_words.swift` packages each catalog scale directly from its source. The lettering approved in these images is used directly, not substituted with native labels.

Menu reference is 1774×887. Word centers and widths live in `GelatoWordArtwork`; selection ordinals represent the player's attempt, not correctness. Paper inset contains all printing. The service-side order sits on the timber backing at logical rect (50,38,31,20); its world crop uses the authored paper silhouette to exclude the dark source backdrop. Bench clue uses the existing paper at (131,95,26,12). Counter and cabinet hotspots match the existing service view, not the retired gutter view.

The two source states were visually inspected: words and marker positions match the intended extraction. The initial state has no markers. Image inspection and asset export are not game verification; no build, test, device launch or screenshot pass was run.

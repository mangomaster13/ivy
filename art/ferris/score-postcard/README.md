# Ferris — glockenspiel and harbour postcard

Selected after artwork inspection on 2026-09-25 under the user's instruction to use recommended choices without further questions. Built-in imagegen supplied physical artwork; `scripts/export_ferris_score.swift` produces the exact independent notation/lettering and 1x/2x/3x catalog assets. No game build, tests, simulator or game screenshots were run.

Yard's documented `art/yard/source` folder is absent in this checkout. The current `story-yard-base@3x.png` was inspected and supplied as the style reference instead; it is not enlarged into a new source. Existing booth and cabin production images establish spatial identity. No new character or iPod artwork is used.

| Source | Runtime asset | State / physical contract |
| --- | --- | --- |
| `source/cabinet.png` | `ferris-music-cabinet` | 1774×887; seven brass bars on felt pads, tethered mallet, clipped blank paper, record toggle, pull handle, empty ticket slot. The exact score/draft are separate graphic layers. |
| `source/harbour-low.png`, `harbour-middle.png`, `harbour-high.png` | `ferris-harbour-0/1/2` | Fixed cabin framing and shelf. Strong foreground roof parallax, then clock tower, then dome. Fictional harbour geography, not a precise real-world vista. |
| `source/press.png`, `press-empty.png` | `ferris-press`, `ferris-press-empty` | Same three drums, lever, shallow supported card bed. Second image removes only the card; it is used after retrieval. |
| `source/cabin-empty-bed.png` | `ferris-cabin-empty-bed` | Source crop `(183,620,220,75)`, replaces only the little press bed in the main cabin while no card is placed or after retrieval; never obscures a window or clue. |
| `source/postbox.png` | `ferris-postbox` | Empty exit postbox and open return carriage. Main view uses this only after ticket use; before that it shows the existing closed boarding scene. |
| `source/stamps.png` | `ferris-stamp-0/1/2` | Individually cropped warehouse / clock / observatory ink artwork, derived from the actual landmark identities. All drum faces accept all motifs. |
| `source/postcard.png` | `ferris-postcard` | Physical paper crop `(34,44,1468,932)`, not an advertised transparent sprite. Worn corners and full paper border remain. Right seat uses a surface-aligned transform; pickup removes the independent layer. |
| `source/postcard-finished.png` | `ferris-postcard-finished` | Same card with precise Juniper title and all three postmarks. Existing `ferris` ID and slot are retained. |
| Exporter-generated layers | `ferris-score`, `ferris-near-far-lettering`, `ferris-stamped-lettering`, `ferris-record-off/on`, `ferris-postcard-clue` | Bounded exact graphics; dynamic input remains independently drawn. Notes preserve the score and near/far evidence, not bar-index answers. |

## Measured placement (320×160)

- Music inspection crop: `(78,22,200,100)`. Bars' x centres: `96,120,144,166,188,211,233`, y hit range `87...117`. Cropping enlarges the closeup so adjacent minimum-48pt hit regions remain separate at the stated 533×266 content budget.
- Upper paper writable inset: `(100,27,116,20)` for target staff; `(100,45,116,20)` for draft. Record strip: single played note centred `(155,73)`, recording word `(199,73)`; toggle `(229,65,12,16)`; pull handle `(254,53,17,37)`. Undo uses existing shared UI in the top-right free space, not over the paper.
- Ticket paper centred `(159.5,152)`, anchored immediately below cabinet slot. It is not baked into the closed cabinet.
- Cabin postcard on right seat: `(252,122,27,18)`; pitch follows cushion surface. Press entry `(23,98,51,28)`; shelf belongs to left bench wall and does not bridge the aisle.
- Press drum centres `(111,68)`, `(157,68)`, `(204,68)`; each symbol fits a 24×25 interior. Card's usable inscription rectangle `(99,94.5,116,21)` is inside the full supported bed `(89,91,135,27)`. Press lever `(263,30,24,35)`.
- Postbox slot `(122,91,20,10)`; return carriage `(210,38,52,73)`; departure walkway `(278,125,40,30)`.

`cabinet-lettered.png`, `press-lettered.png` and `postcard-finished.png` are authored-art composites inspected for spelling, surfaces, object counts and motif fit. They are not runtime screenshots or proof of gesture acceptance. The first low/middle variants were rejected for simply removing landmarks without sufficient visible occlusion. The selected variants use stronger foreground occlusion. The postcard generator retained an outside tan field; the exporter crops to the physical paper bounds instead of calling it transparent.

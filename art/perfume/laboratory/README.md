# Lost Labels — perfume laboratory

Status: gameplay and visual proposal approved by the user on 2026-09-27; production artwork and game integration written. Build/device/gesture acceptance remains user-owned and has not been run by the agent.

## Proposal

`source/laboratory-proposal-v2.png` is a 1774 × 887 overview design, generated with the built-in imagegen tool on 2026-09-27. It is not a production background containing baked interactive objects. The open journal, paper flap, samples, tested strips, labels, cup selections and finished outputs require separate states/artwork after approval.

Current catalog references were inspected before generation:

- `Scenes/Yard/story-yard-base.imageset/story-yard-base@3x.png`: visual language only.
- `Scenes/LeLabo/ll4-bench.imageset/ll4-bench@3x.png`: shop, camera family, materials, desk, shelves, window and brass lever.
- `Scenes/LeLabo/ll4-entry.imageset/ll4-entry@3x.png`: current shop and gift-box continuity; reviewed, not supplied to the generator.

The historical `art/yard/source` directory is absent from this checkout. Current catalog references are not claimed to be the missing high-resolution production originals.

## Prompt and provenance

First generation: `exec-4699eb9e-888a-4b95-9b9a-d8df627f9002.png` in the current task's generated_images directory. Asked for a 2:1 full-scene worktop inspection matching Yard's dark hand-drawn contours, grouped colors, restrained stepped texture, matte surfaces, teal shadows and local amber light. Left: readable paired laboratory records and folded reference. Center: exactly six neutral sample vials A–F in a supported three-by-two rack, six scent papers and paper dispenser. Right: three empty cups X/XXII/XXX and the existing physical lever. No game footer, new UI controls, finished perfumes or revealed sample identities.

Revision: `exec-254ed952-7512-4864-ac43-4680b65a7ea9.png`, copied unchanged as `laboratory-proposal-v2.png`. Preserve geometry/lighting/objects; replace wrong botanical tag illustrations with exactly Gaiac Wood, Cedar, Incense, Bergamot, Oakmoss, Patchouli; contain the entire journal on the table; replace illegible right-page text with Cedar unchanged. and a fully closed reference flap.

## Artwork inspection

The reviewed revision has all six A–F samples and six named loose tags, three empty cups, a closed reference flap, the two correct Cedar observations and no clipped journal edge. Glass bases, rack, pages and tags rest on the worktop. Lighting and dark hand-painted outlines follow the supplied references. No app launch or game screenshot was used.

This is a composition proposal. Generated lettering is not the final Juniper typography asset; all production lettering will be exported independently using the bundled font within the paper's inset face. Small overview labels are not intended as the sole readable clue surface.

## Proposed physical surfaces and interaction split

Normalized overview bounds measured visually from this proposal, pending exact production source exports:

| Assembly | Owning support | Overview bounds | Interaction |
| --- | --- | --- | --- |
| Journal | Left tabletop | x .02–.34, y .48–.81 | Opens full-size paginated records; no scrolling |
| Six samples | Two levels of wooden rack | x .37–.61, y .34–.66 | Opens sample/label closeup; A–F remain stable |
| Six papers | Table below rack | x .36–.62, y .66–.77 | Closeup pairs each paper with its explicit A–F ID |
| Loose labels | Foreground tabletop | x .37–.82, y .78–.95 | Separate lettering and tag sprites, reversible assignments |
| Cups | Brass tray on right tabletop | x .64–.85, y .49–.71 | Opens three named recipe drafts; each has two sample positions |
| Lever | Right wooden machine base | x .82–.99, y .08–.84 | Whole-set submission inside blending view |

The rack's upper/lower support lines are approximately y .49/.63; upright vial height projects above them, without extending the worktop. The overview's small hit regions open enlarged closeups. Production closeups must reserve at least 48-point targets in the root content viewport and independently readable two-record pages. Back and Notes remain the existing root controls; do not bake them into artwork.

Asset identities for production: sample A–F vials (neutral laboratory containers, never revealing their ingredients); six separate material-name tags; six abstract mark sprites; blank/tested scent papers; closed/open reference; three formula pages and two observation pages; three cup draft overlays; existing `ll4-upright-*` and `ll4-seated-*` finished bottles. The mark-to-material map lives in `PerfumeLaboratory.swift`; no plant illustration may accidentally disclose an unknown sample's identity.

## Production assets and integration

`scripts/export_perfume_laboratory.swift` exports all 1x/2x/3x directly from generated originals, or from authored CoreText/CoreGraphics lettering/mark sources. `ll4-notes` and the six existing `ll4-label-*` assets are reused. The bundled Juniper face supplies new inscriptions. Backgrounds never contain game controls or the runtime paper marks/guesses.

| Source | Generated original | Export/use |
| --- | --- | --- |
| samples.png | exec-06e6b057-dc55-4fd8-9ec2-c69bfc510125.png | ll5-samples: six A–F vials and blank fixed paper surfaces |
| blending.png | exec-40fd9868-654b-4a65-9a39-8a6968566894.png | ll5-blending: three empty cups with blank draft labels |
| overview.png | exec-183f9cdf-7789-4bfe-9e4f-2821a66db9c6.png | ll5-overview: scene 4; dynamic tags and record inscriptions are separate |
| paper-sprites.png | exec-e2261301-b54b-42ac-bb20-67035ac97df2.png | Alpha-preserving extraction of scent-paper tool and closed reference |
| empty-tray.png | exec-1c0a6fef-d14a-416a-8601-61c514935bde.png | ll5-empty-tray: matching cup-removal state; independent bottle sprites |
| overview-empty.png | exec-57db77f9-d919-4d72-99a3-04ced62fab24.png | ll5-overview-empty: exact matching empty dispenser and output tray |

Production prompts enlarged the approved rack and blending area with the same materials, light and camera family, omitted runtime identities/answers, and specified supported objects and clean work surfaces. Empty-state edits removed only cup/card silhouettes or dispenser papers. Source results were inspected for six samples, three cups, support, letter identity, hidden reference and same-scene state geometry. Lettering and both extracted paper sprites were also visually inspected. These are artwork inspections, not app screenshots.

Actual source coordinates, on the shared 320×160 canvas:

- Sample columns x=74/156/234, centers y=40/89; support bases y≈62/113. Fixed paper centers x=102/186/263, y=54/103. Player labels sit on the shelf front at y=66/117; six loose label slots are x=27+53i, y=141. No slot reflow after a label is placed.
- Blending cup centers x=70/120/171, front label y=95, support base y≈112. Finished bottles use the same tray support at y=111. Each completed cup is removed with a 49×57 source-aligned mask centered at (x,87), then its output sprite is drawn independently. Lever target (232,28); foreground sample selectors x=27+53i,y=141. Feedback occupies the top-left area and does not shift controls.
- Book writing bounds: left page x=25–147, right x=173–293, y=24–132. Observations are side-by-side, with 118×18 headings and paired 30×30 marks. Folded reference at (236,118), 49×39. No native scene text overlays. Notes draws the same evidence and only includes discovered pages/marks; legacy formula page identity maps to the unified recipe spread.
- Source-sized targets are enlarged to at least 48pt. Rack rows and foreground label centers stay distinct at a 512×256 fitted viewport. Tap-then-target is available for labels and recipe samples; dragging uses the same target geometry before its positioning transform. Tapping an assigned label selects it; tapping the same bottle again returns it. A cup tap with no selected sample removes its last sample; accessible actions can also remove the first.

`PerfumeLaboratory.swift` now owns sampling, labels, complete-set judgment, page evidence, pickup and migration guards. `PerfumeLaboratoryViews.swift` owns rack, records, blending, overview state overlays and enlarged closeups. Existing cabinets remain scenery; the old raw-material pickup and old blending entry points are disabled once the optional laboratory record is activated. Successful batches create three independent pending outputs; reload never puts unclaimed output in Tools. The existing gift-box order and perfume ownership commit are reused.

Two focused XCTest methods cover pure state/legacy decoding and the integrated tool–Notes–blend–pickup–box path. They were written but not executed. No validation scripts, verification build, device launch, reset or game screenshot pass was performed. Runtime touch/drag behavior, final device text size and artwork alignment still require user acceptance.

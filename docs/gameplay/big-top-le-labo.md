# Big Top → sloping street → Le Labo

Historical implementation record. Current gameplay, anti-greedy rules and lettering are governed by [IVY-GUIDE](IVY-GUIDE.md) and [UI-RULES](../ui/UI-RULES.md). The correct-prefix neon feedback, placemat pickup, native display lettering and legacy room/save identifiers below describe the old version and do not override the current target. Runtime verification remains user-owned.

## Journey and physical entrances

Gelato's visible glass-tube neon uses a random permutation, saved across visits and excluding the answer and its reverse. Open its physical closeup and tap B-I-G-T-O-P directly; each tube has its own fixed colour. Correct taps keep the prefix illuminated; any wrong or repeated tap immediately extinguishes all tubes and clears the prefix. The sixth correct tap saves the completed fact, the tubes settle into BIG TOP order, and only then does the scene transition into Big Top. There is no input field, Enter or backspace. This is the confirmed 2026-09-21 design; implementation is pending. World and closeup reuse the same tube sprites. Approved visual direction: art/big-top-le-labo/design-v2.

Big Top has a dining-table view and a counter/service view. Scene 1 owns the dining menu; scene 2 owns the service-side search and must not duplicate scene 1’s clipboard entrance. Fold back the table placemat, take the menu into Tools, and place it on the order clipboard. Placement immediately opens the menu; later taps on the placed book open it directly without a clipboard inspection step. The four-page textured paper menu has twenty English dishes and persistent pencil ticks. Tap a dish to toggle its mark, then press the physical brass bell to submit the entire order; wrong menu choices remain editable. Paper, cloth and clipboard use authored painting assets, not flat colour blocks. Exactly Half Roast Goose, Steamed Rice, Rice Noodles, Lemon Tea and Ovaltine succeeds. Rice/noodles are one bowl, drinks one glass. The dining table then displays the five-item meal. The first tap on the served meal opens Element and immediately persists the existing `noodle` reward; there is no second pickup tap or flight interstitial. Serving the correct meal opens the exit to the street immediately; claiming its memory is a separate optional action before leaving, and remains available upon return.

The sloping Hong Kong street is viewpoint 0 of the existing `supermarket` room identity. Its left restaurant door returns to Big Top. LE LABO is a native label on the high projecting shop sign; the right-hand shop door opens interior viewpoint 1. Viewpoints 1–4 are connected only by interior scene arrows: display/book → wood cabinet → botanical/spice worktop → blending bench. The physical shop door returns to the street. After collecting perfume, the uphill path goes to cinema. Cinema's back route returns to the street.

## Perfume catalogue and actions

All three products use complete names: Gaiac 10, Bergamote 22, Mousse de Chene 30. Tokyo and Amsterdam are contextual city labels, not substitute product names.

- Gaiac 10: Gaiac Wood + two distinct choices from Musk, Cedar, Olibanum / Incense.
- Bergamote 22: Bergamot + two distinct choices from Grapefruit, Petitgrain, Orange Blossom, Vetiver, Cedar.
- Mousse de Chene 30: Oakmoss + two distinct choices from Patchouli, Crystal Moss, Clearwood, Cinnamon, Pimento Bay Oil, Pink Pepper.
- Five game distractors: Cardamom, Iris, Violet, Jasmine, Ambroxyde. These are documented notes in Le Labo's other products, not claims about complete commercial formulas.

The target catalogue has twenty individual ingredient tools, distributed across four physical containers by material rather than correct recipe. Remove one non-essential distractor from the current twenty-one while keeping old IDs decodable. Players read formula features, then search by shape, storage and cross-view evidence; they do not need to clear every room. Horizontal Tools scrolling remains available and retains its view when toggling Memories.

Place three ingredient bottles in the bench's holders by tap or drag. Any ingredient is accepted in any holder, including wrong choices. Tap a held bottle to return it or replace it with another tool. The painted press handle judges the complete mixture; incorrect mixtures remain intact. No quantities, timers, alcohol ratios or finite stock. Success returns the source bottles to Tools and produces one labelled product at the press, awaiting a separate pickup. The same fragrance cannot be produced twice.

Place the products left to right in the presentation box: Gaiac 10 → Bergamote 22 → Mousse de Chene 30. All slots accept all bottles; support drag, tap selection, movement, swapping and returning a bottle to Tools. Individual placement does not disclose correctness. Full correct arrangement becomes the shared Element presentation. Correct arrangement immediately saves `perfume`, removes remaining fragrance tools and opens the uphill route as Element appears; there is no second pickup tap. Migrate old `supermarket` ownership on load.

## Evidence and inventory

The physical formula book contains three diagrams: core on the left, possible supporting materials on the right, one-filled-plus-two-outline-drop notation. Only pages actually viewed enter Notes. The presentation lid's full-name order inscription is preserved in Notes. Its product-number evidence is written as Roman numerals X, XXII and XXX, meaning Gaiac 10, Bergamote 22 and Mousse de Chene 30; these are product numbers, never slot numbers. These use the same native components in both locations, not generated walkthroughs. Notes opens from closeups and returns to the previous overlay and its existing navigation stack.

All tool pickups switch the footer to Tools, including petals; tools and ingredients are never auto-selected upon pickup. Placed tools leave the tray. Reusable raw-material stock returns after successful blending. Memories retain all thirteen stable IDs. First collection uses the existing flight; subsequent inspection uses Element with the original return context.

## Persistence and compatibility

`MemoryProgress.bigTop` and `.perfumery` are optional records. Old completed `bigTop` / `perfume` markers and collected `noodle` / legacy `supermarket` IDs migrate to complete new puzzles and the current `perfume` collectible. Already reached downstream rooms retain their route access; migration does not grant missing keepsakes. Menu page and choices, neon draft, container openings, ingredient discoveries, mixture holders, unclaimed output and presentation positions persist. Transient selection/animation and open overlay are not used as completion facts.

Files: FoodAndFragrance.swift owns catalogue and guarded actions; BigTopViews.swift and PerfumeViews.swift own physical closeups; FoodAndFragranceWorld.swift owns native labels/removable world objects. Existing root layout, navigation, inventory, collection and asset export rules apply.

## Current design status

The 2026-09-21 Vuori tag layer, Gelato rainwater-routing and ingredient-relationship chain, Big Top settle-before-transition order, scene 2 service-side menu search, twenty-ingredient catalogue target and Roman product-number inscription are confirmed design requirements awaiting implementation. Existing saves remain compatible through migration from the old `supermarket` collectible ID to `perfume`.

## Delivery scope

Artwork originals and generation notes live in `art/big-top-le-labo`. All asset scales are exported directly from selected original images. UI text stays native. No tests, verification build, device run or screenshot pass was performed for this implementation. Preserve the user's normal save; any subsequent agent review must use non-persisting IVY_REVIEW.

## Open visual defects · user reference IMG_6237.PNG

The user reports Le Labo sign overflow, missing individual ingredient design and misaligned ingredients. The supplied cabinet screenshot shows repeated small bottle imagery intersecting shelf fronts; it does not show the reported sign. Source inspection finds height-only sizing in LeLaboBrandArtwork, common bottle fallback artwork for ingredients, and separate index-derived world/closeup grids. These are implementation risks consistent with the reports, not a completed render diagnosis.

The user subsequently authorized implementation of the new material direction. The repair now uses 21 individual transparent ingredient assets, stable ID-based shelf/support placements, a bounded brand mark, the new reception background and a physical compartment tray. Source art was inspected and exported; runtime appearance and gestures have not been device-verified.

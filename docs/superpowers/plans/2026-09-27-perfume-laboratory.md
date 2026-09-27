# Perfume Laboratory Implementation Plan

**Goal:** Replace ingredient collecting and repeated blending with the approved six-sample deduction puzzle.

**Architecture:** Keep the existing shop, GameStore, inventory, three finished bottle identities, gift-box assembly and thirteen memories. Add an optional laboratory record to PerfumeProgress, with a small value model for sampled papers, movable guesses, three complete recipes and independently taken outputs. Views must not decide correctness.

**Tech Stack:** SwiftUI, existing asset catalog and XCTest target; no new dependencies.

**Spec:** The user's approved “失去标签的香气” proposal in this task, made concrete below.

## Constraints

- Work on main and preserve unrelated working changes. Commit/push only if the user opts in.
- Do not run tests, validation scripts, verification builds, device launches or game screenshots: testing is user-owned.
- UI-RULES requires approval of concrete visual artwork before production integration. Prepare art and independent logic now; export and connect the approved design afterwards.
- Preserve legacy ingredient IDs, finished perfumes, gift-box arrangement, access and collectible ownership. Never reset player saves.
- One whole-set judgment; no correct ingredient, label or cup feedback. Labels and clue reading are not completion prerequisites.
- Authored English lettering, Yard style, physical support bounds, root-owned controls and 48-point targets.

## Puzzle specification

Six anonymous samples A–F map to a persisted shuffled order of gaiacWood, cedar, incense, bergamot, oakmoss, patchouli. Their liquid appearance must not identify the material. Each has one invariant abstract mark: gaiacWood=dashes, cedar=branch, incense=rings, bergamot=stars, oakmoss=mesh, patchouli=waves.

Four historical observations, shown as two readable pairs:

1. Cedar + Incense → branch + rings.
2. Cedar + Patchouli → branch + waves.
3. Bergamot + Gaiac Wood → stars + dashes.
4. Bergamot + Oakmoss → stars + mesh.

The common mark identifies the common ingredient; each remaining mark identifies the other ingredient. Both groups are uniquely solvable. A physical folded reference exposes Cedar's branch mark on request. Notes contains only discovered evidence, never automatically inferred labels. No Hint button or timed tutorial.

Final recipes are simplified fictional game formulas: Gaiac 10=gaiacWood+incense; Bergamote 22=bergamot+cedar; Mousse de Chene 30=oakmoss+patchouli. None is copied from a historical observation. Pair order is irrelevant; three cup identities matter. Each material is used once. There are 90 full partitions into three named pairs; no partial validation reduces that search. Recipes show names, not target marks. Correctness does not depend on player-applied labels.

Take reusable scent papers from the dispenser, actively select them, then tap samples. Tested papers remain in front of their sample. Movable labels are optional guesses and can be swapped/removed. Tap or drag a sample into a cup; change/remove freely. Press the physical lever to judge the whole unfinished set. Failed complete attempts retain drafts. Success produces only missing finished bottles, each separately collected into Tools, then the existing Roman-numeral box assembly awards perfume.

## Task 1 — Concrete artwork and placement

Files: `art/perfume/laboratory/README.md`, `art/perfume/laboratory/source/`.

- [x] Produce and inspect an overview proposal against current Yard and Le Labo catalog references. Document that historical source paths are absent in this checkout.
- [x] Present the actual image for approval. The overview is not a production bitmap containing the whole interactive UI.
- [x] After approval, author separate closeups for readable records, samples/labels and blending; export independent strips, labels, sample IDs, cup drafts and folded reference states.
- [x] Record physical surface bounds and shared image/hotspot transforms in the artwork README. Keep six samples distinguishable by A–F, not semantic bottle shape or material color. Each ingredient label has its own lettering asset; no ingredient-art substitution.

## Task 2 — Persistent puzzle model

Files: `ios/Ivy/Game/PerfumeLaboratory.swift`, `ios/Ivy/Game/FoodAndFragrance.swift`, `ios/IvyTests/WonderlandTests.swift`, `ios/Ivy.xcodeproj/project.pbxproj`.

Interfaces: `PerfumeLabProgress(legacy:)`, `sample(_:)`, `assignLabel(_:to:)`, `placeSample(_:in:)`, `removeSample(_:from:)`, `submit() -> Bool`, `takeBottle(_:) -> Bool`; fixed evidence and formulas in `PerfumeLaboratory`.

- [x] Add optional `PerfumeProgress.laboratory`; decoding an old save leaves it nil and preserves old fields.
- [x] Implement bounded actions, unique sample use, movable guesses, order-insensitive pairs and whole-set completion. Keep unclaimed outputs distinct from produced bottles.
- [x] Map previously known selected ingredients to discovered samples/labels. Preserve produced/taken bottles; unfinished recipes remain solvable without reproducing old successes. Do not activate migration before new UI is ready.
- [x] Leave one focused XCTest covering deductions, wrong drafts, complete submission, legacy progress and Codable round trips. Do not execute it.

## Task 3 — Approved art and game integration

Files: `PerfumeViews.swift`, `FoodAndFragranceWorld.swift`, `Exploration.swift`, `ExplorationViews.swift`, `ExplorationLayout.swift`, `MemoryJourney.swift`, `ContentView.swift`, existing inventory artwork routing, new catalog assets and export script.

- [x] Connect store-guarded actions only in the appropriate room/panel; preserve Back, Notes return location and partial drafts.
- [x] Add a scent-paper tool with explicit pickup and selection, independent from scene paper samples. Clear transient selection on leaving, not persisted drafts.
- [x] Replace the old blend controls and disable material collecting for the new path; leave old IDs decodable. Reuse the existing box and collection flow.
- [x] Replace formula Notes pages with the same discovered artwork used on the desk; never leak unsampled marks, hidden reference or inferred identity in accessibility labels.
- [x] Route pending legacy output to the new physical output row without duplicate pickups. Preserve old owned/arranged states and street/scene access.
- [x] Update IVY-GUIDE and DEVELOPMENT to describe the actual integrated revision, superseding the old twenty-ingredient rule only when integrated.

## Delivery evidence

Source review and generated-art inspection are distinct from runtime verification. Report exactly what is integrated, what awaits art approval and what remains user-tested. No agent-run tests or builds for this ordinary development request.


Implementation complete in source and assets; all checked steps describe authored/reviewed work, not executed tests. Tests, app build and device acceptance were deliberately not run.

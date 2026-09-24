# Gelato Word Chain Implementation Plan

**Goal:** Replace the water/flavour-choice puzzle with the approved complete word chain, delayed leaf extraction, typed JASMINE and active spoon tasting.

**Architecture:** Keep Gelato's existing menu/tasting/container routes. An optional Codable progress record owns the draft, chain completion and flavour completion; the store guards every action. Existing collection and tool consumption remain authoritative.

**Tech Stack:** SwiftUI, Codable, existing asset catalogs and XCTest.

**Spec:** User-approved conversation; artwork in `art/gelato/word-puzzle/`. The visible-leaf menu is approved for the solved state only.

## Constraints

- Stay on main; preserve unrelated work and all 13 collectibles.
- Whole-chain feedback only; no marks or marked-letter accessibility labels before completion. No flavour choices.
- Keep partial drafts, wrong answers, tool ownership and completed legacy saves.
- Use native keyboard, painted input, root Back/footer handling and 48 pt controls.
- Tests and device verification are user-owned; write focused regression coverage but do not execute checks or builds.
- User approved checkpoint commits and normal pushes. Commit only this feature and its necessary keyboard-focus dependency.

## Milestones

- [x] Export the approved menu, clue images and a matched unmarked state; record exact placement and provenance. Commit and push assets.
- [x] Add `GelatoWordProgress` and store operations; migrate old menu/water completion and saved collection without replay. Route legacy entry points through the new gates.
- [x] Replace menu and tasting UI, connect order/bench clues and Notes, remove water interaction entry points. Supply order feedback as selection ordinals, never correctness.
- [x] Update current gameplay/UI rules and focused existing XCTest cases for wrong/full chain, premature input/taste, reload and old-save compatibility. Read the changed code; do not run it. Commit and push the integrated feature.

The initial layout uses the approved 1774×887 menu canvas. Paper occupies x=0.08…0.76 and y=0.23…0.87; words use the image's three rows. The right countertop owns submit/input, below the lantern. All drawing and targets share the fitted canvas. Below 528×264, the paper camera crop and external action column support 480×230 while keeping 48 pt hit areas; keyboard focus gives the input the content width.

Implementation and source review are complete. Regression tests are authored but not run; build/device checks remain user-owned. Push status is reported in the task.

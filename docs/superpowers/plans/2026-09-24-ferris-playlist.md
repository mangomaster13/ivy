# Ferris playlist implementation plan

**Goal:** Replace the two-ticket placeholder with the user-approved iPod order → ticket pickup → ticket use → cabin → phone selfie flow.

**Architecture:** A dedicated FerrisProgress and GameStore extension own durable facts and guards. FerrisViews uses existing exploration, inventory, fitted artwork, Back and Element presentation. No new dependencies or collection IDs.

**Spec:** User approval in this task, 2026-09-24. Exact order: Enchanted / I don’t want to say goodbye / Part of the band / 也许 / Lover. No new clues or listening wait.

## Constraints

- Remain on main. Commit and normally push completed milestones as requested.
- User owns testing: do not run tests, validation scripts, verification builds, devices or screenshot passes. Add one regression check for state guards and restore, without executing it.
- Preserve the thirteen collections, old ferris ownership and opened facts. Separate ticket issued/taken/used and phone taken/photo taken.
- Existing Yard-styled exterior and cabin door art can be reused. New objects need authored artwork; exact track lettering is exported separately, never generated spelling.
- Real selfie reference has not been supplied; any illustrated couple is explicitly provisional, not a likeness claim.

## Milestones

- [x] State and save compatibility: add FerrisPuzzle.swift, optional MemoryProgress.ferris, tool identities, retirement of solveLater ferris, reset integration, and one XCTest in the existing test target. Persist whole-list drafts; reject invalid reorder indices; gate pickup, ticket use, cabin entry and shutter in GameStore.
- [x] Scene and assets: add FerrisViews.swift and Xcode source entries, scene hotspots, tool art, whole-list drag and accessibility reorder, ticket dispenser and gate, cabin phone pickup and selected-tool camera, selfie Element. Keep every track visible without scrolling; use a close screen camera on compact viewports, with the shared Play action beside the screen. The user chose the classic click-wheel body; the scene retains it and the puzzle camera focuses its LCD.
- [x] Update current gameplay/status documents, record art provenance and manual acceptance steps, inspect the diff. No claims of runtime verification; the final integration is committed and pushed at delivery.

## Manual acceptance after delivery

Wrong full order stays editable; correct order issues a ticket without collecting it; leaving/restoring keeps the draft and each intermediate fact; ticket ownership alone cannot enter the cabin; using the selected ticket opens the door; phone pickup is separate from selecting it; shutter owns ferris exactly once; old completed saves bypass replay and retain access; Back returns to the correct view; drag and VoiceOver reorder match on the smallest and largest supported landscape phones.

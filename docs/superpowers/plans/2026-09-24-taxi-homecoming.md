# Taxi Homecoming Implementation Plan

> **For agentic workers:** Implement the approved Taxi design in the current checkout. Do not run builds, tests, or device passes: Ivy's testing policy assigns those to the user for ordinary development.

**Goal:** Replace Taxi's word answer with a physical route puzzle and return to the opening cottage for the finale.

**Architecture:** Reuse the existing room, memory closeup, Notes, and collection flows. Add one small persisted Taxi progress value and a dedicated scene closeup. Keep the 13 existing collection slots and migrate the old Taxi completion flag.

**Tech Stack:** SwiftUI, existing asset catalog, `GameStore` snapshot.

**Spec:** Approved Taxi visual design and route in `docs/gameplay/2026-09-23-later-eggs-tool-design.md`; latest user correction sends the cab to the opening Yard and ends with “Love always leads me home—to you.”

## Global Constraints

- Preserve unrelated changes already present in the shared working tree.
- Use the approved road, map and cottage images; keep each physical item aligned with its image state.
- Do not expose route correctness one edge at a time.
- Do not reset or lose older saves.
- Commit and push Taxi checkpoints to `main` as requested.

### Task 1: Approved artwork

- [x] Export each approved high resolution source directly into 1x, 2x and 3x Taxi image sets.
- [x] Keep the source images under `art/taxi/source`.
- [x] Review file names and source dimensions, then commit and push only Taxi artwork.

### Task 2: Route and receipt

- [x] Add saved route, card and receipt facts with defensive old-save migration.
- [x] Replace the Taxi word answer with card, route board and receipt interactions.
- [x] Record the route card in Notes; use a whole-route result and Undo.
- [x] Review the touched source and diff without running tests or a build.

### Task 3: Homecoming

- [x] Show the cottage arrival state and enable the left car door after arrival.
- [x] Route that door to the opening Yard, then use the existing Yard door to reach Hall.
- [x] Add the approved closing line to the existing ending and update authoritative design docs.
- [x] Review the final diff, commit and push only Taxi work.

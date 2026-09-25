# Ferris score and postcard implementation plan

**Goal:** Replace the iPod/people/selfie sequence with a playable glockenspiel, physical ride ticket, harbour observation and stamped postcard posting.

**Architecture:** Keep FerrisProgress and the existing GameStore/FerrisCloseupView seam. Preserve the thirteen keepsake IDs. Add only the postcard tool and postbox panel; the old camera panel routes to the press for compatibility. No new packages or shared UI redesign.

**Tech Stack:** SwiftUI, Codable, AppKit asset export, built-in imagegen.

**Spec:** The concrete interaction and asset contracts below. User approved the music/postcard direction and on 2026-09-25 delegated subsequent choices to the agent's recommendation, including artwork selection after inspection. Commits and normal pushes on main are authorized. Agent tests/builds/device launches are not authorized.

## Design and constraints

- Cabinet: seven naturally ordered brass bars, a clipped ivory staff, separate recording strip, physical record toggle, pull handle and empty ticket slot. Exploration strikes reveal the note; only recording appends it. Toggle does not erase a draft. Undo removes the last recorded note. Pull submits the whole phrase, never a prefix. Correct phrase (zero-based ascending staff positions): `[0,2,4,3,1,5,6,2,0]`. All notes have one duration, no accidentals or timed input. Both staff and accessible labels use the same mapping.
- The complete target staff is visible/readable and independently enters Notes on inspection, without gating submission on clue ownership. Notes contain evidence, not instrument-index answers.
- Ticket is emitted at the cabinet, collected separately, actively used at the existing gate and consumed. Opening the carriage remains a separate action.
- Cabin: original opposing benches and central walkway. A shallow fold-down shelf supports the three-drum press. A blank card is a separate pickup; active placement into the press opens its focused view. The card leaves Tools when placed. Completed card is separately taken back into Tools for posting.
- Window evidence has three reversible elevation stops with fixed interior framing: low shows pier warehouse, middle reveals clock tower behind the roof, high reveals the observatory behind the tower/ridge. These are authored fictional harbour landmarks, not claims about a real private memory or exact Hong Kong geography. No automatic timeout or reaction test.
- Stamp drums accept any of three landmark identities, including duplicates. Correct left-to-right order is warehouse, clock tower, observatory. A near-to-far pictogram and precise English inscription on the card communicate the rule. Wrong whole presses retain selections and leave no permanent ink. This is intentionally a short observation interlude after the main music puzzle, not a second anti-bruteforce main puzzle: at most 27 blind combinations / 6 permutations. Do not claim otherwise or add punishment.
- Exit postbox accepts the actively selected completed postcard, consumes it, awards existing `ferris` exactly once and opens Element. Old selfie ownership maps to posted. Old phone ownership maps to postcard taken. Old solved playlist maps to solved music; tickets and access survive. Old downstream access survives without a free keepsake.
- No iPod, main character art or camera in the new flow. Existing unrelated scene assets remain on disk as history, not selected by the new flow.
- Existing root Back/54pt footer and 48pt touch regions. Physical controls do not get duplicate floating buttons; Undo uses the existing PuzzleButton. No tests, validation builds, simulator or runtime screenshots; leave one focused XCTest source covering state, invalid transitions, round trip and old saves.

## Work sequence

- [x] Read current flow, rules, source images and shared controls; preserve initial worktree text in `/tmp/ivy-ferris-start` to isolate staging from unrelated work.
- [x] Generate and inspect cabinet, three cabin elevations, press closeup, postcard and exit postbox. Export from the selected source at each scale; author exact note/lettering layers independently. Record coordinates from the actual images in FerrisLayout and art README.
- [x] Implement music input and durable ticket facts in `ios/Ivy/Game/FerrisPuzzle.swift`, replace the iPod view in `FerrisViews.swift`, and add the score Notes entry.
- [x] Implement reversible cabin observation, postcard placement, press and posting in the same files; connect panel/tool cases, collection image, Element copy, reset and exit guards.
- [x] Update `ios/IvyTests/FerrisPuzzleTests.swift` with a runnable end-to-end state check: wrong melody retained; full melody grants only ticket eligibility; ticket selection required; invalid stamp attempt retained; completed card cannot award until selected and posted; duplicate posting idempotent; save round trip and legacy photo/phone/ticket migration. Do not execute it.
- [x] Update the Ferris implementation record and targeted current-guide rows; do not include pre-existing Taxi changes in commits.
- [ ] Commit and push completed milestones on main using normal Git, with precise unverified-runtime disclosure. Final delivery reports source inspection and artwork inspection separately from tests/builds that were not run.

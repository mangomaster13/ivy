# Ferris · ticket booth, fragmented melody, ride scene

2026-09-25: user approved replacing the iPod, boys and selfie with a glockenspiel ticket puzzle and a harbour postcard sequence, then authorized recommended choices without further questions and checkpoint pushes on main. Code and artwork are connected; no tests, validation builds, device launches or runtime screenshots were run. Player acceptance remains outstanding.

## Player flow

1. Enter a full ticket-booth scene. Only the service-window hotspot opens the musical instrument. Four loose scores replace the complete target: shuffled zero-based fragments `[0,1,4]`, `[4,3,6]`, `[2,5,0]`, `[0,3,2]`. A physical Join plaque opens an illustrated example and start/end notes. Use every fragment once, share equal end/start notes, begin on E and finish on D. No external music knowledge or hearing is required. Notes retain the shuffled evidence and example, never the answer.
2. Explore the seven bars to see their staff positions, then toggle the recording switch. Strikes append to the recording strip; Undo removes the last note. Leaving/reopening preserves the draft and recording mode. Pulling the handle judges the entire phrase without prefix feedback. The unique complete connection is fragment 4 → 3 → 1 → 2, producing zero-based `0,3,2,5,0,1,4,3,6`. Taking fragment 1 first reaches the end via fragment 2 but strands the other two. Wrong input stays editable; there are no attempt limits or clue-reading gates.
3. Correct input persists completion and returns to the cabinet. The ticket protrudes from its actual slot; inspect and take it separately. Choose the ticket in Tools and use it at the reader. Only then enter the carriage.
4. Boarding changes to the cabin main scene (view 2), not an inspection overlay. Position and height survive reload. The postcard starts inside the left-shelf press and cannot be taken before solving it. Root page arrows change elevation; scene arrows cannot bypass boarding or the door. The three existing, spatially consistent harbour plates remain in use. Inspecting the press opens a closeup; Back returns to the cabin. Its Near to far evidence enters Notes.
5. Turn three drums to warehouse → clock tower → observatory, applying the card's Near to far diagram. All three positions accept any motif, including duplicates. Pull the handle for a whole impression. Wrong attempts retain the drums and leave no permanent ink. Correct input stamps the card but grants no collectible yet.
6. Only after successful stamping, take the card into Tools. The left arrow descends high → middle → low, then remains available: one more press reaches the exit main scene (view 1). The physical door also exits at the lowest height, never above the platform. Select or drag the card to the postbox slot; posting consumes it, saves the original `ferris` collectible and shows Element. The red taxi then leads to Taxi. Revisit keeps the sent card available as a memory and does not require a consumed tool.

The main inference is reconstruction of the whole fragment chain, not copying a target staff. Blindly sweeping bars does not submit; the handle judges nine recorded notes at once, and neither exploration nor recording reports matches. Finite permutations can still be enumerated; this is not a claim of mathematical immunity to brute force. The three-stamp sequence remains a light observation interlude (27 raw combinations or six permutations).

2026-09-25 keepsake revision: “Above the city” uses the original `keepsake-ferris` wheel artwork for Element, Memories and Settings. The postcard remains a puzzle tool; posting and existing collectible ownership are unchanged. This asset-reference change was not built or runtime-tested.

## State and compatibility

`FerrisProgress` holds music draft, recording mode, ticket facts, elevation, card pickup/placement, stamp draft, stamped/retrieved/posted facts and exit access. GameStore guards each action's room, overlay and immediate prerequisites. `ferrisCamera` is retained as an internal old panel identifier for the press; no camera UI remains. New `ferrisPostcard` is a tool, never a fourteenth collectible.

`exploration.views["ferris"]` is 0 for the booth, 1 for the exit and 2 for the cabin. Old unboarded view-1 saves return to the booth; already boarded/owned saves keep their access. Existing solved music bypasses the new puzzle, while unsolved recorded notes remain editable. Boarding and alighting clear inspection ancestry and save the new main-scene position. The old cabin/postbox panel entry points redirect to physical navigation instead of opening nested scenes.

Decoder migration: `playlistSolved` → `musicSolved`; `phoneTaken` → `postcardTaken`; `photoTaken` → `posted`. Prior ticket facts persist. Existing owned/opened ferris sets posted; old matched ticket pairs preserve solved music. Existing downstream Taxi access preserves passage without manufacturing postcard ownership. A malformed local field does not discard the rest of the save. Old unstamped cards now wait inside the press instead of appearing in Tools; stamp drafts, completed stamping, retrieved cards and posted progress persist. Only retrieved, unposted cards restore into Tools. Retired phone tools are removed without triggering pickup UI. Restoring or migrating never forces the footer tab.

Source and scene contracts: [art README](../../../art/ferris/score-postcard/README.md). Current plan: [implementation plan](../../superpowers/plans/2026-09-25-ferris-score-postcard.md). Existing unrelated Taxi edits are excluded from Ferris commits.

The newer [scene and fragment artwork](../../../art/ferris/scene-redesign/README.md) supersedes that earlier plan's music and navigation. `scripts/export_ferris_fragments.swift` packages the new booth and blank four-paper cabinet, exact rule diagrams and Notes evidence. Runtime fragment ink uses the existing `FerrisStaff` geometry.

## Verification boundary

Return-navigation fix: a bounded Swift harness extracted the actual cabin navigation configuration and descent/exit methods. Before the fix it failed at height 0 because the previous arrow disappeared; afterwards three previous actions reached the exit scene with the card retained. Added an XCTest for descent, saved exit position and subsequent posting; the XCTest suite and device UI were not run.

Performed: source-flow inspection and visual inspection of generated art/lettering composites; production asset export. Not performed: XCTest execution, game compilation, simulator/device launch, runtime screenshots or gesture testing. `FerrisPuzzleTests.swift` contains one runnable state/compatibility check covering exploration vs recording, wrong drafts, complete submission, post-solve-only postcard pickup, active ticket/posting tool selection, stamping vs posting, persistence, invalid indices and old saves. These assertions have not been run.

## Ticket and physical navigation revision — 2026-09-25

User approved the ticket ready/empty and Ferris↔Taxi design board. The ticket inspection now uses authored ready/empty plates; cabinet paper and Tools share an independent matching ticket sprite. Taken/used saves keep the slot empty using existing facts.

The boarded Ferris side view and postbox inspection share the new forecourt: clickable red taxi on the road, postbox on pavement, accessible open gondola at left. The cabinet no longer has an invisible taxi navigation target. Existing posting/legacy-exit guards remain. Taxi has a permanent roof-clipped Ferris postcard on every driving plate, including arrival; clicking it returns to forecourt and leaves all driving progress intact. The garden door remains separate and arrival-only.

See [production artwork and anchors](../../../art/ferris/taxi-navigation/README.md). No tests, builds, validation scripts or device sessions were run for this revision.

# Ferris · glockenspiel, ticket, harbour postcard

2026-09-25: user approved replacing the iPod, boys and selfie with a glockenspiel ticket puzzle and a harbour postcard sequence, then authorized recommended choices without further questions and checkpoint pushes on main. Code and artwork are connected; no tests, validation builds, device launches or runtime screenshots were run. Player acceptance remains outstanding.

## Player flow

1. At the wheel, inspect the wooden glockenspiel. The top staff shows nine equal notes. In Explore mode, striking any of seven naturally ascending bars shows its staff position; no listening or external music knowledge is required. The complete score enters Notes on inspection, without a clue-reading gate.
2. Toggle the physical recording switch. Strikes append to the lower staff. Undo removes the last note; leaving/reopening preserves notes and recording mode. Pulling the handle judges the entire phrase, never a correct prefix. Wrong input stays editable. Answer, from low E4 to D5 indexed 0...6: `0,2,4,3,1,5,6,2,0`.
3. Correct input persists completion and returns to the cabinet. The ticket protrudes from its actual slot; inspect and take it separately. Choose the ticket in Tools and use it at the reader. Only then enter the carriage.
4. The postcard starts inside the left-shelf press and cannot be taken before solving it. Use the root page arrows to revisit three elevation views: near warehouse roof, clock tower behind it, observatory farther back. Inspect the press directly without a tool or placement step. Its Near to far evidence enters Notes.
5. Turn three drums to warehouse → clock tower → observatory, applying the card's Near to far diagram. All three positions accept any motif, including duplicates. Pull the handle for a whole impression. Wrong attempts retain the drums and leave no permanent ink. Correct input stamps the card but grants no collectible yet.
6. Only after successful stamping, take the card into Tools. Use the cabin door to return to the exit platform. Select the card and use the postbox slot; posting consumes it, saves the original `ferris` collectible and shows Element. The right-hand walkway then leads to Taxi. Revisit keeps the sent card available as a memory and does not require a consumed tool.

The music puzzle is the main inference/encoding task: seven possible notes over a complete nine-note phrase, with no prefix feedback. The three-stamp sequence is explicitly a light observation interlude after it: 27 raw combinations or six permutations, not a brute-force-resistant second main puzzle. No time/attempt penalties, extra decoys or clue-reading locks were added.

## State and compatibility

`FerrisProgress` holds music draft, recording mode, ticket facts, elevation, card pickup/placement, stamp draft, stamped/retrieved/posted facts and exit access. GameStore guards each action's room, overlay and immediate prerequisites. `ferrisCamera` is retained as an internal old panel identifier for the press; no camera UI remains. New `ferrisPostcard` is a tool, never a fourteenth collectible.

Decoder migration: `playlistSolved` → `musicSolved`; `phoneTaken` → `postcardTaken`; `photoTaken` → `posted`. Prior ticket facts persist. Existing owned/opened ferris sets posted; old matched ticket pairs preserve solved music. Existing downstream Taxi access preserves passage without manufacturing postcard ownership. A malformed local field does not discard the rest of the save. Old unstamped cards now wait inside the press instead of appearing in Tools; stamp drafts, completed stamping, retrieved cards and posted progress persist. Only retrieved, unposted cards restore into Tools. Retired phone tools are removed without triggering pickup UI. Restoring or migrating never forces the footer tab.

Source and scene contracts: [art README](../../../art/ferris/score-postcard/README.md). Current plan: [implementation plan](../../superpowers/plans/2026-09-25-ferris-score-postcard.md). Existing unrelated Taxi edits are excluded from Ferris commits.

## Verification boundary

Performed: source-flow inspection and visual inspection of generated art/lettering composites; production asset export. Not performed: XCTest execution, game compilation, simulator/device launch, runtime screenshots or gesture testing. `FerrisPuzzleTests.swift` contains one runnable state/compatibility check covering exploration vs recording, wrong drafts, complete submission, post-solve-only postcard pickup, active ticket/posting tool selection, stamping vs posting, persistence, invalid indices and old saves. These assertions have not been run.

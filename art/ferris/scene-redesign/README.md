# Ferris scene redesign — implementation, 2026-09-25

The user approved the gameplay direction and then explicitly requested code implementation. The ticket-booth entry, main-scene cabin/exit and overlapping-fragment puzzle are now connected. Original review plates below retain their draft status; production uses the corrected sources and exact notation described here. No tests, verification builds or device sessions were run.

## Production assets and state

`scripts/export_ferris_fragments.swift` packages `review/ticket-booth.png` into `ferris-ticket-booth`, and the imagegen-cleaned `source/fragment-cabinet.png` into `ferris-fragment-cabinet`. No generated music ink survives. The four sheets receive `FerrisStaff` notation using `FerrisProgress.fragments`; the source composite `fragment-cabinet-lettered.png` records that assembly. Fragment bounds in the shared 320×160 canvas are `(110,28,49,13)`, `(172,28,50,13)`, `(108,51,51,13)`, `(173,51,51,13)`. Bar centres are `88,114,140,165,191,217,243` at y=105.5. At the minimum 533×266 stage and a 210×105 inspection camera, adjacent centres are at least 63pt apart, allowing separate 48pt targets.

The small Join plaque is independent lettering. Clicking it opens the original cabinet's large paper with an exact rule diagram (`ferris-join-guide`); Notes use `ferris-fragment-clue`, with large shuffled fragments, a joining example and endpoint notes. No production clue contains the complete solution. Guide lettering fits the paper's `(100,27,123,34)` writable bounds. Recording uses the new cabinet's narrow blank strip; exploration displays a single played note there without answer comparison.

The cabin main scene uses the existing consistent low/middle/high plates, their press support and empty-bed patch. The draft `review/cabin.png` is retained as a concept, not mixed with the old elevation set. The existing forecourt remains the exit. The booth's window, reader, gondola and lower promenade path have new matching hotspots. Main-scene positions and cabin height are persisted; old completed states and 13 collectible slots remain intact.

Generated with the built-in imagegen tool. Reference roles: current `story-yard-base@3x.png` provides authoritative style because `art/yard/source` is absent; existing `score-postcard/source/cabinet.png` provides musical device materials; existing `harbour-middle.png` provides cabin and landmark identities. Prompts are saved alongside this file.

## Review plates

- `review/ticket-booth.png`: eye-height promenade view. Musical device rests on the left service counter; ticket reader and waiting gondola are reachable across the paved foreground. Ticket slot empty. Physical TICKETS sign stays within its border. Wheel suspension details and the closed/open boarding states need production refinement.
- `review/cabin.png`: seated-height main scene, matching teal framing, brown benches, central aisle and closed right door. Left wall shelf supports the three-drum press and unclaimed postcard. This is a middle-height composition proposal, not the full low/middle/high set. Final elevation variants must preserve cabin geometry and show actual landmark occlusion changes; the current image alone does not establish all depth evidence.
- `review/music-fragments.png`: seven-bar instrument retained from the existing game, four separate clipped clue papers above a distinct blank recording strip. All papers lie within the music stand, bars and device remain supported. Generated notation is visibly inaccurate and is NOT authoritative puzzle evidence; exact notes, equal durations, start/end marks and a legible overlap demonstration must be authored separately before production. The three-node plaque alone does not teach the complete rule. This plate is for physical layout and materials only.

## Gameplay direction

Fragments using pitch indices 1–7: A=1,4,3; B=3,6,1; C=1,2,5; D=5,4,7. Start 1, finish 7. Each fragment used once; adjacent end/start notes overlap and are played once. Only complete chain A→B→C→D uses all fragments and finishes at 7. Phrase: 1,4,3,6,1,2,5,4,7. Papers are displayed shuffled (C,D,B,A), without answer-order labels. No prefix feedback or correct-fragment snapping. Free exploration shows the played note; the recording strip shows input only. Exact rule demonstration and endpoints are required, not hidden assumed music knowledge.

Navigation intention: service window opens instrument closeup; active ticket use permits boarding; cabin is a persisted scene, press is its closeup; closeup dismissal returns to cabin, physical door at platform height leads to exit scene. Preserve tickets, solved music, completed postcards, all existing ownership, and 13 collectible identities. Existing solved saves must not replay the new music puzzle.

Root controls and inventory are deliberately not baked into these scene-content plates. Production must reuse the current native shared controls. Visual inspection of these illustrations is not device or interaction verification.

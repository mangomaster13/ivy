# Cinema scene integration · 2026-09-24

Code is connected; no build, test, device launch or gameplay screenshot was run. User acceptance remains outstanding.

## Flow and ownership

`CinemaPuzzle.swift` owns the case, film, projection and whole-answer decision. `CinemaViews.swift` owns the booth slots, camera and ink masks. The existing GameStore inventory, Notes, inspection return stack, action rail and Element presentation remain shared. The iOS project includes both new source files.

Clicking the shelf case opens its closeup and lid; taking the film is a separate action. The booth camera shows the case with its lid resting closed between inspections; caseOpened records access, not continuous lid animation. Picking up the film switches to Tools without selecting it. The projector requires ownership at entry and active selection/drop at insertion. Inserted film leaves Tools, can be removed without consumption, and retains its orientation, displacement and selected seats. It is consumed only on completion.

The screen remains independently inspectable. Drag moves the actual ink layer; Flip reverses it. Seats switches to row inspection; tapping a row magnifies its five chairs, and Back returns to the full projection. The trailing rail submits the pair as one attempt. Incorrect projection or seats retain the draft and give the same whole-attempt response. Successful completion saves cinema and the exit before opening Element. Reopening the screen preserves the projection; Remember reopens the existing Element.

Legacy completed or already collected Cinema becomes the completed projection without replay, animation or inventory-tab changes. Earlier players already beyond Cinema retain exit access without receiving an unearned collectible. Optional `MemoryProgress.cinema` keeps pre-feature saves decodable. Debug reset clears Cinema-specific facts and tools only when its existing reset range includes Cinema; no reset was executed.

## Asset and placement contract

Use current `ios/Ivy/Assets.xcassets/Scenes/Cinema/` assets. The former `art/later-eggs/production/README.md` is absent from this checkout, so it is not evidence for source provenance.

| Object | Existing resource | Physical bounds / state |
| --- | --- | --- |
| Booth | `later-cinema-projection-booth-background` | 320 × 160 logical canvas; left doorway returns to the street, rear doorway leads to the bookstall |
| Case | booth shelf; `later-cinema-film-case-full` / `-empty` | Main shelf x137 y26 w39 h16; closeup film footprint x92 y62 w163 h44; taken film never respawns |
| Film | `later-cinema-acetate-film` | Same identity in Tools and projector; gate x142 y60 w18 h46 in projector canvas |
| Ticket | `later-cinema-ticket-clue` | Right table x268 y124 w24 h12; same evidence image in Notes |
| Projector | `later-cinema-projector-background` | Dedicated gate closeup; both tap and inventory drop target the slot |
| Projection | `later-cinema-screen-background`, `-base-overlay`, `-aligned-overlay` | 591 × 296 source coordinates; chair centers x233 + 52c, y82 + 37r; image and hit transforms share these coordinates |
| Reward | `later-cinema-keepsake` | Existing cinema collectible slot, no new ID |

The base ink remains fixed. Masks split the existing completed ink into moving right chair halves and a half-heart; the other half-heart stays fixed. No correctness-triggered replacement image or snapping reveals the answer. Offsets are continuous within ±55 / ±35 source units; matching tolerance is 3 source units. The projected heart spans C3 and C4, which are indices 12 and 13 in the 4 × 5 grid.

The camera magnifies the source image without stretching. Five seat targets require a 240 pt main width, or 364 pt total content width with the action rail and margins; row inspection uses one full-surface tap target plus named VoiceOver row actions. The current landscape layout is the intended support envelope. Runtime alignment and the smallest supported viewport still need user evaluation.

## Known artwork gap

The existing ticket and film use rounded notches, not the approved half-heart notch. The film sprite also depicts broad seat silhouettes rather than the exact complementary projection ink. Code reuses these supplied assets but does **not** claim the ticket-to-film orientation evidence is final. A matching ticket/film artwork revision is still needed; do not treat this delivery as visual acceptance or invent replacement provenance. The masks and displayed case states also remain subject to user visual review.

## Blind-play audit and remaining verification

Scanning case/projector hotspots only obtains and inserts film. Scanning seats cannot complete while the continuously positioned layer is reversed or displaced. A player must reconstruct the whole image and submit both seats together; no individual chair, orientation or offset returns a correct/incorrect signal. Once the optical rule is solved, selecting the two pictured seats is its closing action. No attempt limit or lost tool penalizes an error.

One test is added to `WonderlandTests`: active tool requirement, reverse/misaligned rejection, draft round-trip, whole completion, and old completion/access migration. It was **not run**. Manual user checks remain: movement/flip, remove/reinsert, wrong seats, cross-row selection, interrupted save, Notes return, completed revisit and smallest-phone touch geometry. The unresolved notch artwork limits the evidence chain even with the code connected.

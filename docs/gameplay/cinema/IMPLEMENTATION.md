# Cinema · three-film assembly · 2026-09-24

The user approved the three-layer comparison in `art/cinema/three-films/approved-design.png`. This replaces the former single-film half-heart alignment. Code and production assets are connected. No app build, automated test, device launch or gameplay screenshot was run; player acceptance remains outstanding.

## Play

Open the shelf case, then take the three films together as the existing `cinemaFilm` tool. Pickup switches to Tools without selecting it. Select/drop that tool into the projector. The stack disappears from Tools and the box remains empty. Removing and reinserting the films preserves all three positions and orientations.

The screen initially contains **no heart or half-heart**, and no correct seat is highlighted. `Film A/B/C` selects the current layer, dragging translates it, and `Flip` reverses its face. Each film contains disconnected portions of several chairs, labels and asymmetric aisle turns. The user reconstructs continuity across the complete seating plan, rather than matching one pair of chair halves or a heart-shaped notch.

`Project` judges all three films together. Wrong attempts retain the arrangement and use one whole-picture response. Matching fragments never lock, snap, turn green or report individual correctness. All three faces must read forward and both coordinate spreads must be at most 3 source units. Any common translation is accepted: there is no invisible required screen coordinate. On success the projector recenters the complete picture and persists `projectionRevealed`; only then is the separate heart sprite displayed between C3 and C4. The optical arrangement then remains fixed.

`Seats` opens the existing row/seat inspection. Wrong pairs preserve the full projection and selected seats. Choosing C3 and C4 and submitting saves the original `cinema` collectible and exit access before entering Element. The completed scene and Remember action remain available on revisit.

The ticket retains its approved English inscription, recorded as the same image in Notes. Its round notch is decorative; **heart-shaped notch clues are retired**, not an outstanding asset requirement. No new collectible slot or separate tool-search puzzle is introduced.

## Shared coordinates and artwork

`CinemaPuzzle.swift` owns the persisted films, whole-projection decision, selection and migration. `CinemaViews.swift` owns the source partition, source-to-screen camera and seat targets. Existing inventory, Notes, root Back, action rail, haptics and Element are reused.

| Surface | Production resource / bounds |
| --- | --- |
| Booth | Existing 320 × 160 `later-cinema-projection-booth-background`; navigation and shelf retained |
| Case | `cinema-three-case-full` shows three staggered films on the lining; pickup switches to existing `later-cinema-film-case-empty`; hit region x92 y62 w163 h44 |
| Film | `cinema-film-blank` plus the corresponding `CinemaInkLayer`; three instances form the Tools/projector stack |
| Projection | Heart-free `cinema-three-ink`, 1536 × 1024 source; mapped to x178 y35 w300 h200 in the 591 × 296 screen canvas |
| Partition | A 12 × 8 tessellation assigns each cell to exactly one layer using `(column * 7 + row * 11 + column * row % 5) % 3`; all layers use this single source, including the films' printed ink |
| Seat centers | Source x384 + 208c, y274 + 209r, mapped through the same diagram rectangle and camera as the image |
| Heart | Independent `cinema-heart-reveal`, rendered only when film is inserted and the whole-projection reveal is saved; no red ink exists in the three source layers |

The uneven partition crosses row and chair boundaries, while non-symmetric aisle marks and readable lettering distinguish orientation. The diagram remains one picture; the generated comparison is not used as an interactive background. Source images, production prompts and export script are retained. Image scales read their high-resolution source directly and preserve alpha.

The trailing action rail is 80 pt wide with 48 pt controls and 12 pt gaps. Its three controls require 168 pt height; five enlarged seat targets require 240 pt main width, or 356 pt including the rail and margins. The scene reserves 40 pt beneath the main interaction for feedback. Physical imagery and hit coordinates move together. The current landscape content envelope is intended; no device layout claim is made.

## Persistence

Optional `films`, `activeFilm` and `projectionRevealed` additions decode earlier saves. A former unfinished single film keeps its old displacement/face as film A and its inventory/container/seat facts; films B and C start dispersed. Former completed/collected Cinema migrates to all three aligned films, revealed heart and the same owned collectible, with no animation or tab switch. Earlier access beyond Cinema remains valid. Partial moves use scheduled persistence and flush when leaving; flips, layer selection and Project persist immediately. The existing Cinema reset range clears the optional record, but no reset was executed.

## Blind-play reasoning and remaining acceptance

Obtaining and inserting the stack is exploration, not the main puzzle. Repeated seat clicks cannot skip the projection stage. No individual alignment correctness is returned; repeated Project only evaluates the full multi-layer arrangement. Continuous positions, mixed fragment ownership and global orientation require reconstruction of several joins. A correctly assembled picture is intentionally recognizable through its natural line continuity, as with a physical jigsaw.

The existing Cinema regression test was revised for three-film whole submission, no early seat entry/reveal, wrong-orientation rejection, valid shared translation, remove/reinsert, wrong-seat preservation, JSON round-trip and legacy single-film/completion migration. It was not run. Remaining user checks: perceptual difficulty, ink readability, touch placement, saved drag/flip recovery, Notes return, smallest-phone layout and completed revisit.

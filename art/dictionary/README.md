# Dictionary integration · 2026-09-24

Implements the approved Dictionary station between Cinema and Ferris. Device playtesting is user-owned; no build, automated checks, launch or gameplay screenshots were run for this delivery.

## Asset and surface contract

The current scene uses the approved bookmark redesign. The older `later-dictionary-*` imagesets remain for history; the formerly documented `art/later-eggs/production/` directory is absent from this checkout.

| Object | Imageset suffix | Surface / bounds |
| --- | --- | --- |
| Stall | `bookmark-stall` | 320 × 160 logical stage; lower shelf book and right-pillar Ferris painting are baked into the fixed background; counter remains empty for sprites |
| Book | `closed-book` | `DictionaryLayout.book` (128, 91, 82, 41); alpha silhouette stays on counter |
| Lyric bookmark | `bookmark-stall`, `bookmark-closeup`, `bookmark` | Lower central shelf book at scene bounds (172, 50, 22, 29); full-shelf closeup and transparent Notes art use the same authored paper design |
| Ferris painting | `bookmark-stall` | Hanging on the right pillar; route hotspot at (250, 27, 20, 32), not the Ferris silhouette outside |
| Pen | `fountain-pen` | `DictionaryLayout.pen` (213, 87, 29, 20), on the baked empty stand; disappears while held, returns when solved |
| Open book | `open-book-background` | 16:9 original under a proportional full-content camera; no stretching |
| Printed entries | `page-entries-overlay` | Full image overlay with the exact open-book transform |
| Live ink | Runtime strokes | Normalized right-page bounds (0.49, 0.29, 0.31, 0.30); clear of spine and tray |
| Keepsake | `later-dictionary-keepsake` | Existing eleventh collectible slot |

The book and writing views use `DictionaryCamera.artworkFrame` to cover the full root content while preserving the source aspect ratio. Ink, printed entries and gestures use that same transform; the writing camera fits the area left of the shared right-hand action rail, reserving only the bottom feedback line. Undo sits above Enter; Write and Remember occupy the same rail. The bookmark closeup is a separate full-screen shelf camera. See [the closeup coverage fix](../../docs/ui/closeup-content-fix.md) for the earlier camera fix and its verification scope.

## English bookmark

The user explicitly replaced the former Chinese exception. English header: **Stefanie Sun · Dictionary of Love**. Lyric: **In the dictionary of love, “forever” cannot be found.** The older `song-card-english.png` is retained as a lettering reference, not used in the current scene. The approved new design places a narrow bookmark in a dark teal book on the lower shelf; tapping it opens a complete shelf closeup. Notes uses the isolated transparent bookmark.

`source/bookmark-stall.png`, `source/bookmark-closeup.png`, and `source/bookmark.png` are the selected high-resolution built-in imagegen outputs. The existing stall established room geometry, the older English card established exact wording, and `story-yard-base@2x.png` established painting style. Each 1x/2x/3x export derives directly from its source. The fixed stall art contains no counter book or pen, so those remain stateful sprites; the dictionary's blank writing entry still has no prewritten answer. Artwork and source text were inspected, but no device rendering was run under the user-owned testing policy.

## State, recognition and completion

`DictionaryPuzzle.swift` owns pen guards, drafts, submission and migration. `DictionaryViews.swift` owns the shared placement and book camera. The player reads both objects independently, takes the pen, selects it in Tools and writes. Each stroke remains separate; Undo removes the last stroke. Drafts save during writing and on lift/exit. Enter rasterizes only the actual ink, then uses Apple's `VNRecognizeTextRequest` off the main actor with English recognition and language correction disabled. It does not inject the answer as custom vocabulary. Only the whole recognized word `FOREVER` passes; no correct-letter feedback. Cancellation, changing the draft/tool or leaving the page cannot award a stale submission. On success preserve strokes, return the pen, persist the collectible once and open Element.

Legacy `sunset` collectible and room IDs decode to `dictionary`; the view key and old completed-but-unclaimed fact migrate. Existing completion requires no replay, and migration never invents handwriting. Missing new fields preserve old saves; invalid local drawing data is discarded without losing other progress. The old framing slider cannot award the new word.

Narrow regression coverage lives in `EggOrderTests.swift` (migration, tool selection, draft roundtrip and obsolete-solver bypass), authored but not run. Remaining user checks: real finger handwriting recognition, readable small-screen entry crop, pen placement, Undo after wrong input, app restore, completion return path and legacy-save ownership. Recognition accuracy and assistive direct-touch handwriting have not been device-validated.

Apple API reference: https://developer.apple.com/documentation/vision/vnrecognizetextrequest

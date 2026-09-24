# Dictionary integration · 2026-09-24

Implements the approved Dictionary station between Cinema and Ferris. Device playtesting is user-owned; no build, automated checks, launch or gameplay screenshots were run for this delivery.

## Asset and surface contract

Use the existing `later-dictionary-*` imagesets. The formerly documented `art/later-eggs/production/` directory is absent from this checkout; imported assets are the available approved references.

| Object | Imageset suffix | Surface / bounds |
| --- | --- | --- |
| Stall | `stall-background` | 320 × 160 logical stage; rear counter edge at y≈84, front at y≈130 |
| Book | `closed-book` | `DictionaryLayout.book` (128, 91, 82, 41); alpha silhouette stays on counter |
| Lyric card | `song-card` | `DictionaryLayout.song` (79, 95, 51, 34), separate from book and stand |
| Pen | `fountain-pen` | `DictionaryLayout.pen` (213, 87, 29, 20), on the baked empty stand; disappears while held, returns when solved |
| Open book | `open-book-background` | 16:9 original under a proportional full-content camera; no stretching |
| Printed entries | `page-entries-overlay` | Full image overlay with the exact open-book transform |
| Live ink | Runtime strokes | Normalized right-page bounds (0.49, 0.29, 0.31, 0.30); clear of spine and tray |
| Keepsake | `later-dictionary-keepsake` | Existing eleventh collectible slot |

The book and writing views now use `DictionaryCamera.artworkFrame` to cover the full root content while preserving the source aspect ratio. Ink, printed entries and gestures use that same transform; the bottom 88 pt are reserved inside the scene for controls and feedback. See [the closeup coverage fix](../../docs/ui/closeup-content-fix.md) for the camera, lyric-card support surface and actual verification scope.

## English card

The user explicitly replaced the former Chinese exception. `song-card-english.png` is the retained generated source (1536 × 1024, RGBA); 1x/2x/3x exports derive directly from it. English header: **Stefanie Sun · Dictionary of Love**. Lyric: **In the dictionary of love, “forever” cannot be found.** The card is shared by the scene, independent closeup and Notes. Source inspected for lettering, margins and alpha; this is asset inspection, not in-game visual acceptance.

Generated with the built-in imagegen tool, using the original imported card as the composition reference and `story-yard-base@2x.png` as the available Yard style reference. The prompt requested text localization only, retaining cream paper, teal border, music notes, camera angle and hand-painted texture; a second edit requested transparent background extraction. No new room art or prewritten answer on the blank book page.

## State, recognition and completion

`DictionaryPuzzle.swift` owns pen guards, drafts, submission and migration. `DictionaryViews.swift` owns the shared placement and book camera. The player reads both objects independently, takes the pen, selects it in Tools and writes. Each stroke remains separate; Undo removes the last stroke. Drafts save during writing and on lift/exit. Enter rasterizes only the actual ink, then uses Apple's `VNRecognizeTextRequest` off the main actor with English recognition and language correction disabled. It does not inject the answer as custom vocabulary. Only the whole recognized word `FOREVER` passes; no correct-letter feedback. Cancellation, changing the draft/tool or leaving the page cannot award a stale submission. On success preserve strokes, return the pen, persist the collectible once and open Element.

Legacy `sunset` collectible and room IDs decode to `dictionary`; the view key and old completed-but-unclaimed fact migrate. Existing completion requires no replay, and migration never invents handwriting. Missing new fields preserve old saves; invalid local drawing data is discarded without losing other progress. The old framing slider cannot award the new word.

Narrow regression coverage lives in `EggOrderTests.swift` (migration, tool selection, draft roundtrip and obsolete-solver bypass), authored but not run. Remaining user checks: real finger handwriting recognition, readable small-screen entry crop, pen placement, Undo after wrong input, app restore, completion return path and legacy-save ownership. Recognition accuracy and assistive direct-touch handwriting have not been device-validated.

Apple API reference: https://developer.apple.com/documentation/vision/vnrecognizetextrequest

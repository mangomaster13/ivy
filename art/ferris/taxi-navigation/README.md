# Ferris ticket states and Taxi navigation

2026-09-25: user approved `review/design-board.png` and authorized staged commits/pushes. Production artwork was generated with built-in imagegen; exact prompts are in `PROMPTS.md`. The review board is not a runtime asset. Yard's current catalog image supplied the painting reference because the documented Yard source folder is absent.

## Production sources

| Source | Catalog asset | Physical contract |
| --- | --- | --- |
| `source/forecourt.png` | `ferris-taxi-forecourt` | 1774×887 full scene. Open gondola at left; postbox on raised pavement; fully framed taxi parked on road below the curb. First generated curb crossing the tires was rejected and corrected. |
| `source/ticket-ready.png` | `ferris-ticket-ready` | Closeup: one ticket protrudes from the brass dispenser. Visible only after music solved and before pickup. |
| `source/ticket-empty.png` | `ferris-ticket-empty` | Registered empty-slot edit; ticket and its shadow removed. Used after pickup, including after consumption/revisit. |
| `source/ticket.png` | `ferris-navigation-ticket` | Independent alpha paper for cabinet and Tools; retains emblem, notches and exact TICKET lettering. |
| `source/postcard.png` | `taxi-ferris-postcard` | Independent alpha paper with two brass roof-trim clips. Permanent navigation object, separate from puzzle postcard ownership. |

`scripts/export_ferris_navigation.swift` exports each scale directly from the original. Transparent object padding is cropped before proportional resizing; source files remain untouched.

## Anchors and behavior

Coordinates use the existing 320×160 canvas and root fitted transform. Forecourt postbox slot `(95,94,11,5)`, carriage doorway `(18,53,25,41)`, taxi `(194,71,121,62)`. The full postbox body opens inspection. Main forecourt and its inspection reuse the same plate and anchors. The existing boarding gate closeup retains its own original anchors.

Ticket cabinet paper `(152,146,15,13)` has its top held at the existing dispenser opening and stays within the scene; detailed pickup target `(122,62,76,71)` matches the new closeup. Pickup reads existing `musicSolved` and `ticketTaken`; no new saved state or collectible slot.

Taxi postcard `(199,8,53,32)` attaches to roof trim right of the mirror, clear of passenger visor, map clip and road targets. It persists on every driving plate and remains clickable after arrival; the garden door remains a separate arrival-only object. Returning through the postcard opens Ferris forecourt, retaining the complete TaxiProgress. The Ferris taxi retains the existing posting/legacy-unlock guard. No invisible taxi hotspot remains on the music cabinet plate.

## Delivery boundary

Performed: source-flow reading, generated artwork inspection and production export. Exported ticket and postcard were inspected for silhouette, lettering and transparent margins. No game tests, validation scripts, build, device launch or runtime screenshot pass was run. RoomGraphTests contains a new runnable ticket/round-trip check and TaxiPuzzleTests expectations reflect the permanent postcard; execution and device touch/layout acceptance remain with the user.

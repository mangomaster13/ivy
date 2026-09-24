# Ferris four-scene artwork

Approved visual direction, 2026-09-24. `scripts/export_ferris_playlist.swift` exports each high-resolution source directly to the Ferris asset catalog at 1x/2x/3x. No source is enlarged from a catalog export.

| Source | Runtime asset | Physical surface and state |
| --- | --- | --- |
| `promenade-source.png` | `ferris-promenade` | Eye-height waterfront path under the wheel. The two men share wired earphones; the classic iPod stays in the yellow-shirt man's hand. Earphones are the playlist hotspot. |
| `booth-source.png` | `ferris-ticket-booth` | Ticket booth beside the same path. Blank paper/sign faces; brass-edged dispenser slot on the booth's front panel. No iPod. |
| `gate-closed-source.png` | `ferris-boarding-closed` | Waist-height ticket slot on the queue post, closed carriage door beyond it. |
| `gate-open-source.png` | `ferris-boarding-open` | Same camera, gate and carriage, with only the door open. |
| `cabin-empty-source.png` | `ferris-cabin-interior` | Opposing seats and harbour window. Right cushion is empty so the existing independent phone sprite can be taken. |
| `selfie-cartoon-source.png` | `ferris-selfie` | The same two adults as clearly drawn cartoon characters inside the carriage, for camera, collection and revisit. |

The source photos `IMG_4977.HEIC` and `IMG_5036.HEIC` establish the pair's features and relationship. `IMG_6536.HEIC` is the later, controlling reference for the yellow-shirt man's fuller face and short curls. The user chose yellow short sleeves, no hat, and an unmistakably cartoon selfie. The original photographs are not included in this repository; these are newly authored game illustrations. `story-yard-base` supplies painting style, while the prior Ferris assets supply the harbour and carriage identities.

All six scene sources use one eye-height spatial sequence, 1774×887 for scenes and 1254×1254 for the collectible. The first scene's iPod is held, not a booth object. Scene two's ticket emerges from its fixed front slot as a separate sprite. Scene three's ticket is used at the queue post, separate from the carriage door. In scene four the phone rests on the right bench as a separate sprite; taking it leaves the authored empty cushion. These supports, slots and anchors are defined in `FerrisLayout` on the shared 320×160 canvas. The scene art contains no game controls.

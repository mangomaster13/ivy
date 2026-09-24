# Ferris playlist artwork

Built-in image_gen sources, 2026-09-24. Prompts: [prompts.md](prompts.md). Runtime packing: [export_ferris_playlist.swift](../../../scripts/export_ferris_playlist.swift). All 1x/2x/3x images are exported directly from high-resolution sources, with alpha retained; no low-resolution export is enlarged.

The user selected the **classic circular click-wheel iPod**. `ipod-source.png` is the rejected touch-device exploration and is not used or exported. `classic-source.png` is the full-resolution classic design; `classic-cutout.png` is its image_gen cutout pass. Ticket/phone `*-cutout.png` files are exact copies of their generated alpha sources. Source alpha was inspected while preparing sprites; this was artwork production, not a game validation run.

| Runtime resource | Source | Surface / state |
| --- | --- | --- |
| ferris-classic-ipod | classic-cutout.png | Existing independent object; the four-scene promenade now depicts it held by the yellow-shirt man instead of standing at the booth |
| ferris-ipod-screen | classic-source.png, crop (162,180,698,510) | Camera closeup of the LCD and ivory bezel, not a generic UI panel |
| ferris-track-0…4 | Exact text in export script | Independent two-line title/artist lettering; all five reorder as whole objects; CJK fallback preserves 林忆莲 / 也许 |
| ferris-dispenser | dispenser-source.png | Fixed counter front / gate railing plate; wheel emblem, recessed slot and brass lip |
| ferris-ride-ticket | ticket-cutout.png | Extends from slot, disappears on pickup; same asset in Tools |
| ferris-selfie-phone | phone-cutout.png | Rests on the right bench seat, disappears on pickup; same object in Tools |
| ferris-cabin-interior | `../sequence/cabin-empty-source.png` | Seated eye-height cabin with an empty right bench for the independent phone |
| ferris-selfie | `../sequence/selfie-cartoon-source.png` | Shared camera preview / collection / revisiting; cartoon recreation of the user's supplied photo references |

The earlier `selfie-provisional-source.png` is historical and is no longer exported. The user supplied three photo references and approved the new cartoon selfie. The photo files themselves are not committed; source and scene details are recorded in [the four-scene artwork](../sequence/README.md).

Style anchor: `ios/Ivy/Assets.xcassets/Scenes/Yard/story-yard-base.imageset/story-yard-base@2x.png`; the documented original `art/yard/source/yard-closed.png` is absent from this checkout. Cabin color/structure reference: existing `later-ferris-cabin-open`. Retain dark contours, grouped color masses, matte surfaces, local amber light and blue-teal shadows. Generated source images and exported lettering were inspected directly. No app/device screenshots were taken.

Object layout and hit targets are owned together by `FerrisLayout` in FerrisViews.swift. The four-scene revision replaces the old exterior and gate view while retaining the independent ticket and phone, song lettering and original progress fields. No saves were reset for artwork work.

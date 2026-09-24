# Ferris playlist artwork

Built-in image_gen sources, 2026-09-24. Prompts: [prompts.md](prompts.md). Runtime packing: [export_ferris_playlist.swift](../../../scripts/export_ferris_playlist.swift). All 1x/2x/3x images are exported directly from high-resolution sources, with alpha retained; no low-resolution export is enlarged.

The user selected the **classic circular click-wheel iPod**. `ipod-source.png` is the rejected touch-device exploration and is not used or exported. `classic-source.png` is the full-resolution classic design; `classic-cutout.png` is its image_gen cutout pass. Ticket/phone `*-cutout.png` files are exact copies of their generated alpha sources. Source alpha was inspected while preparing sprites; this was artwork production, not a game validation run.

| Runtime resource | Source | Surface / state |
| --- | --- | --- |
| ferris-classic-ipod | classic-cutout.png | Upright at booth counter, bottom at y≈106 on the 320×160 exterior; remains after solving |
| ferris-ipod-screen | classic-source.png, crop (162,180,698,510) | Camera closeup of the LCD and ivory bezel, not a generic UI panel |
| ferris-track-0…4 | Exact text in export script | Independent two-line title/artist lettering; all five reorder as whole objects; CJK fallback preserves 林忆莲 / 也许 |
| ferris-dispenser | dispenser-source.png | Fixed counter front / gate railing plate; wheel emblem, recessed slot and brass lip |
| ferris-ride-ticket | ticket-cutout.png | Extends from slot, disappears on pickup; same asset in Tools |
| ferris-selfie-phone | phone-cutout.png | Rests on the right bench seat, disappears on pickup; same object in Tools |
| ferris-cabin-interior | cabin-source.png | Seated eye-height cabin; warm bench, coat on left, clear right seat, distant harbour |
| ferris-selfie | selfie-provisional-source.png | Shared camera preview / collection / revisiting; illustrative people only |

**The selfie does not depict an approved likeness.** No actual selfie was supplied in this task. Replace the provisional image through the project's photo-reference recreation workflow when the reference is available. Do not present this art as a reconstruction of the user's real appearance.

Style anchor: `ios/Ivy/Assets.xcassets/Scenes/Yard/story-yard-base.imageset/story-yard-base@2x.png`; the documented original `art/yard/source/yard-closed.png` is absent from this checkout. Cabin color/structure reference: existing `later-ferris-cabin-open`. Retain dark contours, grouped color masses, matte surfaces, local amber light and blue-teal shadows. Generated source images and exported lettering were inspected directly. No app/device screenshots were taken.

Object layout and hit targets are owned together by `FerrisLayout` in FerrisViews.swift. The main scene uses existing exterior art, with independent iPod, dispenser and ticket layers; both cabin door states are existing scene assets. The phone is not baked into the cabin. No saves were reset for artwork work.

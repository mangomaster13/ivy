# First Letter and finale artwork

Approved direction on 2026-09-25: cream folded paper, red ivy wax seal, warm wooden surface; user requested the game's system lettering, Kiddos, and the same style for the first Letter. The finale machine's dispensing assembly is also redesigned. No new copy or rewards.

## Sources and production

Built-in imagegen produced the images in `source/`. Reference roles: current `story-yard-base@3x.png` for Yard painting style (the documented `art/yard/source` is absent in this checkout); previous `art/finale/source/machine-heart.png` for machine identity and room; the approved two-state letter design for cream paper and wax seal. The design board is a proposal, never a runtime background.

Prompt direction: readable hand-painted dark contours, grouped shapes, restrained stepped brushwork, matte cream paper and wood, teal shadows, localized amber light; no vector placeholders, roll ends, extra objects or baked controls. For letter production, keep an overhead camera and a blank unfolded sheet on the same wooden surface; derive a closed envelope state and transparent envelope sprite from the approved design. For machine production, retain the room, compact console, teal/brass body and right lever; give the envelope a recessed dispensing mouth and supporting brass tray. Derive each state by changing only the lever, envelope depth or heart.

`scripts/export_finale_letters.swift` exports all scales directly from these originals and renders exact Kiddos text using the bundled font. `letter-first.png` and `letter-finale.png` are authored composites. `envelope.png` supplies Yard `story-envelope` and `art/keepsakes/source/letter.png`; run `scripts/export_keepsakes.swift letter` for its inventory artwork.

## Placement and states

- Letter reference canvas: 1774×887, overhead, full wooden support surface. Paper spans approximately x=400…1390, y=58…808; text uses x=565…1285, y=176…745, leaving ivy, folds and edges readable. Both pages use the same composition; no runtime text positioning. Root `PixelCanvas` owns the fitted 320×160 transform.
- Machine reference canvas: 1774×887, front three-quarter camera. Envelope lies within the lower slot/tray x≈750…1060, y≈480…612, front edge behind the brass lip. Half-dispensed paper remains held by the mouth; full-dispensed paper rests in the tray. The console fully supports the machine.
- Logical 320×160 interactive centers: lever (245,57), letter (162,99), token (164,68). The existing 33×25 brass/glass token assembly remains unchanged and fits inside the new window. All 13 icons retain their existing individual containment assets.
- Closed → open is a short dissolve between authored full scenes, replacing the mismatched scroll atlas. First-letter saved opening and dismiss actions remain; the finale reopens directly after it has been viewed. Reduced motion skips the initial sealed pause. No ownership or save fields change.

## Delivery evidence

Viewed source and lettered artwork for material, text fit, supports and state composition. Production exports completed, including a text-width guard. No build, game test, device launch or gameplay screenshot was run; runtime appearance and gestures remain user-owned acceptance. Generated state frames may have minor brush-texture variation.

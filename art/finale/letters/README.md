# First Letter and finale artwork

Approved direction on 2026-09-25: cream folded paper, red ivy wax seal, warm wooden surface; user subsequently selected Juniper lettering for both letters and the same style for the first Letter. The finale machine's dispensing assembly is also redesigned. No new copy or rewards.

## Sources and production

Built-in imagegen produced the images in `source/`. Reference roles: current `story-yard-base@3x.png` for Yard painting style (the documented `art/yard/source` is absent in this checkout); previous `art/finale/source/machine-heart.png` for machine identity and room; the approved two-state letter design for cream paper and wax seal. The design board is a proposal, never a runtime background.

Prompt direction: readable hand-painted dark contours, grouped shapes, restrained stepped brushwork, matte cream paper and wood, teal shadows, localized amber light; no vector placeholders, roll ends, extra objects or baked controls. For letter production, keep an overhead camera and a blank unfolded sheet on the same wooden surface; derive a closed envelope state and transparent envelope sprite from the approved design. For machine production, retain the room, compact console, teal/brass body and right lever; give the envelope a recessed dispensing mouth and supporting brass tray. Derive each state by changing only the lever, envelope depth or heart.

`scripts/export_finale_letters.swift` exports all scales directly from these originals and renders exact Juniper text using the bundled font. `letter-first.png` and `letter-finale.png` are authored composites. `envelope.png` supplies Yard `story-envelope` and `art/keepsakes/source/letter.png`; run `scripts/export_keepsakes.swift letter` for its inventory artwork.

## Placement and states

- Letter reference canvas: 1774×887, overhead, full wooden support surface. Paper spans approximately x=400…1390, y=58…808; text uses x=545…1305, y=176…745, leaving ivy, folds and edges readable. Both pages use the same composition; no runtime text positioning. Root `PixelCanvas` owns the fitted 320×160 transform.
- Machine reference canvas: 1774×887, front three-quarter camera. Envelope lies within the lower slot/tray x≈750…1060, y≈480…612, front edge behind the brass lip. Half-dispensed paper remains held by the mouth; full-dispensed paper rests in the tray. The console fully supports the machine.
- Logical 320×160 interactive centers: lever (245,57), letter (162,99), token (164,68). The existing 33×25 brass/glass token assembly remains unchanged and fits inside the new window. All 13 icons retain their existing individual containment assets.
- Both letters start sealed on every visit and wait for a tap. A 1.2-second center-out unroll reveals the unchanged paper and Juniper lettering behind two travelling painted curls; repeated taps during opening are ignored. A tap after opening dismisses immediately, with no reverse roll or closing delay. Reduced motion reveals the paper immediately after the tap. The first-letter opened flag remains compatible bookkeeping and no longer skips the user action; ownership and save fields do not change.
- `desk.png` is the support scene with the sheet removed; `curl.png` is a matching cream-paper roll edge on alpha, trimmed by its painted bounds during export. `letter-*-paper` uses the same original canvas and extracted paper silhouette. Runtime paper center is (161,77.84), vertical extent 135.84 logical units; curls travel along the exposed top and bottom edges. The mask reveals texture rather than drawing a colored paper placeholder.

## Delivery evidence

Viewed source and lettered artwork for material, text fit, supports and state composition. Production exports completed, including a text-width guard. No build, game test, device launch or gameplay screenshot was run; runtime appearance and gestures remain user-owned acceptance. Generated state frames may have minor brush-texture variation.

# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Stack

SwiftUI, iOS 17+, existing Xcode project at `ios/Ivy.xcodeproj`. Bundle ID `com.ivy.gift`.

## Users

Primary: one person (the gift recipient), Hangzhou, busy, iPhone, possibly likes rust-lake-style observation games. Plays in landscape, possibly lying down or switching to WeChat mid-session.

Secondary: the author, who ships via TestFlight and supplies copy, a lyric phrase, a letter, and an optional photo.

## Product Purpose

A private 16-bit point-and-click collectible gift: walk a small stone house, look closely, collect personal objects, then draw a pre-set prize. Success is finishing or leaving safely in 8–15 minutes, recognizing at least four objects without hints, and feeling it is a cartridge — not an H5.

## Positioning

A house that lives only on his phone. One lyric lock on the front door; no accounts, no map, no App Store page. Neighboring products cannot copy the specific objects or the TestFlight-only audience.

## Operating Context

Opens from a home-screen icon. Portrait hold shows a rotate hint. Landscape play. Progress persists on-device. Intended distribution: TestFlight to one Apple ID.

## Capabilities and Constraints

- Five rooms: yard, hall, kitchen, stairs, bedroom. Canvas 320×160, nearest-neighbor scale.
- Front door is the only lock. Tapping it (while locked) cuts to a **lyric lock screen** — a new 320×160 picture, not a dim yard with a text field, not a system keyboard.
- On that screen: a stave (what he has assembled) and a 4×4 pad of letter/digit plates. Required unique glyphs of `coveredinyou817` plus three decoys (`9`, `a`, `s`). Positions shuffle each time the screen opens; they stay still while it is up.
- Each tap appends that glyph to the stave. Plates are reusable (`o` and `e` are tapped twice). No spaces, no confirm. When the stave equals `coveredinyou817`, the door auto-unlocks, `ivy` is collected, and play cuts to the hall.
- Wrong prefix stays on the stave. **Backspace** drops the last glyph. **Reset** clears the whole stave and stays on the lock screen (pad does not reshuffle). Cancel returns to the yard with the stave kept. Cap 20 glyphs. Do not highlight the next correct plate. Do not accept aliases (`iamcoveredinyou`, `8.17`, `0817`).
- The complete chorus never appears on any plate, stave prompt, or sky line. The yard sky may show one fill-in-the-blank (`your ivy grows, ____`). The blank is the lyric half; `817` is never written in the sky.
- Interior doors stay unlocked. Mailbox `sep29` and hall `vuori` stay their own short inputs; they are not this lock.
- Yard is a living night: stepped ivy sway, drifting cloud sprites. Reduce Motion freezes both.
- Yard collectibles sit on the flanks (left `sep29`, door still center for `ivy`). Each yard unlock grows ivy on **both** sides.
- Nine collectibles; lottery machine in the hall lights when the bar is full; prize is predetermined.
- Hall lamp toggles only the hall; Vuori phone glows in the dark.
- No combat, crafting, notifications, iCloud, widgets, or dual portrait/landscape layouts.
- No SF Symbols as the main interface.

Assumed from `docs/game-design.md` (author design spec). Locked: door answer `coveredinyou817` (assemble, no aliases). Open: remaining observation lines, prize letter, photo.

## Brand Commitments

Name: Ivy. Binding visual: existing 16-bit night-cottage pixel kit in `ios/Ivy/Assets.xcassets` (stone house, locked palette, ivy). Not a utility app.

## Evidence on Hand

Pixel kit: `intro-house`, `room`, `palette`, ivy overlays, UI boxes. Landscape room bases in the catalog: `yard`, `hall`, `hall-dark`, `kitchen`, `stairs`, `bedroom` (logic 320×160, nearest-neighbor). Do not fabricate real photos of the recipient.

## Product Principles

1. The house is ordinary; secrets live in objects, not in a second city.
2. One verb at a time: tap (look closer, collect, or assemble the door line), or walk through a door. The front door is not a text field.
3. Haptics and light are feedback, not decoration. Surprise lives in five staged reveals (look closer, slot accepts, lamp, front door, lottery), documented in `docs/ux-motion.md`. Yard wind and clouds are atmosphere, not a sixth reveal.
4. Scope stays small: five rooms, one lock, TestFlight.

## Accessibility & Inclusion

Minimum 44pt hit targets (lock-screen plates, backspace, reset, cancel included). Game canvas stays inside the safe area. Mailbox / Vuori keyboards, when used, must never cover confirm. The lyric lock has no confirm: it unlocks on exact stave match. No VoiceOver copy written yet.

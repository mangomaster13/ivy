> Latest revision: use [IVY-GUIDE.md](IVY-GUIDE.md) for current petal locations and tray interaction. Petal 0 is in the blanket folds, not under the pillow; petals drag from Tools and used slots disappear. The bouquet lies on the bed, clear of the pillow. The approved softened background applies to the Rose and city puzzles. Earlier wording below about petals resting beside the bouquet is historical.

# Rose · three petals

Approved direction: 2026-09-19. The visual authority is `art/rose/references/three-petals-approved.png`, using the red bouquet character from `art/memories/source/bouquet-final.png`.

Preserve the three red rose heads, smiling kraft-paper wrapper, brown arms, bundled green stems, dark contours, matte brush texture and warm highlights. The completed object must be the approved bouquet. No pink single-stem flower or photographic plush parts.

## Play

- Inspect the bedroom pillow to expose petal 0; inspect the desk lamp to expose petal 1. Tap each revealed physical petal to take it.
- The existing “as a whole” box contains petal 2 and the independent Gelato coin. Opening the box does not automatically collect either.
- Inspect the bouquet on the bed. Found petals rest beside it. Drag them into the flower-head area in any order; a forgiving release region snaps each to its own recess. A missed drop returns home. VoiceOver offers equivalent placement actions.
- Each petal restores its original painted region. The third settles, then the whole bouquet gives a small pulse. Tap the finished bouquet to collect `rose` once. Reduce Motion removes the snap/pulse animation.
- Keep the scene background, shared Back control, root-owned footer and feedback row. No extra instructions, visible counters, arrows, checkmarks or tying controls.

## Artwork implementation

`RoseArtwork.swift` keeps three source-space silhouettes on the approved 1254 × 1254 original. The same silhouettes render the detached pieces and their dark textured recesses. Placed sprites move to the exact corresponding source coordinates; the final artwork remains the original bouquet. These are native independently interactive layers, not a screenshot of the design sheet.

`scripts/export_rose.swift` derives the `rose-bouquet` asset at 400 / 800 / 1200 px directly from the source. No scale is derived from another scale and none exceeds source resolution. The image export is production work, not a verification build.

## Progress compatibility

`MemoryProgress.rose` is optional for old-save decoding. It records revealed, found and placed indices 0–2. Old folds and stitches receive equivalent placed-petal credit; the old held petal and twine reward receive found-petal credit. The legacy twine identifier remains decodable but is retired from gameplay. Already-collected Rose stays collected. All 13 collectible IDs and the save key remain unchanged.

The existing non-persisting `IVY_REVIEW=rose` starts with all three loose petals. `rose-complete` and `rose-collect` remain available. Normal saves are not reset.

## User-owned acceptance

No agent tests, verification build, device launch, screenshots or gesture trial were run. Manual acceptance covers discovery at all three locations, out-of-order placement, off-target return, partial progress after reopening/relaunch, reduced motion, VoiceOver placement, final collection and old saves. Check both small and large landscape phones, especially footer/Back clearance and petal hit areas.

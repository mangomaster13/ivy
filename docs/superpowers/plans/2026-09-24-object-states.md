# Object State Artwork Implementation Plan

**Goal:** Replace pasted inventory art in the approved six scene groups with complete authored state plates.

**Architecture:** Keep existing GameStore progression and collection methods. Render one full scene plate per existing state and overlay only transparent physical hotspots; Big Top retains interactive lock symbols. Derive variants from a single approved production master, not resized board panels.

**Tech Stack:** SwiftUI, Xcode image catalogs, built-in image_gen, existing Swift/ImageIO export pattern.

**Spec:** art/object-state-design/README.md (approved by user: 替换吧).

## Constraints

Current main branch; preserve saves, 13 collectible slots and unrelated work. No builds, tests, validation scripts, device launches or screenshots under user-owned testing policy. Inspect generated source art only. Commit and push completed milestones as authorized. No new dependency or generic scene framework.

## Steps

- [x] Produce independent 2:1 masters for counter/menu, pot/key, drawer/eraser, travel book/ticket, box/petal/token, cabinet/scoop, counter/cup. Reference current source geometry and approved boards; keep all hotspot-bearing furniture unchanged.
- [x] Derive missing object/closed/tasted variants using image_gen edits of each master; preserve contact shadows only when corresponding objects are present. Closed variants are generated from the same object masters; the box puzzle retains its separate left-box/right-input composition.
- [x] Save sources and prompt/source provenance under art/object-states; export new catalog images directly at 1x/2x/3x without upscaling originals. Commit and push artwork milestone.
- [x] MemoryCloseups.swift: route pot/drawer/open box/book through a full fitted scene with fixed transparent hotspots; choose image from opened/picked/rose facts, keep existing pickup methods and input puzzle. Remove generic HStack image placement for these panels.
- [x] BigTopViews.swift and Exploration.swift: choose matching full counter plate for closed/menu present/menu taken in main scene and drawer crop; replace menu image with transparent hotspot sharing artwork footprint. Keep other service-counter tools outside scope.
- [x] GelatoCloseups.swift and GelatoWordPuzzle.swift: choose closed/available/taken scoop and unserved/served/tasted cup scene, align transparent hotspots to painted clip/cup. Keep flavor/spoon prerequisites, feedback and native puzzle controls.
- [x] Leave a narrow state-selection regression test in existing WonderlandTests.swift without running it; update asset/state/anchor record, review only changed source text, commit and push integration milestone.

No new save fields, migrations or alternative gameplay are required. Manual device acceptance stays with user.


Completed: 22 production originals and catalog sets exported; six scene groups wired to saved facts. Source artwork and changed code inspected. Regression checks added but not run; no game build, device launch or screenshots. Artwork milestone: 9ac3ce9.

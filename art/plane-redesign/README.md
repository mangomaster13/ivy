# Ticket / Departure visual proposal · 2026-09-25

Status: user approved both proposals on 2026-09-25; production assets and views are now connected. The review images remain proposals, not runtime screenshots. No builds, tests, device launches or game screenshot passes run.

Generated using built-in imagegen. References inspected: current catalog `story-yard-base@3x` for Yard painting style (documented art/yard source is absent in this checkout), `ticket-paper@3x` for ticket silhouette, and `story-lock-panel@3x` for the existing support surface.

- `review/ticket-proposal.png`: overhead cream ticket on teal panel. Preserve worn notched silhouette, perforated stub, airplane/globe engravings. Teal ink, muted terracotta stamp, route in Georgia italic and existing inscription. Main-body lettering stays inside its border, above the graphite area. Graphite conceals all four symbols; production must separate paper, lettering, symbols and erasable mask.
- `review/departure-proposal.png`: overhead folded atlas supported by left portion of panel; right portion reserved for existing independent route controls. Matte cream paper, blue-teal sea, muted relief, brass unselected markers. Generated geography and city locations are illustrative only, not approved interaction coordinates. Production must retain ChinaGeometry, JourneyCity.all, uniform projection and existing route logic; regenerate a suitable substrate and render accurate map/markers separately.

Prompt direction: match Ivy Yard's hand-painted pixel-storybook contours, grouped color shapes, restrained stepped brush texture, matte materials and local warm light. No photorealism, glossy 3D, HDR, app chrome or baked controls. One straight overhead camera, full paper footprint supported within panel, subtle contact shadow, no extra props or answer highlights.

Visual inspection: ticket silhouette, typography, stub and graphite area are legible; atlas has consistent overhead support and ten unselected markers. Map geography requires deterministic production treatment. Both proposals emphasize paper texture more than Yard's distant scene; preserve grouped painterly shapes when preparing final assets. Existing Back, footer and PuzzleButton remain independently rendered. No device/layout acceptance claimed.

## Production assets and placement

Built-in imagegen produced three independent source plates, inspected before export:

| Source | Catalog asset | Role |
| --- | --- | --- |
| `source/ticket.png` | `plane-ticket-paper` | Transparent worn ticket; no lettering, clues or permanent graphite |
| `source/atlas-paper.png` | `plane-atlas-paper` | Transparent folded atlas with teal sea field and compass; no land or city dots |
| `source/atlas-land.png` | `plane-atlas-land` | Illustrated cream/sage/ochre relief texture, clipped by existing `ChinaGeometry` at runtime |
| `scripts/export_plane_art.swift` | `plane-ticket-lettering`, `plane-depart`, `plane-departing`, `plane-route-one`, `plane-route-two` | Deterministic CoreText lettering; Georgia Italic route, Juniper inscription, Kiddos controls |

Source prompts: isolate the approved ticket, retaining its outline, engraved border, airplane/globe and stamp while removing lettering, graphite and backing; isolate the folded paper with a blue-teal printable interior, removing geography and pins; paint an edge-to-edge cream/sage/ochre land texture without coastlines, boundaries or markers. All retain the approved overhead camera and matte storybook style. Export each scale directly from original PNG or vector lettering with `swift scripts/export_plane_art.swift` (asset authoring, not an app build).

Ticket uses a 620×282 reference canvas. Route ink bounds are (49,79,435,40); inscription bounds (62,121,409,29), measured from top left. The removable graphite/clue region uses normalized centre (0.43,0.72), size (0.73,0.28), inside the main body's engraved border and left of the perforation. Lettering shares the paper transform. Existing normalized stroke records, completion coverage and four-symbol order are unchanged. The Tools thumbnail uses the same new ticket paper. Removed the extra 52pt top spacer to enlarge the physical ticket while preserving the feedback row.

Atlas is a 3:2 assembly: paper, country texture mask, coast outline, ten original unnamed city markers, selections and flight overlay share one fitted canvas. Projection fits the central 82% width / 78% height inside the paper's printed border. Texture relief is decorative, not surveyed terrain or a clue. Coastline, islands and cities use the existing bundled geometry and `JourneyCity.all` (including Harbin and Sanya); generated proposal coordinates are discarded. Paper creases continue across the land at normalized x 0.176/0.312/0.466/0.682 and y 0.494. Map width is constrained by both remaining width and height; controls retain a 160pt column, 20pt gap and 48pt touch targets. No device-specific branches.

Runtime owners: `JourneyMap.swift`, ticket portion of `RubbingSurface.swift`, and the ticket sizing/tool-image entries of `MemoryCloseups.swift`. Existing shared rubbing material, route rules, navigation, departure timing, ticket consumption and all thirteen collectible/save identities are preserved. Generated sprites and lettering were visually inspected; assembled device appearance and actual gestures remain for user acceptance.

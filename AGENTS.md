# Ivy project rules

Before extending scenes, changing puzzles, UI, copy or assets, or modifying game state, read the [Ivy project skill](docs/skills/ivy-game/SKILL.md). It routes to the current [game design baseline](docs/gameplay/IVY-GUIDE.md) and [development principles](docs/engineering/DEVELOPMENT.md). The user has accepted gameplay through Gelato; preserve that baseline unless the task requests a change. Older plans do not override current rules.

Before changing game UI, interactions, copy, or assets, read [the UI rules](docs/ui/UI-RULES.md). These are explicit user preferences and apply to new work and revisions.

For sign text, ingredient/tool artwork, or shelf placement, follow [the asset and placement rules](docs/ui/UI-RULES.md#sign-lettering-ingredient-artwork-and-shelf-placement): define physical text bounds, an approved per-item asset map, and stable surface-anchored slots before implementation. Generic bottle placeholders and guessed centre-based shelf grids are not finished work.

When the user supplies photo references for visual content, recreate the corresponding game artwork; do not substitute pure text, generic icons or renamed generic assets. Follow [the photo-reference rule](docs/ui/UI-RULES.md#user-photographs-require-recreated-artwork) and the existing design-approval workflow.

Preserve existing player progress and the 13 collectible slots. The target IDs are in [IVY-GUIDE.md](docs/gameplay/IVY-GUIDE.md): `perfume` replaces legacy `supermarket`, and `dictionary` replaces legacy `sunset`. When code is updated, migrate old saves without losing ownership or forcing a replay. Do not reset saves to demonstrate a change; use the non-persisting debug review mode.

The user owns testing by default. For ordinary design, development and polish, deliver the changes without running tests, validation scripts, verification builds, device launches or screenshot passes. Only run agent-led verification for a debugging task or when the user explicitly requests testing; follow [the testing policy](docs/ui/UI-RULES.md#testing-policy--user-owned-by-default). Do not treat a routine UI revision as debugging just to trigger tests.

Before generating or editing any scene image, reference-based artwork, or object sprite, read [image generation rules](docs/art/IMAGE-GENERATION-RULES.md). Establish the camera, believable furniture scale, support surfaces and circulation first; inspect generated results against them before delivery.

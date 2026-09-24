# Text input artwork · revised 2026-09-23

The user first approved [this four-piece design](approved.png), then replaced the custom keyboard direction with one painted input well and the iOS system keyboard. Only `ivy-input-v2` is used by active text-entry scenes. `keycap-source.png`, `enter-source.png`, `space-source.png` and their image sets remain historical design exports, not runtime controls.

The selected system-input previews are [box idle](system-input-box-idle.png), [box editing](system-input-box-editing.png) and [lock idle](system-input-lock-idle.png). They were generated with the built-in image tool from the user's screenshots `IMG_6474.PNG` and `IMG_6475.PNG`; `memory-box-puzzle@3x.png` and `story-lock-panel@3x.png` constrained the approved scenes, and `input-source.png` constrained the input material. The prompt changed only the input controls, preserving the scene camera, physical objects and clue text. The native keyboard in the editing image is illustrative; iOS supplies its actual appearance.

Reference roles: `story-yard-base@3x.png` supplied the matte pixel-storybook contours, brush texture and restrained colour; the prior `ivy-keycap`, `ivy-input-well` and `ivy-confirm` supplied the enamel and aged-brass material palette. The generated review board defined the matching shape family. No lettering is baked into the input; the native `TextField` uses Juniper and owns live text, focus, deletion and accessibility.

Render the input with a 48 pt high touch region and comfortable horizontal insets. Keep its live text vertically centered. The native keyboard's Done action submits; no other in-game text-entry controls appear.

The approved preview and source images are design and export evidence. Device appearance and gestures still require the user's playtest or an authorized device debugging pass.

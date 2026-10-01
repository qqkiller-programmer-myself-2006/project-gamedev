# Responsive layout verification — 2026-10-01 (issue #45)

Screens: Battle, Merchant, Rest camp. Captured with `tools/dev/ui_preview.gd` (`--resolution=`, `--scale=`; Merchant seed 11, Rest seed 5) and inspected by eye.

| Screen | 1280×720 ×1.0 | 1280×720 ×1.4 | 1920×1080 ×1.0 | 1920×1080 ×1.4 |
| --- | --- | --- | --- | --- |
| Battle | Pass | Pass (after badge fix) | Pass | Pass |
| Merchant | Pass | Pass | Pass | Pass |
| Rest | Pass | Pass* | Pass | Pass* |

\* Known, deliberate behavior at 1.4× text: the Equipment grid switches to 2 columns, so the stat sheet (HP, Energy, STR…) shrinks to about one visible row and must be scrolled. Nothing overlaps, but this is the "1.45× text scrolling" decision awaiting team sign-off in #39. The Tip box also covers the last visible row of the left list (it scrolls). No change made.

## Fix made

- `src/client/match/battle/battle_view.gd`: the Turn and skill cooldown badges now scale their minimum size with `settings.text_scale`; at 1.4× they were compressed beside the action panel.

## Other checks

- No important text, number, badge or control overlaps or clips at 1.0×. Transient floating damage numbers may overlap nameplates mid-animation (by design).
- Keyboard focus and reduced-motion behavior: covered by `tests/client/test_accessibility_baseline.gd` (merged in #112); this change does not alter them.
- Browsers: local web smoke cannot run here (no `build/web`, no Playwright). CI job "Export PC, browser and server builds + cross-platform smoke test" runs `tools/ci/web_smoke.mjs` on Chromium and is green on main. No browser-specific issue observed; Firefox/Safari are not covered by automation.
- Tests: 447 passed, 0 failed.

## Screenshots

- [Battle 1280×720 ×1.4](img/2026-10-01-battle-1280x720-scale-1.4.png)
- [Battle 1920×1080 ×1.4](img/2026-10-01-battle-1920x1080-scale-1.4.png)
- [Merchant 1280×720 ×1.0](img/2026-10-01-merchant-1280x720-scale-1.0.png)
- [Merchant 1920×1080 ×1.4](img/2026-10-01-merchant-1920x1080-scale-1.4.png)
- [Rest 1280×720 ×1.4](img/2026-10-01-rest-1280x720-scale-1.4.png)
- [Rest 1920×1080 ×1.4](img/2026-10-01-rest-1920x1080-scale-1.4.png)

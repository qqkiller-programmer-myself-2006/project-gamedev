# Responsive layout verification — 2026-10-01 (issue #45), redone on the redesigned UI

The first version of this report (written before PR #119/#125 redesigned combat and camp) no longer applied. Everything below was re-captured on `main` after the redesign and the follow-up fixes (#127 polish, #130 badges, #134 boss banner, f23ece0 camp/battle at 1.4×). Tool: `tools/dev/ui_preview.gd` (`--resolution=`, `--scale=`; Rest seed 5/9, Merchant seed 9/11).

"Viewed" = I looked at the PNG myself. "Reported" = a Codex run reported pass but I did not open that image.

| Screen | 1280×720 ×1.0 | 1280×720 ×1.4 | 1920×1080 ×1.0 | 1920×1080 ×1.4 |
| --- | --- | --- | --- | --- |
| Battle (turn) | Viewed, pass | Viewed (boss turn), pass | Reported | Viewed, pass |
| Boss warning banner | Viewed, pass | Viewed, pass | Reported | Viewed, pass |
| Rest camp | Viewed, pass | Viewed, pass | Viewed, pass | Reported |
| Merchant | Not viewed | Not viewed | Not viewed | Viewed, pass |

## What was found and fixed during this pass

- Combat status badges (Turn / Ready / energy) ran off the right edge after the redesign → #130.
- Boss WARNING banner covered the boss nameplate and the first turn-list row at ×1.4; battle log clipped its newest line → #134.
- Items card text clipped, target caption over nameplates, Summary banner over the title, Gold wording → #127.
- Camp overflowed the screen at 1280×720 ×1.4 (Equipment panel off the right edge, buttons below the screen, mid-word breaks) → fixed on main by f23ece0 (tabs moved inside their columns; the middle tab labels now read in full).

## Remaining minor items (not fixed)

- At ×1.4 the Equipment gear grid is below a scrolling area; the stat sheet and slots need scrolling (known; sign-off pending in #39).
- At 1920×1080 ×1.4 an enemy sprite on the far right can sit under the Turn/Ready/energy badges, and the "Frost Lance"/"Crushing Root" move caption bar is faint under the enemy plates.
- Turn-list heading flush to the left screen edge at 1920×1080.

## Other checks

- Keyboard focus and reduced-motion behavior are covered by `tests/client/test_accessibility_baseline.gd` (#112) and the layout smokes `t35`/`t43`/`t88`.
- Browsers: local web smoke cannot run here (no `build/web`, no Playwright). CI "Export PC, browser and server builds + cross-platform smoke test" runs `tools/ci/web_smoke.mjs` on Chromium and is green. Firefox/Safari are not covered.
- Full suite on main after these merges: 453 passed, 0 failed.

## Screenshots

- [Battle 1920×1080 ×1.4](img/2026-10-01-battle-1920x1080-scale-1.4.png)
- [Boss warning 1280×720 ×1.4](img/2026-10-01-boss-warning-1280x720-scale-1.4.png)
- [Rest 1280×720 ×1.0](img/2026-10-01-rest-1280x720-scale-1.0.png)
- [Rest 1280×720 ×1.4](img/2026-10-01-rest-1280x720-scale-1.4.png)
- [Rest 1920×1080 ×1.0](img/2026-10-01-rest-1920x1080-scale-1.0.png)
- [Merchant 1920×1080 ×1.4](img/2026-10-01-merchant-1920x1080-scale-1.4.png)

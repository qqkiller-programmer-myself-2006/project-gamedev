# Final build checklist (#54) — 2026-10-01

Base: `main` c0bf6ee. Supported browser: Chromium only (owner decision, #45).

## Verified by Claude (evidence in repo/CI)
- [x] Headless suite 447 passed, 0 failed (run locally on `main`; CI "Headless GDScript tests" green on PR #114).
- [x] CI "Export PC, browser and server builds + cross-platform smoke test" green (Chromium 1280x720, PC <-> browser, both host directions).
- [x] Layout at 1280x720, text 1.0 / 1.4, and 1920x1080 for Battle, Merchant, Rest (#45); Camp Tip clip fixed in PR #114.
- [x] Keyboard focus + reduced motion covered by `tests/client/test_accessibility_baseline.gd` and `test_battle_smoothness.gd` (#44).
- [x] Art: Elder Thornwarden, Thornback Boar, Old Swordsman, Veteran Hunter, Shrine Spirit, Bram (Classless) in game (#75, #85).
- [x] Boss fight shown in a real preview (Cave backdrop, Elder Thornwarden, phase banner) — `ui_preview` 06_boss_turn / 07_boss_warning.

## Open visual issues seen at 1920x1080 + text 1.4 (not fixed; decide before final build)
1. Path Vote (`03_vote`): right column text and the vote/ready rows run off the bottom edge, Tip text cut mid-sentence.
2. Summary (`90_summary_defeat`): the "Defeat" banner still overlaps the "DEFEAT" title (QA item U26).
3. Camp Equipment panel at 1.4: last line (HP / Invest Points) cut off.
4. Combat at 1.4: turn list is small and its text is hard to read; target caption sits on the back row.
Repro: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/q --seed=11 --scale=1.4 --resolution=1920x1080 --class=rogue`

## Needs the owner (an AI cannot do these)
- [ ] #55 / #19 deploy Cloudflare Worker + D1 and staging (credentials) — follow `docs/running.md`.
- [ ] #39 team sign-off on motion level and 1.45x text scrolling.
- [ ] Play one full Story run and one Multiplayer run by hand (animation feel after #88 cannot be judged from still images).
- [ ] Decide on open visual issues 1-4 above (fix now or ship).
- [ ] Final sign-off on #54, then close #47, #40, #2.

## Build / release steps
- [ ] `bash tools/run_tests.sh` with no other Godot running -> 0 failed.
- [ ] Export Web + Windows, confirm both `manifest.json` files ship and `deploy/` does not.
- [ ] Merge to `main`, confirm CI green, tag the build.

# Final build checklist (#54, due 2026-10-02)

Legend: [C] Claude can run / verify, [H] needs the owner.

## Before building
- [C] `git status` clean, main CI green, `bash tools/run_tests.sh` all pass (454 at 2026-10-01 after PR #143).
- [C] `simulate.gd --seeds=40 --humans=1,2 --pace` win rate 70–92%, no softlock.
- [C] UI screenshots at 1280×720 and 1920×1080, ×1.0 and ×1.4 (`tools/dev/ui_preview.gd`); see `2026-10-01-responsive-verification.md`.
- [x] Path Vote overflow and Summary banner overlap at 1080p x1.4 fixed in PR #125 (previews checked at full resolution).
- [x] Camp Equipment overflow and Battle chip/log clipping at 1.4x fixed in PR #135; layout smoke tests (T35/T42/T43/T88/T46) now run in CI (PR #137, #143).
- [x] Battle skill menu, nameplate and target prompt at 1.4x fixed in PR #143.
- [H] Known remaining at 1.4x: Skill menu row 4 is only visible after scrolling; target prompt sits over the party row; Camp lists show only 1-3 rows (they scroll); not clipped. Accept or improve after final build.
- [H] #39 sign-off on motion level and 1.4× stat-sheet scrolling.
- [H] #55 Worker + D1 deployed (`wrangler login`, see `docs/guides/running.md`); the client's profile URL points at it.
- [x] #75 / #85 art (boss, Boar, Old Swordsman, Veteran Hunter, Shrine Spirit, Bram) done and in game.

## Build
- [C] Run the `builds` workflow; download `web-build`, `windows-build`, `linux-server`.
- [C] `tools/ci/web_smoke.mjs` green on the artifacts.

## Smoke on the real build
- [H] PC `.exe`: Single-player Story and a Duo room through to Guardian Boss.
- [H] Browser: same, plus a mixed PC + browser room (checklist in `docs/guides/staging.md`).
- [H] Stopwatch one full Match (target 20–30 min) and note it in #19.

## Release
- [H] Staging deployment (#19), then tag and publish.

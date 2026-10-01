# Final build checklist (#54, due 2026-10-02)

Legend: [C] Claude can run / verify, [H] needs the owner.

## Before building
- [C] `git status` clean, main CI green, `bash tools/run_tests.sh` all pass (447 at 2026-10-01).
- [C] `simulate.gd --seeds=40 --humans=1,2 --pace` win rate 70–92%, no softlock.
- [C] UI screenshots at 1280×720 and 1920×1080, ×1.0 and ×1.4 (`tools/dev/ui_preview.gd`); see `2026-10-01-responsive-verification.md`.
- [H] #39 sign-off on motion level and 1.4× stat-sheet scrolling.
- [H] #55 Worker + D1 deployed (`wrangler login`, see `docs/guides/running.md`); the client's profile URL points at it.
- [H] Decision on #85 (Classless / boss art) — currently placeholder blocks.

## Build
- [C] Run the `builds` workflow; download `web-build`, `windows-build`, `linux-server`.
- [C] `tools/ci/web_smoke.mjs` green on the artifacts.

## Smoke on the real build
- [H] PC `.exe`: Single-player Story and a Duo room through to Guardian Boss.
- [H] Browser: same, plus a mixed PC + browser room (checklist in `docs/guides/staging.md`).
- [H] Stopwatch one full Match (target 20–30 min) and note it in #19.

## Release
- [H] Staging deployment (#19), then tag and publish.

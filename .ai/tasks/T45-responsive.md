# T45 — Issue #45: verify responsive layout (Battle, Merchant, Rest camp)

Acceptance: verified at 1280x720 and 1920x1080 (also with --scale=1.4 text); no important text/numbers/badges/controls overlap or clip; supported browser set checked and browser-specific issues recorded; screenshots/evidence stored; keyboard + reduced-motion behavior preserved.
Do:
1. Generate screenshots with tools/dev/ui_preview.gd (find the real path) for Battle, Merchant, Rest at 1280x720 and 1920x1080, scale 1.0 and 1.4 (seed 11 gives Merchant, seed 3 gives Rest; see .ai/checkpoint.md). Look at each image. Fix any overlap/clipping in src/client (minimal fixes) and re-shoot.
2. Browser check: run the web smoke (tools/ci/web_smoke.mjs, see docs/running.md) if feasible locally; otherwise record that CI's web smoke covers it. Record browser notes.
3. Write docs/review/2026-10-01-responsive-verification.md listing each screen/resolution, result, fixes made, browser notes, and relative links to a few key screenshots copied into docs/review/img/ (keep small, <=6 PNGs).
Constraints: work only in this worktree, no push/PR, no opencode; local commit OK.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 444+).
Final message: per screen/resolution pass/fail, fixes, changed files, exact test summary.

# T76 — Issue #76 P2 follow-ups (profile/D1, Story profile, export filters)

Read `gh issue view 76` (if gh is blocked in your sandbox, use the body below) and docs/review/2026-09-30-final-review.md (find on main or branch claude/github-project-issue-learning-20567b via `git show`).
Items: F4 Story uses empty in-memory profile so owned Races/Boons never apply -> simplest: state "no meta in Story" in docs/adr/0014 (ADR-0014) unless wiring a read-only local profile is trivial; F5 same-token sessions on one server can overwrite each other; F6 join blocks up to 3 s on profile load; F7 queued saves dropped on shutdown; F8 "progress not saved" notice lands on Lobby which ignores it; F17/F19 exclude `deploy/*` from export presets (export_presets.cfg) and note manifest.json shipping check; fix other P2s in the report if small.
Constraints: server/profile code under src/ and tests/; keep tests deterministic; no push/PR, no opencode. Commit locally on the branch is fine.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 444).
Final message: per-item done/skipped with reason, changed files, exact test summary.

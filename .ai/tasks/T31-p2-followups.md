# T31 — P2 follow-ups (issue #76)

Read docs/review/2026-09-30-final-review.md. Fix the open P2 items:
- F4 rest: Story uses an empty in-memory profile so owned Races/Boons never apply. Decide the smallest safe option: state "no meta in Story" in the relevant ADR (docs/adr) and in the Story UI text, OR wire a read-only local profile. Prefer the documented option unless wiring is small.
- F5: two sessions with the same token on one server can overwrite each other's profile. Serialize/guard per token.
- F6: join blocks up to 3 s on profile load. Make it non-blocking or bounded with a cached/default fallback.
- F7: queued profile saves are dropped on server shutdown. Flush on shutdown.
- F8: the "progress not saved" notice lands on the Lobby which ignores it. Make the Lobby (or a global toast) show it.
- F17/F19: exclude deploy/* from export presets (export_presets.cfg); confirm hero/enemy manifest.json files are included in export (add include filter if needed).
- Any other P2 finding in the report that is small and safe.

Rules:
- Add a headless test per fix (tests/profile, tests/match, tests/client as fits).
- Do not change combat rules or balance.
- Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all passing.
- Final message: each F-number fixed / not done (with reason), changed files, exact test summary line.

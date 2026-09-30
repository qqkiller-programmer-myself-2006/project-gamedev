# T28 — Reliability: unknown encounters (#41), Status cleanup (#42), Ready check (#43)

Read `AGENTS.md` ("Where things live"), `CONTEXT.md`, `gh issue view 40`, `gh issue view 41`, `gh issue view 42`,
`gh issue view 43` (each has acceptance criteria — do all of them), and the related ADRs.

- #41: an unsupported encounter type is detected at the Match boundary and reported (error/terminal event naming the type);
  never silently completed. Document the behaviour in code and, if it is a rule, in the matching ADR.
- #42: tests (through Match commands, snapshots and events only) that Statuses are cleared after a won Combat, a lost Combat,
  a passed Class Challenge and a failed one; fix any leak you find without changing tick/expiry/reward behaviour.
- #43: Ready check — single player leaves Merchant/Rest without AI Ready commands; co-op advances when every connected human
  is Ready; a disconnected human counts as Ready; duplicate Ready keeps its deterministic error; snapshots/events expose a
  Ready count matching human state; tests for both Merchant and Rest.

Files: `src/match/**`, `tests/**`, `docs/adr/**` (only if a rule changes). Not `src/client/**` or `src/server/**` (another
executor is working there).
Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
(baseline 331). ONE Godot process at a time. Report in English: per acceptance criterion pass/fail, tests added, test line.

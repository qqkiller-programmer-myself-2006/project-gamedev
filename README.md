# BEYOND THE WORLD'S END — Forest vertical slice

Online co-op fantasy turn-based RPG built with **Godot 4.7** and **GDScript**.
The current goal is the Forest vertical slice described in
[issue #2](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/2).

- Domain glossary: [`CONTEXT.md`](CONTEXT.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Product requirements: [`docs/prd.md`](docs/prd.md)
- Testing guide: [`docs/testing.md`](docs/testing.md)

## Project layout

```text
project.godot          Godot project (one codebase for server, PC and browser)
content/forest.json    All Forest content and balance numbers
src/core/              Injected dependencies: GameRng, ManualClock, SystemClock, ForestContent
src/match/             Authoritative game logic behind the Match interface (MatchServer)
tests/                 Headless tests (run_tests.gd runner, TestCase, MatchHarness)
scripts/               Command-line helpers
```

## Quick start

```bash
# Godot 4.7.2 must be on PATH as `godot` (or set GODOT=/path/to/godot)
./scripts/run_tests.sh
```

## The Match interface

`MatchServer` (`src/match/match_server.gd`) is the only seam game logic is
tested through. It receives three dependencies from outside — a `GameRng`
seed, a clock and `ForestContent` — and exposes:

| Call | Purpose |
| --- | --- |
| `open_session()` | Anonymous session for a new connection |
| `command(session, cmd)` | Apply a command; returns `{"ok": true, ...}` or `{"ok": false, "error": code}` |
| `update()` | Process timers due at `clock.now()` |
| `take_events(session)` | Events this session should see |
| `snapshot(session)` | State this session should see |
| `close_session(session)` | Connection dropped |

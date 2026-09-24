# BEYOND THE WORLD'S END — Forest vertical slice

Online co-op fantasy turn-based RPG built with **Godot 4.7** and **GDScript**.
The current goal is the Forest vertical slice described in
[issue #2](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/2).

- Domain glossary: [`CONTEXT.md`](CONTEXT.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Product requirements: [`docs/prd.md`](docs/prd.md)
- Testing guide: [`docs/testing.md`](docs/testing.md)
- Running server and clients: [`docs/running.md`](docs/running.md)
- Balance and pacing: [`docs/balance.md`](docs/balance.md)
- Browser build: [`docs/web.md`](docs/web.md)
- Accessibility checklist: [`docs/accessibility.md`](docs/accessibility.md)
- Staging and QA checklist: [`docs/staging.md`](docs/staging.md)

## Project layout

```text
project.godot          Godot project (one codebase for server, PC and browser)
content/forest.json    All Forest content, text and balance numbers
src/core/              Injected dependencies: GameRng, ManualClock, SystemClock, ForestContent
src/match/             Authoritative game logic behind the Match interface (MatchServer)
src/net/               Wire protocol, WebSocket server transport and client connection
src/server/            Headless server node (GameServer)
src/client/            Client UI: screens, per-phase panels, theme, settings, sounds
src/app/               Entry point: --server starts the server, otherwise the client
tests/                 Headless tests (runner, Match tests, regression, network)
tools/                 simulate.gd (balance), ui_preview.gd (screenshots), web_smoke.mjs
deploy/                Staging: server container, Caddy (HTTPS + wss proxy), compose
scripts/               Command-line helpers
```

## Quick start

```bash
# Godot 4.7.2 must be on PATH as `godot` (or set GODOT=/path/to/godot)
./scripts/run_tests.sh                               # all tests, headless
godot --headless --path . -- --server --port=8910    # authoritative server
godot --path . -- --url=ws://127.0.0.1:8910          # PC client (open two for co-op)
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

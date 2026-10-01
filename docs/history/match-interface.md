# The Match interface


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

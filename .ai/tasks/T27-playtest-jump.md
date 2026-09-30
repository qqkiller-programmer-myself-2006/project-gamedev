# T27 — Dev Playtest: jump straight to a scene (#57 follow-up, T10b)

Read `AGENTS.md` ("Where things live"), `src/client/client_app.gd` (`can_playtest`, `start_dev_playtest`, `stop_dev_playtest`),
`src/client/title/title_screen.gd` (the "(DEV) Playtest" button + Seed toggle), `src/server/game_server.gd`
(`listen_embedded`), `src/match/match_server.gd`, `tools/dev/ui_preview.gd` (how it drives the game to each screen).

Goal: the owner tests by hand. From the title, "(DEV) Playtest" opens a small dev panel (only in debug/`--dev` builds, never in
release exports) where they pick:
- **Start at**: Journey start (today's behaviour), Combat (Layer 1), Merchant, Rest camp, Class Encounter, Story event,
  Cave (Layer 5 combat), Boss.
- **Class** for the player's character (Classless, Swordsman, Archer, Mage, Guardian, Assassin), and the existing **Seed**.
Then the embedded server starts a single-player match and fast-forwards to that scene.

Build it as a dev-only server command (e.g. `dev_jump {target, layer, class}`) that `MatchServer` accepts ONLY when a flag
like `allow_dev` is set — set it only in the embedded Playtest server (like `allow_story` for Story). Online `GameServer`
never sets it; test that the online server rejects `dev_jump` with an error code (text in `ui_text.gd`).
Implement the jump with existing rules (set layer, grant EXP/level for the layer, pick the encounter of that type from content)
rather than a second game engine; keep it deterministic with the seed.
Command line: `--dev --playtest --jump=boss --class=mage --seed=7` does the same without the panel.

Files: `src/client/**`, `src/match/match_server.gd` + a small helper in `src/match/` if needed, `src/server/game_server.gd`,
`tests/**`, `docs/guides/running.md` (document the panel and flags). Do not change content or rules.
Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
(baseline 331); tests: each jump target lands on the right encounter type; the online server rejects `dev_jump`. Windowed:
`"$GODOT" --path . -- --dev --playtest --jump=boss --class=mage --seed=7` for ~10 s, screenshot via `ui_preview` or your own
capture, look at it. ONE Godot process at a time. Report in English: what changed, test line.

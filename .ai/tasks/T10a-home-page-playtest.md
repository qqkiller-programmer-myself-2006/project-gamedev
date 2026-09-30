# T10a — New home page + one-click Playtest bypass (client only)

You are working on BEYOND THE WORLD'S END (Godot 4.7 / GDScript). Read `CONTEXT.md`, `src/client/screens/title_screen.gd`,
`src/client/client_app.gd`, `src/app/main.gd`, `src/app/launch_options.gd` and `src/server/game_server.gd` first.
The current home page (`build/.../01_title.png`, attached) is a plain form on a flat green background. The owner wants a much
nicer home page, and a bypass button to play-test the game manually without running a separate server.

## Files you may change

`src/client/screens/title_screen.gd`, new files under `src/client/home/`, `src/client/client_app.gd` (only what the Playtest
flow needs), `src/app/launch_options.gd` (a `--dev` flag), `src/client/ui/ui_text.gd` (append only), `tools/ui_preview.gd`
(keep its title-screen automation working). Do NOT edit `src/server/**`, `src/match/**`, `content/**` — other agents are
changing them right now. You may *use* `GameServer` as-is.

## 1. Home page (1280×720 base; must also work at 1920×1080 and text scale 1.4)

Style: same pixel look as the AAC-style screens — Pixelify Sans with dark outline, dark navy panels (#1c2233) with a light grey
2 px border and small corner diamonds, like `docs/references/aac_rogue/01–03`.
- **Animated backdrop** drawn in code: night-sky gradient, moon, two parallax tree-line layers that drift slowly, drifting fog,
  a few fireflies. Respect Reduced motion (static when on).
- **Campfire scene** bottom-centre: a code-drawn campfire with flickering light, and the owner's class sprites standing around
  it using idle frames from `assets/characters/<class>/idle_*.png` (swordsman left of the fire facing right, archer and mage
  right of it facing left) with a gentle 2 px bob. Read `assets/characters/manifest.json`. Nearest-neighbour filtering.
- **Logo**: "BEYOND THE WORLD'S END" large, gold with dark outline and a soft pulsing glow; subtitle "Forest — a co-op journey".
- **Menu** (navy panel, left side or centre-left): big buttons **Play**, **Settings**, **Credits**, **Quit** (Quit hidden on web).
  Play opens a second panel: your name, **Create room**, **Room code + Join**, and an **Advanced** toggle that reveals the server
  address field (default from launch options). Back returns to the menu. Keep all current behaviour (remembered name, validation,
  errors shown in the panel).
- Credits panel: game title, "Made with Godot 4.7", font credit (Pixelify Sans, OFL), "Character art by the project owner".
- Version/build text bottom-right (small). Keyboard: arrows/Tab/Enter on all buttons, Esc = back.

## 2. Playtest bypass

- Visible only when `OS.is_debug_build()` or the `--dev` launch option is present, and never on the web build.
- A **Playtest ▶** button (visually distinct, e.g. orange border and a small "DEV" tag) in the menu. Clicking it:
  1. starts an embedded `GameServer` as a child node on `127.0.0.1` with a free port (try 8911, then 8912…),
  2. connects to it, creates a room with name "Tester", and **starts the Match immediately** as Single-player (the Host start
     command the lobby already uses),
  3. shows a small "DEV PLAYTEST" tag in a screen corner for the whole session, and stops the embedded server when you leave
     to the home page or quit.
- Next to it a small **options** popup: text field `Seed` (optional int → pass to the embedded server only if `GameServer`
  already supports a seed option; otherwise disable the field with tooltip "arrives with T10b") and a "Two players" checkbox
  that opens a second client window is NOT required — skip it.
- Command line: `--dev --playtest` jumps straight into the playtest flow on start (for quick restarts from the editor).
- Existing flows must keep working unchanged: `--url/--name/--join/--auto` launch options, browser `?server=...&auto=1`,
  `tools/ui_preview.gd`, `tools/web_smoke.mjs`.

## Verify

1. `bash scripts/run_tests.sh` → 0 failed (paste the summary line).
2. Screenshot the home page (extend `tools/ui_preview.gd` if needed) at 1280×720, 1920×1080 and `--scale=1.4`; check nothing
   overlaps and it looks polished.
3. Run the game with `"$GODOT" --path . -- --dev --playtest` and confirm (log output / screenshot) that it reaches the first
   Path Voting or first encounter screen without any other process running; then confirm a normal run without `--dev` shows no
   Playtest button.

Report in English: files changed, how the embedded server is started/stopped, test summary line, screenshot paths.

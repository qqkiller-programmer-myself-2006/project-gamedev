# T20a — Enemy sprites and painted backgrounds in battle (#73 step 2, client)

Read `AGENTS.md` ("Where things live"), `gh issue view 73`, `docs/design/ui-style.md`, `assets/enemies/manifest.json`,
`src/client/match/battle/{battle_view,battle_token,battle_backdrop,sprite_set}.gd`, `assets/heroes/manifest.json`.

## Content contract (another executor adds these fields to `content/forest.json` in parallel — do NOT edit content)
- `enemies.<id>.sprite`: an id in `assets/enemies/manifest.json` (e.g. `grey_wolf.sprite = "wolf"`). Optional
  `enemies.<id>.sprite_variant`: a variant name from the manifest (use `variants/<name>.png` as a static idle frame + tint-free).
  Enemies without `sprite` (boar, boss, class-trial NPCs) keep today's code-drawn look.
- `journey.backdrops`: `{"1": "forest", ..., "5": "cave"}` (layer number as string -> `assets/backgrounds/<name>.png`);
  `boss.backdrop`: `"cave"`. Missing -> today's code-drawn forest backdrop. Until the content lands, test with a local
  override in your tests/preview only (do not commit content changes).

## Build
1. Enemy sprites: extend `SpriteSet` (or a small `EnemySpriteSet` beside it) to load `assets/enemies/manifest.json`. Battle
   tokens for enemies with `sprite` play `idle` (loop), `attack` when the enemy acts, `hurt` when hit, `die` once on death
   (hold last frame), mirrored to face left (the art faces right). Scale so the sheet's `size_px` 32/48/64 reads as
   small/medium/large next to the heroes (hero idle is ~80 px tall on the 1280x720 layout); nearest filtering; feet on the
   token's ground line; nameplate/HP bar positions follow the sprite's height (see `_body_height()` in `battle_token.gd`).
2. Backgrounds: `battle_backdrop.gd` draws `assets/backgrounds/<name>.png` (cover-fit, nearest or linear is fine for painted
   art) for the current layer/boss when content names one; keep the dim overlay so tokens and HUD stay readable (contrast test
   `tests/client/test_ui_contrast.gd` must pass). Fall back to the current code-drawn scene.
3. `tools/dev/ui_preview.gd`: the combat/boss shots show enemy sprites and the painted backdrop (use an in-preview content
   override if the content fields are not merged yet).
4. Tests (`tests/client/`): manifest loads, every enemy id with a `sprite` resolves frames for idle/attack/hurt/die, unknown
   sprite id falls back without error.

## Rules
- Files: `src/client/**`, `tools/dev/ui_preview.gd`, `tests/client/**`. Not `content/**`, not `src/match/**`.
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
  (baseline 285); windowed `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --out=build/t20a` and look at the combat
  and boss shots yourself. ONE Godot process at a time.
- Report in English: what changed, screenshots viewed, test line.

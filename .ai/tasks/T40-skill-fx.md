# T40 — Skill FX art + battle wiring (production in ~5 h)

Read first: `AGENTS.md`, `docs/design/ui-style.md`, `src/client/match/battle/battle_token.gd`, `src/client/match/battle/battle_view.gd`
(`handle_event`), `content/forest.json` (`skills`), and look at `assets/heroes/*` and `assets/enemies/giant_spider/effects/*.png`
so the new FX match the existing pixel-art style (chunky pixels, dark outline, limited palette, transparent background).

## Goal
Every class skill gets a short visual effect in battle (none exist today; only `giant_spider/effects/web_*.png`).
Skills: power_slash, aimed_shot, fireball, frost_lance, protect, shield_wall, stab, prep_time, poke_up, inject_venom.
"Ultimate-tier" (longest cooldown / biggest impact: fireball, power_slash, shield_wall, frost_lance, inject_venom) get a bigger,
more dramatic effect (more frames, larger canvas, screen-flash accent).

## Part A — images (priority, do first)
1. Use your image-generation tool to make one horizontal sprite strip per skill (transparent PNG background; if you cannot get a
   true alpha channel, generate on a flat `#ff00ff` background and key it out with Pillow). Normal skills: 6 frames at 128x128;
   ultimate-tier: 8 frames at 192x192. If image generation is unavailable or output is unusable, draw the frames procedurally with
   Pillow in `tools/art/make_skill_fx.py` (slash arcs, arrow streak, fire burst, ice shards, shield glow, dagger flash, poison drip).
2. Save raw strips under `art_source/fx/<skill>.png` and sliced frames as `assets/fx/<skill>/frame_00.png ...` (slicer:
   `tools/art/slice_skill_fx.py`; assert the exact frame count, hard fail otherwise). Also write `assets/fx/manifest.json`:
   `{"<skill>": {"frames": N, "size": [w,h], "fps": 14, "anchor": "target|actor|party", "tier": "normal|ultimate"}}`.
3. Make `assets/fx/_contact.png` (all strips on navy `#0e1a33`) and look at it yourself; redo any frame that is blurry, cropped,
   has leftover magenta, or does not read as its skill.
4. Run `"$GODOT" --headless --path . --import` so `.import` files exist, and commit them.

## Part B — wiring (small, only after Part A is committed)
- New `src/client/match/battle/skill_fx.gd` (`class_name SkillFx`): `static play(parent: Control, skill: String, at: Vector2)`
  loads `assets/fx/manifest.json` once, plays frames on a `TextureRect` (nearest filter) via Tween, then `queue_free()`.
  Missing skill / missing files -> silently return (never crash).
- In `battle_view.gd` `handle_event`: when `event.get("skill")` is non-empty, spawn the FX at each result target token (anchor
  `target`), at the actor token (`actor`) or at the party centre (`party`, for shield_wall). Respect reduced-motion if the project
  already has such a setting (grep `reduced`/`motion`; if absent, skip).
- Add `tests/client/test_skill_fx.gd`: every skill in `content/forest.json` has a manifest entry, the right number of existing
  frames and a loadable texture; `SkillFx.play` with an unknown skill returns without error.

## Part C — review
After A+B, review your own diff critically (git diff vs `main`): style consistency across all 10 skills, frame counts, file sizes
(each strip < 300 KB, total `assets/fx` < 6 MB), no touched files outside the list below, null/free safety of the tween code.
Fix what you find; list remaining concerns in the report.

## Rules
- Allowed paths: `assets/fx/**`, `art_source/fx/**`, `tools/art/*skill_fx*.py`, `src/client/match/battle/skill_fx.gd`,
  `src/client/match/battle/battle_view.gd` (only `handle_event` + one member), `tests/client/test_skill_fx.gd`, `docs/design/`
  (a short "Skill FX" note). Do not edit server/match code or content JSON.
- Commit in small steps (`feat(fx): ...`) with explicit `git add <paths>` (never `git add -A`), each ending with
  `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Do not push.
- Verify: `GODOT=<path> bash tools/run_tests.sh` -> exact summary line, 0 failed. ONE Godot process at a time.
- Report in English: files, contact sheet path, test line, commit hashes, open concerns.

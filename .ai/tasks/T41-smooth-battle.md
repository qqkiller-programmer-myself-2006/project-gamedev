# T41 — Smoother battle rendering (#88: S1, S2, S3, S5)

Client only: `src/client/**`, `tests/client/**`. Source: `docs/review/2026-09-30-full-qa-report.md` (S1, S2, S3, S5) and issue #88.

1. **S1** `_build_stage` in the battle view destroys and recreates every BattleToken on each update (flicker, lost hover/tooltip,
   jumping HP bars). Keep one BattleToken per unit id and update it in place; tween HP/Energy bars ~0.25 s with a trailing damage bar.
2. **S2** The state update is applied before its events (`client_app.gd` ~313-316), so HP drops before the attack plays. Queue per
   action: attack (~0.3 s) -> hit flash/number -> HP tween. Banners short and non-blocking. Must still work with reduced motion
   (no tweens/shake, apply instantly) and must never leave the UI waiting on an animation when the next turn needs input.
3. **S3** `content/forest.json` (56 KB) is re-read and parsed on every battle build (`battle_view.gd` ~190). Cache it once;
   switching Fight/Items/Esc in local mode rebuilds only the bottom panel.
4. **S5** Per-frame waste: `add_theme_color_override` every frame in `tick()` (only on change), `load()` in `SpriteSet` for variant
   enemies inside `_draw` (cache), dialogue typewriter should use `visible_characters` instead of re-slicing, add short fades for
   chapter cards/dialogue.
5. Tests (tests/client): token node identity is preserved across two consecutive updates; HP bar value reaches its target after the
   tween; forest.json parsed once across N builds; reduced-motion applies instantly.

Verify (one Godot process at a time, `$GODOT` set): `--import`, `bash tools/run_tests.sh` -> 0 failed, not fewer passed than before;
previews `tools/dev/ui_preview.gd -- --seed=11 --out=build/t41` and `--scale=1.4`; look at a combat image.
Report (<200 words): per item done / not done, exact test summary line, changed files, stray files. Do not commit or push.

# T32 — Redesign Combat and Merchant screens to match the new mockups

Reference images (look at both with your image input; they are also in the repo):
`docs/references/redesign/combat_target.png` (Combat, Forest 2/5) and `docs/references/redesign/merchant_target.png`
(Travelling Merchant camp). These are **target mockups** for look and layout. Read `AGENTS.md`, `docs/design/ui-style.md`,
`src/client/ui/ui_kit.gd`, `src/client/match/battle/{battle_view,battle_token,combat_panel}.gd`,
`src/client/match/camp/{camp_view,merchant_panel}.gd`. Client only: `src/client/**`, `tests/client/**`, new art under `assets/ui/`.
Do not touch `src/match/**` (rules) or `content/`. Keep every existing key binding, tooltip, accessibility setting (text scale,
reduced motion, focus order) and all game behaviour; this is a visual/layout redesign.

## Combat (combat_target.png)
- Left column: the turn-order list as 5 portrait cards — each card has the hero **portrait** (`SpriteSet.portrait(class)`),
  name, `Lv N`, HP bar with `cur/max` inside the bar, energy bar with `cur/max`; current actor has a gold border and a
  gold arrow marker at its left. Above the list a gold-framed "Turn N" banner. Keep enemy entries in the order list too
  (as in the current game) but styled the same way.
- Top-right: gold-framed location tag with a tree icon, "Forest (2/5)".
- Enemy nameplates: wide dark plates across the top middle, each with enemy portrait (`assets/enemies/<id>/portrait.png`),
  name, `Lv`, HP and energy bars — placed above the enemies like the mockup, not under each sprite. Party nameplates stay
  compact or move into the left column; no duplicate info.
- Bottom action bar: one wide dark panel with gold corner ornaments: hero portrait, `Name · Class Lv N`, HP and energy bars with
  numbers, and three large buttons **Fight [F]**, **Items [I]**, **Focus [O]** with sword / bag / eye icons (reuse `assets/icons`,
  draw missing icons with the existing icon pipeline or simple pixel art). Focused/selected button = gold border.
- Keep: target numbers, status badges, damage numbers, banners, timer/"waiting for X" text (T31), Gold display (put it in the bar).
- Sprites stay as they are; field layout may be adjusted so nothing overlaps the new plates at 1280x720 and 1920x1080.

## Merchant (merchant_target.png)
- Top bar: game title with compass icon on the left, location tag on the right, both gold-framed.
- Left panel: merchant header (stall art if you can make a good pixel-art banner; otherwise a tasteful panel with the
  existing icon), "Travelling Merchant / Supplies for the road ahead.", a table (Item / Price / Stock) of rows: item icon,
  name + one-line description, gold price with coin icon, "N left", gold-outlined **Buy** button. First row focused with gold border.
- Right panel: hero switcher (prev/next arrows + 4–5 portrait tiles, selected has gold border); a character card with
  name, class, `Lv`, full-body sprite (idle frame) and stats (HP/ATK/DEF/SPD — map to the real attributes the game has, do not
  invent rules); equipment slot grid (Weapon, Helmet, Chest, Boots, Charm 1–3) showing "Empty" — **only show slots the game
  actually has**; if a slot does not exist in the rules, leave it out rather than fake it; Inventory list `(n/cap)` with a Sort
  control only if sorting exists.
- Bottom: Gold amount with coin icon, big gold **Ready** button with crossed-swords icon. Keep existing Merchant/Rest behaviour,
  keyboard focus (`camp_focus_smoke`), Ready/leave rules and purchase confirmation.
- The Rest camp screen should reuse the same frame/ornament styling so both camp screens look consistent.

## Shared style
- Extend `UiKit` (one place) with the new ornament frame (gold corner ornaments, dark navy fill, gold accent) as type variations;
  screens must not build their own StyleBoxes or hex colours (see ui-style.md). Update `docs/design/ui-style.md` with the new variations.
- Text must stay readable (WCAG AA tokens in `tests/client/test_ui_contrast.gd`); support text scale 1.0–1.4.

## Verify
One Godot process at a time; `$GODOT` is set by the runner. `"$GODOT" --headless --path . --import`, then `bash tools/run_tests.sh`
→ 0 failed. Then windowed previews: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=11 --speed=10 --out=build/t32`
(also `--scale=1.4`, and seed 3 for the Rest camp) and LOOK at `04_combat_turn`, `06_boss_turn`, `08_merchant` and the rest camp image
against the mockups; fix overlaps/cropping and iterate until the match is close. List the screenshots and every deviation from the
mockup in your report. Commit with explicit `git add`; messages end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
You MAY commit in your own worktree; do not push or merge.

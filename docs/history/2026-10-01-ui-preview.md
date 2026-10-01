# UI preview — 2026-10-01

ย้ายมาจาก README.md (หัวข้อ Latest UI preview)

Captured `origin/main` at `7310d3e` (PRs #122 and #123) with Godot 4.7.2 on
Windows. The updated title, lobby, voting, battle, and camp screens use more
game-like proportions. Combat places initiative cards along the left, enemy
cards above the battlefield, and Fight / Items / Focus in a large bottom action
bar. The Merchant screen uses Shop, Inventory, and Equipment columns. PR #123
adds animated skill-effect sprites.

Run the scripted Duo preview to capture the current UI:

```bash
godot --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=7 --speed=8
```

This run produced 27 PNGs covering the title, lobby and character setup, settings,
path voting, combat actions and targets, boss states, Merchant, combat rewards,
skill-effect poses, and defeat summary. Build output is ignored by Git. The seed
ended in Defeat and did not visit Rest, Story, or Treasure, so those screens are
not represented in this capture. No test suite was run for this preview.

Redesign references: [combat target selection](../references/redesign/combat_target.png)
and [Merchant](../references/redesign/merchant_target.png).

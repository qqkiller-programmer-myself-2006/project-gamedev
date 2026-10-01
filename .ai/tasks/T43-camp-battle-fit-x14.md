# T43 — Camp and Battle overflow the viewport to the right at text 1.4 (main ce362dd)

Client only: `src/client/**`, `tests/client/**`. Theme: `docs/design/ui-style.md`, `UiKit`. Follow the method of T42b
(`.ai/tasks/T42b-vote-horizontal.md`, `tests/client/t42_vote_summary_layout_smoke.gd`): the previous smoke test passed while the
screen overflowed because the 1.4 scale was never really applied (ClientApp._ready() reloads settings). Reuse the fixed setup.

Repro: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t43 --seed=11 --scale=1.4 --resolution=1920x1080 --class=rogue`
(also `--seed=3` for Rest, and 1280x720 at 1.0 / 1.2 / 1.4). Look at FULL resolution: `04_combat_turn.png`, `06_boss_turn.png`,
`08_merchant.png`, `10_rest.png`.

Seen at scale 1.4 (1920x1080, UI stretches from 1280x720 logical):
1. **Merchant and Rest**: the right-hand Equipment panel runs past the right screen edge (title "Equipment" and the slot grid /
   Hide button are cut). The three-column layout (Shop/Crafting, Inventory, Equipment) is wider than the viewport.
2. **Battle**: the bottom-right chips (Turn / P Ready / S E2) are cut at the right edge, and in the boss fight the battle log box on the
   bottom-left clips its first characters ("en takes 29." instead of "Wren takes 29.").

Do:
- Find what forces the width (print `get_combined_minimum_size()` per column) and fix so every panel, button and chip lies fully inside the viewport at text
  scale 1.0 / 1.2 / 1.4 at 1280x720 logical: narrower columns, scrolling, smaller slot grid, wrapping chips. Keep keyboard
  focus, tooltips and existing behavior. Do not shrink the font below the UI-style minimum.
- Add a real-rect smoke test (same style as the T42 one) for Merchant, Rest and Battle at 1.4 with 5 party members: the global rect of every
  top-level panel, the Ready/Hide buttons, the status chips and the log lies inside the viewport. Do not weaken existing tests.
Verify: `bash tools/run_tests.sh` -> 0 failed (>= 452 passed); previews above, LOOK at the right edge of each image.
Report (<150 words). Do not commit or push.

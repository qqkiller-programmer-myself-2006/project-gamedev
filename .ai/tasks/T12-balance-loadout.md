# T12 — Balance: loadout mode wins 100%

Read `docs/balance.md`, `docs/adr/0012-*.md`, `docs/adr/0013-*.md`, `tools/simulate.gd`. Now that players pick a Class, Race and
Boons before the match (ADR-0013), `"$GODOT" --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2 --loadout`
wins **100%** in both modes (target 70–97%), while the default Classless path is 88% / 83%.

Tune **content numbers only** (`content/forest.json`: enemy stats per Layer, boss HP/ATK/phases, reward/EXP curve, Boon and
Race magnitudes, tree/Prestige bonuses, Class base stats) so that:
- loadout mode: 1 human and 2 humans both land in 80–92%;
- default mode stays within 70–97%;
- `--pace` modelled human pacing stays sane (see the existing regression test).
Explain each change in `docs/balance.md` (before/after table). Do not change game code except `tools/simulate.gd` if the bot
plays loadout mode unrealistically well (e.g. always picking the strongest Boons) — then make its picks varied and say so.

Files you may change: `content/forest.json`, `docs/balance.md`, `tools/simulate.gd`, tests that pin exact numbers you changed.
Verify: `bash scripts/run_tests.sh` → 0 failed (exact line); both simulate modes with the final numbers. ONE Godot process at a
time. Report in English: changes, test line, final win rates for both modes.

## Also: Story mode (from #58 QA)
`simulate.gd --story --seeds=40 --humans=1` wins 9/40 (23%), all defeats at the boss, and the story bot never visits Merchant or
Rest. First make `tests/support/match_bot.gd` in story mode play every character with the class AI presets (`src/match/ai/party_ai.gd`)
and choose sensible routes (like the normal bot), then tune so story mode also lands in 70–90%. Merge the latest integration branch
into this worktree first (`git merge claude/github-project-issue-learning-20567b`) — it now contains the Story room code.

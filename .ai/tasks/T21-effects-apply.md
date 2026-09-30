# T21 — Attribute / Boon / Race effects actually apply (#65)

Read `AGENTS.md` ("Where things live"), `gh issue view 65` (full acceptance list), `docs/review/2026-09-29-server-review.md`
findings S4, S5, S6, S7, S15, S19 (each has file:line, failure scenario and suggested fix — the paths there are pre-restructure:
`src/match/attributes.gd` is now `src/match/rules/attributes.gd`), `docs/adr/0012-*.md`, `docs/adr/0013-*.md`, `content/forest.json`.

Do every acceptance item of #65:
1. S4: Race/Chosen One/Elf bonuses are added to `attributes` BEFORE derived stats (max_hp/atk/def/mag/res/spd/crit) are computed.
2. S6: turn order uses `derived.initiative` (ties: spd, then stable order); keep enemies/party interleaving rules.
3. S7: a dodged hit applies no statuses.
4. S5: every Boon/passive listed in ADR-0013 and content is implemented, or hidden from the picker with a content flag and a
   one-line note in ADR-0013 (prefer implementing: Critical Healing, Will of Thiacdemo, Alert first-2-turns Block/Dodge +5%).
5. S15: loadout ids validated by exact key lookup (no dotted paths): `class: "swordsman.base"` -> `invalid_loadout`.
6. S19: Reset Skills on an empty tree -> `nothing_to_reset`, no Gems charged; add the player text to `src/client/ui/ui_text.gd`.
7. Tests for each item (`tests/match/`). Re-run balance: `"$GODOT" --headless --path . -s tools/dev/simulate.gd -- --seeds=100 --humans=1,2`
   plus `--loadout` and `--story --humans=1`; all must stay 70–92%; if not, tune content numbers only and record in
   `docs/design/balance.md` (UTF-8).

Files: `src/match/**`, `content/forest.json`, `docs/adr/0013-*.md`, `docs/design/balance.md`, `tests/**`, `src/client/ui/ui_text.gd`
(one new text only). Not other client files (another executor works there).
Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
(baseline 289). ONE Godot process at a time. Report in English: per item what changed, tests added, win rates, test line.

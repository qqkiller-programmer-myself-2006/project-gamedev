# T4 round 2 — make the suite green honestly

Continue on this branch (enemy Energy + personal Gold are committed as WIP). Same rules and file limits as
`.ai/tasks/T4-enemy-energy-gold-server.md`.

QA re-ran `bash scripts/run_tests.sh` and got **247 passed, 7 failed** (full log: `.ai/t4_failing_tests.log`).
Your previous report said "1 failed" — always paste the real final summary line from the runner.

Failing tests and what QA expects:

1. `test_guardian_boss.gd::test_defending_against_the_telegraphed_blow_halves_it` — expected damage events `[43, 21]`,
   got `[]`. **Likely a real regression**: turning the telegraphed blow into a `special` action stopped emitting the damage
   entries (or Guard/Defend no longer halves it). The boss's telegraphed blow must still deal damage, still be halved by
   Guard, and still emit the same damage events. Fix the code, not the test.
2. `test_energy.gd::test_enemies_have_no_energy` — the rule intentionally changed (ADR-0012 §3). Replace it with a test
   that asserts the new rule (enemies start at 0 and gain +1 per own turn), keeping the name meaningful.
3. `test_merchant_rest_treasure.gd` — four tests (`buying_spends_shared_gold...`, `invalid_and_sold_out...`,
   `single_player_moves_on_without_buying`, `gold_won_in_combat_buys_items`) assume shared gold. Update them to the
   personal-gold rules (buyer pays from own gold; reward split) while keeping what each test protects
   (sold-out/invalid rejection, moving on without buying, combat gold is spendable).
4. `test_full_runs.gd::test_player_dropping_mid_match_still_finishes` — do not weaken this test. Make the game handle it:
   a dropped player's character is controlled by AI, so at the next Merchant/Rest its gold must go to the remaining
   humans (ADR-0012 §4) — check that this path works for a slot that *became* AI mid-match. If `tests/support/match_bot.gd`
   needs to learn `transfer_gold` / `transfer_item` to play like a sensible human, teach it. Re-check balance afterwards.
5. Wolf "Rend" costs 1 Energy and wolves gain +1 per turn, so a wolf uses Rend every turn after its first — that makes the
   special its normal attack. Raise costs so specials fire roughly every 2–3 turns (e.g. Rend 2), and keep win rates in range.

Verify: `bash scripts/run_tests.sh` → **0 failed** (paste the exact summary line); `simulate.gd --seeds=100 --humans=1,2`
within 70–97% (paste numbers). Delete `.ai/t4_failing_tests.log` when done.
Report in English: each item 1–5 and what you changed; exact test summary line; win rates.

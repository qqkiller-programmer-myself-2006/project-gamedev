# T5 round 2 — finish the loadout/meta server work (ADR-0013)

Continue on this branch; same spec and file limits as `.ai/tasks/T5-loadout-server.md` (read it again, all of it).
Round 1 (committed as WIP) added the ProfileStore seam (memory/file/D1), the five room commands, loadout snapshots and
loadout application at match start. It stopped early. Still missing — do all of it:

1. **Gems**: award at Match end (ADR-0013 §5: +10 per Layer passed, +50 boss win, +5 per Story Clue) and from Class
   Encounter wins when the character already has a Class; include gems earned per player in the end-of-match summary; persist
   through the store (async, never blocking the Match).
2. **Tests** (none were added yet): `tests/match/test_loadout.gd`, `tests/match/test_meta_progression.gd`,
   `tests/core/test_profile_store.gd` covering every item in the original spec's verify section, including Classless when no
   loadout, AI class fill from `party.ai_class_order`, Enervation only with the Boon (update `tests/match/test_rogue.gd` so its
   Enervation tests equip the Boon), and `D1ProfileStore` request building with an injected fake HTTP sender (no network).
   Make sure the test runner discovers `tests/core/` (check `tests/run_tests.gd`).
3. **simulate.gd**: add `--loadout` mode where bots pick class/race/boons; report win rates for default and loadout modes.
4. **CONTEXT.md** per ADR-0013 Consequences, and the status line of ADR-0010 (Enervation now a Boon).
5. Run the **full** suite: `bash scripts/run_tests.sh` → 0 failed. Paste the exact final summary line (QA re-runs it).

Report in English: files changed, the exact test summary line, win rates (both modes), anything not done.

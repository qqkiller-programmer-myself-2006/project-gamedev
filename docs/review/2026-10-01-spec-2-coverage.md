# Spec #2 coverage audit — 2026-10-01

Main at e5a866a + this branch. Full suite: **447 passed, 0 failed**. Every behavior in the "Testing Decisions" section of #2 is covered through the Match interface (seed + ManualClock), plus real-transport tests.

| #2 requirement | Evidence (tests) |
| --- | --- |
| Full path, Single-player and Duo, many seeds | `tests/regression/test_full_runs.gd` (single/duo finish, idle humans never stall, drop mid-match still finishes) |
| Party = 5, AI fills empty slots (1–5 humans) | `tests/match/test_rooms.gd` (five slots, duo = 2 humans + 3 AI, always five Classless) |
| Room code format / join errors | `test_rooms.gd` (6 chars, no confusable chars, case-insensitive, wrong/full/in-progress/closed) |
| Path Voting rules | `tests/match/test_journey_voting.gd` (one vote each, AI no vote, majority, seeded tie, immediate resolve, deadline, no votes → random) |
| Action window 15 s → auto Defend | `tests/match/test_combat.gd` (clock-driven) |
| Server authority (bad commands rejected, no state change) | `tests/match/test_match_interface.gd`, `test_merchant_rest_treasure.gd`, `tests/net/test_transport.gd` |
| Classless cannot Skill; Class Encounter opens all 4 Classes | `test_class_encounter.gd`, `test_archer_mage.gd`, `test_guardian.gd`, `test_assassin.gd` |
| AI presets by Class | `test_ai_replacement.gd`, `test_guardian.gd`, `test_archer_mage.gd` |
| Disconnect → AI keeps state, no stall | `test_ai_replacement.gd` (hand-over intact, own window, vote, duo finishes, room closes) |
| Merchant / Reward | `test_merchant_rest_treasure.gd` (buy, Gold short rejected, combat Gold buys items) |
| Always completable (Class Encounter early, Merchant before Boss) | `test_journey_voting.gd`, `test_class_encounter.gd`, `test_full_runs.gd` (every seed) |
| Guardian Boss phases, Victory/Defeat, new match | `tests/match/test_guardian_boss.gd`, `test_full_runs.gd` |
| Cross-platform smoke through real transport | `tests/net/test_smoke_server_process.gd` + CI job "Export PC, browser and server builds + cross-platform smoke test" (Chromium) |
| Determinism / single RNG source | `tests/shared/test_game_rng.gd`, `test_no_engine_randomness.gd` |

## Not verifiable without a person or infrastructure (kept open in #19 / #54)

- Story 76: dedicated staging server (needs VPS/domain; steps in `docs/guides/staging.md`).
- Story 81: manual PC + browser + mixed checklist (table in `docs/guides/staging.md`).
- Story 82: a real 20–30 min human playthrough (simulation with human pacing is in range, but not a human measurement).
- Browsers other than Chromium; subjective UI/UX polish.

## Verdict

All automatable acceptance of #2 is met. #2 should close only after #19 records the staging run.

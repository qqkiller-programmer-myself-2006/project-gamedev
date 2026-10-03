# T4S-04 — `choose_route` + final encounter by route

- **Task ID:** T4S-04
- **Owner:** Claude 2 (`ai/3d-claude2`, worktree `Project-GameDev-Agents/Claude2`)
- **Dependencies:** T4S-01a merged into `claude/game-project-lead-9a9ecc` (classes `support`/`healer` exist). Start by fast-forwarding from the lead branch.
- **Read first:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0014-*.md` (Story mode, local MatchServer, Story save validation), `docs/adr/0016-story-reboot-new-classes-auto-battle.md` (Route + route-2 encounter rules), `docs/design/story-script-routes.md`, `src/client/story/story_director.gd`, `src/client/story/story_save.gd`, `src/client/story/story_launcher.gd`, `src/net/local_connection.gd`, MatchServer command handling and journey/boss code in `src/match/**`

## Goal
The player picks a route at the decision scene in Layer 5 (before the Guardian Boss). The server stores it and uses it to choose the final encounter.

| Route | Meaning | Final encounter |
| --- | --- | --- |
| 1 | stay with friends | Guardian Boss (Selen) — existing boss flow |
| 2 | go with Nanny | **friends fight**: 4 enemies built from the other 4 party members, IQ cannot die |
| 3 | follow the mission | Guardian Boss (Selen) — existing boss flow |

## Scope
1. **Command `choose_route`** `{route: 1|2|3}` handled by MatchServer, only valid in Story mode, only once, only at the decision point (when the boss is next / `boss_reached` before the boss combat starts — pick the cleanest existing hook and document it). Invalid calls are rejected with the existing error path. Route stored in match state and exposed in the snapshot the client already reads.
2. **Story save:** route is saved and restored. Keep `StorySave.VERSION` rules: bump the version if the shape changes and reject old saves through the existing restore rejection path (ADR-0014, ADR-0016 consequence).
3. **Route-2 encounter:**
   - Enemies are generated at encounter start from the 4 non-IQ party members: same Class and level the player gave them, stats from the normal enemy/party scaling (pick and document the rule), names = the friends' names.
   - IQ has a "cannot die" rule for this encounter only: damage reduces HP but never below 1. Implement as a status/flag on the unit, not a special case scattered through damage code.
   - Win when all 4 enemies are down; the result event lets the client continue to the route-2 cutscene. Since IQ cannot die, this encounter has no loss condition: it only ends in victory. Document this.
   - Party members other than IQ: the route-2 story has IQ fight alone. Implement as IQ-only player side for this encounter.
4. **Client hook (minimal):** in `src/client/story/**`, when the story reaches the route decision, show a 3-option choice (reuse `DialoguePanel` if it supports choices, otherwise a minimal choice list in the same style) and send `choose_route`. Labels via `Tr.t` with Thai translations. Do not write story dialogue — Claude 1 (T4S-02) owns `content/story_mode.json` and story text; use a placeholder trigger name `route_decision`.
5. **Content:** the route-2 encounter definition may be added as a **new top-level key** in `content/forest.json` (do not edit other keys; Agy 1 owns the rest of that file until T4S-01c). Prefer generating it in code from party data if that needs no content.
6. **Tests** (`tests/match/`, `tests/client/story/` if needed): command validation (wrong mode, twice, wrong time, bad value), route stored + in snapshot, routes 1/3 reach Selen, route 2 builds 4 enemies matching chosen Classes/levels, IQ HP never below 1 across many hits including DoT, victory ends encounter, Story save round-trip with route, old-version save rejected.

## Allowed paths
`src/match/**`, `src/client/story/**` (choice hook only), `src/net/local_connection.gd` (only if the command path needs it), `content/forest.json` (one new top-level key only), `tests/**` (new files; existing tests only where the save version changes), `i18n/**`, `CONTEXT.md` (add terms Route, Route decision)

## Forbidden paths
`content/story_mode.json`, `src/client/match/**`, `src/client/home3d/**`, `src/client/cutscene/**`, `src/server/**`, `assets/**`

## Acceptance criteria
1. All tests in scope 6 exist and pass.
2. `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` green, test count not reduced.
3. Multiplayer unaffected: `choose_route` rejected outside Story mode; existing multiplayer tests unchanged and passing.
4. test_thai_catalog passes.

## Handoff
`.ai/handoff/T4S-04.md`: branch + sha, files changed, test result, decisions taken (hook point, enemy scaling rule, loss condition), open questions. Commit on `ai/3d-claude2`, never push.

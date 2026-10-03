# Story slice — task ownership (2026-10-03)

Follows `docs/plans/2026-10-02-3d-vertical-slice.md`, ADR-0015, ADR-0016 and `docs/art/3d-pipeline.md`.
**Claude 1 is the lead** (owner's decision): it writes specs, reviews, runs tests and merges into `claude/game-project-lead-9a9ecc`, and also implements its own tasks (T4S-02, T4S-03) in the `Claude1` worktree. Lead duties come first; its own tasks pause while a review or merge is waiting. Other workers commit on their own branch only, never push.

## Workers

| Worker | Engine | Worktree / branch | Strength used for |
| --- | --- | --- | --- |
| Claude 1 (lead) | Claude Code | lead branch `claude/game-project-lead-9a9ecc`; own tasks in `Project-GameDev-Agents/Claude1` / `ai/story-claude1` | Lead: specs, review, merge. Own tasks: Thai story writing, story content data |
| Claude 2 | Claude Code | `Project-GameDev-Agents/Claude2` / `ai/story-claude2` | MatchServer rules (route system) |
| Agy 1 | agy | `Project-GameDev-Agents/Agy1` / `ai/3d-agy1` | Classes, content, balance |
| Agy 2 | agy | `Project-GameDev-Agents/Agy2` / `ai/3d-agy2` | Client presentation (cutscene, 3D import) |
| Codex | codex | `Project-GameDev-Agents/Codex1` / `ai/3d-codex1` | Battle HUD + Auto, character images |

## Tasks

| ID | Task | Owner | Depends on | Main paths |
| --- | --- | --- | --- | --- |
| T3D-07 | Battle HUD (slanted black/red/white) | Codex | — (running) | `src/client/match/battle/hud/**` |
| T4S-01a | Support/Healer effects + classes + skills | Agy 1 | — (running) | `content/forest.json`, `src/match/**` |
| T4S-01b | Support/Healer AI + Class Encounter + skill tree | Agy 1 | 01a | same |
| T4S-01c | Support/Healer balance | Agy 1 | 01b | `forest.json` numbers, `balance.md` |
| T4S-02 | Thai story content: all chapters + 3 routes, class-aware lines, new triggers (`layer_N_enter`, `route_decision`, `route_N_intro`, `defeat_layer_N`) | Claude 1 | — | `content/story_mode.json`, `src/client/story/**` |
| T4S-03 | Party rename IQ/Fifa/Tata/Cake/May + Story class pools by gender | Claude 1 | T4S-01c, T4S-02 | `content/forest.json` (party), story class pools |
| T4S-04 | `choose_route` command + state + Story save; final encounter by route (1/3 Guardian Selen, 2 friends fight with IQ HP floor 1) | Claude 2 | T4S-01a merged | `src/match/**`, `src/profile/**` (Story save), tests |
| T4S-05 | Auto command (player party driven by `PartyAi`) + wire HUD Auto button | Codex | T3D-07, T4S-01b | `src/match/**` (command), `src/client/match/battle/hud/**` |
| T3D-08 | Cutscene router + `.ogv` player (graph per ADR-0015, skip, Thai subtitles) | Agy 2 | — | `src/client/cutscene/**` |
| T3D-09 | VRM pipeline: godot-vrm addon, one sample model + Mixamo idle/strike/hurt/die in `Battle3DStage` | Agy 2 | T3D-08, owner's first `.vrm` | `addons/**`, `src/client/match/battle3d/**` |
| TART-01 | Character sheets (6 main + 4 side) from `prompt-pack.md` | Codex (image) | T3D-07 | `assets/art/sheets/**`, `MANIFEST.3d.json` |

## Waves (max 2 Godot test runs at once — 15.7 GB RAM)

1. **Now:** Codex T3D-07, Agy 1 T4S-01a (both running). Claude 1 T4S-02 can start (mostly writing; runs tests only at the end).
2. **Next:** Agy 2 T3D-08; Claude 2 T4S-04 after 01a merge; Agy 1 01b.
3. **Then:** Codex T4S-05 + TART-01; Agy 1 01c; Claude 1 T4S-03.
4. **Last:** Agy 2 T3D-09 once the owner has the first VRoid model.

## Conflict rules
- `content/forest.json`: Agy 1 owns it until T4S-01c merges; then Claude 1 (T4S-03). Nobody else edits it.
- `src/match/**`: Agy 1 (classes/effects), Claude 2 (route, new files where possible), Codex (Auto command, new files where possible). Lead merges in order 01a → T4S-04 → 01b → T4S-05.
- `i18n/th.po` and `messages.pot`: everyone may add entries; lead resolves merge conflicts.

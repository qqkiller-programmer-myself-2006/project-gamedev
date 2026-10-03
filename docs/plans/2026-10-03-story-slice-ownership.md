# Story slice — task ownership (2026-10-03)

Follows `docs/plans/2026-10-02-3d-vertical-slice.md`, ADR-0015, ADR-0016 and `docs/art/3d-pipeline.md`.
**Claude 1 is the lead** (owner's decision): it writes specs, reviews, runs tests and merges into `claude/game-project-lead-9a9ecc`, and also implements its own tasks (T4S-02, T4S-03) in the `Claude1` worktree. Lead duties come first; its own tasks pause while a review or merge is waiting. Other workers commit on their own branch only, never push.

## Workers

| Worker | Engine | Worktree / branch | Strength used for |
| --- | --- | --- | --- |
| Claude 1 (lead) | Claude Code | lead branch `claude/game-project-lead-9a9ecc`; own tasks in `Project-GameDev-Agents/Claude1` / `ai/3d-claude1` | Lead: specs, review, merge. Own tasks: Thai story writing, story content data |
| Claude 2 | Claude Code | `Project-GameDev-Agents/Claude2` / `ai/3d-claude2` | MatchServer rules (route system) |
| Codex | codex via `.ai/run-agent.ps1` | `Codex1` / `ai/3d-codex1` for HUD/Auto/images; `Agy1` / `ai/3d-agy1` for the T4S-01 chain | Classes/balance, Battle HUD + Auto, character images |

## Tasks

| ID | Task | Owner | Depends on | Main paths |
| --- | --- | --- | --- | --- |
| T3D-07 | Battle HUD (slanted black/red/white) | Codex | — (running) | `src/client/match/battle/hud/**` |
| T4S-01a | Support/Healer effects + classes + skills | Codex (done by fallback, in Agy1) | — (awaiting review) | `content/forest.json`, `src/match/**` |
| T4S-01b | Support/Healer AI + Class Encounter + skill tree | Codex (in Agy1) | 01a | same |
| T4S-01c | Support/Healer balance | Codex (in Agy1) | 01b | `forest.json` numbers, `balance.md` |
| T4S-02 | Thai story content: all chapters + 3 routes, class-aware lines, new triggers (`layer_N_enter`, `route_decision`, `route_N_intro`, `defeat_layer_N`) | Claude 1 | — | `content/story_mode.json`, `src/client/story/**` |
| T4S-03 | Party rename IQ/Fifa/Tata/Cake/May + Story class pools by gender | Claude 1 | T4S-01c, T4S-02 | `content/forest.json` (party), story class pools |
| T4S-04 | `choose_route` command + state + Story save; final encounter by route (1/3 Guardian Selen, 2 friends fight with IQ HP floor 1) | Claude 2 | T4S-01a merged | `src/match/**`, `src/profile/**` (Story save), tests |
| T4S-05 | Auto command (player party driven by `PartyAi`) + wire HUD Auto button | Codex | T3D-07, T4S-01b | `src/match/**` (command), `src/client/match/battle/hud/**` |
| T3D-08 | Cutscene router + `.ogv` player (graph per ADR-0015, skip, Thai subtitles) | Claude 2 (in Claude2) | — | `src/client/cutscene/**` |
| T3D-09 | **On hold** — full-3D VRM experiment, replaced by 2.5D (owner decision 2026-10-03, `docs/art/2-5d-pipeline.md`) | — | owner go-ahead | — |
| T25D-01 | 2.5D sprite units in `Battle3DStage` (placeholder art first) | Claude 2 (in Claude2) | T4S-04 | `src/client/match/battle3d/**` |
| TART-02 | Battle sprites (idle per class, hurt, down) + portraits, chroma key, manifest | Codex + Claude 1 | TART-01, owner locks sheets | `assets/art/**`, `tools/art/chroma_key.py` |
| TART-01 | Character sheets, 6 main x 3 candidates, owner picks and locks | Codex (image) | — (approved to dispatch) | `art_source/**` |

## Waves (max 2 Godot test suites at once — enforced by `tools/run_tests.sh`)

**2026-10-03 update: agy dropped.** A second agy account cannot be separated on one Windows user (login lives in Windows Credential Manager), so the team is Claude 1 (lead), Claude 2 and Codex. Agy tasks moved: T4S-01b/01c to Codex (still in the `Agy1` worktree, where 01a lives), T3D-08/T3D-09 to Claude 2. If Codex is backlogged or rate-limited, Claude 1 implements the next Codex task itself.

1. **Now:** lead reviews/merges T4S-01a and T3D-07. Claude 1 T4S-02 in between.
2. **Next:** Codex T4S-01b; Claude 2 T4S-04 (after 01a merge).
3. **Then:** Codex 01c → TART-01 (can run in parallel with 01c: no Godot) → T4S-05 → TART-02 after the owner locks sheets; Claude 2 T3D-08; Claude 1 T4S-03 (after 01c).
4. **Last:** Claude 2 T25D-01 after T4S-04 (real sprites drop in when TART-02 lands). T3D-09 (full 3D) is on hold.
## Conflict rules
- `content/forest.json`: Codex (T4S-01 chain) owns it until T4S-01c merges; then Claude 1 (T4S-03). Nobody else edits it.
- `src/match/**`: Codex (classes/effects, T4S-01 chain), Claude 2 (route, new files where possible), Codex (Auto command, new files where possible). Lead merges in order 01a → T4S-04 → 01b → T4S-05.
- `i18n/th.po` and `messages.pot`: everyone may add entries; lead resolves merge conflicts.

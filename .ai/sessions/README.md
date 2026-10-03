# Worker session briefs (one laptop, separate sessions)

Each worker runs as its own session in its own worktree under
`D:\UserData\Documents\LRU\Game Dev\Project-GameDev-Agents\`. Ownership and order: `docs/plans/2026-10-03-story-slice-ownership.md`.

Shared rules for every session:
- Work only in your own worktree and branch. Never push. Never edit another worker's paths.
- Before starting: `git merge --ff-only claude/game-project-lead-9a9ecc` (or ask the lead if it is not a fast-forward).
- Read `AGENTS.md`, `CONTEXT.md`, the task file, and the ADRs it lists.
- Tests: `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`. Run `--headless --path . --import` after adding a `class_name`. At most 2 Godot test suites run at the same time on this laptop; `tools/run_tests.sh` enforces this with slots next to the Godot binary and waits automatically (prints "Waiting for a free Godot test slot").
- Respond to the owner in Thai. Code, commits and docs in English unless the file is already Thai.
- When done: commit on your branch, then write the handoff (branch + sha, files, test result, open questions) to `.ai/handoff/<task-id>.md` in your worktree and tell the owner. The lead reviews and merges.

---

## Claude 1 — lead (Claude Code)
- Worktree: `Project-GameDev-Agents/Claude1`. Since the 2026-10-03 handoff the **lead branch `claude/game-project-lead-9a9ecc` is checked out here** (the old lead worktree was detached). Do own tasks on short branches off it (e.g. `ai/3d-claude1`) or directly on it, then merge.
- Claude 1 runs on its own: writes specs, dispatches executors, reviews, tests, merges, and pushes the lead branch to `origin` after each verified merge (owner approved pushing this branch; never push `main`, never open/merge PRs without asking).

### Lead operating rules (carried over from the previous lead session's memory — this worktree has a different memory folder)
- **Dispatch:** `powershell -File .ai/run-agent.ps1 -Agent codex|agy -Worktree <abs path> -TaskFile .ai/tasks/<file>.md -TimeoutMin N [-FallbackAgent codex|agy] [-Images <path>]`. Run it in the background with a long timeout (the Bash/PowerShell background limit is 30 min by default — pass the max). Status in `.ai/logs/*.status.json` (`state`, `last_activity`).
- Before dispatching to Codex/agy/another Claude, the account must be logged in and the owner must have agreed to that run. Planning/spec/doc work never needs approval.
- If Codex and agy are both rate-limited or failing, Claude 1 implements the task itself instead of waiting.
- After merging UI work, launch the real game window for the owner (`D:/dev-tools/godot/Godot_v4.7.2-stable_win64.exe --path .`, add `-- --3d` for 3D).
- Review like a code reviewer: read the diff, check allowed/forbidden paths in the task file, run the full suite yourself (do not trust the executor's numbers), check i18n (`test_thai_catalog`), then merge with `--no-ff` and log one line in `.ai/checkpoint.md`.
- Executors often skip i18n or screenshots: send a short `-retry.md` task rather than fixing by hand, unless it is a one-line fix.
- Owner writes in Thai; answer in Thai, terse.

### State at handoff (2026-10-03 ~12:50)
- Lead branch tip pushed to `origin/claude/game-project-lead-9a9ecc`; suite last verified at 519 passed (after T3D-01..06).
- **Running (started by the previous lead session; logs in `D:\UserData\Documents\LRU\Game Dev\Project-GameDev\.claude\worktrees\close-claude-codex-issues-d72ea7\.ai\logs\`):**
  - T3D-07 battle HUD — Codex in `Codex1` (uncommitted changes there: `src/client/match/battle/hud/`, `battle_view.gd`, `ui_kit.gd`, `ui_preview.gd`, i18n, `tests/client/match/battle/`). When it ends: review against `.ai/tasks/T3D-07-battle-hud.md`, run suite, take the required screenshots in a real window if Codex could not, commit on `ai/3d-codex1`, merge.
  - T4S-01a Support/Healer — agy stalled, Codex finished it (fallback) in `Agy1`; uncommitted there. Same review flow, commit on `ai/3d-agy1`, merge; then dispatch T4S-01b to **Codex in `Agy1`**.
- **Ready specs:** T4S-04 (Claude 2, after 01a merge), T3D-08 (Claude 2, after T4S-04). Not yet written: T4S-02/T4S-03 (own tasks), T4S-05 (Auto), TART-01 (character sheets), T3D-09 (VRM).
- **agy dropped (2026-10-03):** a second agy account cannot be separated on one Windows user (login is in Windows Credential Manager). Do not dispatch `-Agent agy` and do not use `-FallbackAgent agy`. Pending owner decision: first VRoid model for T3D-09.
- Lead duties first: write task specs in `.ai/tasks/`, review worker handoffs, run the full test suite after each merge, keep `.ai/checkpoint.md` and the ownership plan current.
- Own tasks: T4S-02 (Thai story content into `content/story_mode.json`, from `docs/design/story-script-draft.md` and `story-script-routes.md`), then T4S-03 (party rename + Story class pools, after T4S-01c merges).
- Start prompt: "You are Claude 1, lead of BEYOND THE WORLD'S END. Read `.ai/sessions/README.md`, `docs/plans/2026-10-03-story-slice-ownership.md` and `.ai/checkpoint.md`, then report current task status in Thai."

## Claude 2 (Claude Code)
- Worktree: `Project-GameDev-Agents/Claude2`, branch `ai/3d-claude2`.
- Tasks: T4S-04 (`choose_route`, route state + Story save, final encounter by route; starts after T4S-01a is merged), then T3D-08 (cutscene router + `.ogv` player; the spec says Agy 2 — Claude 2 owns it now, work in `Claude2`/`ai/3d-claude2`), then T25D-01 (2.5D sprite units in `Battle3DStage`, `.ai/tasks/T25D-01-sprite-units.md`; after T4S-04). T3D-09 (full 3D VRM) is on hold — owner chose 2.5D (`docs/art/2-5d-pipeline.md`).
- Start prompt: "You are Claude 2. Read `.ai/sessions/README.md` and do the next Claude 2 task that has no handoff yet."

## Codex (executor, dispatched by Claude 1 through `.ai/run-agent.ps1`)
- T4S-01 chain in `Project-GameDev-Agents/Agy1` / `ai/3d-agy1` (01a done, then 01b, 01c — the task files say Agy 1; Codex owns them now).
- Then in `Project-GameDev-Agents/Codex1` / `ai/3d-codex1`: TART-01 (character sheets, dispatched 2026-10-03, runs in parallel with 01c — no Godot), T4S-05 (Auto command), TART-02 (battle sprites, after the owner locks sheets).
- Codex can also be opened interactively by the owner; start prompt: "Read `.ai/sessions/README.md` and do the next Codex task that has no handoff yet." Never run it in a worktree where a runner is active.


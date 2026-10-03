# Worker session briefs (one laptop, separate sessions)

Each worker runs as its own session in its own worktree under
`D:\UserData\Documents\LRU\Game Dev\Project-GameDev-Agents\`. Ownership and order: `docs/plans/2026-10-03-story-slice-ownership.md`.

Shared rules for every session:
- Work only in your own worktree and branch. Never push. Never edit another worker's paths.
- Before starting: `git merge --ff-only claude/game-project-lead-9a9ecc` (or ask the lead if it is not a fast-forward).
- Read `AGENTS.md`, `CONTEXT.md`, the task file, and the ADRs it lists.
- Tests: `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`. Run `--headless --path . --import` after adding a `class_name`. At most 2 Godot test runs at the same time on this laptop — if another worker is testing, wait.
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
  - T4S-01a Support/Healer — agy in `Agy1` (fallback codex). Same review flow; then dispatch T4S-01b to Agy 1.
- **Ready specs:** T4S-04 (Claude 2, after 01a merge), T3D-08 (Agy 2, can start now). Not yet written: T4S-02/T4S-03 (own tasks), T4S-05 (Auto), TART-01 (character sheets), T3D-09 (VRM).
- Owner decisions pending: whether the agy2 second-account trick (separate `USERPROFILE`) works; first VRoid model for T3D-09.
- Lead duties first: write task specs in `.ai/tasks/`, review worker handoffs, run the full test suite after each merge, keep `.ai/checkpoint.md` and the ownership plan current.
- Own tasks: T4S-02 (Thai story content into `content/story_mode.json`, from `docs/design/story-script-draft.md` and `story-script-routes.md`), then T4S-03 (party rename + Story class pools, after T4S-01c merges).
- Start prompt: "You are Claude 1, lead of BEYOND THE WORLD'S END. Read `.ai/sessions/README.md`, `docs/plans/2026-10-03-story-slice-ownership.md` and `.ai/checkpoint.md`, then report current task status in Thai."

## Claude 2 (Claude Code)
- Worktree: `Project-GameDev-Agents/Claude2`, branch `ai/3d-claude2`.
- Task: T4S-04 (`choose_route`, route state + Story save, final encounter by route). Starts after T4S-01a is merged into the lead branch. Spec will be at `.ai/tasks/T4S-04-*.md`.
- Start prompt: "You are Claude 2. Read `.ai/sessions/README.md` and do the task assigned to Claude 2."

## Agy 1 (agy)
- Worktree: `Project-GameDev-Agents/Agy1`, branch `ai/3d-agy1`.
- Tasks: T4S-01a, then 01b, then 01c (`.ai/tasks/T4S-01*.md`). Owns `content/forest.json` until 01c merges.
- Start prompt: "You are Agy 1. Read `.ai/sessions/README.md` and do the next Agy 1 task that has no handoff yet."

## Agy 2 (agy)
- Worktree: `Project-GameDev-Agents/Agy2`, branch `ai/3d-agy2`.
- Tasks: T3D-08 (cutscene router + `.ogv` player), then T3D-09 (VRM pipeline, after the owner's first VRoid model).
- Start prompt: "You are Agy 2. Read `.ai/sessions/README.md` and do the next Agy 2 task that has no handoff yet."

## Codex
- Worktree: `Project-GameDev-Agents/Codex1`, branch `ai/3d-codex1`.
- Tasks: T3D-07 (battle HUD), then T4S-05 (Auto command), then TART-01 (character sheets).
- Start prompt: "You are Codex. Read `.ai/sessions/README.md` and do the next Codex task that has no handoff yet."

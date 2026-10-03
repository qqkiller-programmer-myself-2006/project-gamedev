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
- Worktree: `Project-GameDev-Agents/Claude1`, branch `ai/3d-claude1` for own tasks; merges into `claude/game-project-lead-9a9ecc`.
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

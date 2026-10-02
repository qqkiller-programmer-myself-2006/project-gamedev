# T3D-06-retry — finish i18n + commit

- **Task ID:** T3D-06-retry
- **Owner:** Codex1 (`ai/3d-codex1`, worktree `Project-GameDev-Agents/Codex1`)
- **Dependencies:** T3D-06 uncommitted changes already in the worktree (hooks + tests). Do NOT redo them.
- **Read first:** `.ai/tasks/T3D-06-entry-hooks.md` (Part C), `tools/i18n/` usage, `AGENTS.md`

## Goal
Part C of T3D-06 is missing: every new `Tr.t("...")` literal needs a Thai msgid in `i18n/messages.pot` and `i18n/th.po`. Known missing: "Back to Menu [Esc]", "Story", "Battle", "Party", "WASD / Arrows  Move   E / Enter  Interact", "Coming soon", "Unavailable" (and any other literal the failing test lists; Home3D calls Tr.t through variables, so add its station labels explicitly).

## Allowed paths
`i18n/**`, and only if needed to make the i18n test pass: the files already modified by T3D-06. Remove the stray `assets/video/*.ogv.uid` files from the commit (leave them untracked/ignored; do not add them).

## Forbidden paths
Same as T3D-06 (`src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `home3d/`, `battle3d/`).

## Acceptance criteria
1. `bash tools/run_tests.sh` -> 0 failed (previous: `516 passed, 1 failed`, failing `tests/i18n/test_thai_catalog.gd::test_every_client_tr_literal_is_translated`).
2. `tools/i18n` extract/check clean (per its README).
3. Commit on `ai/3d-codex1` with explicit `git add <files>` (no -A): all T3D-06 files + i18n. No push.
4. Write a short report to stdout: files changed, exact test summary line, and a screenshot of Home3D and Battle3D under `--3d` if tools/dev/ui_preview.gd supports it (otherwise say so).

## Test commands / Handoff
As in `docs/plans/2026-10-02-3d-vertical-slice.md`.

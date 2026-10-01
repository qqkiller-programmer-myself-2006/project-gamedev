# Task: restore the UI polish items U22 U24 U26 U27 U32 U33 U34 (+U31 partial) that never reached main

Commit `f4b20cd` on the old branch `origin/claude/remote-control-dc3630` ("fix(ui): polish U22 U24 U26 U27 U32 U33 U34,
partial U31 (#87)") was never merged. `main` has since received other polish work for the same issue #87 (PRs from branches
`ai/t30-ui-polish` = "QA polish U14-U34", `ai/t87-polish` = "QA polish leftovers U18/U19/U22/U23/U26", plus responsive,
title-menu and path-vote work). So SOME items may already be done on main in a different form. Do an audit first, then port
only what is genuinely missing.

## Read first
`AGENTS.md`, `CONTEXT.md`, `docs/guides/testing.md`; the original: `git show f4b20cd` (message + diff, 12 files);
issue text: `gh issue view 87`; QA report: `git show origin/claude/qa-full-review:docs/review/2026-09-30-full-qa-report.md`
(items U14-U34 with file:line); original test: `git show f4b20cd:tests/client/test_t42_ui_polish.gd`.

## Items in the original commit (from its message)
- U22 personal Gold wording ("Your Gold", own share, not "The Party")
- U24 DoT tip must not mention a turns counter that is not shown
- U26 one Victory title on Summary; the banner must not block Esc/F2
- U27 consistent Esc (list screens get the menu)
- U32 text size / reduced motion changes apply mid-match
- U33 dialogue box sizes to its content, portrait keeps aspect, narrator style
- U34 real pager dots
- U31 partial: title fits at x1.4 (vote status/timer below the fold was NOT fixed; try to fix it only if cheap)
- U25 (toast covers lobby Copy code) was NOT fixed in the original; fix only if trivial, otherwise list it.

## Steps
1. **Audit** each item against current `main` in the code and (where cheap) with a preview/screenshot. Write a table into
   `docs/plans/2026-10-02-ui-polish-audit.md`: item | done on main? (yes/partial/no) | evidence (file:line or test) | action.
2. **Port** only items marked partial/no. Re-implement on current code (files have moved/changed: e.g. `src/client/client_app.gd`,
   `src/client/match/*`, `src/client/story/*`, `src/client/ui/ui_text.gd`); do NOT cherry-pick blindly or overwrite newer work.
3. **Tests:** port the cases of `test_t42_ui_polish.gd` that still apply, adapt to current APIs, drop cases for items already done
   on main only if an equivalent test already exists (say which). Place under the current `tests/client/` layout, keep `.uid` with
   the script, register as the runner requires. Name it `tests/client/test_ui_polish_restore.gd`.
4. i18n: if you add/change strings run the i18n extract/check tools in `tools/i18n/` (see how T38 did it: `i18n/messages.pot`, `th.po`).
5. If there are screenshot previews that show a change, save them under `docs/screenshots/` and list paths.

## Constraints
- No behaviour change beyond these items. Do not touch assets, `.claude/agents`, `.ai/checkpoint.md`, CI. Do not commit or push.
- One Godot process at a time. `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`.
- Do not use `git show ref:path` in this shell (path mangling); use `git cat-file -p <blob>` or `git show <commit>` with `-- path`.

## Verify (paste exact lines)
- Baseline full suite BEFORE changes, then after: `bash tools/run_tests.sh` → baseline + new, 0 failed.
- `"$GODOT" --headless --path . --import` exits 0, no new script errors.
- `git status --short`.

## Report (under 250 words)
The audit table (short), what you ported, what you skipped as already done, what you could not do, test counts before/after.


Note: `origin/claude/qa-full-review` does not exist on the remote; use the local branch `claude/qa-full-review` instead (e.g. `git show claude/qa-full-review:docs/review/2026-09-30-full-qa-report.md`).

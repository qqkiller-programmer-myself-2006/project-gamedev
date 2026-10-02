# Task: bring PR #117 (Thai localisation + UI polish) up to date with main so it can merge

PR #117 = branch `claude/close-claude-codex-issues-d72ea7` ("Thai localisation + UI polish/perf + QA evidence (#44 #45 #83 #87 #88)").
It is 26 commits ahead and 16 behind `origin/main`, state CONFLICTING, and its CI test job fails. Its value: Thai is the default
locale (`--lang=en` / `?lang=en` for English), Noto Sans Thai fallback, `th.po` with 793 msgids, Thai translation of docs, damage queue,
responsive/a11y evidence. Main has since gained (all merged, do NOT lose any of it): T38 Story Party class picker, UI polish
U22–U34 (Esc list menu, dialogue sizing, pager dots, personal-Gold wording), U27 menu positioning, U33 dialogue-above-log,
repo-tidy docs (README tree, folder READMEs, CONTRIBUTING, docs index), LICENSE, layout smoke scripts auto-run by `tools/run_tests.sh`.

## Do (in the worktree you are given, which is checked out on the PR branch)
1. `git fetch origin`, then **merge** `origin/main` into the branch (a merge, not a rebase: the branch already contains merge commits and the PR is open).
   Expected conflicts (from `git merge-tree`): `README.md`, `docs/README.md`, `i18n/messages.pot`, `i18n/th.po`,
   `src/client/match/match_screen.gd`, `src/client/story/chapter_card.gd`, `src/client/story/dialogue_panel.gd`,
   `src/client/title/title_screen.gd`, `tools/dev/ui_preview.gd`. Resolve each by keeping BOTH sides' intent:
   - Code files: main's new behaviour (T38 picker, U24–U34 polish, `_position_list_menu`, dialogue safe bounds / `set_safe_bounds`,
     chapter-card `apply_settings`, ui_preview `--story-setup-only`) AND the PR's changes (translation wrapping with `tr()`/UiText,
     damage queue, etc.). Read both diffs (`git diff <merge-base>..origin/main -- <file>` and `..HEAD`) before editing.
   - `README.md` / `docs/README.md`: PR side is Thai; main added a project-tree section, folder index, Contributing link and the
     docs index in the repo's Thai-with-English-identifiers style. Keep main's new sections, written in Thai consistent with the PR.
   - `i18n/messages.pot` + `i18n/th.po`: do not hand-merge. Take the PR's `th.po` as the base, then regenerate the template with the repo's tools
     (`tools/i18n/`, see `docs/guides/` and how T38 did it) so every msgid in code is in the catalog, and add Thai translations for the
     strings main added (T38 picker texts `story_choose_class`, `story_picker_*`, `story_skill*`, Esc menu, personal Gold wording "for you"/"Your Gold",
     DoT tip, etc.). The Thai catalog check must pass with 0 untranslated.
2. Make the tests pass. The PR's CI test job failed (find out why by running the suite; one commit already says "layout smoke scripts run in English locale" —
   the new smoke scripts from main (`menu_position_smoke`, `dialogue_log_smoke`, `camp_focus_smoke`) must also run in English locale or be locale-independent; with Thai as the
   default locale text widths differ, so check the layout assertions at Thai strings too and fix real overlaps rather than loosening checks).
   `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` must end with 0 failed and no `SMOKE FAILED`.
3. Real-window evidence (non-console exe `/d/dev-tools/godot/Godot_v4.7.2-stable_win64.exe --rendering-driver opengl3 -s ...`): run
   `tools/dev/story_preview.gd --full` (now works on main) in Thai and in English (`--lang=en` if supported by the script/app; else set the locale in a throwaway wrapper) and
   `tools/dev/ui_preview.gd --story-setup-only`; save a few key PNGs to `docs/screenshots/` (title/story setup picker in Thai, story battle, Esc menu). Describe what you see; flag any Thai text that is clipped.
4. Commit the merge resolution yourself ONLY IF the task runner allows; otherwise leave the merge staged/unfinished-free (all conflicts resolved, `git status` shows a completed merge state or modified files).
   Do NOT push. Do NOT touch `.claude`, `.ai/checkpoint.md`, CI workflows, assets. Do not use `git show ref:path` in this shell (path mangling): use `git cat-file -p <blob>` or `git show <commit> -- path`.

## Report (under 250 words)
Per conflicted file: how resolved. Test counts before (merged) / after. Which strings you added to Thai. Screenshots saved. Anything left untranslated or clipped. Any item from the PR you had to drop and why.

# Task: repo-tidy — make the folder layout and GitHub repo files clean and easy to read

Goal: someone opening this repo for the first time should understand the layout in two minutes, and the GitHub repo should
follow common best practice. **No behaviour change to the game.**

## Read first
`AGENTS.md`, `CONTEXT.md`, `README.md`, `docs/README.md`, `docs/plans/2026-09-29-restructure.md` (earlier restructure — do not
undo it), `.claude/agents/repo-restructurer.md` (the move rules below come from it).

## Hard rules
- Move with `git mv`. A script moves with its `.uid`; never delete a `.uid`. Do not rename `class_name`s, functions, signals,
  content ids or JSON keys. Do not reformat code.
- Before moving ANY path, `git grep -n` the old path over code, `.tscn`, `.cfg`, `project.godot`, `export_presets.cfg`,
  `.github/workflows`, `deploy/`, `.ai/*.ps1`, `.claude/agents/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTEXT.md`, `docs/`
  and update every hit in the same commit. Leave historical records (`docs/review/`, `.ai/tasks/`, `.ai/checkpoint.md`) as written.
- Do NOT touch `assets/**` folder structure (887 files, `res://` references everywhere) unless a path is provably unused.
  Prefer documenting over moving when a move is risky. Tests that list directories must still cover every folder.
- Do not commit, push, delete branches or change git config/remotes. Leave changes uncommitted.
- ONE Godot process at a time. `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`.

## Part A — in-repo layout (do in this order, small steps)
1. **Audit** the tree (`git ls-files`, top-level dirs, root files, `docs/`, `.ai/`, `tools/`, `art_source/`, `deploy/`, `tests/`).
   Write the findings to `docs/plans/2026-10-01-repo-tidy.md`: what is misplaced, duplicated, stale or unexplained, with the
   decision for each (move / delete / document / leave) and why.
2. **Root clutter:** root should hold only project files + `README.md`, `CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`, `LICENSE` (if the
   owner has one — do not invent a licence; list "missing LICENSE" in the report instead), config dotfiles. Move/remove anything else
   that is safe.
3. **Docs:** make `docs/README.md` a real index (one line per folder and per top-level doc, grouped: guides / design / plans /
   history / research / review / adr / agents / references / screenshots). Fix every dead relative link
   (check with a small script over all `*.md`; report the count before/after).
4. **Folder READMEs:** add a short `README.md` (3–8 lines: what lives here, how it is produced/used, who edits it) to each of
   `src/`, `tests/`, `tools/`, `art_source/`, `deploy/`, `content/`, `i18n/`, `.ai/` and the main subfolders of `src/` if missing.
   Match the existing Thai-with-English-identifiers style of `README.md`.
5. **Root README:** add a "โครงสร้างโปรเจกต์" section (directory tree, one line each) and a "Contributing" pointer. Keep the rest.
6. **Dead weight:** find tracked files that nothing references (stale tmp/backup/duplicate files, empty dirs with only `.gitkeep`
   that are pointless, `*.import`/`.godot` leaks). Delete only if provably unused (`git grep` the basename and the `res://` path);
   otherwise list them in the plan doc.

## Part B — GitHub repo hygiene (files only; no API calls)
1. `.gitignore`: add missing standard Godot/OS/editor entries (`*.tmp`, `.DS_Store`, `Thumbs.db`, `.vscode/`, `.idea/`,
   `*.translation` etc. as appropriate); keep every existing entry. Verify `git status` shows no tracked file now ignored.
2. Add `.editorconfig` (utf-8, LF, tabs for `.gd`/`.tscn`, 2-space for md/json/yml — match what the code already uses; check first).
   Check `.gitattributes` has LF normalisation and Git LFS/binary rules for `assets/` types actually present; fix gaps.
3. Add `CONTRIBUTING.md` (branch naming `ai/<name>` / `feat|fix|docs|refactor/<name>`, Conventional Commit style used in
   `git log`, how to run `tools/run_tests.sh`, PR checklist, issue labels from `docs/agents/triage-labels.md`).
4. Add `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md` + `config.yml`
   (blank issues allowed), `.github/CODEOWNERS` (owner = `@qqkiller-programmer-myself-2006`). Keep them short; Thai/English mix as in README.
5. Check `.github/workflows/*.yml` still reference only paths that exist. Do not change CI logic.
6. Write `docs/guides/github-setup.md`: the settings the owner must click in GitHub (cannot be done from files): default branch
   `main`, branch protection (require PR + `tests` check), "Automatically delete head branches", squash-merge default, labels.

## Verify (all must pass; paste the exact lines in your final report)
- `"$GODOT" --headless --path . --import` then `bash tools/run_tests.sh` → same pass count as before you started (record it first).
- `git grep` for every old path you moved returns nothing outside the historical records.
- Markdown dead-link script: 0 broken relative links in the files you touched.
- `git status --short` listing; confirm no `.godot/`, `*.import`, `build/`, `.ai/logs/` is tracked.

## Final report (under 250 words)
Changed files grouped by Part A/B, test counts before/after, every path moved, items you deliberately left and why, and a
list of GitHub settings/branch cleanup still needed from the owner.

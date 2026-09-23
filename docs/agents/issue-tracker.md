# Issue tracker: GitHub

Issues and specs for this repo live as GitHub Issues in
`qqkiller-programmer-myself-2006/project-gamedev`. Use the `gh` CLI for
all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`.
- **Read an issue**: `gh issue view <number> --comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments`.
- **Comment on an issue**: `gh issue comment <number> --body "..."`.
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: `gh issue close <number> --comment "..."`.

Infer the repository from `git remote -v`; `gh` does this automatically
when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** External pull requests are not part of
the issue triage queue unless this file is explicitly updated.

## When a skill says “publish to the issue tracker”

Create a GitHub issue.

## When a skill says “fetch the relevant ticket”

Run `gh issue view <number> --comments`.

## Wayfinding operations

The `/wayfinder` map is a single GitHub issue labelled `wayfinder:map`.
Child work is represented by linked GitHub sub-issues when supported; if
sub-issues are unavailable, add a task list to the map body and put
`Part of #<map>` at the top of each child issue.

Use `wayfinder:<type>` labels for `research`, `prototype`, `grilling`,
and `task`. Native GitHub issue dependencies are the canonical blocking
representation. If dependencies are unavailable, use a `Blocked by: #<n>`
line at the top of the child issue body.

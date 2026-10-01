# GitHub repository setup

These settings must be selected by the repository owner in GitHub. They cannot be set by files in this repository.

## Repository settings

1. Under **Settings → General → Default branch**, set `main` as the default branch.
2. Under **Settings → General → Pull Requests**, enable **Automatically delete head branches** and set **Squash and merge** as the default merge method.
3. Under **Settings → Branches**, add a ruleset or branch protection rule for `main`: require pull requests before merging and require the `test` job (workflow `tests`) to pass.
4. Under **Issues → Labels**, create the five labels from [`../agents/triage-labels.md`](../agents/triage-labels.md): `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`.

## Branch cleanup

After enabling automatic deletion, review existing merged head branches in GitHub and remove obsolete ones there. Keep `main` and any branch with work that has not been merged. This guide does not delete branches or change repository settings.

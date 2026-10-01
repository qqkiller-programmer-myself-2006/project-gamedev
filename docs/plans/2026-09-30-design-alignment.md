# Design alignment plan — 2026-09-30

## Goal

Make the repository's product description, domain glossary, accepted ADRs, review notes, and GitHub Project point to one current design. Keep this first pass documentation-only; do not change gameplay until any open product choice is recorded in an accepted ADR.

## Current source of truth

Use the latest accepted ADR and explicit owner decisions as the implementation contract. ADR-0013 replaces the old Classless-first direction for matches with a pre-match Class/Race/Boon loadout; Classless remains a compatibility path when no loadout is supplied. ADR-0014 currently defines offline Story mode as using an isolated in-memory profile with Human and no Boons or class-tree meta. The implementation in `src/client/story/story_launcher.gd` and `src/match/room.gd` follows that Story rule.

The open question is whether Story should continue to have no online profile meta or inherit the lead player's Race/Boons. The accepted ADR and current implementation say no; an older final-review follow-up suggests yes. Preserve the accepted behavior unless the owner records a new decision. If changed, revise ADR-0014 and define save validation, profile source, and tests before code changes.

## Findings

1. **PRD conflicts with ADR-0013.** `docs/design/prd.md` says the player begins Classless and discovers Classes during travel. ADR-0013 says the normal match starts with a pre-match loadout and only missing-loadout compatibility starts Classless.
2. **The domain glossary contradicts itself.** `CONTEXT.md` says Enervation is a Boon in its introduction, but its Assassin and Enervation entries still describe an Assassin passive and say the slice has no Boons. ADR-0013 explicitly supersedes that rule.
3. **ADR naming/supersession drift.** ADR-0010's rename/supersession note was placed before its YAML front matter, and its accepted body still describes Rogue's Enervation passive. ADR-0013 also still names the Tier 1 Class Rogue after #74 renamed it Assassin. Preserve ADR-0010 as history, but make its supersession easy to parse and find; use Assassin in ADR-0013's current requirements.
4. **Review follow-up #76 mixes a decision with a defect.** Story's no-meta behavior matches ADR-0014 today, while the review recommends wiring the profile Race/Boons. Resolve it as a product decision before treating it as implementation work.
5. **GitHub Project #8 has stale statuses.** Issues #46, #82, #84, and #86 are closed, but their Project items remain `In Progress`. The Project should be reconciled from issue state; #47 remains active, while #54 and #55 still need human sign-off/deployment.
6. **Checkpoint was behind main.** `.ai/checkpoint.md` ended at the 0cc1 worktree/#90 handoff, while this checkout is detached at `main` HEAD `7dd5d8b` (PR #97 merged) and PR #98 is open. The current audit entry now records that newer state.

## Work sequence

### A. Documentation-only alignment — completed in this audit

- Updated `docs/design/prd.md` to describe the current pre-match loadout and Classless compatibility path. Broader narrative goals remain intact.
- Fixed the conflicting Assassin and Enervation entries in `CONTEXT.md`; Enervation is now a Boon, not an Assassin passive.
- Repaired ADR-0010 front matter and marked its Enervation decision superseded by ADR-0013. The historical rule text remains intact.
- Updated ADR-0013's current Class and Boon wording to use Assassin after rename #74.
- Added a post-review disposition in `docs/review/2026-09-30-final-review.md`: F4's proposed Story profile behavior is not a defect under the accepted ADR-0014 policy. Keep historical findings visible as a dated review snapshot.
- Updated the checkpoint's current entry with the latest `main` commit (`0779ef1`, including merged PR #98) while keeping historical log entries intact.

### B. Resolve tracking drift

- Set Project #8 items #46, #82, #84, and #86 to `Done` to match their closed GitHub issues.
- Keep #47 `In Progress`; check #54 and #55 with the owner because their remaining work is human QA/sign-off and Worker deployment.
- Update the current checkpoint/work queue to mention PR #98 as open and avoid treating old #90 handoff notes as today's active branch state.

### C. Story profile decision and follow-up

- Default: keep Story on Human/no Boons/no class-tree meta as specified by accepted ADR-0014.
- If the owner wants shared progression in Story, write a new ADR decision first. Then define whether the profile is read-only, which slot inherits it, how online gems stay isolated, how save validation handles tree bonuses, and how Continue preserves the loadout. Track implementation in a separate issue.

## Acceptance checks

- Current requirements in PRD, `CONTEXT.md`, ADR-0013, and ADR-0014 do not contradict each other; historical ADR-0010 differences are explicitly marked superseded.
- Search results for current-design text contain no active statement that Enervation is an Assassin passive or that standard matches begin Classless.
- Story behavior has one explicit policy shared by ADR-0014, #76 follow-up, and tests.
- Project #8 status matches closed/open GitHub issue state for the listed items.
- Run `bash tools/run_tests.sh` once no other Godot process is running; expected result is exit code 0 and 0 failed. If docs-only changes do not touch runtime, the test suite is still a baseline regression check rather than behavior verification.

## Risks / limits

- PRD is much larger than the ADR set; revise only mechanics contradicted by accepted ADRs and retain narrative/product goals.
- Do not mutate Project #8 or rewrite closed issues until the owner approves the proposed Story policy and tracking cleanup.
- Full tests were not run during this audit because a Godot editor process is open on another checkout; the repository checkpoint warns that concurrent Godot runs can fail silently.

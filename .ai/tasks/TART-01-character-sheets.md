# TART-01 — Character sheets (6 main characters)

- **Task ID:** TART-01
- **Owner:** Codex (image generation; worktree `Project-GameDev-Agents/Codex1`, branch `ai/3d-codex1`)
- **Dependencies:** none. Owner approval to dispatch is given (2026-10-03, "เอา 2.5D แล้ว เจนรูปไปใส่").
- **Read first:** `AGENTS.md`, `docs/art/2-5d-pipeline.md`, `docs/art/prompt-pack.md` (rules, STYLE/NEGATIVE blocks, Part 1 table), `docs/design/character-designs-draft.md`

## Goal
Produce character design reference sheets for IQ, Fifa, Tata, Cake, May and Nanny (before brainwashing), so the owner can pick and lock each face before any sprite is made.

## Scope
1. For each of the 6 characters, generate **3 candidate sheets** (different seeds / slight wording variations of hair and face only; hair/eye color, outfit, height and signature item must follow the design doc exactly). Use the template and the exact `[DESCRIPTION]` rows from `prompt-pack.md` Part 1, plus the STYLE and NEGATIVE blocks.
2. Rules from the prompt pack apply: no copyrighted names or artists in prompts, adults 20–25, modest outfits, all women wear glasses, original designs only.
3. Save PNGs to `art_source/sheets/<character>/<character>_cand<1-3>.png` (not in `assets/` yet; these are candidates).
4. Write `art_source/sheets/INDEX.md`: per file the full prompt used, tool, seed if available, date. Also a contact sheet `art_source/sheets/contact_sheet.png` (all 18 candidates in a grid) for the owner to review quickly.
5. Self-check each image against the design doc (hair color, eye color, glasses, signature item, coat with red lining, white armband) and write a one-line pass/fail note per image in `INDEX.md`. Do not hide failures.
6. If the Codex environment cannot generate images, stop and say so in the handoff with the exact error; do not substitute other tools.

## Allowed paths
`art_source/**` (new), nothing else. Do **not** touch `assets/`, `src/`, `content/`, `i18n/`.

## Acceptance criteria
- 18 candidate images + `INDEX.md` + contact sheet exist, or a clear failure report.
- No image contains text, logos, watermark or a recognisable existing character.

## Handoff
`.ai/handoff/TART-01.md`: branch + sha (commit `art_source/` only if the repo tracks it; otherwise leave uncommitted and list the folder path), tool used, per-image pass/fail table, problems (glasses, hands), open questions. Never push.

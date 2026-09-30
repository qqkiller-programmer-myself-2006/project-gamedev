# T33 — Story mode shows single-player UI, prologue first (#82, U3 U4 U5)

Source: `docs/review/2026-09-30-full-qa-report.md` (U3, U4, U5) and ADR-0014 (offline Story mode). Client files:
`src/client/**`, `tests/client/**`. Server/story files only if U5 truly needs it (`src/match/**` story wiring) — prefer a
client-side fix. Use CONTEXT.md vocabulary.

How to tell Story from Multiplayer: untimed decisions arrive with `deadline == null` or `deadline < 0` (the server sends -1 for
camp/class offers and null for untimed combat); the client also knows it is in Story mode (see how `story_panel.gd` and
`src/client/story/*` detect it). Use one helper (e.g. on the app or UiKit) instead of repeating checks.

1. **U3 — no "0s" timers in Story**: Merchant/Rest show an orange "0s"; the Class offer shows "Offer closes in 0s" and
   "Silence counts as declining" (`camp_view.gd` ~501–505, `class_panel.gd` ~59–64). Treat `deadline == null or deadline < 0`
   as "no timer": hide the countdown, no warning sound, no "silence" text.
2. **U4 — no multiplayer chrome in Story**: hide PLAYER badges and owner names on party cards, the "X joined." toast, "every
   player has one vote and AI never votes", "Voted: nobody yet. Waiting for: …", "Final tally … votes". Reword the path vote as
   a plain choice ("Choose your path"). Multiplayer must look exactly as before.
3. **U5 — prologue before the first choice**: the prologue / chapter card plays after the first path is chosen because
   `src/client/story/story_director.gd` ~112–118 waits for no pending decision, and Story has no timer. In Story, show the
   prologue and chapter card first and only then reveal the first vote/choice (e.g. hold the decision panel until the director
   finished the queued card), without breaking Continue from a save.

Tests: add client tests for (1) deadline -1/null → no countdown text, (2) Story hides vote/owner chrome, Multiplayer keeps it,
(3) director shows the prologue before the first path panel.

Verify (one Godot process at a time; `$GODOT` is set by the runner): `"$GODOT" --headless --path . --import`,
`bash tools/run_tests.sh` → 0 failed (no fewer passed than before). Story screenshots: see `tools/dev/` for the story preview
(`ui_preview.gd` has a story option — read its header), output to `build/t33`, and LOOK at prologue, first path choice,
merchant/rest and class offer images.

Report (under 200 words): per item done / not done, exact test summary line, screenshots you looked at, changed files, stray
files. Do not commit or push.

# T32 — Readable digits and no broken ligatures (#84, U10 + U11)

Source: `docs/review/2026-09-30-full-qa-report.md` (U10, U11). Client only: `src/client/**`, `tests/client/**`, fonts under
`assets/` if a font change is needed. Do not touch `src/match/**`, `content/`. Follow `docs/design/ui-style.md` (Navy + Gold).

1. **U10 — digits**: with Pixelify Sans the digit 5 reads as "S" ("Cave (S/S)", "Lvl S", "Layer 1 of S", "Reset Skills S0 Gems")
   and 7 reads as 1 ("70/70" looks like "10/10"). Numbers the player must read — HP, Energy, Gold, level, layer x/y, costs,
   Gems, timers, damage numbers — must use a font with clear digits. Preferred: keep Pixelify for words, render numeric text
   with the body font (a single place in `UiKit`, e.g. a `number_label()` / a font fallback rule, not ad-hoc per screen).
   Alternative only if cleaner: a pixel font with distinct 5/S and 7/1 that is already in the repo or has an OFL licence (no
   network downloads without saying so in the report).
2. **U11 — ligature**: the "fi" ligature renders as a strange glyph ("Profile" shows "ProAle"). Disable ligatures
   (`opentype_features` `liga=0`, also `clig`/`dlig` if needed) on the PixelifySans FontVariation / Theme font so every label is
   affected.
3. **Guard**: extend `tests/client/test_font_glyphs.gd` so it fails if ligatures are enabled for the pixel font and if the
   numeric style does not use the digit-safe font.

Verify (one Godot process at a time; `$GODOT` is set by the runner): `"$GODOT" --headless --path . --import`,
`bash tools/run_tests.sh` → 0 failed (no fewer passed than before your change). Windowed preview
`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --out=build/t32` and `--scale=1.4 --out=build/t32_x14`: LOOK at the
setup (Profile tab), combat HUD, merchant and summary images — 5 and 7 must be unmistakable, "Profile" must read correctly.

Report (under 200 words): per item done / not done, exact test summary line, screenshots you looked at, changed files, stray
files. Do not commit or push.

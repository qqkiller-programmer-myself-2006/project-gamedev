# T41-r3 — Finish T41: make the suite green (continue in this worktree; keep all current uncommitted UI work)

The previous Codex run crashed mid-way. Reviewer ran `GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`
-> 437 passed, 4 failed:
1. tests/client/test_accessibility_baseline.gd::test_combat_log_and_footer_use_viewport_anchors_at_large_scale
2. tests/client/test_nameplate_scale.gd::test_default_scale_keeps_ten_pixel_plate_text
3. tests/client/test_story_ui.gd — "script failed to load" (compile error in the test or code it uses)
4. tests/client/test_ui_contrast.gd::test_theme_has_the_navy_and_gold_variations
For each: decide whether the code or the test is wrong. The new UI design is intended (compact one-row header, log panel inset left,
readable fonts), so update tests that assert the OLD design, but fix real bugs in code. Do not weaken invariants like "nothing
overflows the viewport".

Also fix one visual bug seen in `build/ux_after2/1280x720_scale1.0/04_combat_turn.png`: the combat log panel (bottom-left) overlaps
the "Dain (AI)" nameplate/back-row tokens; make the log sit clear of tokens and nameplates (smaller, or moved under the turn list,
or collapsed into the bottom footer) at 1280x720 and 1920x1080, scale 1.0 and 1.4. Re-capture with
`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ux_after3 --seed=11 --speed=10 --class=mage` and look at it.

Finish by running the FULL suite (one Godot at a time; other sessions' Godot may be running, that is accepted) and report the exact
summary line. Do not commit. Report: files changed, test line, screenshot path.

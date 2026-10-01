# T40-r2 — Fix skill FX art (continue in this worktree; Part B code is fine, keep it)

Read `.ai/tasks/T40-skill-fx.md` and your previous work (uncommitted: `tools/art/make_skill_fx.py`, `assets/fx/`, `art_source/fx/`).
Reviewer findings on `assets/fx/_contact.png` — fix ALL of them in `tools/art/make_skill_fx.py`, regenerate, re-slice:

1. CLIPPING: late frames of fireball and power_slash touch the right/bottom canvas edge (bbox reaches 192). Every frame must keep
   >= 8 px transparent margin on all four sides. Add an assert in `slice_skill_fx.py` that fails otherwise.
2. power_slash must read as a diagonal sword slash: a thick crescent arc (white core, yellow edge, 3-4 px wide at the middle,
   tapering to points) sweeping top-right to bottom-left over the frames, with a few spark pixels. Not a zigzag line.
3. Small/thin skills (aimed_shot, stab, poke_up, frost_lance) are too small for their canvas. Make the effect fill ~60-70% of the
   canvas, at least 4 px thick: aimed_shot = arrow/bolt streak with impact star on the last frames; stab = bright pierce flash
   (cross-shaped glint + 3 radial lines); poke_up = upward thrust with dust/impact burst; frost_lance = large ice spear with
   crystal shards bursting at the end.
4. protect vs shield_wall must differ clearly: protect = single golden shield icon with a soft pulse ring over one ally;
   shield_wall = wide row of 3 overlapping blue translucent shields forming a wall, pulsing, canvas 192.
5. fireball: full round fireball growing into an explosion with embers, fully inside the canvas (shrink radius if needed).
6. Keep the pixel-art style: chunky 2-4 px pixels (draw small then upscale nearest), 1 px dark outline `#0a1020`, <= 8 colours per skill.
7. Regenerate `assets/fx/_contact.png` at 2x scale on navy with an 8 px grid so edges are visible. LOOK at it, and fix anything still
   wrong before reporting.
8. Re-run `"$GODOT" --headless --path . --import`. Then the focused test, then the full suite ONLY if
   `tasklist | grep -i godot` shows no other Godot process; otherwise run only `tests/client/test_skill_fx.gd` and say so.
   (`$GODOT` = D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe.)

Rules as in T40. Do not commit. Report in English: what changed per skill, margins check result, test lines.

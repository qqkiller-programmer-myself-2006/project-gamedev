# T43 — Make the fireball FX look like a fireball

In `tools/art/make_skill_fx.py` only the `fireball` strip (8 frames, 192x192, tier ultimate, anchor target) must change.
Problem (seen in `assets/fx/_contact.png`): early frames look like a flower/petals, and the last frames are a hollow thin ring.
Make it read as a real fireball in the same chunky pixel style (draw small, upscale nearest, 1 px dark outline `#0a1020`, <= 8 colours):
- f0-f2: a round fireball (white-yellow core, orange body, red rim) streaks/grows with a flickering flame tail trailing to the upper-left
  and 2-4 spark pixels; the outline of the ball must be irregular flame tongues, NOT symmetric petals.
- f3-f5: it hits and explodes: bright white-yellow flash core, irregular orange/red fireball blast (blobby, not a perfect circle) that
  expands, with embers flying outward and a few smoke-dark puffs.
- f6-f7: blast shrinks/rises and fades with embers falling; no hollow thin ring; ends almost transparent.
Keep canvas 192, 8 frames, fps, anchor, tier, the >= 8 px transparent margin, and the adjacent-frame difference check.
Other skills must stay byte-identical (do not change their code paths; verify with `git diff --stat` that only `assets/fx/fireball/*`,
`art_source/fx/fireball.png`, `assets/fx/_contact.png`, `assets/fx/_motion.png` and the generator changed).
Verify: regenerate + slice + `"$GODOT" --headless --path . --import`; LOOK at `_contact.png` and iterate; run
`tests/client/test_skill_fx.gd` and the full suite (`GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`).
Do not commit. Report in English: what the fireball does per frame, test summary line.

# T3D-07-retry — Battle HUD polish (Thai clipping, overlaps)

- **Owner:** Codex (runner, worktree `Project-GameDev-Agents/Codex1`, branch `ai/3d-codex1`; first `git merge --ff-only claude/game-project-lead-9a9ecc`)
- **Base:** T3D-07 is merged (3258b5d). Read `.ai/tasks/T3D-07-battle-hud.md` again — same allowed/forbidden paths.

## Problems found in review (build/ux_battle3d_1280/04_combat_skills.png, build/ux_battle3d_1920/04_combat_energy_low.png)
1. Thai text is clipped by the slanted panels: TurnOrder names lose their first glyph on the left (อาริน, แบรม, โครา, เดย์น, เรน, หมาป่า), the TargetBanner caption "เป้าหมาย" loses its top (upper vowels/tone marks), the countdown "12 วินาที" touches the slanted left edge. Pad text inside each slanted panel by at least the slant width plus 6 px, and leave room above for Thai upper marks.
2. The TurnOrder rows overlap the CommandFan (Focus/Item buttons sit behind the second TurnOrder row). Lay them out so nothing overlaps at 1280×720, scale 1.4 and 1920×1080.
3. When the Skill/Item menu is open it covers the CommandFan buttons; the fan labels behind it show through ("ทักษะ [S]" is cut). Either hide/dim the fan while a submenu is open or place the submenu so it does not cover the fan.
4. Unusable skills (not enough Energy / on cooldown) must look clearly disabled in the 3D menu (energy_low screenshot: the Energy-1 and Energy-2 skills look the same as usable ones for an actor at 0/6).

## Acceptance
- New screenshots for all six states at 1280×720, 1280×720 text scale 1.4, and 1920×1080 with no clipped Thai and no overlaps; list paths in the handoff.
- Add a layout test in `tests/client/match/battle/hud/` that asserts TurnOrder, CommandFan, TargetBanner and PartyPlates rects do not intersect and label text fits its panel at scale 1.4.
- `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` green (count not lower than 530), i18n check passes.
- If Git Bash lacks `dirname`/`seq`/`sleep` in your sandbox, say so in the handoff; the lead reruns the suite.

## Handoff
branch + sha, files, test result, screenshot paths, open questions. Do not commit unless told; never push.

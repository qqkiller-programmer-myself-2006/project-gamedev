# Task: source and wire an `enemy_death` SFX

Context: `src/client/ui/sound_bank.gd` maps cues to files in `assets/audio/sfx/`. The cue `enemy_death` currently reuses `hit.ogg` as a placeholder and is not played anywhere. Combat events carry per-target results with `down: true` when a target is knocked out (see `_describe_action` and the `action_resolved` handler in `src/client/match/match_screen.gd`, and `src/client/match/battle/battle_view.gd` around the `result.get("down")` check). Player slots are targets starting with "p"; everything else is an enemy. Read `docs/research/audio-sourcing.md` and `assets/audio/CREDITS.md` for licence rules and conventions. Do not commit.

## 1. Find a sample (network enabled)
One short (0.6 to 2 s) enemy defeat sound for a fantasy RPG: a creature/monster death groan or a dissolve/poof/collapse, not gory, clearly different from `hit.ogg`, `sword_hit.ogg` and `player_down.ogg`. Licence: CC0 or CC-BY 4.0 only (no NC, no ND); verify on the item page. Prefer OpenGameArt, Kenney.nl, or Freesound (CC0 only, per-item page). Packs already used and fine to reuse: Kenney packs, leohpaz, JaggedStone, artisticdude, BMacZero. Skip anything with unclear licence; if nothing suitable and clearly licensed exists, stop and report that without changing files.

## 2. Add it
Download to a temp dir OUTSIDE the repo. Convert to mono 22.05 kHz OGG Vorbis (ffmpeg), trim silence, peak-normalize to about -1.5 dB like the other new SFX, under 150 KB, save as `assets/audio/sfx/enemy_death.ogg`. Point `"enemy_death"` in `CUE_ASSETS` at it. Update `assets/audio/CREDITS.md` (file, source URL, author, licence, edits; CC-BY credit text verbatim if CC-BY), the in-game credits line in `src/client/title/title_screen.gd` (`_show_credits`) if a new author or licence appears, and the cue table/gap notes in `docs/research/audio-sourcing.md`. Run the headless import (`"$GODOT" --headless --path . --import`, GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe).

## 3. Hook up (minimal, `src/client/match/match_screen.gd`)
In the `action_resolved` feedback handler, play `enemy_death` once per action when any result has `down` true and its target is an enemy (not starting with "p"); play `player_down` once per action when a player target goes down (cue exists, currently unused). Do not play the `hit` cue on top of those in the same action; keep the existing precedence for crit/heal/buff/debuff/miss. Never remove banners/log lines/floating text and do not change game logic.

## 4. Verify
Add a small test only if there is a clean seam; do not loosen existing tests. Run `tools/run_tests.sh` with GODOT set; all tests must pass. Report: file added, source URL + licence, edits made, which events trigger which cue, test result.

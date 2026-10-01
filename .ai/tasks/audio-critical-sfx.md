# Task: source and wire a `critical` hit SFX

Context: `src/client/ui/sound_bank.gd` maps cues to files in `assets/audio/sfx/`. The cue `critical` still has an empty path in `CUE_ASSETS` (synthesized fallback). `src/client/match/match_screen.gd` already plays "critical" when a result has `crit` true. Read `docs/research/audio-sourcing.md` and `assets/audio/CREDITS.md` for licence rules and format conventions. Do not commit.

## 1. Find a sample (network enabled)
Find one short (< 1.5 s) punchy critical-hit / heavy-impact sound: a sharp metallic strike with a bright ring or a heavy slash-impact, clearly distinct from the existing `hit.ogg` and `sword_hit.ogg`. Licence: CC0 or CC-BY 4.0 only (no NC, no ND); verify on the item page. Prefer OpenGameArt, Kenney.nl, or Freesound (CC0 only, per-item page). Already used and fine to take from again: Kenney packs, leohpaz "8 Heals and Buffs", JaggedStone "Magic Spell SFX", artisticdude "Swishes". Skip anything with unclear licence; if nothing suitable and clearly licensed exists, stop and report that without changing files.

## 2. Add it
Download to a temp dir OUTSIDE the repo. Convert to mono 22.05 kHz OGG Vorbis (ffmpeg), trim silence, peak-normalize to about -1.5 dB like the other new SFX, keep it under 100 KB, save as `assets/audio/sfx/critical.ogg`. Set `"critical"` in `CUE_ASSETS` of `sound_bank.gd`. Update `assets/audio/CREDITS.md` (file, source URL, author, licence, edits; keep CC-BY credit text verbatim if CC-BY) and the in-game credits line in `src/client/title/title_screen.gd` (`_show_credits`) if a new author or licence appears. Update the gap list in `docs/research/audio-sourcing.md`. Run the headless import (`"$GODOT" --headless --path . --import`, GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe).

## 3. Verify
Do not change combat logic. Run `tools/run_tests.sh` with GODOT set; all tests must pass. Report: file added, source URL + licence, edits made, test result.

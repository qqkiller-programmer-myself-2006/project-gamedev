# Task: source and wire magic SFX (magic_cast, heal, buff, debuff) into SoundBank

Context: `src/client/ui/sound_bank.gd` already maps cues to files in `assets/audio/sfx/`. The cues `magic_cast`, `heal`, `buff`, `debuff` (and `critical`, `miss`) currently have an empty path and use the synthesized fallback. Read `docs/research/audio-sourcing.md` and `assets/audio/CREDITS.md` for what was already chosen and the licence rules. Do not commit.

## 1. Find samples (network enabled)
Find short (< 3 s) fantasy/RPG magic sound effects that fit: a spell cast, a heal/restore chime, a positive buff (rising shimmer), a negative debuff (descending/dark). Licences: CC0 or CC-BY 4.0 only (no NC, no ND). Verify the licence on each item page, and prefer the same style as the existing Kenney SFX. Good places to check: OpenGameArt (CC0/CC-BY entries, e.g. "Magic SFX", "RPG sound pack" style packs), Kenney.nl, Freesound (CC0 only, per-item page), itch.io CC0 packs. Do not use Pixabay unless the licence page makes commercial use without attribution explicit; do not use anything unclear. If a CC-BY sample is chosen, record the required credit text verbatim.
Also try to find `critical` (sharp impact/ring) and `miss` (whoosh) the same way; if nothing suitable and clearly licensed, leave those two on the synth fallback.

## 2. Add the files
Download to a temp dir OUTSIDE the repo, audition by checking duration/format, and copy only the chosen ones to `assets/audio/sfx/` as `magic_cast.ogg`, `heal.ogg`, `buff.ogg`, `debuff.ogg` (+ `critical.ogg`, `miss.ogg` if found). Convert to OGG Vorbis with ffmpeg if needed, normalise peak loudness to roughly match the existing Kenney SFX (no clipping), trim silence. Keep each file small (< 300 KB). Follow `.gitattributes`. Run the headless import (`"$GODOT" --headless --path . --import`, GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe).
Update `CUE_ASSETS` in `sound_bank.gd` for those cues (keep synth fallback behaviour), and update `assets/audio/CREDITS.md` (source URL, author, licence, any edits made). Update `docs/research/audio-sourcing.md` gap list.

## 3. Hook up (small, in `src/client/match/match_screen.gd`)
In the combat event handler that already plays "hit" (`results` loop around the `result.has("heal")` branch, and `_describe_action`): play `heal` when a result has `heal` (once per action, not per target), play `buff` for a result with `status` of "protected"/"shielded" or other positive status, `debuff` for a negative status applied to a target, `critical` when `result.get("crit")` (instead of or after "hit", not overlapping badly). Check the real status/skill names in `src/shared/` and `content/forest.json` before deciding what is positive vs negative; if a skill is clearly a spell, play `magic_cast` at action start. Keep it minimal, never remove banners/log lines/floating text, and do not change game logic.

## 4. Verify
Extend `tests/client/test_sound_bank.gd` if needed (cues still resolve). Run `tools/run_tests.sh` with GODOT set; all tests must pass. Report: files added/changed, source URL + licence per file, which events trigger which cue, test result, anything skipped.

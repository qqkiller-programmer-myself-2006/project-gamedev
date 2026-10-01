# Task: download the approved CC0/CC-BY audio and wire it into SoundBank

The owner approved downloading the packs listed in `docs/research/audio-sourcing.md`. Read that file first; it has the URLs, licences and the cue mapping. Do not commit.

## Packs to download (network is enabled)
Kenney Interface Sounds, Kenney 50 RPG sound effects, Kenney 85 Short music jingles, Zane Little "Glizzy Elf Forest RPG Music Pack", YannZ "FREE Contemplative Fantasy Music Pack" (CC-BY 4.0), MintoDog "Hope". Use the download links on the OpenGameArt pages listed in the research doc (or the Kenney pages). Download to a temp dir OUTSIDE the repo, inspect, then copy only the files actually used.

## Layout and import
- Copy used files to `assets/audio/sfx/` and `assets/audio/music/` with clear lowercase names (e.g. `ui_click.ogg`, `music_forest.ogg`). Keep music as .ogg (convert with ffmpeg if available; if Glizzy/Hope ship wav/flac and no converter exists, keep original format and note it). Total repo size added should stay modest: skip unused tracks, avoid files > ~12 MB.
- Check `.gitattributes` for audio/LFS handling and follow it.
- Let Godot import the files (run the editor headless import: `"$GODOT" --headless --path . --import`, GODOT is `D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe`) so the `.import` files exist; commit nothing.
- Mark music loops as looping (ogg `loop=true` in the `.import` or via `AudioStreamOggVorbis.loop` when loading).
- Write `assets/audio/CREDITS.md` from the template in the research doc, listing exactly the files used and their source packs; keep the YannZ CC-BY credit text verbatim. Also surface it from the existing credits/about UI if one exists; otherwise just keep the file.

## SoundBank changes (`src/client/ui/sound_bank.gd`)
- Keep the public API: `play(cue: String)` and static `set_volume(volume: float)`. Existing cues must keep working: turn, warn, hit, vote, good, bad, click. Map them to the real samples per the research doc.
- Keep the synthesized tones as an automatic fallback when an asset file is missing, so nothing breaks (and the existing tests still pass).
- Add new cues: hover, cancel, error, sword_hit, enemy_death, player_down, level_up, loot_pickup, victory_sting, defeat_sting. Where the research found no good sample (magic_cast, heal, buff, debuff, critical, miss), reuse/pitch-shift existing samples sparingly or leave the cue out; do not invent files.
- Add music: `play_music(track: String)`, `stop_music()`, with cross-fade (about 0.6 s), no restart if the same track is already playing. Tracks: title (YannZ main menu), lobby (same), forest, battle, guardian (Hope), victory, defeat (use the Kenney lose jingle, then silence). Respect `reduced_motion`? Not needed; music just follows the volume setting.
- Create two audio buses at runtime if absent ("SFX" and "Music", both sending to Master) so no `default_bus_layout.tres` change is required; route SFX players to SFX and the music players to Music. Master volume via `set_volume` stays as is. Add a separate music volume only if it is small and fits `ClientSettings`/`settings_panel.gd` cleanly (an optional "Music" slider next to the existing volume one; persist in `user://settings.cfg` under `[audio] music_volume`, default 0.6). If it is not clean, skip it and say so.
- Use a small pool of AudioStreamPlayers for overlapping SFX so rapid clicks/hits do not cut each other.

## Hooking up music (minimal)
Call `play_music` at the obvious scene points only: title screen -> "title", lobby -> "lobby", match exploration -> "forest", battle mode (see `_battle_mode` in `src/client/match/match_screen.gd`) -> "battle", Guardian boss fight -> "guardian", match won/lost screens -> "victory"/"defeat". Look at `src/client/client_app.gd`, `title/`, `lobby/lobby_screen.gd`, `match/match_screen.gd` and pick the least invasive hooks. Add the new SFX cues where the game already has matching events (hit/death/loot/level-up) only if it is a one-line change; otherwise leave them available but unused and list them in your report.
Remember the project rule: every sound cue also has a visual equivalent; do not remove any banner/log.

## Verify
- `tools/run_tests.sh` with GODOT set must pass (same pass count as before or more). Add a test in `tests/client/` that constructs SoundBank, checks every cue name above resolves to a player (asset or fallback) and that `play_music` of an unknown track does not crash.
- Run the headless import step and confirm no import errors for the new files.
- Final report: list files added/changed, which sample went to which cue, total size added, tests run with results, and anything you skipped.

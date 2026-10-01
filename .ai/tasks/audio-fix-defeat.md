# Task: fix defeat music replaying in SoundBank

Bug in `src/client/ui/sound_bank.gd`: `_on_music_finished` resets `_music_track` to "" when the one-shot "defeat" jingle ends. `match_screen.refresh()` (src/client/match/match_screen.gd) calls `play_music("defeat")` on every state refresh during the defeat phase, so after the jingle ends the next refresh replays it.

Fix: a one-shot track ("defeat") that already played must not restart while it is still the requested track. Keep `_music_track = "defeat"` after it finishes (do not clear it), and make `play_music` return early when `_music_track == track` and the track is one-shot, or is looping and still playing. Switching to any other track must still work, and returning to "defeat" after another track must play it again.

Add a test in `tests/client/test_sound_bank.gd` covering: calling play_music("defeat") twice does not restart it after it finished (simulate by calling the finished handler `_on_music_finished(_music_active_index)`), and a different track after defeat still switches. The test runner executes tests before the scene tree root exists (see existing test), so `play_music` may early-return on `is_inside_tree()`; if so, test the guard logic through a small extracted helper such as `_should_skip_music(track) -> bool` rather than loosening the tree check.

Verify: run `tools/run_tests.sh` with GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe; all tests must pass. Do not commit. Report files changed and the test result.

# Task: make the `hover`, `cancel` and `error` cues audible in the UI (and swap the samples only if they are poor)

Context: `src/client/ui/sound_bank.gd` already has the cues `hover` (ui_hover.ogg), `cancel` (ui_cancel.ogg) and `error` (ui_error.ogg), all Kenney Interface Sounds (CC0), but nothing in the game plays them. `src/client/ui/ui_kit.gd` builds the buttons (`button`, `primary`, ...), `src/client/client_app.gd` has `sounds`, `toast()` and `banner()`; `send()` plays "click" on every outgoing command. Read `docs/research/audio-sourcing.md` and `assets/audio/CREDITS.md`. Do not commit. Project rule: every sound cue keeps a visual equivalent; never remove toasts/banners/log lines.

## 1. Check the samples (network enabled, optional)
Inspect the three existing files (duration, peak level, how they sound relative to `ui_click.ogg`). If one is clearly unsuitable (too long > 0.5 s, too loud/harsh, or indistinguishable from click), pick a better sample from the same Kenney "Interface Sounds" pack (CC0, https://opengameart.org/content/interface-sounds, 100 OGG files) or another CC0/CC-BY source, convert to mono 22.05 kHz OGG, peak-normalize to about -1.5 dB, and update `assets/audio/CREDITS.md` and the Credits line in `src/client/title/title_screen.gd` only if the source or author changes. Otherwise keep the files and say so.

## 2. Hook up the cues (minimal, no logic changes)
- `hover`: play when the mouse enters an enabled Button created through `UiKit` (mouse_entered). Quiet and rate-limited so sweeping the mouse across a list does not machine-gun: add a short global cooldown (about 60 to 80 ms) inside `SoundBank` for hover only, and keep it lower in volume than click if per-cue volume is easy. Not for disabled buttons, not on keyboard focus.
- `cancel`: play for dismiss-type buttons: Back, Close, Cancel, Leave, "Got it"-style dismissals and Esc-to-close, replacing the generic click for those. Find the existing callers (grep `"back"`, `Close`, `Back [Esc]`, `_dismiss_hint`, `confirm_leave`, settings panel close, camp/inventory close). Keep it to a small, clear set of call sites.
- `error`: play together with `toast()` when the toast is an error (calls using `UiText.error(...)`, `connection_lost`, rejected commands). Prefer one place: a helper such as `ClientApp.toast_error(message)` or an optional `cue` parameter on `toast()`, then switch the existing error toast call sites to it. Informational toasts stay silent.
- Do not double-play: a button that plays cancel must not also play click for the same press.

## 3. Verify
Keep existing tests passing; add a small test for the hover throttle if SoundBank exposes a clean seam. Run `tools/run_tests.sh` with GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe; all tests must pass. Run the headless import if any audio file changed. Report: files changed, which call sites trigger which cue, whether samples were swapped (and why), test result.

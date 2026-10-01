# Task: find production-quality audio (music + SFX) for the game

RESEARCH ONLY. Do not edit code, do not download audio into the repo, do not change git.
Write your result to `docs/research/audio-sourcing.md`.

## Context
BEYOND THE WORLD'S END: online fantasy turn-based co-op RPG, Godot 4.7, 1280x720.
Today all sound is synthesized beeps in `src/client/ui/sound_bank.gd` (cues: turn, warn, hit, vote, good, bad, click).
Callers: `src/client/client_app.gd`, `match/match_screen.gd`, `lobby/lobby_screen.gd`, `title/settings_panel.gd`.
No audio assets exist and there is no music. Goal: make the game feel production-ready.

## What to research (use web search, network is enabled)
1. Free, commercially usable sources only: CC0 or CC-BY (no NC, no ND). Prefer Kenney.nl, OpenGameArt (CC0/CC-BY entries), Freesound (CC0 only), itch.io CC0 packs, Pixabay audio. Verify the licence on each page.
2. Needed categories:
   - UI: click, hover, confirm, cancel, error, turn-start, countdown warn, vote cast
   - Combat: sword/weapon hit, magic cast, heal, buff/debuff, critical, miss, enemy death, player down
   - Outcomes: victory/good fanfare, defeat/bad sting, level-up/EXP, loot/gem pickup
   - Music loops: title/lobby, forest exploration, battle, Guardian boss, victory, defeat (fantasy, loopable, ogg/wav preferred)
3. For every recommended asset or pack give: name, direct URL, author, exact licence, attribution text required, file format, approximate size/count, and which existing/new cue it should map to.
4. Recommend one coherent shortlist (small number of packs, consistent style) rather than a long unfiltered list. Flag anything with unclear licence.
5. Include a mapping table: existing cues (turn, warn, hit, vote, good, bad, click) -> suggested asset, plus new cues to add.
6. Include a short integration note for Godot 4 (import as .ogg, AudioStreamPlayer, bus layout for Music/SFX, volume setting already in `SoundBank.set_volume`) and a CREDITS.md template for attribution.

## Acceptance
- `docs/research/audio-sourcing.md` exists, English, with the shortlist, mapping table, licence details with URLs, credits template.
- Every URL was actually opened/checked; do not invent links. Mark anything unverified as "unverified".
- No other files changed.

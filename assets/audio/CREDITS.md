# Audio Credits

## Kenney — CC0 1.0
- `sfx/ui_click.ogg`, `sfx/ui_hover.ogg`, `sfx/ui_cancel.ogg`, `sfx/ui_error.ogg`, `sfx/ui_turn.ogg`, `sfx/ui_warn.ogg`, `sfx/ui_vote.ogg`: Interface Sounds, https://opengameart.org/content/interface-sounds
- `sfx/hit.ogg`, `sfx/sword_hit.ogg`, `sfx/player_down.ogg`, `sfx/loot_pickup.ogg`: 50 RPG sound effects, https://opengameart.org/content/50-rpg-sound-effects
- `sfx/level_up.ogg`, `sfx/reward_sting.ogg`, `sfx/defeat_sting.ogg`: 85 Short music jingles, https://opengameart.org/content/85-short-music-jingles
  Attribution is not required; included for provenance.

## JaggedStone — CC0 1.0
- `sfx/magic_cast.ogg`: magical_3.ogg from Magic Spell SFX, https://opengameart.org/content/magic-spell-sfx
  Attribution is not required; included for provenance.

## leohpaz — CC-BY 4.0
- `sfx/heal.ogg`: 02_Heal_02.wav from 8 Heals and Buffs SFX, https://opengameart.org/content/8-heals-and-buffs-sfx
- `sfx/buff.ogg`: 16_Atk_buff_04.wav from 8 Heals and Buffs SFX, https://opengameart.org/content/8-heals-and-buffs-sfx
- `sfx/debuff.ogg`: 21_Debuff_01.wav from 8 Heals and Buffs SFX, https://opengameart.org/content/8-heals-and-buffs-sfx
- Required credit: “8 Heals and Buffs SFX” by leohpaz, https://opengameart.org/content/8-heals-and-buffs-sfx, licensed under CC BY 4.0, https://creativecommons.org/licenses/by/4.0/.

## artisticdude — CC0 1.0
- `sfx/miss.ogg`: swish-7.wav from Swishes Sound Pack, https://opengameart.org/content/swishes-sound-pack
  Attribution is not required; included for provenance.

## BMacZero / Brian MacIntosh — CC0 1.0
- `sfx/critical.ogg`: `bing1.wav` from Metal Impact Sounds, https://opengameart.org/content/metal-impact-sounds
  Optional credit: Brian MacIntosh.

## marcelofg55 — CC0 1.0
- `sfx/enemy_death.ogg`: `Monster SFX.wav` from Monster SFX, https://opengameart.org/content/monster-sfx
  Attribution is not required; included for provenance.

## Zane Little Music — CC0
- `music/music_forest.ogg`, `music/music_battle.ogg`, `music/music_victory.ogg`: Glizzy Elf Forest RPG Music Pack, https://opengameart.org/content/glizzy-elf-forest-rpg-music-pack
  Attribution is not required; included for provenance.

## MintoDog — CC0
- `music/music_guardian.ogg`: Hope (Orchestral battle music), https://opengameart.org/content/hopeorchestral-battle-music
  Attribution is not required; included for provenance.

## YannZ — CC-BY 4.0
- `music/music_title.ogg` (also used for lobby): FREE Contemplative Fantasy Music Pack, https://opengameart.org/content/free-contemplative-fantasy-music-pack
- Required credit: Music by YannZ https://yannz41.itch.io Spotify: https://open.spotify.com/intl-it/artist/76CUcHd0t0XViSm9YBbHBw Contact: yziango@gmail.com

## Changes made
- Converted the Glizzy Elf Forest Loop, Grizzly Dwarf Battle Loop, and Grizzly Dwarf Battle Victory Loop from WAV to OGG Vorbis with FFmpeg; no edits or trims.
- Renamed selected samples to the lowercase filenames listed above. `music_title.ogg` is used for both title and lobby; `defeat_sting.ogg` is used for both the defeat cue and one-shot defeat music.
- Converted `magical_3.ogg` to mono 22.05 kHz OGG Vorbis and removed leading/trailing silence; converted the heal, attack buff, and debuff WAVs to mono 22.05 kHz OGG Vorbis, removed silence, and trimmed the source samples to under 3 seconds. Converted `swish-7.wav` to mono 22.05 kHz OGG Vorbis and removed silence. Peak-normalized all five new files to an approximately -1.5 dB true-peak ceiling; each is under 300 KB.
- Trimmed silence from `bing1.wav`, converted it from mono 44.1 kHz PCM WAV to mono 22.05 kHz OGG Vorbis, and peak-normalized it to approximately -1.5 dBFS; the resulting `critical.ogg` is under 100 KB.
- Trimmed `Monster SFX.wav` to 1.95 seconds, converted it from stereo 48 kHz PCM WAV to mono 22.05 kHz OGG Vorbis, and peak-normalized the encoded result to approximately -1.5 dBFS; the resulting `enemy_death.ogg` is under 150 KB.

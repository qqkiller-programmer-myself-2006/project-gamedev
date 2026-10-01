# Audio Sourcing Research

Checked 2026-10-01. This is a compact, source-checked shortlist for **BEYOND THE WORLD'S END**. All recommended sources below declare CC0 or CC-BY 4.0 on the asset page; no NC or ND terms were found. No audio was downloaded into this repository.

## Recommended shortlist

The three Kenney packs form a practical, consistently stylized SFX base. The music sources fill the RPG loop and menu needs, but their musical styles differ; audition them in-game before adopting both. “Format” and “size” below refer to details published on the source page. Where the listing omits an internal audio format, that is explicitly marked unverified.

| Asset / direct source URL | Author | Exact licence and attribution | Format; approximate size/count | Recommended use |
|---|---|---|---|---|
| [Interface Sounds](https://opengameart.org/content/interface-sounds) (original [Kenney page](https://kenney.nl/assets/interface-sounds)) | Kenney | CC0. Attribution is optional; suggested credit: `Kenney.nl` or `www.kenney.nl`. | 100 separate OGG files; ZIP 834.5 KB. | Click, hover, confirm, cancel, error, vote cast. The source describes clicks, snaps, minimize/maximize and confirmation sounds. Select individual files by audition. |
| [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) (original [Kenney page](https://kenney.nl/assets/rpg-audio)) | Kenney | CC0. Attribution is optional; suggested credit: `Kenney.nl` or `www.kenney.nl`. | 50 OGG files; ZIP 691 KB. | Weapon handling / sword hit candidates, hit, enemy death, loot/coin pickup and player-down impact candidates. Pack description/tags include metal, cloth, footsteps, coin and knife; confirm exact fit by audition. |
| [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (original [Kenney page](https://kenney.nl/assets/music-jingles)) | Kenney | CC0. Attribution is optional; suggested credit: `Kenney.nl` or `www.kenney.nl`. | 85 OGG files (17 jingles × 5 instruments); ZIP 1.1 MB. | Victory/good, defeat/bad, level-up/EXP and short loot/gem reward stingers. Choose and audition individual variants; source tags include win/lose. |
| [Glizzy Elf Forest RPG Music Pack](https://opengameart.org/content/glizzy-elf-forest-rpg-music-pack) | Zane Little Music | CC0. No attribution required. Optional credit: `Music by Zane Little Music (CC0), “Glizzy Elf Forest” — https://opengameart.org/content/glizzy-elf-forest-rpg-music-pack`. | ZIP 44.4 MB; 5 listed pieces: Forest Loop, Battle Intro, Battle Loop, Victory Intro, Victory Loop. Internal audio codec/container is **unverified** on the listing. | Forest exploration, regular battle, battle transition and victory. Not listed as a boss or title/lobby theme. |
| [FREE Contemplative Fantasy Music Pack](https://opengameart.org/content/free-contemplative-fantasy-music-pack) | YannZ | CC-BY 4.0. Required credit text from the source: `Music by YannZ https://yannz41.itch.io Spotify: https://open.spotify.com/intl-it/artist/76CUcHd0t0XViSm9YBbHBw Contact: yziango@gmail.com`. | 15 listed OGG variants/tracks (menu, pause, one-shot, credits, 10 modular loops, in-game loop); OGG files range approximately 3.2–11.1 MB in the listing. MP3 equivalents are also listed. | Main-menu/title and lobby music; calm exploration/transition loops. The composer describes introspective, ambient fantasy music. It is a calmer style than the action music above. |
| [Hope (Orchestral battle music)](https://opengameart.org/content/hopeorchestral-battle-music) | MintoDog | CC0. No attribution required. | OGG 2.2 MB; FLAC 7.6 MB; one explicitly loopable track. | Optional Guardian boss battle alternative, subject to audition: it is bright orchestral battle music, rather than explicitly dark/boss music. |

### Scope and gaps

The enemy-death sourcing gap is resolved with `Monster SFX.wav` by marcelofg55 (CC0) from [Monster SFX](https://opengameart.org/content/monster-sfx); the in-game cue uses a trimmed version. `player_down` continues to use the existing Kenney sample.

This shortlist is deliberately small and uses six creators/packs plus a single optional boss track. The Kenney SFX pages do not claim dedicated fantasy spell, heal, buff/debuff, critical, miss or countdown sounds. The `magic_cast`, `heal`, `buff`, `debuff`, `miss`, and `critical` cues now use separately sourced short samples (see `assets/audio/CREDITS.md`); `critical` uses `bing1.wav` from BMacZero's CC0 Metal Impact Sounds pack. The music shortlist has no explicit defeat loop or dedicated Guardian boss composition; Kenney loss jingles can serve as defeat stings, and Hope is only a possible boss loop. A dedicated boss/defeat score remains a sourcing gap.

## Cue mapping

“New cue” means a cue name to add to the current `SoundBank` cue set. Candidate filenames are not asserted because the source pages list pack contents but not individual sample names. Select exact files after downloading/auditioning outside this research pass.

| Current cue | Suggested source / selection direction |
|---|---|
| `turn` | Interface Sounds: restrained confirmation/selection tone. |
| `warn` | Interface Sounds: warning/error-like switch; use repeated/countdown timing from the game event, since no dedicated countdown sample is verified. |
| `hit` | RPG sound effects: metal/impact sample; choose a short hit. |
| `vote` | Interface Sounds: confirmation click distinct from ordinary click. |
| `good` | 85 Short music jingles: win/reward candidate; or Glizzy Victory Intro for a larger outcome. |
| `bad` | 85 Short music jingles: lose candidate. |
| `click` | Interface Sounds: button click. |
| `hover` (new) | Interface Sounds: light rollover/switch sample. |
| `cancel` (new) | Interface Sounds: lower-pitched/back-like switch; audition for a clear cancel distinction. |
| `error` (new) | Interface Sounds: negative switch; audition. |
| `countdown_warn` (new) | Interface Sounds short alert, repeated by timer; dedicated countdown asset not verified. |
| `sword_hit` / `weapon_hit` (new) | RPG sound effects: metal/knife sample. |
| `magic_cast` (new) | JaggedStone's Magic Spell SFX, `magical_3.ogg` (CC0). |
| `heal` (new) | leohpaz's 8 Heals and Buffs SFX, `02_Heal_02.wav` (CC-BY 4.0). |
| `buff` (new) | leohpaz's 8 Heals and Buffs SFX, `16_Atk_buff_04.wav` (CC-BY 4.0). |
| `debuff` (new) | leohpaz's 8 Heals and Buffs SFX, `21_Debuff_01.wav` (CC-BY 4.0). |
| `critical` (new) | Metal Impact Sounds: `bing1.wav` by BMacZero (CC0); sharp metallic impact/ring. |
| `miss` (new) | artisticdude's Swishes Sound Pack, `swish-7.wav` (CC0). |
| `enemy_death` (source update) | `Monster SFX.wav` by marcelofg55 from [Monster SFX](https://opengameart.org/content/monster-sfx) (CC0); monster/creature sound selected and trimmed for enemy defeat. |
| `player_down` | Kenney's 50 RPG sound effects pack; existing `player_down.ogg`. |
| `level_up` / `exp_gain` (new) | 85 Short music jingles: ascending/reward candidate. |
| `loot_pickup` / `gem_pickup` (new) | RPG sound effects coin candidate; 85 Short music jingles for a higher-tier gem reward. |
| `victory_sting` / `defeat_sting` (new) | 85 Short music jingles win/lose tags; Glizzy Victory Intro as an expanded victory transition. |
| `music_title` / `music_lobby` (new) | YannZ main menu loopable track (`Ravi de te revoir`); one selection can cover both title and lobby initially. |
| `music_forest` (new) | Glizzy Elf Forest Loop. |
| `music_battle` (new) | Glizzy Battle Loop. |
| `music_guardian` (new) | Hope orchestral loop as a provisional option; dedicated boss score is still a gap. |
| `music_victory` (new) | Glizzy Victory Loop. |
| `music_defeat` (new) | No dedicated defeat loop verified. Use a short Kenney lose jingle then silence/low ambience until a score is sourced. |

## Licence notes and source checks

- The three Kenney items are listed as CC0 on both the publisher's asset pages and the linked OpenGameArt listings. OGA gives exact formats, sizes and optional attribution text for each. CC0 allows commercial use without asking permission; credit is still useful for provenance. [CC0 1.0 deed](https://creativecommons.org/publicdomain/zero/1.0/).
- The Zane Little Music pack page explicitly labels it CC0 and lists its pieces and ZIP size. It does not specify contained codecs; that field remains unverified until the archive can be inspected.
- YannZ's listing explicitly says CC-BY 4.0, specifies loopable menu and in-game tracks, provides OGG/MP3 listings and the requested credit. The page includes a comment thread describing correction/removal of additional restrictions so the page is now CC-BY only; use the published CC-BY attribution and retain the source/license record.
- MintoDog's page explicitly says CC0, loopable, and lists OGG/FLAC file sizes.
- Links above were opened and checked on 2026-10-01. No download links to archives were fetched. The Kenney publisher pages confirm the publisher license/count; OpenGameArt pages provide the detailed file metadata.
- Pixabay/Freesound/itch.io results are omitted from the shortlist: these candidates were not needed after finding suitable direct CC0/CC-BY source pages. Do not infer a blanket site license for user-uploaded assets; verify each item page individually.

## Godot 4 integration note

Godot supports WAV, Ogg Vorbis and MP3 imports. Prefer short WAV samples for frequent SFX and OGG Vorbis for music/long sounds; the Godot import documentation notes the CPU and size trade-offs. Use `AudioStreamPlayer` for non-positional UI/menu/music playback, with `stream` set to the imported resource and `bus` assigned to `SFX` or `Music`. Create those buses in the project audio bus layout and route both to `Master`. Keep `SoundBank.set_volume(volume)` as the master setting if preserving the current single-slider behavior; for independent settings, add per-bus controls and avoid applying the same slider twice. The current method changes the `Master` bus volume/mute only.

Sources: [Godot audio import formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html), [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html), [Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html), and repository `src/client/ui/sound_bank.gd`.

## `CREDITS.md` template

```markdown
# Audio Credits

## Kenney — CC0 1.0
- Interface Sounds: https://opengameart.org/content/interface-sounds
- 50 RPG sound effects: https://opengameart.org/content/50-rpg-sound-effects
- 85 Short music jingles: https://opengameart.org/content/85-short-music-jingles
  Attribution is not required; included for provenance.

## Zane Little Music — CC0
- Glizzy Elf Forest RPG Music Pack: https://opengameart.org/content/glizzy-elf-forest-rpg-music-pack
  Attribution is not required; included for provenance.

## MintoDog — CC0
- Hope (Orchestral battle music): https://opengameart.org/content/hopeorchestral-battle-music
  Attribution is not required; included for provenance.

## YannZ — CC-BY 4.0
- FREE Contemplative Fantasy Music Pack: https://opengameart.org/content/free-contemplative-fantasy-music-pack
- Required credit: Music by YannZ https://yannz41.itch.io Spotify: https://open.spotify.com/intl-it/artist/76CUcHd0t0XViSm9YBbHBw Contact: yziango@gmail.com

## Changes made
- [List any edits, trims, mixes, conversions, or other modifications to the audio files.]
```

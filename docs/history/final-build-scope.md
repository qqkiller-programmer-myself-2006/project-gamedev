# สถานะ Final build (2026-10-02)

ย้ายมาจาก README.md

Goal: every screen and rule matches the AAC reference images ([#47](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/47)).

- **Modes:** online co-op Multiplayer (room code, 1–5 players, AI fills empty slots) and offline **Story mode**
  (one player controls all five, story scenes, chapter cards, Save/Continue; no timers) — ADR-0014.
- **Before the match:** pick Class, Race and Boons (ADR-0013); Skill tree, Prestige and Gems kept per player on the server
  (Cloudflare Worker + D1, `deploy/profile-worker`; the owner deploys it — see its README).
- **Classes:** Swordsman, Archer, Mage, Guardian, Assassin (renamed from Rogue on 2026-09-30; old profiles migrate),
  plus Classless. Hero art from the owner's sprite sheets (`art_source/heroes/`), cut by `tools/art/slice_character_sheet.py`.
- **Rules (ADR-0012):** 7 attributes (STR/DEX/CON/INT/FTH/CHA/LCK), Fight / Items / Focus with Strike and Guard,
  Energy for party and enemies, personal Gold with Transfer, Consumable slot.
- **Journey:** 5 Layers — Layers 1–4 in the forest (Wolf, Thief, Golem, Slime, Goblin), Layer 5 and the boss in a cave
  (Kobold, Skeleton, Giant Spider, Minotaur), painted forest/cave backdrops. Boss and Thornback Boar art pending (#75).
- **UI:** one Navy + Gold theme ([docs/design/ui-style.md](../design/ui-style.md)), 55 code-drawn pixel icons beside labels
  ([docs/design/icons.md](../design/icons.md)), text scale up to Extra-large.
- **Balance** (100 seeds, [docs/design/balance.md](../design/balance.md)): every mode wins 74–93% with bots.
- **Quality:** 362 headless tests; reviews in [docs/review/](../review/).

Older sections below describe earlier milestones; where they say *Rogue*, the class is now *Assassin*.

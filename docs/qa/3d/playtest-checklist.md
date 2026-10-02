# Story Mode Offline — Playtest QA Checklist (T3D-05)

This checklist verifies the offline single-player Story mode journey from launch to completion. It ensures that 3D presentation enhancements (`Home3D`, `Battle3D`, `CutscenePlayer`) integrate smoothly without regressing core RPG rules, input handling, or UI functionality.

---

## Pre-Test Setup & Environments

- [ ] **Engine:** Godot 4.7.2 (`Godot_v4.7.2-stable_win64_console.exe`).
- [ ] **Clean Worktree:** No uncommitted changes or extraneous cache (`git status`).
- [ ] **Import Cache:** Run `godot --headless --path . --import` before launching.
- [ ] **Test Configurations:**
  - Standard 2D Fallback: `godot --path .`
  - 3D Presentation Mode: `godot --path . -- --3d`
  - Playtest Jump (Direct): `godot --path . -- --dev --playtest`

---

## Phase 1: Boot & Home / Title Hub

- [ ] **Boot Performance:** Application launches to interactive state within 3 seconds.
- [ ] **Home Hub Navigation:**
  - **2D Mode:** Title screen displays logo, campfire background, party heroes, and buttons: *Play*, *Settings*, *Quit*.
  - **3D Mode (`Home3D`):** Player character navigates the 3D hub via WASD/Arrow keys, camera tracks smoothly without clipping.
  - Interactive Stations accessible: Story, Battle, Party, Class, Shop, Settings.
- [ ] **Settings Verification:**
  - Text scale toggle (1.0× and 1.4×) scales font without clipping text boxes.
  - Language toggle switches cleanly between Thai (th) and English (en).
  - Reduced motion toggle disables screen shake and particle bursts.

---

## Phase 2: Party Setup (Story Mode)

- [ ] **Story Mode Selection:** Selecting *Story* opens character setup.
- [ ] **Character Slots:** 5 Party slots shown (Arin, Bram, Cora, Dain, and Wren).
- [ ] **Class Assignment:**
  - Can choose Tier 1 Classes: Swordsman, Archer, Mage, Guardian, Assassin.
  - Unassigned slots filled according to `party.ai_class_order`.
  - Wren's identity and loadout conform to ADR-0006/0013.
- [ ] **Race & Boon Selection:**
  - Owned race selection updates derived base attributes.
  - Capacity-limited boons (e.g. *Alert*, *Enervation*) apply without exceedance.
- [ ] **Start Journey:** Confirming setup initializes the single-player match via `StoryLauncher` without network calls.

---

## Phase 3: Prologue & Cutscene Presentation

- [ ] **Prologue Trigger:** Story prologue starts immediately upon match creation.
- [ ] **Presentation Check:**
  - **2D / Text Mode:** `DialoguePanel` displays narrative text and portrait.
  - **3D Mode:** Cutscene player loads Ogg Theora (`.ogv`) clip with audio in sync.
- [ ] **Dialogue Controls:**
  - Space / Enter / Click advances dialogue line-by-line.
  - Skip button dismisses the prologue cleanly without hanging state.
- [ ] **Chapter Card Transition:** Chapter 1 title card displays and auto-dismisses after duration.

---

## Phase 4: Path Voting & Navigation

- [ ] **Single-Player Pacing:** Vote timer does not prematurely force a random choice (human pacing).
- [ ] **Route Options:** Node choices displayed with correct icons and site hints (Combat, Rest, Merchant, Story Event, Class Encounter).
- [ ] **Keyboard Selection:** Keys `[1]`, `[2]`, `[3]` or mouse click registers the route selection immediately.

---

## Phase 5: Combat & Battle View (`BattleView` / `Battle3D`)

- [ ] **Stage Rendering:**
  - **2D Mode:** Renders `BattleToken` sprites, idle animations, and area backdrop.
  - **3D Mode (`Battle3D`):** 3D `SubViewport` renders 3D arena stage while preserving 2D UI overlay.
- [ ] **Turn Order & Action Banner:**
  - Current acting hero highlighted in turn order list.
  - 15-second action window active for the human player slot.
  - Turn banner announces current character turn.
- [ ] **Command Input:**
  - `[1]` or `[F]` **Strike:** Targets valid enemy, plays attack animation, applies DEF/damage calculation.
  - `[2]` **Guard:** Applies DEF boost for the turn.
  - `[O]` **Focus:** Grants +1 Energy and +10% Dodge for 1 turn (costs 0 Energy).
  - `[I]` **Items:** Opens consumable item list; items activate without error.
  - `[3..N]` **Skills:**
    - Energy requirement checked against hero's current Energy.
    - Cooldown tracked properly in character turns.
    - Skill targeting: Single enemy, all enemies, or party allies.
- [ ] **Energy System:**
  - Starts at 1 on Combat Round 1.
  - Increases by +1 per hero turn (capped at 6).
  - Resets between combats.
- [ ] **Enemy Mechanics & Telegraphs:**
  - Enemy energy increments predictably.
  - Boss / Elite telegraph warnings appear before heavy hits (`07_boss_warning`).
- [ ] **Status Effects & DoTs:**
  - Bleed, Poison, Toxin apply stacks and tick damage at start of turn ignoring DEF/RES.
  - Status icons and counter badges accurately displayed above tokens/models.
- [ ] **Combat Conclusion:**
  - HP reduction to 0 triggers defeat/death animation.
  - Victory reward panel appears: EXP awarded to all party members, personal Gold distributed, items sent to Stash.

---

## Phase 6: Camp Encounters (Rest & Merchant)

- [ ] **Rest Camp:**
  - Party HP fully recovered upon entering.
  - **Stat Allocation:** Unspent stat points can be added to attributes (STR, DEX, CON, INT, FTH, CHA, LCK).
  - **Gear Management:** 8 gear slots (Helmet, Chest, Legs, Boots, Weapon, Charm ×3) allow equip/unequip from shared Stash.
  - **Crafting:** Recipes convert collected materials into consumables or gear.
  - **Ready Check [R]:** Pressing `[R]` marks player ready and advances to next layer.
- [ ] **Merchant Camp:**
  - Items in store have clear Gold pricing.
  - Purchases deduct from character's personal Gold.
  - Ready button `[R]` closes store when finished.

---

## Phase 7: Story Events & Lore Clues

- [ ] **Story Encounters:** Dialogue prompts present narrative choices.
- [ ] **Story Clues:** Collecting a clue increments the clue log count and stores persistent clue metadata.

---

## Phase 8: Class Encounter & Challenges

- [ ] **Challenge Arena:** Non-lethal duel against trainer within round limit.
- [ ] **Class Offer:** Passing the challenge offers class adoption [Y/N] to eligible characters.
- [ ] **Post-Challenge Restoration:** All character HP and statuses reset to pre-challenge state.

---

## Phase 9: Guardian Boss (Layer 5)

- [ ] **Layer 5 Boss Encounter:** Transition into boss arena.
- [ ] **Boss Mechanics:**
  - Multi-round combat with boss telegraph warnings.
  - High damage moves require Guard or Focus mitigation.
- [ ] **Boss Defeat:** Boss death sequence initiates final match resolution.

---

## Phase 10: Match Summary & Persistence

- [ ] **Victory / Defeat Screen:**
  - Final Gems calculated and stored in local profile.
  - Story Clues count displayed.
  - EXP and levels summarized.
  - Return button navigates back to Home / Title Hub cleanly.
- [ ] **Save / Continue Check:**
  - Mid-journey layer progress saves via `StorySave`.
  - Title screen *Continue* option restores party state, stash, and current layer correctly.

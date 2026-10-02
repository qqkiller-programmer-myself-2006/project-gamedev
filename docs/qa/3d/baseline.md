# 3D Vertical Slice — 2D Baseline QA Report (T3D-05)

- **Date:** 2026-10-03
- **Task ID:** T3D-05
- **Branch:** `ai/3d-agy2`
- **Base Commit:** `bd22113` (branched from `origin/main` `17f393b`)
- **Godot Version:** 4.7.2-stable official (`D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`)
- **Renderer:** `gl_compatibility` (OpenGL 3.3 / Compatibility)
- **Primary GPU:** NVIDIA GeForce RTX 4050 Laptop GPU (Driver 617.14)
- **Display Resolution:** 1280×720 (UI canvas items expands to window size)

---

## 1. Test Suite Baseline

Full test suite execution status before introducing 3D presentation code:

| Test Group | Tests Run | Passed | Failed | Duration | Command |
|---|---|---|---|---|---|
| **Headless Unit Suite** | 487 | 487 | 0 | 65.90s | `godot --headless --path . -s tests/run_tests.gd` |
| **QA 3D Smoke Suite** | 2 | 2 | 0 | 1.39s | `godot --headless --path . -s tests/run_tests.gd -- --filter=test_qa3d` |
| **Total Unit Tests** | **489** | **489** | **0** | **~67s** | `tools/run_tests.sh` |
| **Smoke Layout Scripts** | 8 | 8 | 0 | ~35s | Automated in `tools/run_tests.sh` |

### Smoke Scripts Verified
1. `camp_focus_smoke`: Focus retention and keyboard shortcuts during camp search and ready checks.
2. `dialogue_log_smoke`: 4 scale and resolution combinations (1280×720, 1920×1080 at 1.0× and 1.4×).
3. `menu_position_smoke`: 4 scale and resolution combinations for menu placements.
4. `t150_154_large_text_layout_smoke`: Large text layout compliance for camp and battle HUD at 1.45× text scale.
5. `t35_layout_smoke`: 6 resolution and viewport scale combinations passed.
6. `t42_vote_summary_layout_smoke`: Voting and summary panel minimum layouts.
7. `t46_skill_menu_layout_smoke`: English and Thai localized battle skill menu layout checks.
8. `t88_skill_badge_layout`: Battle skill badges layout at various text scales.

> [!NOTE]
> All 489 unit tests and 8 smoke layout scripts passed with 0 failures on the baseline branch.

---

## 2. Boot Time Baseline

Boot metrics measured using `tools/dev/qa3d_perf.gd` and OS execution monitors:

| Metric | Measured Value | Notes |
|---|---|---|
| **Cold Client Launch (Windowed)** | ~2,100 ms | Time from process launch to first rendered frame (`Measure-Command`) |
| **Engine Startup to Scene Init** | 1,913 ms | `Time.get_ticks_msec()` at scene `_initialize()` |
| **Scene Ready Time** | < 1 ms | `ClientApp` initialization and UI assembly |
| **Headless Server Cold Boot** | ~1,000 ms | Headless authoritative `GameServer` listening on ws port |

---

## 3. Performance & Rendering Baseline (2D Title & Client App)

Measured using `tools/dev/qa3d_perf.gd` over 120 sampled frames (with 20 warmup frames):

```json
{
  "fps_metrics": {
    "fps_average": 371.8,
    "fps_min": 329.7,
    "fps_max": 480.0,
    "fps_1percent_low": 335.0
  },
  "frame_time_ms": {
    "avg": 2.6,
    "min": 2.0,
    "max": 3.0,
    "p50": 2.8,
    "p95": 2.8,
    "p99": 3.0
  },
  "rendering_metrics": {
    "draw_calls_avg": 249,
    "draw_calls_max": 249,
    "objects_avg": 565,
    "primitives_avg": 6057
  },
  "memory_metrics_mb": {
    "static_current": 67.0,
    "static_peak": 79.6
  }
}
```

### Performance Targets for 3D Slice Merges
- **Target Framerate:** ≥ 60 FPS on desktop (frame time ≤ 16.6 ms).
- **Target 1% Low:** ≥ 45 FPS (frame time p99 ≤ 22.2 ms).
- **Draw Call Budget:** Draw calls in `Home3D` and `Battle3D` should stay under 500 per frame on `gl_compatibility`.
- **Memory Footprint:** Static memory under 256 MB.

---

## 4. Visual Baseline: 2D Story Mode Flow

Screenshots captured via `tools/dev/ui_preview.gd` and `tools/dev/story_preview.gd` are archived in `docs/qa/3d/screenshots/`:

| Step / Screen | Screenshot Filename | Description & Baseline Elements |
|---|---|---|
| **1. Title Screen** | `docs/qa/3d/screenshots/01_title.png` | 2D campfire, party members standing, logo, version tag, Play / Settings / Quit buttons. |
| **2. Party Setup** | `docs/qa/3d/screenshots/02_story_party_setup.png` | Story party setup showing Arin, Bram, Cora, Dain, and Wren slots with Class picks. |
| **3. Class Picker** | `docs/qa/3d/screenshots/02_story_party_picker.png` | Class selection modal with Swordsman, Archer, Mage, Guardian, Assassin. |
| **4. Story Prologue** | `docs/qa/3d/screenshots/03_story_prologue.png` | Opening story narrative dialogue box with character portraits and dialogue advance. |
| **5. Chapter Card** | `docs/qa/3d/screenshots/04_chapter_card.png` | Chapter 1 title card transition banner with golden border. |
| **6. Story Battle Stage** | `docs/qa/3d/screenshots/05_story_battle.png` | 2D stage with Forest backdrop, 5 hero tokens, enemy tokens, turn notice, bottom action bar. |
| **7. Combat Skills** | `docs/qa/3d/screenshots/05b_combat_skills.png` | Action window active: Strike [1/F], Guard [2], Focus [O], Items [I], and Class Skills. |
| **8. Camp Rest** | `docs/qa/3d/screenshots/06_camp_rest.png` | Camp rest encounter: Party HP restoration, Stat points allocation, 8-slot Gear, Crafting. |
| **9. Camp Merchant** | `docs/qa/3d/screenshots/07_camp_merchant.png` | Camp shop encounter: Item catalogue, price in shared party gold, Ready check [R]. |
| **10. Victory Summary** | `docs/qa/3d/screenshots/08_summary_victory.png` | Victory summary screen with earned Gems, Story Clues collected, EXP gained, and Return button. |

---

## 5. Known Engine Warnings & Baseline Observations

1. **Focus Grab Warning:**
   ```text
   WARNING: This control can't grab focus. Use set_focus_mode() and set_focus_behavior_recursive() to allow a control to get focus.
      at: grab_focus (scene/gui/control.cpp:3011)
      res://src/client/match/battle/battle_view.gd:1286
   ```
   - Triggered when refreshing the battle view while certain buttons are not in focus mode. Does not affect gameplay.

2. **Console Resource/RID Leak Warnings at Exit:**
   ```text
   WARNING: CanvasItem / ObjectDB instances leaked at exit.
   ERROR: RID allocations of type DummyTexture / ShapedTextDataAdvanced leaked at exit.
   ```
   - Standard Godot 4.7 internal driver cleanup notices when shutting down headless or console instances; known benign in baseline.

3. **Concurrency Requirement:**
   - Full test suite should only be run when no other Godot processes are actively running to avoid memory exhaustion (system RAM 15.7 GB).

4. **Story Mode Offline Architecture:**
   - Story mode does not invoke `GameServer` or websocket transport. It executes via `LocalConnection` and `StoryLauncher`, ensuring single-player offline operation remains isolated from multiplayer network logic.

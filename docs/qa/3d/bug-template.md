# 3D Slice Bug Report Template

Use this template to report issues, visual anomalies, or performance regressions found during 3D slice development and playtesting.

---

## Issue Summary

**Title:** `[Area] Brief descriptive summary of the bug`  
**Reported By:** `Agy2 (QA)` / `[Name]`  
**Date:** `YYYY-MM-DD`  
**Git Commit:** `[commit-hash]`  
**Assigned Owner:** `Codex1` (wiring/adapters) / `Claude1` (Battle3D) / `Claude2` (Home3D/Cutscenes) / `Agy1` (Assets)  

---

## Classification

- **Severity:**
  - [ ] **P0 — Blocker:** Crash, freeze, infinite loop, inability to progress Story mode.
  - [ ] **P1 — Critical:** Core RPG mechanics broken, missing battle stage, input unresponsive.
  - [ ] **P2 — Major:** Visual artifact, incorrect model/animation, UI clipping, camera glitch.
  - [ ] **P3 — Minor:** Text misalignment, polish, timing offset under 0.5s.
- **Subsystem:**
  - [ ] `Home3D` (3D Hub, stations, player navigation)
  - [ ] `Battle3D` (3D battle arena, model anchors, camera)
  - [ ] `PresentationAdapter` (State / cue transformation)
  - [ ] `CutscenePlayer` (`.ogv` playback, branching cutscenes)
  - [ ] `StoryDirector` / Flow wiring
  - [ ] `UI / HUD` (Control overlays, action buttons, chips)
  - [ ] `Assets / Models / VFX` (`MANIFEST.3d.json`)
  - [ ] `Performance / Memory` (FPS drop, draw call surge, leak)

---

## Test Environment

- **OS:** Windows 11 / Linux
- **GPU:** `[e.g. NVIDIA RTX 4050 Laptop / Intel Iris Xe]`
- **Godot Version:** `Godot 4.7.2-stable official`
- **Rendering Driver:** `gl_compatibility`
- **Execution Mode:**
  - [ ] 3D Mode (`--3d`)
  - [ ] 2D Fallback (default)
  - [ ] Playtest Jump (`--dev --playtest`)
- **Display Resolution & Scale:** `1280x720` / `1920x1080` (Scale: `1.0` / `1.4`)
- **Language:** Thai (`th`) / English (`en`)

---

## Preconditions & Run Configuration

- **Random Seed:** `[e.g. --seed=11]`
- **Party Loadout:** `[e.g. Swordsman, Archer, Mage, Guardian, Assassin]`
- **Active Layer & Node:** `[e.g. Layer 2, Node 3 (Combat)]`

---

## Steps to Reproduce

1. Launch the game with command: `godot --path . -- --3d`
2. Navigate to ...
3. Select ...
4. Trigger ...

---

## Expected Behavior

Clear description of what should happen according to `CONTEXT.md`, `ADR-0015`, and the 2D baseline.

---

## Actual Behavior

Clear description of what actually occurred (e.g. model failed to load, camera clipped under floor, button unresponsive).

---

## 2D Regression Check

- Does this issue reproduce in standard 2D mode (without `--3d`)?
  - [ ] Yes (Existing core game bug — assign to Codex1)
  - [ ] No (3D presentation regression only)

---

## Performance & Diagnostic Data

- **FPS / Frame Time:** `[e.g. Dropped from 370 FPS to 18 FPS]`
- **Draw Calls:** `[e.g. Increased to 1,200 draw calls]`
- **Memory Static:** `[e.g. 180 MB]`

---

## Visual Evidence

- Screenshot or video path: `docs/qa/3d/screenshots/[filename].png`

---

## Console Log & Stack Trace

```text
[Paste terminal output, engine errors, and GDScript backtraces here]
```

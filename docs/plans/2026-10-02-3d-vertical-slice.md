# แผน 3D vertical slice (Story mode offline) — 5 วัน

ตัดสินใจใน [ADR-0015](../adr/0015-3d-presentation-offline-story-slice.md) สถานะงานจริงอยู่ที่ `.ai/checkpoint.md`

## Worktree / branch (แตกจาก `origin/main` 17f393b)

Base ของ worktree ทั้งหมด: `D:/UserData/Documents/LRU/Game Dev/`

| Worker | Worktree | Branch | บทบาท |
| --- | --- | --- | --- |
| Claude Main | `Project-GameDev/.claude/worktrees/close-claude-codex-issues-d72ea7` | `claude/game-project-lead-9a9ecc` | วางแผน/review/merge |
| Claude1 | `Project-GameDev-Agents/Claude1` | `ai/3d-claude1` | Battle3D (เวที, กล้อง, anchor) |
| Claude2 | `Project-GameDev-Agents/Claude2` | `ai/3d-claude2` | Home3D, CutscenePlayer node |
| Codex1 | `Project-GameDev-Agents/Codex1` | `ai/3d-codex1` | adapter, router, loader, entry hook, HUD logic, test |
| Agy1 | `Project-GameDev-Agents/Agy1` | `ai/3d-agy1` | asset/animation pipeline, manifest, คลิป |
| Agy2 | `Project-GameDev-Agents/Agy2` | `ai/3d-agy2` | QA, playtest, screenshot, perf |

กฎ: รัน executor พร้อมกัน ≤ 2 ตัว (RAM 15.7 GB); full test suite รันตอนไม่มี Godot ตัวอื่นเปิด; ห้าม `git add -A`; ไม่มี `.tscn` ที่ owner > 1 คน
ขอบเขต: **Story mode offline เท่านั้น** (ADR-0014/0015) — Multiplayer ห้ามพัง แต่ไม่ต้องทำ 3D ให้มัน

## Ownership (ห้ามแตะ = ต้องขอ Main)

| Owner | แก้ได้ | ห้ามแตะ |
| --- | --- | --- |
| Claude2 | `src/client/home3d/**`, `src/client/cutscene/player/**` | `src/match/**` `src/net/**` `src/server/**` `content/forest.json` และไฟล์ entry hook |
| Claude1 | `src/client/match/battle3d/**` | เหมือนข้างบน + `home3d/**` |
| Codex1 | `src/client/presentation/**`, `src/client/cutscene/router/**`, `content/cutscenes/**`, test ของงาน 3D, **entry hook (เจ้าของคนเดียว):** `title_screen.gd`, `match_screen.gd`, `battle_view.gd`, `story_director.gd`, `launch_options.gd` | `src/match/**` และโฟลเดอร์ 3D ของ Claude1/2 |
| Agy1 | `assets/models,video,animations,ui/**`, `art_source/**`, `tools/art/**`, `tools/video/**`, `docs/art/**`, `assets/MANIFEST.3d.json` | `src/**` ทั้งหมด |
| Agy2 | `docs/qa/3d/**`, `tools/dev/qa3d_*`, `tests/regression/**` (เพิ่มไฟล์ใหม่เท่านั้น) | แก้โค้ดตรง — ส่ง bug ให้ Codex1 |
| Main | `.ai/**`, `docs/adr`, `docs/plans`, review/merge | โค้ดจริง (ยกเว้นติดโควตา) |

## Milestone

| วัน | เล่นได้ | งาน |
| --- | --- | --- |
| D1 | เดินในฮับ 3D | T3D-01 adapter, T3D-02 Home3D, T3D-04 pipeline, T3D-05 QA baseline |
| D2 | Battle3D เปิดจาก Story จริง | T3D-03 Battle3D, entry hook (title + battle), HUD skeleton |
| D3 | Cutscene แตก branch | router + player + เชื่อม StoryDirector, คลิป .ogv ชุดแรก |
| D4 | หน้าตา/แอนิเมชัน | แทน placeholder ด้วย asset AI, VFX, HUD ดำ/แดง/ขาว |
| D5 | export ได้ | integration, เล่นจบ Story, regression, export Web+Windows |

## กราฟงาน

```
ADR-0015 (Main) ─┬─ T3D-01 adapter (Codex1) ──┬─► T3D-03 Battle3D (Claude1) ─► battle hook + HUD (Codex1)
                 ├─ T3D-02 Home3D (Claude2) ──────► title hook (Codex1, หลัง T3D-02)
                 ├─ T3D-04 asset pipeline (Agy1) ─► คลิป/โมเดล/UI ─► integrate D4
                 └─ T3D-05 QA baseline (Agy2) ────► ทุก merge
D3: router (Codex1) ─► player node (Claude2) ─► StoryDirector hook (Codex1)
```

เริ่มก่อน: **T3D-01 (Codex1)** และ **T3D-02 (Claude2)** ขนานกันได้ (ไม่แตะไฟล์ร่วม) พร้อม T3D-04/05 ถ้า slot ว่าง (≤ 2 ตัวพร้อมกัน)
T3D-03 ใช้ contract ร่างใน spec ได้เลย ไม่ต้องรอ merge T3D-01

## Handoff format (ทุกงาน)

branch + commit sha, ไฟล์ที่แก้, ผล test (ตัวเลข passed), ภาพ/วิดีโอหลักฐานถ้ามี UI, สิ่งที่ยังไม่ทำ, ข้อสงสัยสำหรับ Main
**ห้าม push; commit เฉพาะไฟล์ใน allowed paths** (Main ตรวจ diff แล้ว merge)

## Test (ทุกงาน)

```bash
export GODOT="D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import      # หลังเพิ่ม class_name ใหม่
bash tools/run_tests.sh                     # ต้องผ่านทั้งหมด ห้ามลดจำนวน
```

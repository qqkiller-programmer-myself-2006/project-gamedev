# T3D-01 — PresentationAdapter + flag `--3d`

- **Task ID:** T3D-01
- **Owner:** Codex1 (`ai/3d-codex1`, worktree `Project-GameDev-Agents/Codex1`)
- **Dependencies:** ไม่มี (เริ่มได้ทันที)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/plans/2026-10-02-3d-vertical-slice.md` (handoff/test ตามแผน)

## Goal
สร้าง adapter ฟังก์ชันล้วนที่แปลง match view + event เป็น presentation state/cue ให้ Home3D/Battle3D/Cutscene ใช้ และเพิ่ม flag `--3d` ใน `LaunchOptions`

## Why
ตัดการผูกฉาก 3D กับ snapshot ดิบ ทดสอบ headless ได้ และ 2D เดิมไม่ต้องเปลี่ยน

## Allowed paths
`src/client/presentation/**`, `src/app/launch_options.gd`, `tests/client/presentation/**`

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/forest.json`, `battle_view.gd`, `match_screen.gd`, `title_screen.gd` (hook เป็นงานถัดไป), `home3d/`, `battle3d/`

## Contract (ร่าง — ปรับได้ แต่ต้องรายงานการเปลี่ยน)
`BattlePresentation.state(view: Dictionary) -> Dictionary`
```
{ units: [{id, side: "party"|"enemy", slot: int, class_key: String, name, hp, max_hp, energy, alive: bool}],
  current_actor: String, mode: String, targets: [String] }
```
`BattlePresentation.cues(event: Dictionary) -> Array` — แต่ละ cue: `{type: "strike"|"skill"|"focus"|"item"|"guard"|"hurt"|"die"|"heal", actor, target, skill_id, amount, crit: bool}`
ที่มาของ event: ดู `BattleView.handle_event` และ `MatchScreen.describe` ใช้ชื่อ Strike/Skill/Focus/Item/Guard ตาม `CONTEXT.md` (ชื่อระบบ attack/defend แมปเป็น strike/guard)
`LaunchOptions.use_3d(options) -> bool` อ่าน `--3d`

## Acceptance criteria
1. adapter เป็น `RefCounted`/static ไม่มี Node ไม่แตะ scene tree
2. test ครอบคลุม: party ครบ 5 + enemy หลายตัว, unit ตาย, ทุกชนิด cue, event ที่ไม่รู้จัก → `[]` (ไม่ crash)
3. ไม่มี `--3d` เกมเหมือนเดิมทุกประการ; test suite เดิมผ่านทั้งหมด

## Test commands
ตามแผน (`--import` แล้ว `bash tools/run_tests.sh`)

## Expected output
ไฟล์ใหม่ + test + `src/client/presentation/README.md` บอก contract สุดท้าย

## Handoff format
ตามแผน: branch+sha, ไฟล์ที่แก้, ผล test, สิ่งที่ยังไม่ทำ, ข้อสงสัย; ห้าม push

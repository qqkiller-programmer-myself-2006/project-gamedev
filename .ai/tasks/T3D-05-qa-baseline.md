# T3D-05 — QA baseline + 3D smoke/perf harness

- **Task ID:** T3D-05
- **Owner:** Agy2 (`ai/3d-agy2`, worktree `Project-GameDev-Agents/Agy2`)
- **Dependencies:** ไม่มี (baseline เริ่มได้ทันที; harness ใช้จริงเมื่อมี Home3D/Battle3D)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/plans/2026-10-02-3d-vertical-slice.md`

## Goal
(1) บันทึก baseline ของเกม 2D ปัจจุบัน: จำนวน test ที่ผ่าน, ภาพ `tools/dev/ui_preview.gd` ของ Story flow (title→party→battle→camp), เวลา boot; (2) checklist playtest Story offline (เริ่ม→จบ) และแม่แบบ bug report; (3) สคริปต์วัด perf (FPS/frame ms) สำหรับฉาก 3D

## Why
ต้องรู้ว่า 3D ไม่ทำ regression ของสิ่งที่เล่นได้อยู่แล้ว และมีหลักฐานก่อน/หลังทุก merge

## Allowed paths
`docs/qa/3d/**`, `tools/dev/qa3d_*` (ไฟล์ใหม่), `tests/regression/**` (ไฟล์ใหม่เท่านั้น)

## Forbidden paths
`src/**`, `content/**`, ไฟล์ test/tools เดิมทุกไฟล์ (ห้ามแก้) — พบบั๊กให้เขียน report ส่ง Codex1

## Acceptance criteria
1. `docs/qa/3d/baseline.md`: ตัวเลข test, commit, ภาพ, เวลา boot, ข้อสังเกต
2. `docs/qa/3d/playtest-checklist.md` + `bug-template.md`
3. `tools/dev/qa3d_perf.gd` รันได้และพิมพ์ผลเป็น JSON
4. ไม่แก้ไฟล์นอก allowed paths; full suite รันเฉพาะตอนไม่มี Godot ตัวอื่นเปิด

## Test commands
ตามแผน

## Expected output
เอกสาร + สคริปต์ + รายงาน baseline

## Handoff format
ตามแผน; ห้าม push

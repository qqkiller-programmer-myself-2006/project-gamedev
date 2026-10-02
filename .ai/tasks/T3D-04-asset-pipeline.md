# T3D-04 — Asset/animation/video pipeline + manifest

- **Task ID:** T3D-04
- **Owner:** Agy1 (`ai/3d-agy1`, worktree `Project-GameDev-Agents/Agy1`)
- **Dependencies:** ไม่มี
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/plans/2026-10-02-3d-vertical-slice.md`

## Goal
วางระบบ asset ที่ทำซ้ำได้: โครงโฟลเดอร์, `assets/MANIFEST.3d.json`, style guide (ดำ/แดง/ขาว anime RPG สอดคล้องตัวละครใน `CONTEXT.md`: Arin, Bram, Cora, Dain, Wren), สคริปต์แปลง mp4→`.ogv` (Theora ผ่าน ffmpeg ที่มีใน PATH), ไฟล์ placeholder (คลิปสีล้วนสั้น 3 คลิปสำหรับกราฟ branch ทดสอบ, texture/ไอคอน UI พื้นฐาน), prompt template สำหรับ concept/portrait/UI/texture/คลิป

## Why
ให้ Claude1/2 และ Codex1 มี asset ใช้ตั้งแต่ D2–D3 โดยไม่รอของ AI จริง และของจริงแทนได้ผ่าน manifest ไม่ต้องแก้โค้ด

## Allowed paths
`assets/models/**`, `assets/video/**`, `assets/animations/**`, `assets/ui/**`, `assets/MANIFEST.3d.json`, `art_source/**`, `tools/art/**`, `tools/video/**`, `docs/art/**`

## Forbidden paths
`src/**`, `tests/**`, `content/**`, `export_presets.cfg`, `project.godot`

## ข้อกำหนด
- manifest: `{id, kind: model|portrait|texture|ui|video|anim, path, source: placeholder|ai|hand, tool, prompt, seed, date, license_note, used_by}`
- คลิป ≤ 10 วินาที, ≤ ~5 MB, 1280×720, 24–30 fps; `tools/video/convert_to_ogv` รันซ้ำได้ ไม่เขียนทับต้นฉบับ
- ต้นฉบับหนักอยู่ `art_source/` (มี `.gdignore`) ไม่ import เข้า Godot
- งานที่ต้องใช้บัญชี/เครดิตเครื่องมือ AI ภายนอก → เขียนเป็นรายการ "ต้องให้เจ้าของงานทำ" ใน handoff ห้ามทำเอง
- ห้ามให้ AI asset ตัดสิน logic ของเกม

## Acceptance criteria
1. `tools/art/check_manifest.py` ผ่าน (path มีจริง, field ครบ)
2. `.ogv` placeholder เล่นใน Godot 4.7 ได้ (บอกวิธีทดสอบ) ขนาดตามเกณฑ์
3. `docs/art/style-guide.md` + prompts ครบ; ตารางรายการ asset ที่ต้องผลิตจริงสำหรับ D4 (id/ขนาด/จำนวน)

## Test commands
`python tools/art/check_manifest.py` และเปิด `.ogv` ใน Godot

## Expected output
ไฟล์ + รายการ "ต้องให้เจ้าของงานทำ" + ผลตรวจ manifest

## Handoff format
ตามแผน; ห้าม push

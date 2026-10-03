# T4S-01a — Support/Healer: effect ใหม่ + class + skill + test

- **Task ID:** T4S-01a (ส่วนที่ 1 จาก 3 ของ T4S-01; ดูภาพรวมใน `T4S-01-classes-support-healer.md`)
- **Owner:** Agy1 (agy, `ai/3d-agy1`, worktree `Project-GameDev-Agents/Agy1`) — fallback: Codex
- **Dependencies:** ไม่มี
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0016-story-reboot-new-classes-auto-battle.md`, `docs/adr/0009-energy-and-cooldown-skills.md`, `docs/adr/0010-rogue-class-and-dot-status-effects.md`, `content/README.md`, โค้ด effect เดิมใน `src/match/**`

## Goal
เพิ่ม Class Tier 1 สองอาชีพ `support` และ `healer` ใน `content/forest.json` พร้อม Skill และ effect ใหม่ที่ MatchServer รันได้จริง

- **Healer** (≥ 3 Skill): ฮีลเดี่ยว, ฮีลทั้ง Party, cleanse (ล้าง Status effect ฝั่งลบ เช่น DoT) มี Strike ตามปกติ
- **Support** (≥ 3 Skill): บัฟเพื่อน (เช่น เพิ่มพลังโจมตี/ป้องกัน มี duration), ดีบัฟศัตรู (มี duration), ให้ Energy +N แก่เพื่อนหนึ่งคน (ไม่เกิน cap 6)

## Scope ของงานนี้ (ทำเท่านี้)
1. effect ชนิดใหม่ใน `src/match/**` เท่าที่จำเป็น: `heal` แบบเป้ากลุ่ม (ถ้ายังไม่มี), `cleanse`, `grant_energy` ใช้โครงสร้าง effect/status เดิม ห้ามเปลี่ยนพฤติกรรม effect เดิม
2. class `support`, `healer` + skills + statuses ใน `content/forest.json` (ข้อความอังกฤษตาม ADR-0007) growth Attribute ตามบทบาท (Healer เน้น fth/int, Support เน้น cha/dex) ตามระบบ ADR-0012
3. ไอคอน: ใช้ id ไอคอนที่มีอยู่เป็น placeholder ห้ามแก้ `assets/**`
4. test ใหม่ใน `tests/match/`: ฮีลเดี่ยว, ฮีลกลุ่ม, cleanse ล้าง status จริง, grant_energy ไม่เกิน 6, บัฟ/ดีบัฟมีผลและหมดตาม duration, Energy cost/cooldown ตาม ADR-0009
5. ปรับ test เดิมที่ผูกกับ "จำนวน Class = 5"/รายการ Class ให้เป็น 7 (รายงานทุกไฟล์)
6. i18n: เพิ่มคำแปลไทยของชื่อ/คำอธิบาย Class และ Skill ใหม่ใน `i18n/th.po` (+ `messages.pot` ถ้าระบบต้องการ) และ `docs/design/thai-glossary.md` (Support = ซัพพอร์ต, Healer = ฮีลเลอร์)
7. `CONTEXT.md`: แก้รายการ Tier 1 Class เป็น 7 อาชีพ + คำนิยามสั้น

**ไม่ทำในงานนี้:** AI preset, Class Encounter, skill tree meta (ไป T4S-01b), balance/simulate (ไป T4S-01c)

## Allowed paths
`content/forest.json`, `src/match/**`, `tests/match/**`, `i18n/**`, `CONTEXT.md`, `docs/design/thai-glossary.md`, ไฟล์ test เดิมเฉพาะที่ผูกกับจำนวน/รายการ Class

## Forbidden paths
`src/client/**`, `content/story_mode.json`, `src/profile/**`, `src/net/**`, `src/server/**`, `assets/**`

## Acceptance criteria
1. `forest.json` มี class/skills/statuses ของทั้งสองอาชีพครบตามข้างบน และโหลดผ่าน validation เดิม
2. test ใหม่ครบข้อ 4 และผ่าน
3. `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` เขียวทั้งหมด (จำนวน test ไม่ลด) — รัน `--headless --path . --import` ก่อนถ้าเพิ่ม `class_name`
4. test_thai_catalog ผ่าน

## Handoff format
branch + sha, ไฟล์ที่แก้ (รวม test เดิมที่ปรับ), ผล test (จำนวน passed/failed), id ไอคอน placeholder ที่ใช้, ข้อสงสัย; commit บน `ai/3d-agy1` ได้ ห้าม push

# T4S-01 — Class ใหม่: Support และ Healer (server + content + test)

- **Task ID:** T4S-01
- **Owner:** Agy1 (agy, `ai/3d-agy1`, worktree `Project-GameDev-Agents/Agy1`) — fallback: Codex
- **Dependencies:** ไม่มี (งาน server/content ล้วน; ไม่แตะ client ยกเว้น i18n)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0016-story-reboot-new-classes-auto-battle.md`, `docs/adr/0009-energy-and-cooldown-skills.md`, `docs/adr/0010-rogue-class-and-dot-status-effects.md`, `docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md`, `docs/design/balance.md`, `content/README.md`

## Goal
เพิ่ม Class Tier 1 สองอาชีพ **`support`** (ซัพพอร์ต) และ **`healer`** (ฮีลเลอร์) เข้า `content/forest.json` และ `MatchServer` ให้ครบเหมือน Class เดิม (Swordsman, Archer, Mage, Guardian, Assassin)

บทบาท (เจ้าของงานยืนยันแล้ว):
- **Healer** ฟื้น HP และล้าง Status effect (ต้องมีทั้งฮีลเดี่ยว ฮีลกลุ่ม และ cleanse; ไม่ใช่นักสู้ แต่มีท่าโจมตีพื้นฐาน Strike ได้ตามปกติ)
- **Support** บัฟ/ดีบัฟ และเพิ่ม Energy ให้เพื่อน (ต้องมีท่าบัฟสถานะ, ท่าดีบัฟศัตรู, ท่าให้ Energy +N แก่เพื่อน)

## Why
เนื้อเรื่องใหม่ (`docs/design/story-bible-draft.md`) ต้องการอาชีพเหล่านี้สำหรับเค้กและเมย์; Multiplayer เข้าถึงได้เหมือนกัน (ไม่แยกระบบ)

## Allowed paths
`content/forest.json`, `src/match/**`, `tests/match/**`, `tests/shared/**` (ถ้าจำเป็น), `docs/design/balance.md`, `CONTEXT.md` (แก้เฉพาะรายการ Tier 1 Class ให้เป็น 7 อาชีพ และเพิ่มคำนิยาม Support/Healer), `docs/adr/0010-rogue-class-and-dot-status-effects.md` (เพิ่มหมายเหตุอาชีพใหม่), `docs/design/thai-glossary.md` (เพิ่ม Support = ซัพพอร์ต, Healer = ฮีลเลอร์), `i18n/**`, `tools/dev/simulate*` (ถ้าต้องปรับ), ไฟล์ใหม่ใต้ `tests/match/`

## Forbidden paths
`src/client/**` (ยกเว้นไม่มี), `content/story_mode.json`, `src/profile/**`, `src/net/**`, `src/server/**`, `assets/**`, ไฟล์ test เดิม (ปรับได้เฉพาะที่ผูกกับ "จำนวน Class = 5" หรือรายการ Class ให้เป็น 7 และต้องรายงานทุกไฟล์ที่แก้)

## ข้อกำหนด
- ทำเป็น **ข้อมูลใน `content/forest.json`** ให้มากที่สุด (classes, skills, statuses, class_encounters, meta class trees, `party.ai_class_order` ถ้าเกี่ยวข้อง) แก้ rules ใน `src/match/**` เฉพาะที่จำเป็น (เช่น effect ชนิดใหม่: cleanse, grant_energy, heal กลุ่ม) และต้องมี test ต่อ effect ใหม่
- Skill ใช้ Energy และ cooldown ตาม ADR-0009; ทุก Skill มี id, ชื่อ, คำอธิบาย (อังกฤษใน content ตาม ADR-0007; แปลไทยใน `i18n/th.po`)
- เพิ่ม **AI behavior preset** สำหรับทั้งสองอาชีพให้ `PartyAi` เล่นเองได้สมเหตุสมผล (Healer ฮีลคนที่ HP ต่ำสุดก่อน/cleanse เมื่อมี DoT; Support บัฟก่อนคอมแบตหนัก/ให้ Energy แก่ตัวที่ใช้ Skill แพง)
- เพิ่ม **Class Encounter** (ผู้ฝึกสอน) และ **skill tree** ของ meta (ADR-0013) ให้ทั้งสองอาชีพให้เหมือนอาชีพเดิม
- ไอคอน/sprite: **ใช้ id ไอคอนที่มีอยู่เป็น placeholder** (บันทึกใน handoff ว่าต้องวาดใหม่ภายหลัง) ห้ามแก้ `assets/**`
- Derived stat / Attribute: กำหนด growth ให้สอดคล้องบทบาท (Healer เน้น fth/int, Support เน้น cha/dex ตามที่เหมาะ) ใช้ระบบ ADR-0012 เดิม
- **Balance:** ต้องรัน `simulate` ตามคู่มือ `docs/design/balance.md` ให้ win rate ของโหมด default / loadout / story อยู่ในช่วงเดิม (Story 70–92%) หลังเพิ่ม Class ใหม่ในปาร์ตี้ AI และบันทึกตัวเลขลง `docs/design/balance.md`
- ห้ามเปลี่ยนกติกา Match เดิมที่ไม่เกี่ยวข้อง ห้ามลดจำนวน test

## Acceptance criteria
1. `content/forest.json` มี `support` และ `healer` ครบ: class, skills (Healer ≥ 3, Support ≥ 3), statuses ที่ต้องใช้, class encounter, skill tree
2. test ใหม่ครอบคลุม: ฮีลเดี่ยว/กลุ่ม, cleanse ล้าง Status effect จริง, grant Energy (ไม่เกิน cap 6), บัฟ/ดีบัฟมีผลและหมดตาม duration, AI เล่นอาชีพใหม่ได้โดยไม่ error, Class Encounter ของทั้งสองอาชีพทำงาน
3. เทสต์เดิมทั้งหมดผ่าน (ปรับได้เฉพาะที่ผูกกับจำนวน/รายการ Class) และ `bash tools/run_tests.sh` เขียว
4. ผล balance: ตัวเลขชนะต่อโหมดอยู่ในเป้า (หรือรายงานตามจริงถ้าไม่ถึง พร้อมสิ่งที่ลองแล้ว)
5. `CONTEXT.md`, `thai-glossary.md`, `th.po` อัปเดต และ `tools/i18n` check ผ่าน

## Test commands
ตามแผน (`docs/plans/2026-10-02-3d-vertical-slice.md`) + simulate ตาม `docs/design/balance.md` + `tools/i18n` check

## Expected output
โค้ด/ข้อมูล + test + ตัวเลข balance + รายการไอคอนที่ใช้ placeholder

## Handoff format
branch + sha, ไฟล์ที่แก้ (รวมไฟล์ test เดิมที่ปรับ), ผล test, ตัวเลข balance, สิ่งที่ยังไม่ทำ, ข้อสงสัย; commit บน `ai/3d-agy1` ได้ ห้าม push

# T4S-01b — Support/Healer: AI preset + Class Encounter + skill tree

- **Task ID:** T4S-01b (ส่วนที่ 2 จาก 3 ของ T4S-01)
- **Owner:** Codex (runner, worktree `Project-GameDev-Agents/Agy1`, branch `ai/3d-agy1`) — agy dropped 2026-10-03
- **Dependencies:** T4S-01a merge แล้ว (class/skill/effect มีใน `forest.json`)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md`, `docs/adr/0016-story-reboot-new-classes-auto-battle.md`, โค้ด `PartyAi` และ Class Encounter เดิมใน `src/match/**`

## Goal
ทำให้ `support` และ `healer` ใช้งานได้เหมือน Class เดิมในทุกระบบรอบข้าง

## Scope
1. **AI preset ใน `PartyAi`:**
   - Healer: ฮีลคนที่ HP% ต่ำสุดเมื่อต่ำกว่าเกณฑ์, ฮีลกลุ่มเมื่อ ≥ 2 คน HP ต่ำ, cleanse เมื่อเพื่อนมี DoT/ดีบัฟ, ไม่งั้น Strike
   - Support: บัฟก่อนเมื่อบัฟยังไม่ติด, ให้ Energy แก่เพื่อนที่มี Skill แพงและ Energy ไม่พอ, ดีบัฟศัตรูตัวที่อันตรายสุด, ไม่งั้น Strike
   - ถ้ามี `party.ai_class_order` ให้เพิ่มสองอาชีพอย่างสมเหตุสมผล
2. **Class Encounter** (ผู้ฝึกสอน) ของทั้งสองอาชีพ ใน `forest.json` แบบเดียวกับอาชีพเดิม
3. **meta skill tree** (ADR-0013) ของทั้งสองอาชีพ แบบเดียวกับอาชีพเดิม
4. i18n ไทยของข้อความใหม่ทั้งหมด
5. test: AI เล่นอาชีพใหม่จน Combat จบโดยไม่ error (ฮีล/cleanse/grant_energy ถูกเลือกในสถานการณ์ที่ควร), Class Encounter ทั้งสองอาชีพทำงาน, skill tree โหลดและซื้อ node ได้

## Allowed paths
`content/forest.json`, `src/match/**`, `tests/match/**`, `i18n/**`, `docs/adr/0010-rogue-class-and-dot-status-effects.md` (เพิ่มหมายเหตุอาชีพใหม่)

## Forbidden paths
`src/client/**`, `content/story_mode.json`, `src/profile/**`, `src/net/**`, `src/server/**`, `assets/**`

## Acceptance criteria
1. test ใหม่ครบข้อ 5 และผ่าน
2. `bash tools/run_tests.sh` เขียวทั้งหมด จำนวน test ไม่ลด
3. test_thai_catalog ผ่าน

## Handoff format
branch + sha, ไฟล์ที่แก้, ผล test, ข้อสงสัย; commit บน `ai/3d-agy1` ได้ ห้าม push

# T4S-01c — Support/Healer: balance

- **Task ID:** T4S-01c (ส่วนที่ 3 จาก 3 ของ T4S-01)
- **Owner:** Codex (runner, worktree `Project-GameDev-Agents/Agy1`, branch `ai/3d-agy1`) — agy dropped 2026-10-03. If `tools/run_tests.sh` fails in your sandbox (missing dirname/seq/sleep), run the Godot test runner directly and say so in the handoff.
- **Dependencies:** T4S-01b merge แล้ว
- **อ่านก่อน:** `docs/design/balance.md`, `tools/dev/simulate*`

## Goal
รัน simulate ตามคู่มือ `docs/design/balance.md` หลังมีสองอาชีพใหม่ในปาร์ตี้ AI แล้วปรับตัวเลขใน content ให้ win rate ทุกโหมด (default / loadout / story) อยู่ในช่วงเป้าหมายเดิม (Story 70–92%)

## Scope
1. รัน simulate baseline ก่อนแก้ บันทึกตัวเลข
2. ปรับเฉพาะค่าตัวเลขของ `support`/`healer` (ปริมาณฮีล, cost, cooldown, duration, ค่าบัฟ) ก่อน ห้ามแตะ Class เดิมยกเว้นจำเป็นจริงและต้องรายงาน
3. รันซ้ำจนอยู่ในเป้า หรือหยุดหลังลอง 5 รอบแล้วรายงานตามจริง
4. บันทึกตัวเลขก่อน/หลังและสิ่งที่ปรับลง `docs/design/balance.md`

## Allowed paths
`content/forest.json` (เฉพาะค่าตัวเลข), `docs/design/balance.md`, `tools/dev/simulate*` (ถ้าต้องรองรับ Class ใหม่), `tests/match/**` (ปรับค่าคาดหวังที่ผูกกับตัวเลขที่เปลี่ยน — รายงานทุกไฟล์)

## Forbidden paths
`src/**` ยกเว้นไม่มี, `content/story_mode.json`, `assets/**`

## Acceptance criteria
1. ตัวเลข win rate ต่อโหมดอยู่ในเป้า (หรือรายงานตามจริงพร้อมสิ่งที่ลองแล้ว)
2. `bash tools/run_tests.sh` เขียวทั้งหมด

## Handoff format
branch + sha, ตารางตัวเลขก่อน/หลัง, ค่าที่ปรับ, ผล test; commit บน `ai/3d-agy1` ได้ ห้าม push

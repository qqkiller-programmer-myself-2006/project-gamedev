# T3D-03 — Battle3D arena + กล้องภาพยนตร์ (ไม่แตะ HUD)

- **Task ID:** T3D-03
- **Owner:** Claude1 (`ai/3d-claude1`, worktree `Project-GameDev-Agents/Claude1`)
- **Dependencies:** contract ร่างของ T3D-01 (รับ Dictionary ตามร่างโดยไม่ import adapter จนกว่า T3D-01 merge)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/plans/2026-10-02-3d-vertical-slice.md`, `src/client/match/battle/battle_view.gd` (อ่านอย่างเดียว)

## Goal
เวทีต่อสู้ 3D: ลานอารีนา, จุดยืน party 5 ตัว (ซ้าย) และ enemy (ขวา, ตามจำนวนสูงสุดที่เกมมี), กล้องภาพยนตร์ (idle drift เบา, push-in ตอนโจมตี, shake ตอน crit — ปิดเมื่อ reduced motion), โมเดล placeholder บล็อกสีตาม class, เล่น cue strike / skill / focus / item / guard / hurt / die ฝังด้วย `SubViewport` ใน `Control`

## Why
แทนเฉพาะ "เวที"; HUD/command/input ยังเป็น Control เดิมของ `BattleView` ทำให้ fallback 2D ได้

## Allowed paths
`src/client/match/battle3d/**`, `tests/client/match/battle3d/**`

## Forbidden paths
`battle_view.gd`, `battle_token.gd`, `battle_backdrop.gd`, `combat_panel.gd`, `src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `home3d/`, `presentation/`

## ข้อกำหนด
- API `Battle3DStage extends Control`: `apply_state(state: Dictionary)`, `play_cue(cue: Dictionary)`, `unit_screen_position(id) -> Vector2` (HUD วาง nameplate/damage), `signal unit_clicked(id)` (target selector), `set_quality(low: bool)`
- ศัพท์: Strike, Skill, Focus, Item, Guard (ห้ามตั้งชื่อใหม่)
- `gl_compatibility`: ไม่มี shadow/SSAO/glow; ลื่นบน Web; โทน ดำ/แดง/ขาว (เส้นทแยงเป็นงาน HUD ของ Codex1)
- สร้างด้วยโค้ด; harness รันเดี่ยวอยู่ใต้ `battle3d/dev/` ป้อน state/cue จำลอง

## Acceptance criteria
1. harness แสดง 5 vs N และเล่นครบทุก cue โดยไม่มี error/leak ใน console
2. `unit_screen_position` ใช้ได้ทุกตำแหน่งและขนาดหน้าต่าง
3. test headless สำหรับ anchor/state/cue; suite เดิมผ่านทั้งหมด
4. screenshot ต่อ cue (+ GIF สั้นถ้าทำได้)

## Test commands
ตามแผน

## Expected output
โค้ด + test + screenshot; ผล perf คร่าวๆ (ms/frame หรือ draw calls)

## Handoff format
ตามแผน; ห้าม push

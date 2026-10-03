# T3D-07 — HUD การต่อสู้สไตล์ดำ/แดง/ขาว (แผงเฉียง, คำสั่งเรียงเฉียงรอบตัวละคร)

- **Task ID:** T3D-07
- **Owner:** Codex1 (`ai/3d-codex1`, worktree `Project-GameDev-Agents/Codex1`)
- **Dependencies:** T3D-06 (Battle3D ฝังใน `BattleView` ภายใต้ `--3d` — merge แล้ว) ปุ่ม Auto ต้องการคำสั่งจาก ADR-0016 ซึ่งยังไม่มี ให้ทำปุ่มเป็นตัวแทนที่ปิดใช้งาน/ซ่อนจนกว่าจะมีคำสั่ง
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md` (ศัพท์: Strike, Skill, Focus, Item, Guard — ห้ามเปลี่ยน), `docs/design/ui-style.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/adr/0016-story-reboot-new-classes-auto-battle.md`, `src/client/match/battle/battle_view.gd`
- **ภาพแนวทาง (เฉพาะอารมณ์/โครงการจัดวาง — ห้ามลอก):** `C:\Users\qqkiller2006\.claude\uploads\c2179cfc-018d-490d-8f13-5d2cbca0448b\f5fe86f4-image.jpg` (ส่งผ่าน `-Images`) ไฟล์นี้อยู่นอกรีโป ห้าม commit

## Goal
ออกแบบ HUD ของ `BattleView` ใหม่ (ใช้เมื่อ `--3d`) ให้เป็นแนว modern anime RPG ดำ/แดง/ขาว แผงเฉียงแบบไดนามิก ประกอบด้วย:
1. **CommandFan:** 5 คำสั่ง **Strike / Skill / Focus / Item / Guard** เรียงเฉียงเป็นพัดรอบตัวละครที่ถึงเทิร์น (ตำแหน่งอิงจาก `Battle3DStage.unit_screen_position`) ตัวที่เลือกอยู่ขยายและเป็นสีแดง ที่เหลือขาว/ดำ แต่ละปุ่มมีป้ายภาษาไทย (ผ่าน `Tr.t`) และไอคอน (`Icons`) พร้อมคำอธิบายสั้นของคำสั่งที่ถูกเลือก
2. **PartyPlates:** แผงสถานะ Party มุมขวาล่าง เป็นแผ่นเอียง แต่ละคนมี portrait, HP, Energy, status effect; ตัวที่ถึงเทิร์นเด่นกว่า
3. **TargetBanner:** ป้ายเฉียงมุมซ้ายบนบอกชื่อและ HP ของเป้าหมายที่เล็ง/ศัตรูที่กำลังเลือก
4. **TurnOrder:** ลำดับเทิร์นแบบแถบเอียง ตัวปัจจุบันเด่น
5. **ปุ่ม Auto:** ปุ่มเปิด/ปิด Auto (placeholder, ดู Dependencies)
6. เมนูย่อยของ Skill และ Item (รายการ, cost Energy, cooldown, ไม่พอ Energy ต้องเห็นชัดว่ากดไม่ได้) ตามพฤติกรรมเดิม

## Why
เจ้าของงานต้องการ HUD แนวนี้ (ADR-0015) ใช้สถานะและคำสั่งเดิมของเกม ไม่เปลี่ยนกติกา

## Allowed paths
- ไฟล์ใหม่: `src/client/match/battle/hud/**`, `tests/client/match/battle/hud/**`
- ไฟล์เดิม (แก้เฉพาะจุดเชื่อม ภายใต้เงื่อนไข `--3d`): `src/client/match/battle/battle_view.gd`, `src/client/match/battle/combat_panel.gd`, `src/client/ui/ui_kit.gd` (เพิ่ม token/สไตล์ ไม่เปลี่ยนค่าเดิม), `i18n/**`
- `tools/dev/ui_preview.gd` (เพิ่มโหมด `--3d` ถ้ายังไม่มี)

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `src/client/home3d/**`, `src/client/match/battle3d/**` (พบบั๊กใน battle3d → รายงานใน handoff), UI 2D เดิมเมื่อไม่ใช้ `--3d` ต้องเหมือนเดิมทุกประการ

## ข้อกำหนด
- **ห้ามลอกเกมอ้างอิง:** ห้ามใช้โลโก้/หน้ากาก/ลวดลายเฉพาะ, ฟอนต์ของเกมนั้น, รูปทรงปุ่มและ layout ที่เหมือนเป๊ะ ใช้ภาษาสีและแนวเอียงร่วมกันได้ แต่ต้องวาดรูปทรงเอง และใช้ลวดลายของเรา (เช่น กระดิ่ง/คลื่นเสียงก้อง)
- **เอียงเฉพาะพื้นหลังแผง** (Polygon2D / custom draw) **ตัวหนังสือไทยไม่เอียง** (เพื่อไม่ให้สระ/วรรณยุกต์เพี้ยน) และต้องไม่ถูกตัดที่ text scale 1.4
- ใช้ token สีใน `UiKit` (ดำ/แดง/ขาว) ห้าม hard-code สีใหม่กระจายในไฟล์
- **คีย์บอร์ด:** ใช้ `handle_key` เดิมได้ครบ (ลูกศร/ตัวเลข/Enter/Esc) เลือกคำสั่งและเป้าหมายได้โดยไม่ใช้เมาส์ **เมาส์:** คลิกปุ่มและคลิกเป้าหมายในฉาก 3D ได้
- **reduced motion:** ปิดแอนิเมชันเลื่อน/สั่น เหลือเฉพาะเปลี่ยนสถานะ
- ศัพท์ตาม `CONTEXT.md`: Strike, Skill, Focus, Item, Guard (ไทยตาม `docs/design/thai-glossary.md`) ห้ามใช้ attack/defend เป็นชื่อบนจอ
- Action window 15 วินาทีและตัวนับเวลาเดิมต้องแสดงอยู่ (ในโหมด Story ไม่มีตัวนับ ตาม ADR-0014)
- ประสิทธิภาพ: ไม่สร้าง Control ใหม่ทุกเฟรม; อัปเดตเมื่อ state เปลี่ยน

## Acceptance criteria
1. ไม่มี `--3d`: พฤติกรรมและ test เดิมทุกตัวผ่านเหมือนเดิม (ไม่ลดจำนวน)
2. มี `--3d`: เล่น Combat จบได้ครบ ใช้ทั้ง 5 คำสั่ง เลือกเป้าหมายด้วยคีย์บอร์ดและเมาส์ได้ ปุ่มที่ใช้ไม่ได้ (Energy ไม่พอ/cooldown) แยกออกชัดเจน
3. smoke test เดิมผ่านทั้งหมด: layout ที่ text scale 1.4 (T35, T42b, T46, T88, issue 150/154) พร้อม test ใหม่ของ HUD
4. screenshot 1280×720, text scale 1.4 และ 1920×1080: เทิร์นปกติ, เมนู Skill เปิด, เมนู Item เปิด, เลือกเป้าหมาย, ตัวละครตาย, Energy ไม่พอ
5. มี i18n ภาษาไทยครบ (`tools/i18n` check ผ่าน)

## Test commands
ตามแผน (`docs/plans/2026-10-02-3d-vertical-slice.md`) + `tools/i18n` check

## Expected output
โค้ด + test + screenshot + รายการสิ่งที่ยังไม่ทำ

## Handoff format
branch + sha, ไฟล์ที่แก้, ผล test, ภาพ, ข้อสงสัย; commit บน `ai/3d-codex1` ได้ ห้าม push

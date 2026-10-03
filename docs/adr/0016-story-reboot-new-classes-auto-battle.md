---
status: proposed
---

# Story reboot: ตัวละครชุดใหม่, Class Support/Healer, ฉากสู้รูท 2, ปุ่ม Auto, ภาษาไทยเป็นหลัก

เจ้าของงานตัดสิน (2026-10-03) ให้เขียน Story mode ใหม่ทั้งหมด (ดู `docs/design/story-bible-draft.md`) ซึ่งเปลี่ยนส่วนที่ ADR-0014 ปล่อยให้เป็นข้อมูลล้วน (content) เป็นการเปลี่ยนกติกา/ระบบบางส่วนด้วย ADR นี้ต่อยอด ADR-0014 และปรับ ADR-0007, ADR-0010

## กติกา (ร่าง)

- **ตัวละคร Party ชุดใหม่:** ไอคิว (ชาย), ฟีฟ่า (ชาย), ตาต้า (ชาย), เค้ก (หญิง), เมย์ (หญิง) แทนชุด Arin/Bram/Cora/Dain/Wren ชื่อ เพศ รูปลักษณ์ล็อกตายตัว
- **กลุ่มอาชีพต่อเพศ (เฉพาะ Story mode):** ชาย = Assassin / Archer / Guardian, หญิง = Mage / Support / Healer ตัวละครแต่ละตัวเลือกอาชีพได้เฉพาะในกลุ่มของตน เพื่อจำกัดจำนวน cutscene
- **Class ใหม่:** `support` และ `healer` เป็น Class ระดับ Tier 1 เพิ่มจากเดิม ข้อเสนอบทบาท: Healer ฟื้น HP และล้าง Status effect, Support บัฟ/ดีบัฟและเพิ่ม Energy ให้เพื่อน (เจ้าของงานยืนยันแล้ว) เพิ่ม Skill, AI preset, skill tree, ไอคอน และ sprite; Multiplayer เข้าถึง Class ใหม่ได้ด้วย (ไม่แยกระบบ)
- **Encounter รูท 2:** encounter พิเศษที่ศัตรูคือเพื่อน 4 คน และตัวละครไอคิวมีกฎ "ตายไม่ได้" (HP ลดได้แต่ไม่ต่ำกว่า 1 ตลอด encounter) ศัตรู 4 ตัวคือเพื่อนในทีม **ใช้อาชีพที่ผู้เล่นเลือกไว้** (สร้าง enemy จาก Class/ระดับของตัวละครนั้นตอนเริ่ม encounter ไม่ตายตัว) ผู้เล่นควบคุมได้เอง เมื่อศัตรูครบทุกตัวล้ม ไปต่อ cutscene
- **ปุ่ม Auto:** คำสั่งฝั่ง client เปิด/ปิด AI ควบคุม slot ของผู้เล่น (ใช้ AI replacement เดิมของ `PartyAi`) ใช้ได้ใน Story mode ทุกการต่อสู้ (เจ้าของงานยืนยันแล้ว) Auto ควบคุมเฉพาะ combat และ **ไม่ข้ามหรือเล่น cutscene แทนผู้เล่น**
- **ฉากจบ 3 รูท** เลือกที่ฉากตัดสินใจก่อน Guardian Boss ใน Layer 5; ฉากเกมแพ้แยกตาม Layer
- **ภาษา:** ภาษาไทยเป็นค่าเริ่มต้นของทั้งเกม และเป็นภาษาเดียวที่รองรับใน slice นี้ เนื้อเรื่อง Story mode (`content/story_mode.json`, ฝั่ง client) เขียนเป็นไทยโดยตรง ส่วนข้อความที่ server ส่ง (`content/forest.json`) ต้องมีคำแปลไทยใน `i18n/th.po` หรือย้ายเป็นไทยใน content ปรับ ADR-0007

## Considered Options

- **ไม่เพิ่ม Class ใหม่ ใช้ Class เดิมแทน Support/Healer:** เสี่ยงน้อยกว่า แต่เจ้าของงานเลือกเพิ่ม Class ให้ตรงเนื้อเรื่อง
- **รูท 2 เป็นการต่อสู้สคริปต์ฝั่ง client:** ไม่แตะ server แต่ผู้เล่นควบคุมไม่ได้ เจ้าของงานต้องการให้เล่นได้จริง จึงไม่เลือก

## Consequences

- แตะ `MatchServer` rules/content/AI และ balance — ขัดกับหลัก "ไม่แก้ MatchServer" ของงาน 3D ต้องทำเป็นงานแยก มี owner เดียว และรัน `simulate` ซ้ำ (Story win rate 70–92%)
- ต้องแก้ `CONTEXT.md` (รายการ Tier 1 Class, ตัวละคร, Wren หายไป), ADR-0010 (รายการ Class) และเทสต์ที่อ้างชื่อ Arin/Bram/Cora/Dain/Wren หรือจำนวน Class
- Profile/Story save ที่เคยบันทึกด้วยตัวละครเก่าใช้ไม่ได้ ต้อง reject ตามกฎเวอร์ชัน save เดิม (ยังไม่ release)
- ขอบเขตงาน 3D (ADR-0015) เลื่อนไปหลัง story/system เหล่านี้นิ่ง

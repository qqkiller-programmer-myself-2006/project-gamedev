# แผนจัดแนวเอกสารการออกแบบ — 2026-09-30

## เป้าหมาย

ทำให้คำอธิบายผลิตภัณฑ์ อภิธานศัพท์โดเมน ADR ที่ยอมรับแล้ว บันทึกรีวิว และ GitHub Project อ้างอิงการออกแบบปัจจุบันชุดเดียวกัน รอบแรกให้แก้เฉพาะเอกสาร; อย่าเปลี่ยนรูปแบบการเล่นจนกว่าจะบันทึกการตัดสินใจด้านผลิตภัณฑ์ที่ยังเปิดอยู่ใน ADR ที่ยอมรับแล้ว

## แหล่งอ้างอิงปัจจุบัน

ให้ใช้ ADR ฉบับล่าสุดที่ยอมรับแล้วและการตัดสินใจชัดเจนของเจ้าของงานเป็นข้อกำหนดในการพัฒนา ADR-0013 เปลี่ยนแนวทางเริ่มแมตช์แบบ Classless เป็นการเลือก Class/Race/Boon loadout ก่อนเริ่ม; ยังคงเส้นทางรองรับ Classless เมื่อไม่ได้ส่ง loadout ADR-0014 ระบุปัจจุบันว่า Story mode ออฟไลน์ใช้โปรไฟล์ในหน่วยความจำที่แยกออกมา โดยเป็น Human และไม่มี Boons หรือ meta ของ class tree ส่วนการทำงานใน `src/client/story/story_launcher.gd` และ `src/match/room.gd` เป็นไปตามกติกานี้

คำถามที่ยังเปิดอยู่คือ Story ควรไม่มี meta จากโปรไฟล์ออนไลน์ต่อไป หรือรับ Race/Boons ของตัวละครหลักมาใช้ ADR ที่ยอมรับแล้วและการทำงานปัจจุบันระบุว่าไม่ใช้; บันทึกติดตามจาก final review ฉบับเก่าเสนอให้ใช้ ให้คงพฤติกรรมที่ยอมรับแล้วไว้จนกว่าเจ้าของงานจะบันทึกการตัดสินใจใหม่ หากเปลี่ยน ให้แก้ ADR-0014 และกำหนดการตรวจสอบ save แหล่งโปรไฟล์ และ test ก่อนแก้โค้ด

## ข้อค้นพบ

1. **PRD ขัดกับ ADR-0013** `docs/design/prd.md` ระบุว่าผู้เล่นเริ่มแบบ Classless แล้วค้นพบอาชีพระหว่างเดินทาง ส่วน ADR-0013 ระบุว่าแมตช์ปกติเริ่มด้วย loadout ก่อนเริ่ม และรองรับการเริ่มแบบ Classless เฉพาะกรณีไม่มี loadout
2. **อภิธานศัพท์โดเมนขัดแย้งกันเอง** คำนำของ `CONTEXT.md` ระบุว่า Enervation เป็น Boon แต่รายการ Assassin และ Enervation ยังอธิบายว่าเป็น passive ของ Assassin และระบุว่า slice ไม่มี Boon ซึ่ง ADR-0013 ยกเลิกกติกานั้นอย่างชัดเจน
3. **ชื่อและการแทนที่ ADR ไม่สอดคล้องกัน** หมายเหตุเปลี่ยนชื่อ/แทนที่ของ ADR-0010 อยู่ก่อนส่วน YAML front matter และเนื้อหาที่รับรองแล้วยังอธิบาย passive Enervation ของ Rogue ส่วน ADR-0013 ยังเรียก Tier 1 Class ว่า Rogue หลัง #74 เปลี่ยนชื่อเป็น Assassin ให้เก็บ ADR-0010 ไว้เป็นประวัติ แต่จัดตำแหน่งหมายเหตุการแทนที่ให้อ่านและค้นพบง่าย; ใช้ Assassin ในข้อกำหนดปัจจุบันของ ADR-0013
4. **บันทึกติดตาม #76 ปะปนการตัดสินใจกับข้อบกพร่อง** พฤติกรรม Story ที่ไม่มี meta ตรงกับ ADR-0014 ในปัจจุบัน แต่รีวิวเสนอให้เชื่อม Race/Boons จากโปรไฟล์ ให้ตัดสินใจด้านผลิตภัณฑ์ก่อนนับเรื่องนี้เป็นงานพัฒนา
5. **สถานะ GitHub Project #8 ล้าสมัย** issue #46, #82, #84 และ #86 ปิดแล้ว แต่รายการใน Project ยังเป็น `In Progress` ควรปรับ Project ให้ตรงกับสถานะ issue; #47 ยังดำเนินอยู่ ส่วน #54 และ #55 ยังต้องให้มนุษย์ตรวจรับ/ดำเนินการ deploy
6. **Checkpoint ล้าหลัง main** `.ai/checkpoint.md` จบที่การส่งต่องานจาก worktree 0cc1/#90 ขณะที่ checkout นี้ detached อยู่ที่ `main` HEAD `7dd5d8b` (merge PR #97 แล้ว) และ PR #98 ยังเปิดอยู่ รายการ audit ปัจจุบันได้บันทึกสถานะใหม่นี้แล้ว

## ลำดับงาน

### A. ปรับเอกสารให้ตรงกันเท่านั้น — เสร็จใน audit นี้

 - ปรับ `docs/design/prd.md` ให้อธิบาย loadout ก่อนเริ่มและเส้นทางรองรับ Classless ในปัจจุบัน โดยคงเป้าหมายด้านเนื้อเรื่องส่วนอื่นไว้
 - แก้รายการ Assassin และ Enervation ที่ขัดแย้งกันใน `CONTEXT.md`; ปัจจุบัน Enervation เป็น Boon ไม่ใช่ passive ของ Assassin
 - ซ่อม front matter ของ ADR-0010 และระบุว่าการตัดสินใจเรื่อง Enervation ถูก ADR-0013 แทนที่ โดยคงข้อความกติกาในอดีตไว้
 - ปรับถ้อยคำ Class และ Boon ปัจจุบันใน ADR-0013 ให้ใช้ Assassin หลังเปลี่ยนชื่อใน #74
 - เพิ่มข้อสรุปหลังรีวิวใน `docs/review/2026-09-30-final-review.md`: พฤติกรรมโปรไฟล์ Story ที่เสนอใน F4 ไม่ใช่ข้อบกพร่องภายใต้นโยบาย ADR-0014 ที่ยอมรับแล้ว ให้คงข้อค้นพบในอดีตไว้เป็นภาพรีวิวที่ระบุวันที่
 - ปรับรายการปัจจุบันใน checkpoint ให้ใช้ commit `main` ล่าสุด (`0779ef1` ซึ่งรวม PR #98 ที่ merge แล้ว) โดยคงบันทึกประวัติเดิมไว้

### B. แก้สถานะติดตามงานที่คลาดเคลื่อน

 - ตั้งรายการ #46, #82, #84 และ #86 ใน Project #8 เป็น `Done` ให้ตรงกับ GitHub issue ที่ปิดแล้ว
 - คง #47 เป็น `In Progress`; ตรวจสอบ #54 และ #55 กับเจ้าของงาน เพราะงานที่เหลือต้องให้มนุษย์ทำ QA/ลงนามรับรองและ deploy Worker
 - ปรับ checkpoint/คิวงานปัจจุบันให้ระบุว่า PR #98 ยังเปิดอยู่ และอย่าใช้บันทึกส่งต่องาน #90 เก่าเป็นสถานะ branch ปัจจุบัน

### C. ตัดสินใจเรื่องโปรไฟล์ Story และงานติดตาม

- ค่าเริ่มต้น: คง Story ให้ใช้ Human/ไม่มี Boons/ไม่มี meta ของ class tree ตาม ADR-0014 ที่ยอมรับแล้ว
- หากเจ้าของงานต้องการให้ Story ใช้ความก้าวหน้าร่วม ให้เขียน ADR การตัดสินใจใหม่ก่อน จากนั้นกำหนดว่าโปรไฟล์เป็นแบบอ่านอย่างเดียวหรือไม่ slot ใดใช้ข้อมูลนี้ วิธีแยก Gems ออนไลน์ วิธีตรวจ save เมื่อมีโบนัสจาก tree และวิธีให้ Continue เก็บ loadout ไว้ ติดตามการพัฒนาใน issue แยกต่างหาก

## เกณฑ์ตรวจรับ

- Current requirements in PRD, `CONTEXT.md`, ADR-0013, and ADR-0014 do not contradict each other; historical ADR-0010 differences are explicitly marked superseded.
- Search results for current-design text contain no active statement that Enervation is an Assassin passive or that standard matches begin Classless.
- Story behavior has one explicit policy shared by ADR-0014, #76 follow-up, and tests.
- Project #8 status matches closed/open GitHub issue state for the listed items.
- Run `bash tools/run_tests.sh` once no other Godot process is running; expected result is exit code 0 and 0 failed. If docs-only changes do not touch runtime, the test suite is still a baseline regression check rather than behavior verification.

## ความเสี่ยงและข้อจำกัด

- PRD มีขนาดใหญ่กว่าชุด ADR มาก ให้ปรับเฉพาะกติกาที่ขัดกับ ADR ที่ยอมรับแล้ว และคงเป้าหมายด้านเนื้อเรื่อง/ผลิตภัณฑ์ไว้
- อย่าเปลี่ยน Project #8 หรือเขียน issue ที่ปิดแล้วใหม่ จนกว่าเจ้าของงานจะอนุมัตินโยบาย Story และการปรับข้อมูลติดตามงาน
- ไม่ได้รัน test ทั้งชุดระหว่าง audit นี้ เพราะมี process Godot editor เปิดอยู่ใน checkout อื่น checkpoint ของรีโปเตือนว่าการรัน Godot พร้อมกันอาจล้มเหลวโดยไม่แสดงข้อผิดพลาด

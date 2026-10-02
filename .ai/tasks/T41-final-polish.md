# T41 — รอบสุดท้าย: ข้อความอังกฤษที่เหลือ + UI ที่ค้าง (#87 #88 #44 #45)
ทำใน worktree นี้ (base = branch PR #117). อ่าน `docs/design/thai-glossary.md`, `src/client/ui/tr.gd`.
## A. แปลที่เหลือ (client เท่านั้น; ห้ามแก้ src/match, src/server, src/net)
- "Turn N" (หัว turn list), "CRIT", "Weak: fire"/สถานะ, "Tropper's Stall", HP/EXP/LVL ที่เป็นข้อความอธิบาย, `Layer N of 5`, `Clues`, `Vote for this path`, `Alternatives`, `Featured`, `Votes:`, `Ready N of M. Waiting:`, `Vote closes in Ns - hurry!`, `YOU/PLAYER/AI`, `AI controlled`, ป้าย "Fight/Items/Focus" ให้ตรงชุดคำแปล.
- ชื่อที่มาจาก server/content: ชื่อตัวละคร (Arin, Bram, Cora, Dain, Wren) ตาม glossary, ชื่อ Class/Race/Boon/ไอเท็ม/Story Clue (เช่น "Claw-Marked Shield"), ชื่อ log event ("Bram attacks: Goblin takes 15") — แปลที่ client ด้วย lookup/pattern เดิม; ถ้าชื่อใดไม่อยู่ใน `th.po` ให้เพิ่มคำแปลพร้อมรายการใน glossary.
- สแกนอัตโนมัติ: เขียน test/สคริปต์ที่รัน `ui_preview` แล้วรายงานข้อความละตินที่ยังเห็นใน Label/Button ทุกหน้า (ผ่าน tree ของ Control ไม่ใช่ OCR) ยกเว้นปุ่มลัด/HP/ตัวเลข/ชื่อเกมที่ตั้งใจ; ต้องเหลือ 0 รายการที่ไม่อยู่ใน allowlist.
## B. UI
1. turn list ทับป้าย/ตัวละครฮีโร่ที่ 1280×720 (ดู `build/ui/04_combat_turn.png`) → จัดตำแหน่ง/ความกว้างไม่ให้ทับ token หรือ HP plate.
2. ตัวเลขดาเมจยังซ้อนกันบางจังหวะ (-30 CRIT ทับ -15) → ใช้การ stack แนวตั้งต่อเป้าหมายแบบคิว/offset ต่อเนื่อง ไม่ให้สองตัวเลขอยู่ตำแหน่งเดียวกันพร้อมกัน; เขียน test.
3. #45: Merchant/Rest ที่ ×1.45 ต้องเห็นคอลัมน์ Equipment ได้โดยไม่ต้องเลื่อนแนวนอน (ปรับ layout/ลดขนาดคอลัมน์/wrap) หรือถ้าทำไม่ได้ให้เลื่อนแนวตั้งแทน; แก้ข้อความ `Rect2i size is negative` ที่ Merchant ×1.45.
4. #44: เขียน test อัตโนมัติจำลองการกด key (Tab/ลูกศร/Enter/hotkey ที่เอกสาร) ให้ครบทุก control หลักของ Battle, Merchant, Rest และยืนยันว่ามี focus ที่มองเห็น (focus owner ไม่ใช่ null และมี style) — บันทึกผลเป็นตารางใน `docs/review/2026-10-01-responsive-a11y-evidence.md` (อัปเดตแถวที่เคยเป็น ⚠️).
5. ถ้า Playwright/Chromium ติดตั้งได้ ให้รัน `tools/ci/web_smoke.mjs`; ถ้าทำเพิ่ม Firefox/WebKit ได้ด้วย `npx playwright install firefox webkit` ให้รัน smoke พื้นฐานและบันทึกผล (Edge = Chromium; Safari = WebKit). ระบุข้อจำกัดตรง ๆ.
## Verify
`bash tools/run_tests.sh` ผ่านหมด; `tools/dev/ui_preview.gd --seed=21` ที่ 1280×720, 1920×1080, ×1.45 เปิด PNG ดูจริง; อัปเดตภาพใน `docs/screenshots/2026-10-01-a11y/`.
## Report
ตารางต่อข้อ + ข้อที่ยังเหลือตรง ๆ.

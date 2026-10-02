# T37b — กวาดข้อความ hard-code ใน client ให้เป็นไทย (ต่อจาก T37a)
อ่าน: `docs/design/thai-glossary.md`, `src/client/ui/tr.gd`, `tools/i18n/extract_strings.gd`, `i18n/th.po`, `tests/i18n/test_thai_catalog.gd`.
## Do
ข้อความภาษาอังกฤษที่เขียนตรงใน `src/client/**/*.gd` (Title, Lobby, Character setup/Class/Race/Boons, Settings, Vote panel, Combat/Battle HUD ปุ่ม Fight/Items/Focus และ hint, Camp/Merchant/Rest, Summary, Story, toast/banner/log ที่ client สร้างเอง, tooltip, ชื่อปุ่มลัด label) ให้ผ่าน `Tr.t()` โดย msgid = ข้อความอังกฤษเดิม แล้วเพิ่มคำแปลไทยใน `i18n/th.po` (ผ่าน extractor ที่ขยายให้สแกน `src/client` — ต้อง deterministic).
- ข้อความที่มี `%d/%s` ต้องคง placeholder และลำดับให้ตรง; ปุ่มลัด `[F]` `[1]` คงไว้.
- ข้อความจาก server ใน event log/summary (เช่น "Bram attacks: Goblin takes 15.", "Victory! The Forest is behind you.") แปลที่ client ด้วยรูปแบบ pattern→template (ห้ามแก้ฝั่ง server/match; server ยังเป็นอังกฤษ). ถ้า pattern ไม่ครบ ให้รายงานรายการที่เหลือ.
- ชื่อเกม "Beyond the World's End" แปล/ถอดเสียงตาม glossary หรือเพิ่มแถวใน glossary.
- ตรวจว่าข้อความไทยไม่ล้น/ถูกตัดที่ 1280×720 และ ×1.45 (ปุ่ม, Tip panel, หัวข้อ, ป้าย badge ในรายการ party). แก้ layout เท่าที่จำเป็นให้พอดี (ห้ามตัดข้อความ).
- ห้ามแก้ `src/match`, `src/server`, `src/net`. tests ทั้งหมดต้องยังรันเป็น locale `en` ผ่าน; เพิ่ม test ว่า th.po ครอบทุก `Tr.t("...")` literal ใน src/client (สแกนด้วยสคริปต์) และ placeholder ตรงกัน.
## Verify
`bash tools/run_tests.sh` ผ่านหมด; extractor รันซ้ำได้ POT เหมือนกัน; `check_po.gd` exit 0; เปิดภาพจาก `tools/dev/ui_preview.gd --seed=21` (ค่าเริ่มต้น=ไทย) อย่างน้อย Title, Lobby, Setup, Vote, Combat, Merchant, Summary แล้วยืนยันว่าไม่มีข้อความอังกฤษเหลือ (ยกเว้นปุ่มลัด/ชื่อเฉพาะ) และไม่มี tofu/ข้อความถูกตัด.
## Report
จำนวน msgids, ข้อความที่ยังเป็นอังกฤษและเหตุผล, ผล test.

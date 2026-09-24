---
status: accepted
---

# ใช้ test runner ขนาดเล็กที่เขียนเองในรีโป แทน GUT หรือ gdUnit4

test ทั้งหมดรันด้วย `tests/run_tests.gd` ซึ่งเป็น `SceneTree` script ราว 100 บรรทัด ผ่าน `godot --headless -s` โดยไม่พึ่ง addon ภายนอก เพราะ test ของเราทดสอบผ่าน Match interface เท่านั้น (ไม่ mock, ไม่ต้องการ scene runner หรือ doubles) จึงต้องการแค่ค้นหา `test_*` method, assertion, และ exit code สำหรับ CI; runner ใช้ `OS.add_logger()` (Godot 4.5+) ดักจับ script error ทำให้ test ที่ crash ถูกนับว่า fail แทนที่จะผ่านเงียบ ๆ

## Considered Options

- **GUT**: ครบเครื่องและรัน CLI ได้ แต่ต้อง vendor addon หลายร้อยไฟล์ และต้องรอให้ addon ตามทัน Godot เวอร์ชันใหม่ (เราใช้ 4.7) ความสามารถส่วนใหญ่ (doubles, scene runner) เราไม่ใช้
- **gdUnit4**: เหตุผลเดียวกับ GUT และผูกกับ editor plugin มากกว่า

## Consequences

- เปลี่ยนไปใช้ GUT/gdUnit4 ภายหลังได้ไม่ยาก เพราะ test เป็น method ธรรมดาที่เรียก assertion ของ `TestCase`
- runner ต้องใช้ Godot ≥ 4.5 เพราะใช้ `Logger`; CI pin ไว้ที่ Godot 4.7.2

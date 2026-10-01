# tests/
ชุดทดสอบ GDScript จัดกลุ่มตามระบบใน `src/` พร้อม `support/` สำหรับ harness และ bot.
รันทั้งหมดด้วย `./tools/run_tests.sh`; เพิ่มการทดสอบ gameplay ผ่าน `MatchServer`.
`regression/` ตรวจ full runs ส่วน `i18n/` ตรวจ catalog ภาษา.
ผู้พัฒนาที่เปลี่ยน behavior เพิ่มหรือปรับ test ในกลุ่มที่ตรงกับระบบ.

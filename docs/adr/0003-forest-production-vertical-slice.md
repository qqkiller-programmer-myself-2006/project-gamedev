---
status: accepted (Tier 1 Classes เพิ่มเป็น 5 ตาม ADR-0010; เพิ่ม Equipment และการคราฟต์ที่ Rest ตาม ADR-0011)
---

# จำกัด vertical slice ระดับพร้อมใช้งานจริงไว้ที่ Forest 5 ชั้น

งานระยะแรกเป็น vertical slice ที่มีคุณภาพพร้อมใช้งานจริงและเล่นจบได้ในประมาณ 20–30 นาที ประกอบด้วย Forest 5 ชั้น, กลุ่ม Encounter 6 ประเภท, Tier 1 Class 4 แบบ และ Guardian Boss 1 ตัว พร้อม UI/UX ระดับสูง การเคลื่อนไหว สัญญาณตอบสนอง และการเข้าถึง; ระบบเกมเต็ม เช่น Tier 2/3, Beyond Sea, account, matchmaking, mobile, console, ranking, voice chat และ cinematic เต็มรูปแบบอยู่นอกขอบเขต

## ผลที่ตามมา

- คุณภาพของระบบและ UI/UX ต้องใกล้ระดับพร้อมใช้งานจริง แต่จำกัดปริมาณ content
- ต้องตรวจรับลำดับการเล่นหลักตั้งแต่สร้าง/เข้าห้องจนชนะ Guardian Boss บน PC และ browser
- การเพิ่ม content นอก Forest ต้องผ่านการตัดสินใจขอบเขตงานใหม่ ห้ามแทรกเข้า vertical slice โดยปริยาย
- ข้อมูลเส้นทางที่มี Encounter type ซึ่งเกมไม่รองรับต้องไม่ถูกข้ามราวกับสำเร็จ: เมื่อ Party เข้า Encounter ดังกล่าว Match ส่ง event `match_error` (`error: "unsupported_encounter"`, `encounter_type`) แล้วจบด้วยผล defeat โดย summary มีคีย์ `error` และ `encounter_type` เดียวกัน (#41)

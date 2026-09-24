---
status: accepted (Tier 1 Classes amended to 5 by ADR-0010)
---

# จำกัด production vertical slice ไว้ที่ Forest 5 Layers

งานระยะแรกจะเป็น production-quality vertical slice ที่เล่นจบได้ภายในประมาณ 20–30 นาที ประกอบด้วย Forest 5 Layers, Encounter pool 6 ประเภท, Tier 1 Classes 4 แบบ และ Guardian Boss 1 ตัว พร้อม UI/UX ระดับสูง, motion, feedback และ accessibility; ระบบเกมเต็ม เช่น Tier 2/3, Beyond Sea, account, matchmaking, mobile, console, ranking, voice chat และ cinematic เต็มรูปแบบอยู่นอกขอบเขต.

## Consequences

- คุณภาพของระบบและ UI/UX ต้องใกล้ระดับ production แต่จำนวน content ถูกจำกัด
- ต้องรับรอง core flow ตั้งแต่สร้าง/เข้าห้องจนชนะ Guardian Boss บน PC และ browser
- การเพิ่ม content นอก Forest ต้องผ่านการตัดสินใจ scope ใหม่ ไม่ควรแทรกเข้ามาใน vertical slice โดยปริยาย

---
status: superseded by ADR-0009
---

# จำกัดการใช้ Skill ด้วย cooldown นับเป็น turn ของตัวละคร ไม่ใช้ resource (MP/SP)

Skill ทุกอย่างมีค่า `cooldown` ในข้อมูล content: ใช้แล้วต้องรอ N turn ของตัวละครนั้นเองก่อนใช้ได้อีก และ cooldown รีเซ็ตทุกครั้งที่เริ่ม Combat ใหม่ เลือกแบบนี้เพราะเรียบง่ายที่สุดทั้งกับผู้เล่นใหม่ (เห็นตัวเลข "อีก 2 turn" บนปุ่มเดียว ไม่ต้องบริหารแถบพลัง), กับ AI replacement (ตัดสินใจแค่ "พร้อมหรือไม่") และกับ Action window 15 วินาที; ไม่ต้องมีระบบฟื้น resource ข้าม Encounter ที่ Rest/Item ต้องดูแลเพิ่ม

## Considered Options

- **Resource (MP/SP) ต่อตัวละคร**: ให้ความลึกเรื่องการวางแผนข้าม Encounter แต่ต้องเพิ่ม UI แถบพลัง, Item ฟื้นพลัง, กติกาที่ Rest และ AI ที่ต้องประหยัดพลัง ซึ่งเกินขอบเขต vertical slice
- **ใช้ได้ครั้งเดียวต่อ Combat**: ง่ายแต่ทำให้ Skill แทบไม่มีบทบาทในการต่อสู้ยาวอย่าง Guardian Boss

## Consequences

- การเปลี่ยนไปใช้ resource ภายหลังต้องแก้ content ของทุก Skill, UI และ AI preset ทุก Class จึงถือว่าย้อนยาก
- Skill ที่ `cooldown` เป็น 0 ใช้ได้ทุก turn

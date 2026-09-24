---
status: accepted
---

# เพิ่ม Rogue เป็น Tier 1 Class ตัวที่ 5 พร้อมระบบ Status effect แบบ DoT (ขยาย scope ของ ADR-0003)

Forest vertical slice มี Tier 1 Class 5 แบบ: Swordsman, Archer, Mage, Guardian และ **Rogue** (Melee DoT: มีด + ยาพิษ) ซึ่งค้นพบผ่าน Class Encounter ของตัวเองเหมือน Class อื่น เพื่อรองรับ Rogue เกมมีระบบ **Status effect** ทั่วไปที่ติดได้ทั้งตัวละครและศัตรู โดยเริ่มจาก DoT 3 ชนิดคือ **Bleed**, **Poison** และ **Toxin** และ Rogue มี passive **Enervation** ที่ทำให้ DoT หลายชนิดบนเป้าเดียวกันเสริมกัน ออกแบบตามแบบอ้างอิง AAC (`docs/references/aac_rogue/README.md`) เราตัดสินขยาย scope ครั้งนี้ตามที่ ADR-0003 กำหนดว่าการเพิ่ม content ต้องผ่านการตัดสินใจใหม่ เพราะ Party มี 5 ตัวละคร การมี 5 Class ทำให้ทุก slot มีบทบาทที่ต่างกันได้ และ DoT build ให้ความลึกเชิงวางแผนที่ PRD ต้องการ

## กติกาหลัก

- DoT ทำงานตอนเริ่ม turn ของตัวที่ติด (ก่อนได้ Energy และก่อน action) โดยทำ damage ตามจำนวน stack ไม่ผ่าน DEF/RES และลด duration ลง 1; หมด duration แล้วหลุด
- ติด DoT ชนิดเดิมซ้ำแล้ว stack เพิ่ม (ไม่เกิน `max_stacks`) และ duration ต่ออายุเป็นค่าที่มากกว่า; DoT ต่างชนิดติดพร้อมกันได้
- DoT ทำให้ล้มได้เหมือน damage ปกติ; Status effect ทั้งหมดถูกล้างเมื่อจบ Combat หรือ Challenge
- Enervation (passive ของ Rogue): damage ตรงของ Rogue ×(1 + 0.05 × จำนวนชนิด DoT บนเป้า) ไม่เกิน ×1.4, DoT ที่ Rogue ติดให้แรงขึ้น 15% และ Rogue รับ damage จาก DoT มากขึ้น ×1.15
- ตัวเลขทั้งหมดอยู่ในข้อมูล content

## Considered Options

- **ทำแค่ระบบ DoT ไม่เพิ่ม Class**: ไม่ขยาย scope แต่ไม่มี Class ที่ออกแบบรอบ DoT ทำให้ระบบนี้แทบไม่มีบทบาท

## Consequences

- ADR-0003 และคำนิยาม Tier 1 Class ใน `CONTEXT.md` เปลี่ยนเป็น 5 Class
- ต้องมี Class Encounter, AI preset และ tooltip ของ Rogue และ `MatchBot`/regression ต้องครอบคลุม Rogue
- client ต้องแสดง badge ของ Status effect บนตัวละครและศัตรู และตัวเลข damage ของ DoT ที่แยกชนิดได้โดยไม่ใช้สีอย่างเดียว

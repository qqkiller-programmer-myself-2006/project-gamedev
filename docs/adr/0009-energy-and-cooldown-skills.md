---
status: accepted
---

# Skill ใช้ทั้ง Energy และ cooldown ทุก Class (แทน ADR-0005)

ตัวละครใน Party ทุกตัวมี **Energy** ใน Combat: เริ่มแต่ละ Combat (และ Challenge) ที่ `energy_start`, ได้ `energy_regen` ตอนเริ่ม turn ของตัวเองทุกครั้ง (รวม turn ที่หมด Action window แล้วถูก Defend อัตโนมัติ) และสะสมได้ไม่เกิน `energy_max`; ค่าเริ่มต้นคือ 1 / +1 / 6 ตามแบบอ้างอิง AAC (`docs/references/aac_rogue/README.md`) Skill ทุกอย่างมีทั้ง `energy` (ค่าใช้) และ `cooldown` (นับเป็น turn ของตัวละครเอง เหมือนเดิม) ในข้อมูล content; Attack, Defend และ Item ใช้ 0 Energy Energy และ cooldown รีเซ็ตทุกครั้งที่เริ่ม Combat ใหม่ ศัตรูและ Guardian Boss ไม่มี Energy

เราเปลี่ยนจาก cooldown อย่างเดียวเพราะต้องการจังหวะแบบ "turn แรกเตรียม, turn ถัดไปปล่อยคอมโบ" ที่ Rogue (ADR-0010) และ DoT build ต้องใช้ และถ้า Rogue ใช้ Energy คนเดียว เกมจะมีสองระบบซ้อนกันซึ่งสับสนทั้งกับผู้เล่นและ AI replacement จึงใช้ Energy กับทุก Class

## Considered Options

- **คง cooldown อย่างเดียว (ADR-0005)**: ง่ายที่สุด แต่ไม่มีการตัดสินใจเรื่องจังหวะเก็บพลังที่ Rogue ต้องการ
- **Energy เฉพาะ Rogue**: งานน้อยกว่า แต่มีสองระบบในเกมเดียว

## Consequences

- Skill ทุกตัวของ Swordsman, Archer, Mage และ Guardian ต้องมีค่า `energy` และต้อง rebalance ใหม่ให้ regression suite ยังอยู่ในช่วง win rate ที่กำหนด
- AI preset ทุก Class และ `MatchBot` ต้องคำนึงถึง Energy (ไม่สั่ง Skill ที่ Energy ไม่พอ)
- snapshot/choices ต้องมี Energy ปัจจุบัน/สูงสุดของตัวละคร และค่าใช้ Energy ของแต่ละ Skill; server ปฏิเสธ Skill ที่ Energy ไม่พอด้วย error `not_enough_energy`
- UI ต้องแสดงแถบ Energy และค่าใช้บนปุ่ม Skill (ไม่มี Item ฟื้น Energy และ Rest ไม่เกี่ยวกับ Energy เพราะรีเซ็ตทุก Combat)

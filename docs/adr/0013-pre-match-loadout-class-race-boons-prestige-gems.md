---
status: accepted
---

# เลือก Class, Race และ Boons ก่อนเริ่ม Match แบบ AAC พร้อม Skill tree/Prestige และ Gems ที่เก็บบน server (แทน Classless start)

เจ้าของงานตัดสิน (2026-09-29) ให้หน้าก่อนเริ่ม Match เหมือนภาพ `docs/references/aac_rogue/01–03`: เลือก Class ก่อนเริ่มแบบ AAC, Enervation เป็น Boon ตามภาพ, เผ่า "Robloxian" เปลี่ยนชื่อเป็น **Human** และ Gems เก็บข้ามเกมบน server (Cloudflare D1)

## 1. หน้า Character setup (ใน Room ก่อน Host กด Start)

- แถบไอคอนกลม 5 อันด้านบน: **Profile**, **Races**, **Class**, **Boons**, **Records**; ปุ่ม **Finish** ด้านล่างกลับไปหน้า Room
- ทุกการเลือกเป็น command ไปที่ server ระหว่างอยู่ใน Room เท่านั้น (`set_loadout`, `buy_race`, `tree_upgrade`, `buy_prestige`, `reset_tree`) server ตัดสินและหัก Gems (ADR-0001)
- มุมซ้ายล่างแสดง Gems (ไอคอนเพชรสีเขียว)

## 2. Class ก่อนเริ่ม (แทน Classless start)

- ผู้เล่นจริงเลือก Tier 1 Class (Swordsman, Archer, Mage, Guardian, Assassin) ในหน้า Class แบบ carousel `< >` พร้อมคำอธิบายและ "Recommended Stats" (เปลี่ยนชื่อจาก Rogue ตาม #74)
- slot ของ AI ได้ Class ที่ยังไม่มีใน Party ตามลำดับใน `party.ai_class_order` (ถ้าผู้เล่นไม่ได้ส่ง loadout เลย ตัวละครเริ่ม Classless แบบเดิม — ใช้โดย test เดิมและ client เก่า)
- **Class Encounter** ยังอยู่: ชนะ Challenge ได้ EXP + Gems แทนการรับ Class; ตัวละครที่ยัง Classless (กรณีไม่มี loadout) ยังรับ Class ได้เหมือนเดิม
- **Skill tree ต่อ Class**: 7 node (ผัง 3–3–1 ตามภาพ) แต่ละ node สูงสุด 5/5, ราคา `10 × level ถัดไป` Gems, ข้อมูลอยู่ใน `meta.class_tree` ของ content
  - Stat Points: +1 แต้ม attribute ที่ลงได้ตอนเริ่ม Match ต่อ level
  - Vitality +2% max HP, Might +2% damage ตรง, Precision +1% Crit, Swiftness +1 Initiative ต่อ 2 level, Reserves +1 Energy ตอนเริ่ม Combat ที่ level 5, Mastery (node ล่าง) Skill ของ Class cooldown −1 ที่ level 5
- **Prestige**: เมื่อทุก node 5/5 กด **Buy Prestige** (100 Gems) → Prestige +1 (สูงสุด 25 = MAX) และรีเซ็ต node; แต่ละ Prestige ให้ +1% max HP และ damage ของ Class นั้น
- **Reset Skills** (50 Gems): คืน Gems ที่ใช้ใน tree ของ Class นั้นทั้งหมด

## 3. Race

| Race | ราคา | Passive 1 | Passive 2 |
| --- | --- | --- | --- |
| Human | ฟรี | Adaptable: +1 แต้ม attribute ทุก level คู่ | Versatile: +1 ทุก attribute |
| Elf | ฟรี | Keen Eyes: Crit +5% | Grace: DEX +2 |
| Kobold | ฟรี | Scrappy: Gold จาก reward +10% | Small Target: Dodge +5% |
| Withered | ฟรี | Undying: Lifesteal 5% | Frail: max HP −10% |
| Dwarf | 50 Gems | Dwarven Resilience: max HP +10%, Status resistance +10% | Masterwork: gear ที่คราฟต์ได้ stat +0.75% ต่อ level ปัจจุบัน |
| Lunaeia | 100 Gems | Moonlit: damage เวท +10% | Tidal: Energy เริ่ม Combat +1 |

- **Status resistance** (derived stat ใหม่): โอกาสไม่ติด Status effect ที่ศัตรูใส่

## 4. Boons

- ความจุ 5 ช่อง; รายการแบ่งกลุ่มตามจำนวนช่องที่ใช้ มีช่อง Search; ฝั่งขวาแสดง Boon ที่ใส่และ `Slots: x/5`
- **Enervation ย้ายจาก passive ของ Assassin (เดิม Rogue) มาเป็น Boon** (ผลเหมือน ADR-0010 เดิม) — Assassin ไม่มี passive นี้แล้ว

| Boon | ช่อง | ผล |
| --- | --- | --- |
| Potential: Bunny | 5 | Initiative +3, Dodge +15% |
| The Chosen One | 4 | ทุก attribute +2 (ปลดล็อกเมื่อมี Prestige รวม ≥ 5) |
| Daredevil Impulse | 3 | damage +25% เมื่อ HP ≤ 30% |
| Critical Healing | 3 | Crit ฮีลตัวเอง 20% ของ damage |
| Energy Conserver | 2 | 15% ได้ Energy +1 เพิ่มตอนเริ่ม turn |
| Enervation | 2 | ตาม ADR-0010 |
| Alert | 1 | Initiative +3; 2 turn แรกของ Combat Block และ Dodge +5% |
| Will of Thiacdemo | 1 | ครั้งแรกต่อ Combat ที่โดน damage จนล้ม เหลือ HP 1 แทน |

## 5. Gems และการเก็บข้อมูล

- ได้ Gems ตอนจบ Match: +10 ต่อ Layer ที่ผ่าน, +50 เมื่อชนะ Guardian Boss, +5 ต่อ Story Clue, + Gems จาก Class Encounter
- **ตัวตนผู้เล่น**: client สร้าง token สุ่ม 128 บิตครั้งแรกแล้วเก็บใน `user://` ส่งมาตอนเข้า Room; profile ผูกกับ token นี้ (ไม่มีรหัสผ่าน)
- **ProfileStore** เป็น seam ที่ MatchServer รับจากภายนอก (เหมือน clock/rng): `MemoryProfileStore` สำหรับ test, `FileProfileStore` (ค่าเริ่มต้นของ server ในเครื่อง) และ `D1ProfileStore` เรียก Cloudflare Worker (`deploy/profile-worker/`) ที่ผูก D1 ผ่าน HTTPS พร้อม secret ของ server
- การบันทึกเป็นแบบ async: Match ไม่รอ network; ถ้าบันทึกไม่สำเร็จ server log และลองใหม่

## Considered Options

- **เก็บ Gems ในไฟล์ของ client**: ง่ายที่สุด แต่โกงได้และไม่ตามข้ามเครื่อง — เจ้าของงานมี Cloudflare D1/R2 free tier จึงเลือก server
- **คง Classless start**: รักษาเรื่องราวเดิม แต่ไม่ตรงภาพที่เจ้าของงานต้องการ

## Consequences

- `CONTEXT.md` ต้องแก้: Classless (กรณีไม่มี loadout เท่านั้น), Class Encounter (ได้ reward แทน Class), Race, Boon, Gems, Prestige, Skill tree (meta), Enervation (Boon)
- ADR-0010 ส่วน "Enervation เป็น passive ของ Rogue" ถูกแทน
- การตั้ง Cloudflare Worker/D1 ต้องให้เจ้าของงานล็อกอิน `wrangler` เอง

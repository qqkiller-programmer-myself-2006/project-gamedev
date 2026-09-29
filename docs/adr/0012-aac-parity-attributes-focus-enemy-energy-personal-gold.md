---
status: accepted
---

# เกมตามภาพ AAC ทั้งระบบ: Attribute 7 ตัว, Fight/Items/Focus, Energy ของศัตรู และ Gold ส่วนตัว (แทนบางส่วนของ ADR-0011 และ CONTEXT.md)

เจ้าของงานตัดสิน (2026-09-29) ว่าเกมต้อง "เหมือนภาพอ้างอิง AAC ทั้งหมด" (`docs/references/aac_rogue/`) ทั้งหน้าตาและกติกา ไม่ใช่แค่ชื่อบนจอ ก่อน final build วันที่ 2026-10-02 ADR นี้กำหนดกติกาที่ต่างจากเดิม ส่วนหน้าจอก่อนเริ่ม Match (Class/Prestige, Race, Boons) อยู่ใน ADR-0013

## 1. Attribute 7 ตัว

ตัวละครใน Party มี attribute `str, dex, con, int, fth, cha, lck` ส่วน stat ที่ combat ใช้ (`max_hp, atk, def, mag, res, spd, crit`) กลายเป็น **ค่าที่คำนวณได้** จาก base ของ Class + attribute + gear ดังนั้นสูตร damage เดิมใน `combat_encounter.gd` ไม่เปลี่ยน

| Attribute | ผลต่อแต้ม |
| --- | --- |
| STR | +1 `atk` ถ้า Class มี `atk_attr = "str"` |
| DEX | +1 `atk` ถ้า Class มี `atk_attr = "dex"`; +1 `spd` ต่อ 2 แต้ม; Dodge +0.5% |
| CON | +4 `max_hp`; +1 `def` ต่อ 2 แต้ม; Block +0.5% |
| INT | +1 `mag` |
| FTH | +1 `res` ต่อ 2 แต้ม; การฮีลที่ตัวละครทำแรงขึ้น 2% |
| CHA | ราคาที่ Merchant ถูกลง 1% (สูงสุด 30%) สำหรับผู้ซื้อ |
| LCK | Crit +1%; Crit Damage +2%; โอกาสดรอปของศัตรูที่ตัวนี้ล้ม ×(1 + 0.01×LCK) |

- **Base ของ Class**: เก็บใน `classes.<id>.base` และ `classes.<id>.attributes` (ค่าเริ่มต้น) โดยตั้ง base ให้ **stat ที่คำนวณได้ตอน level 1 เท่ากับค่าเดิมทุกตัว** เพื่อไม่ให้ balance และ test เดิมเปลี่ยนโดยไม่จำเป็น
- **Derived stat ใหม่**: `crit_damage` (= `rules.crit_multiplier` + 0.02×LCK), `dodge`, `block` (ลด damage 50%), `aggro` (ค่าตาม Class: Guardian 1.5, Swordsman 1.2, อื่น 1.0, Rogue 0.85), `lifesteal` (จาก gear เท่านั้น), `energy_regen` (= `rules.energy_regen`)
  - Dodge: การโจมตีตรงจากศัตรูพลาดทั้งหมด (event `action_resolved` มี `dodged: true`) ไม่มีผลกับ DoT tick
  - Block: damage ตรงลดลง 50% (event มี `blocked: true`)
  - Aggro: ศัตรูที่เลือกเป้าแบบสุ่มถ่วงน้ำหนักด้วย `aggro`; behavior ที่มีเป้าตายตัว (เช่น `hunt_weakest`) ไม่เปลี่ยน
- **Level-up**: `leveling.growth` ยังเพิ่มที่ base; ได้ `leveling.points_per_level = 2` แต้ม ลงที่ attribute ได้ที่ Rest ด้วย `invest {stat: "dex"}` (1 แต้ม = +1 attribute)
- **AI**: ลงแต้มตาม `classes.<id>.invest_focus` ซึ่งเปลี่ยนเป็นชื่อ attribute (Swordsman `str`, Archer `dex`, Mage `int`, Guardian `con`, Rogue `dex`, Classless `con`)
- **Snapshot**: `party[].attributes` (7 ค่า), `party[].derived` (`initiative, crit, crit_damage, dodge, block, block_reduction, aggro, lifesteal, energy_regen`), `party[].points`
- ศัตรูไม่มี attribute ใช้ stat ตรงตามเดิม

## 2. ปุ่ม Fight / Items / Focus

- ปุ่มหลักของ HUD คือ **Fight** (เปิด grid ที่มี **Strike**, **Guard** และ Skill ของ Class), **Items** และ **Focus**
- Strike = คำสั่ง `attack` เดิม, Guard = คำสั่ง `defend` เดิม (ชื่อบนจอและใน content เปลี่ยน ชื่อคำสั่งใน protocol คงเดิม)
- **Focus** (คำสั่งใหม่ `focus`): ใช้ turn นี้โดยไม่ลงมือ ได้ Energy +1 ทันที (ไม่เกิน `energy_max`) และ Dodge +10% จนถึงเริ่ม turn ถัดไปของตัวเอง; ไม่ใช้ Energy; `choices.focus = true` เมื่อใช้ได้
- หมด Action window ยังเป็น Guard อัตโนมัติ

## 3. Energy ของศัตรู

- ศัตรูและ Guardian Boss มี Energy: เริ่ม 0, +1 ตอนเริ่มทุก turn ของตัวเอง, สูงสุด `enemies.<id>.energy_max` (ค่าเริ่มต้น `rules.enemy_energy_max = 4`, Boss 6)
- ท่าพิเศษของศัตรู (`enemies.<id>.special`) มี `energy` เป็นค่าใช้ ศัตรูใช้ท่าพิเศษเมื่อ Energy พอ ไม่งั้นโจมตีปกติ; slice นี้มีท่าพิเศษอย่างน้อย 3 ชนิดศัตรู
- Snapshot: `enemies[].energy`, `enemies[].energy_max`

## 4. Gold ส่วนตัว และ Transfer

- Gold เป็นของ**ตัวละครแต่ละตัว** (`party[].gold`) แทน Gold ร่วม; Reward gold แบ่งเท่าๆ กันให้ตัวละครที่ยังอยู่ใน Party (เศษให้ slot ลำดับต่ำสุด) และหน้าจอแสดงเป็น "+N Gold" ของตัวผู้เล่น
- Merchant: ผู้ซื้อจ่ายจาก Gold ของตัวละครตัวเอง ราคาลดตาม CHA ของผู้ซื้อ
- `transfer_gold {to, amount}` ใช้ได้ที่ Merchant และ Rest จากตัวละครของตัวเองไปตัวใดก็ได้ใน Party
- ตอน Merchant/Rest เปิด AI โอน Gold ทั้งหมดของตัวเองให้ผู้เล่นจริงแบบแบ่งเท่า (เพื่อไม่ให้ Gold จม)
- คลังของยังเป็นของร่วม ชื่อบนจอคือ **Stash**; `transfer_item {item, to}` ย้าย Item ใช้แล้วหมด (consumable) จาก Stash ไปช่อง **Consumable** ของตัวละคร (ช่องละ 1 ชนิด) และปุ่ม Items ใน Combat ใช้ของในช่อง Consumable ก่อนแล้วจึงใช้ของใน Stash

## Considered Options

- **เปลี่ยนแค่ชื่อบนจอ**: เสี่ยงน้อยสุด แต่เจ้าของงานเลือกให้เหมือนทั้งระบบ
- **ทิ้ง atk/def/mag เดิมแล้วคำนวณ damage จาก attribute ตรงๆ**: เหมือน AAC กว่า แต่ต้องเขียนสูตรใหม่และ balance ใหม่ทั้งหมดใน 3 วัน จึงใช้ attribute เป็นชั้นที่คำนวณเป็น stat เดิมแทน

## Consequences

- `CONTEXT.md` ต้องอัปเดต: Gold (ส่วนตัว), Energy (ศัตรูมี Energy), Attribute, Focus, Strike/Guard, Stash
- ADR-0011 ข้อ "Gold และคลังเป็นของทั้ง Party / ไม่มี Transfer Gold" ถูกแทนด้วยข้อ 4
- regression win rate ยังต้องอยู่ในช่วง 70–97% (`tools/simulate.gd`)

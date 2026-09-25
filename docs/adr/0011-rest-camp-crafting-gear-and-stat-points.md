---
status: accepted
---

# Rest เป็นแคมป์ที่คราฟต์ของ เปลี่ยน Gear และลง Stat point ได้ พร้อม Ready check (ขยาย scope ของ ADR-0003)

Spec ของ Forest vertical slice (#2) ตัด Equipment ออกจาก scope และ Rest เดิมแค่ฟื้น HP แล้วไปต่อเองใน 4 วินาที ตั๋ว #36 และ #37 ขอหน้า Rest แบบ AAC (`docs/references/aac_rogue/08–10`) ที่มี Crafting, คลังร่วม, Equipment 8 ช่อง, สถิติ, ปุ่ม Invest Points และ `Ready (x/N)` เราจึงขยาย scope ดังนี้ โดยใช้ข้อมูล content ทั้งหมดและให้ server ตัดสินทุกอย่างตาม ADR-0001

## กติกาหลัก

- **Rest camp**: ฟื้น HP ตามเดิม แล้วแคมป์เปิดค้างจนผู้เล่นจริงทุกคนกด Ready หรือหมดเวลา (`encounters.rest.seconds`, ค่าเริ่มต้น 60 วินาที) slot ที่เป็น AI ไม่ต้องกด Ready และผู้เล่นที่หลุดนับเป็น Ready ทันที
- **Material**: ศัตรูทุกชนิดใน Forest มีโอกาสดรอป material (`items.<id>.kind = "material"`) เข้าคลังร่วม
- **Crafting**: ผู้เล่นจริงคนใดก็คราฟต์ได้จาก material ในคลังร่วม ตามสูตรใน `crafting.recipes`; หมวดตามภาพอ้างอิงคือ Boots, Robes, Charms, Vials, Quivers
- **Gear**: ตัวละครมี 8 ช่อง (Helmet, Chest, Legs, Boots, Weapon, Charm ×3); gear บวกค่า stat ตามข้อมูล `items.<id>.gear.stats`; ผู้เล่นจริงใส่/ถอด gear ได้เฉพาะตัวละครของตัวเองและเฉพาะที่ Rest; ของที่ถอดกลับเข้าคลังร่วม
- **Stat point**: ทุก level-up ได้ `leveling.points_per_level` แต้ม ลงได้ที่ Rest ตามอัตรา `leveling.invest`
- **AI**: ตอนแคมป์ปิด AI ลงแต้มทั้งหมดใน `invest_focus` ของ Class และใส่ gear ที่ยังเหลือในคลังให้ช่องที่ว่าง (ผู้เล่นจริงได้เลือกก่อนเสมอ)
- Gold และคลังของยังเป็นของทั้ง Party ตาม `CONTEXT.md` จึง**ไม่มี** Transfer Gold และปุ่ม Transfer ของภาพอ้างอิงกลายเป็น **Equip** (ย้ายของจากคลังร่วมไปใส่ตัวละครของตัวเอง)
- material และ gear ใช้เป็น Item ใน Combat ไม่ได้ (server ปฏิเสธด้วย `item_unusable`)

## Considered Options

- **คง Rest แบบเดิมและทำแค่ UI 3 คอลัมน์**: ไม่ต้องขยาย scope แต่คอลัมน์ Crafting และ Equipment จะเป็นกล่องว่างที่กดไม่ได้ ซึ่งหลอกผู้เล่น
- **Gear ต่อผู้เล่นพร้อม Transfer ระหว่างผู้เล่น**: ตรงภาพอ้างอิงกว่า แต่ขัดกับ Gold/คลังร่วมใน `CONTEXT.md` และเพิ่มกรณีขัดแย้งตอนผู้เล่นหลุด

## Consequences

- ADR-0003 และ spec #2 ข้อ "Equipment system อยู่นอก scope" ถูกแทนด้วย ADR นี้
- Rest ใช้เวลานานขึ้นตามการตัดสินใจของผู้เล่น (pacing model ของ `MatchBot` เพิ่ม `rest` 30 วินาที)
- ความยากเพิ่ม/ลดตามการใช้ gear และแต้ม; regression ยังต้องอยู่ในช่วง win rate เดิม

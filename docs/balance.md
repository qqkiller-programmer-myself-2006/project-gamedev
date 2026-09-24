# Balance และ pacing ของ Forest vertical slice

ตัวเลข balance ทั้งหมดอยู่ใน `content/forest.json` เอกสารนี้บันทึกค่าที่ตั้งไว้ วิธีวัด
และผลการวัดล่าสุด (issue #18)

## วิธีวัด

```bash
# เล่น Match เต็มด้วย bot (ผ่าน Match interface) หลาย seed แล้วพิมพ์สถิติ
godot --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2 --pace
```

- `--pace` ให้ bot "คิด" ก่อนตอบแต่ละการตัดสินใจตาม `MatchBot.HUMAN_PACE`
  (โหวต 10s, turn ใน combat 8s, Class offer 10s, Merchant 25s, อ่าน Story 25s)
- bot ใช้ `MatchBot.sensible_route`: หา Class เมื่อยังมีตัวละคร Classless ≥ 2,
  พักเมื่อ HP รวม < 55%, ซื้อของเมื่อมี Gold ≥ 25, นอกนั้นสู้เพื่อ EXP/Gold
- bot ใน combat: Defend เมื่อ Boss telegraph ใส่ตัวเอง, Shield Wall เมื่อ telegraph
  ทั้ง Party, revive/heal เพื่อนด้วย Item, ใช้ Skill ที่พร้อม, ไม่งั้นตีศัตรูที่เลือดน้อยสุด
- regression suite `tests/regression/test_full_runs.gd` รันใน CI: 40 seed ต่อโหมด,
  ตรวจว่าจบทุก seed, ไม่มี command ผิดกติกา และ win rate อยู่ในช่วง 70–97%

## ค่าหลักที่ตั้งไว้

| หมวด | ค่า |
| --- | --- |
| Pacing (server) | Action window 15s, AI turn 2.0s, enemy turn 2.2s, travel 3s, หน้าสรุป combat 4s, โหวต 20s |
| Leveling | EXP ต่อเลเวล 18 / 30 / 45 / 65 / 90 / 120; ต่อเลเวล +6 HP, +2 ATK, +2 MAG, +1 DEF, +1 RES |
| Classless | HP 40, ATK 8, DEF 3, MAG 4, RES 3, SPD 10 |
| Grey Wolf | HP 64, ATK 10, SPD 13 — 14 EXP, 6 Gold |
| Thornback Boar | HP 120, ATK 13, DEF 5, SPD 7 — 20 EXP, 10 Gold |
| Bramble Archer | HP 52, ATK 11, SPD 11 (แถวหลัง) — 16 EXP, 12 Gold |
| Forest Wisp | HP 46, MAG 10, RES 6 (แถวหลัง, heal 18) — 18 EXP, 9 Gold |
| Guardian Boss | HP 900, ATK 17, MAG 14; 3 phase ที่ 100% / 66% / 33% (+2 ATK/MAG ต่อ phase, +3 SPD ใน phase 2); Crushing Root ×2.3 ATK, Thorn Storm ×1.15 MAG ทั้ง Party |
| Class Encounter | Challenge 3 round, ผ่านได้ 12 EXP ทุกคน; AI รับ Class เดียวกันได้ไม่เกิน 2 ตัว |
| Rest / ร้านค้า | Rest ฟื้น 70% ของ max HP; Herb 12, Tonic 28, Spirit Bloom 40, Firebomb 24 Gold |
| Energy (issue #22) | เริ่ม Combat ที่ 1, +1 ต่อเทิร์นของตัวเอง, สูงสุด 6; Power Slash 2, Aimed Shot 2, Fireball 2, Frost Lance 1, Protect 1, Shield Wall 2 |

## ผลล่าสุด (100 seed ต่อโหมด, `--pace`)

| | Single-player | Duo co-op |
| --- | --- | --- |
| Win rate | 86% | 81% |
| แพ้ที่ | Boss 11, ระหว่างทาง 3 | Boss 12, ระหว่างทาง 7 |
| เลเวลเฉลี่ยตอนจบ | 3.55 | 3.64 |
| Combat rounds (รวม Challenge) / Boss rounds | 26.6 / 14.5 | 27.3 / 13.9 |
| เวลาจำลองเฉลี่ย (min–max) | 9.6 นาที (6.4–20.8) | 12.7 นาที (7.8–29.0) |
| เวลาตามส่วน (นาที) | Boss 4.3, Combat 2.6, Class 1.3, โหวต 0.9 | Boss 5.4, Combat 4.6, Class 1.2, โหวต 0.9 |

ทั้งสองโหมดชนะเป็นส่วนใหญ่ แต่ Boss ยังชนะ Party ได้ราว 1 ใน 8 Match
และความยากไม่ต่างกันตามจำนวนผู้เล่นจริง (Party 5 ตัวเสมอ ตาม ADR-0002)

## ⚠️ Pacing ต่ำกว่าเป้า 20–30 นาทีของ ADR-0003

เวลาที่จำลองได้ (~10–13 นาที) ต่ำกว่าเป้า 20–30 นาที ถึงจะปรับ AI/enemy turn ให้ช้าลงเพื่อ
อ่านทัน และเพิ่ม HP ศัตรูแล้ว เหตุผลหลักคือ 5 Layers ให้ Encounter แค่ 5 ครั้งบวก Boss
และเวลาเกือบทั้งหมดอยู่ใน combat; โมเดลนี้เป็น **ขอบล่าง** เพราะไม่นับเวลาที่ผู้เล่นจริงคุยกัน
อ่าน tooltip ดู animation หรือเรียนรู้ระบบครั้งแรก ต้องยืนยันด้วยการเล่นจริงใน #19

ถ้าการเล่นจริงยังสั้นกว่าเป้า ตัวเลือกที่ปรับได้โดยไม่แตะ logic:

- เพิ่ม HP ศัตรู/Boss (fight ยาวขึ้น แต่เสี่ยงน่าเบื่อ)
- เพิ่มขนาดกลุ่มศัตรูใน Layer 3–5
- ให้หน้าสรุป combat รอทุกคนกดพร้อม (เหมือน Story/Merchant)
- เพิ่มจำนวน Layer — ต้องแก้ ADR-0003 ก่อน

## ผล Energy economy (issue #22) — 100 seed ต่อโหมด, ไม่มี `--pace`

`godot --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2`
ค่า Energy: Power Slash 2, Aimed Shot 2, Fireball 2, Frost Lance 1, Protect 1, Shield Wall 2

| | Single-player | Duo co-op |
| --- | --- | --- |
| Win rate | 85% | 82% |
| แพ้ที่ | Boss 12, ระหว่างทาง 3 | Boss 11, ระหว่างทาง 7 |
| Combat rounds / Boss rounds | 27.9 / 14.7 | 28.4 / 14.2 |
| เลเวลเฉลี่ยตอนจบ | 3.54 | 3.65 |
| command ที่ถูกปฏิเสธ | 0 | 0 |

win rate แทบไม่เปลี่ยนจากก่อนมี Energy (86% / 81%) เพราะ Skill ถูกใช้น้อยลงใน turn แรกแต่ยังใช้ได้เกือบทุก turn หลังจากนั้น

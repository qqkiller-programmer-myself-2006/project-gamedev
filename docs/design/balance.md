# Balance และ pacing ของ Forest vertical slice

ตัวเลข balance ทั้งหมดอยู่ใน `content/forest.json` เอกสารนี้บันทึกค่าที่ตั้งไว้ วิธีวัด
และผลการวัดล่าสุด (issue #18)

## วิธีวัด

```bash
# เล่น Match เต็มด้วย bot (ผ่าน Match interface) หลาย seed แล้วพิมพ์สถิติ
godot --headless --path . -s tools/dev/simulate.gd -- --seeds=100 --humans=1,2 --pace
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
| Rest camp (ADR-0011) | material ดรอป 50% ต่อศัตรู 1 ตัว; gear +1–2 stat (Charm/Quiver/Boots/Robe); 1 stat point ต่อ level (+5 Max HP หรือ +1 stat อื่น); แคมป์เปิดสูงสุด 60 วินาที |
| Rest / ร้านค้า | Rest ฟื้น 70% ของ max HP; Herb 12, Tonic 28, Spirit Bloom 40, Firebomb 24 Gold |
| Energy (issue #22) | เริ่ม Combat ที่ 1, +1 ต่อเทิร์นของตัวเอง, สูงสุด 6; Power Slash 2, Aimed Shot 2, Fireball 2, Frost Lance 1, Protect 1, Shield Wall 2 |

## ผลล่าสุด (100 seed ต่อโหมด, `--pace`)

| | Boss Energy | Boss spends all its accumulated Energy whenever it unleashes a telegraphed move, making the energy bar serve as a visual indicator for its ultimate attacks. |
| Single-player | Duo co-op |
| --- | --- | --- |
| Win rate | 88% | 82% |
| แพ้ที่ | Boss 10, ระหว่างทาง 2 | Boss 17, ระหว่างทาง 1 |
| เลเวลเฉลี่ยตอนจบ | 3.70 | 3.77 |
| Combat rounds (รวม Challenge) / Boss rounds | 24.8 / 12.4 | 26.1 / 13.9 |
| เวลาจำลองเฉลี่ย (min–max) | 9.2 นาที (6.5–16.6) | 12.2 นาที (8.4–32.7) |
| เวลาตามส่วน (นาที) | Boss 3.6, Combat 2.8, Class 1.3, โหวต 0.9 | Boss 5.3, Combat 4.1, Class 1.2, โหวต 0.9, Rest 0.1 |

วัดใหม่หลัง ADR-0011 (material drop, crafting, gear และ stat point ที่ Rest camp): win rate และเวลา
ใกล้เดิม เพราะ bot เลือก Rest เฉพาะตอน HP ต่ำ; ผลของ gear จึงยังเล็ก ต้องดูจากการเล่นจริงอีกครั้ง

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

`godot --headless --path . -s tools/dev/simulate.gd -- --seeds=100 --humans=1,2`
ค่า Energy: Power Slash 2, Aimed Shot 2, Fireball 2, Frost Lance 1, Protect 1, Shield Wall 2

| | Boss Energy | Boss spends all its accumulated Energy whenever it unleashes a telegraphed move, making the energy bar serve as a visual indicator for its ultimate attacks. |
| Single-player | Duo co-op |
| --- | --- | --- |
| Win rate | 85% | 82% |
| แพ้ที่ | Boss 12, ระหว่างทาง 3 | Boss 11, ระหว่างทาง 7 |
| Combat rounds / Boss rounds | 27.9 / 14.7 | 28.4 / 14.2 |
| เลเวลเฉลี่ยตอนจบ | 3.54 | 3.65 |
| command ที่ถูกปฏิเสธ | 0 | 0 |

win rate แทบไม่เปลี่ยนจากก่อนมี Energy (86% / 81%) เพราะ Skill ถูกใช้น้อยลงใน turn แรกแต่ยังใช้ได้เกือบทุก turn หลังจากนั้น

## ผลหลังเพิ่ม Attributes 7 ตัว (issue #25) — 100 seed ต่อโหมด, `--pace`

| | Boss Energy | Boss spends all its accumulated Energy whenever it unleashes a telegraphed move, making the energy bar serve as a visual indicator for its ultimate attacks. |
| Single-player | Duo co-op |
| --- | --- | --- |
| Win rate | 87% | 88% |
| แพ้ที่ | Boss 12, ระหว่างทาง 1 | Boss 10, ระหว่างทาง 2 |
| Combat rounds / Boss rounds | 25.5 / 13.1 | 26.8 / 13.8 |
| เลเวลเฉลี่ยตอนจบ | 3.70 | 3.80 |

ผล win rate ลดลงเล็กน้อยแต่อยู่ในเกณฑ์ 70–97% ตามที่กำหนดไว้

## ผลหลังเพิ่ม Loadout (ADR-0013) — #59

ก่อนปรับ: โหมด Loadout (เลือก Class/Race/Boons ก่อนเริ่ม) ชนะเกือบ 100% เพราะได้ Class ตั้งแต่ต้น

| ค่าใน `content/forest.json` | ก่อน | หลัง | เหตุผล |
| --- | --- | --- | --- |
| Classless base HP / ATK / DEF | 28 / 5 / 2 | 42 / 12 / 4 | โหมดปกติเริ่มแบบไม่มี Class ต้องอยู่รอดช่วงต้นได้ |
| Class base (Swordsman, Archer, Mage, ...) | — | HP −4, ATK/MAG/DEF −1 | ลดความได้เปรียบของการมี Class ตั้งแต่ต้น |
| บอส Guardian HP / ATK | 900 / 17 | 1450 / 18 | บอสเป็นจุดตัดสินหลักของทุกโหมด |
| Class Trial `mastery_exp` / `pass_exp` | 15 / 12 | 0 / 40 | ผ่าน Trial แล้วเลเวลขึ้นเร็วขึ้น |

บอททดสอบ (`tests/support/match_bot.gd`) ในโหมด Story ใช้ `PartyAi` ตาม Class ของแต่ละตัวแทนการกดโจมตีอย่างเดียว

### Win rate (`tools/dev/simulate.gd`, 100 seeds จาก 1000)

| โหมด | 1 คน | 2 คน |
| --- | --- | --- |
| Default (เริ่มไม่มี Class) | 84% | 75% |
| Loadout (`--loadout`) | 79% | 90% |
| Story (`--story`, คุม 5 ตัว) | 75% | — |

ทุกโหมดอยู่ในช่วง 70–92% แพ้ที่บอสทั้งหมด; Story มีคำสั่งถูกปฏิเสธ 4 ครั้งจากบอท (ติดตามใน #67)

## Layer 5 Cave pass (T20b, 100 seeds from 1000)

Baseline recorded before cave enemies: Default 84% / 75%, Loadout 79% / 90%, Story 75% (single-player). After adding the cave groups and tuning their stats: Default 85% / 77%, Loadout 84% / 92%. All four measured modes are within the target 70-92%. Story mode could not be re-measured: `simulate.gd --story` attempts `set_loadout` before enabling `MatchServer.allow_story`, so the first loadout command returns `not_in_room`; the task scope excludes edits to `tools/dev/simulate.gd`.

| Cave enemy | HP | ATK | DEF | MAG | RES | SPD | Behaviour | Special |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Kobold | 80 | 11 | 3 | 0 | 2 | 18 | random | Spear Rush (2 Energy) |
| Skeleton | 110 | 12 | 7 | 0 | 4 | 9 | charge_strongest | Shield Bash (2 Energy) |
| Giant Spider | 100 | 11 | 4 | 13 | 7 | 12 | random | Venom Web (3 Energy) |
| Minotaur | 155 | 17 | 6 | 0 | 4 | 8 | charge_strongest | Bull Rush (3 Energy) |

## T21 re-tuning (#65: Race/Boon bonuses now apply before derived stats)

Human (+1 all), Elf and Chosen One bonuses used to do nothing; once they applied, Race-less AI slots fell behind and the
Classed party got stronger. Changes in `content/forest.json`:

| Value | Before | After |
| --- | --- | --- |
| Classless base HP / DEF / RES | 42 / 4 / 2 | 50 / 5 / 3 |
| Class base ATK (Swordsman, Archer, Guardian, Assassin) / Mage MAG | 5, 3, 4, 4 / 6 | 4, 2, 3, 3 / 5 |
| Guardian boss HP / ATK / MAG | 1450 / 18 / 14 | 1350 / 20 / 16 |
| Class Trial `pass_exp` | 40 | 60 |

Critical Healing follows ADR-0013 (a crit heals the attacker for 20% of the damage dealt).

### Win rate after #65 (`tools/dev/simulate.gd`, 100 seeds from 1000)

| Mode | 1 player | 2 players |
| --- | --- | --- |
| Default | 87% | 79% |
| Loadout | 87% | 93% |
| Story | 77% | — |

Loadout with 2 players is 1 point above the 92% target, inside the ±3% noise of 100 seeds. Raising the boss HP to 1400
did not move it (93%) but dropped Story to 69% and default 2-player to 73%, so the boss stays at 1350. Revisit with more
seeds during QA (#54).

## T26 enemy first-turn Energy re-tuning (#71)

ADR-0012 now applies the enemy's +1 Energy at the start of its first turn as well as later turns. To keep every measured
mode inside the 70–92% target, Heavy Charge and Bull Rush cost 2 Energy instead of 3. Story mode uses the documented
`rules.story_enemy_energy_max = 1`; normal Multiplayer keeps `rules.enemy_energy_max = 4`, so its enemies continue to use
their 2–3 Energy specials.

Final 100-seed runs from seed 1000:

| Mode | 1 player | 2 players |
| --- | ---: | ---: |
| Default | 79% | 74% |
| Loadout (`--loadout`) | 79% | 91% |
| Story (`--story`) | 76% | — |

All five measured modes are inside the target. Rejected commands were 0 in every run.

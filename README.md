# BEYOND THE WORLD'S END — Forest vertical slice

Online co-op fantasy turn-based RPG built with **Godot 4.7** and **GDScript**.
The current goal is the Forest vertical slice described in
[issue #2](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/2).

- Domain glossary: [`CONTEXT.md`](CONTEXT.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Product requirements: [`docs/prd.md`](docs/prd.md)
- Testing guide: [`docs/testing.md`](docs/testing.md)
- Running server and clients: [`docs/running.md`](docs/running.md)
- Balance and pacing: [`docs/balance.md`](docs/balance.md)
- Browser build: [`docs/web.md`](docs/web.md)
- Accessibility checklist: [`docs/accessibility.md`](docs/accessibility.md)
- Staging and QA checklist: [`docs/staging.md`](docs/staging.md)

## Project layout

```text
project.godot          Godot project (one codebase for server, PC and browser)
content/forest.json    All Forest content, text and balance numbers
assets/fonts/          Pixelify Sans (OFL, see OFL.txt) for headings, buttons and numbers
src/core/              Injected dependencies: GameRng, ManualClock, SystemClock, ForestContent
src/match/             Authoritative game logic behind the Match interface (MatchServer),
                       including StatusBook (Status effects / DoTs)
src/net/               Wire protocol, WebSocket server transport and client connection
src/server/            Headless server node (GameServer)
src/client/            Client UI: screens, per-phase panels, theme, settings, sounds
src/client/battle/     Full-screen BattleView (fights) and CampView (Merchant / Rest)
src/app/               Entry point: --server starts the server, otherwise the client
tests/                 Headless tests (runner, Match tests, regression, network)
tools/                 simulate.gd (balance), ui_preview.gd (screenshots), web_smoke.mjs
deploy/                Staging: server container, Caddy (HTTPS + wss proxy), compose
scripts/               Command-line helpers
docs/references/       AAC Rogue reference screenshots the battle/camp UI follows
docs/screenshots/      Current battle and camp screens (from tools/ui_preview.gd)
```

## Quick start

```bash
# Godot 4.7.2 must be on PATH as `godot` (or set GODOT=/path/to/godot)
./scripts/run_tests.sh                               # all tests, headless
godot --headless --path . -- --server --port=8910    # authoritative server
godot --path . -- --url=ws://127.0.0.1:8910          # PC client (open two for co-op)
```

## The Match interface

`MatchServer` (`src/match/match_server.gd`) is the only seam game logic is
tested through. It receives three dependencies from outside — a `GameRng`
seed, a clock and `ForestContent` — and exposes:

| Call | Purpose |
| --- | --- |
| `open_session()` | Anonymous session for a new connection |
| `command(session, cmd)` | Apply a command; returns `{"ok": true, ...}` or `{"ok": false, "error": code}` |
| `update()` | Process timers due at `clock.now()` |
| `take_events(session)` | Events this session should see |
| `snapshot(session)` | State this session should see |
| `close_session(session)` | Connection dropped |

## งานล่าสุด: Energy, DoT, Rogue และหน้าจอแบบ AAC

งานชุดนี้ส่งใน [PR #29](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/pull/29)
(merge แล้ว, ปิด #22–#26) โดยอ้างอิงระบบและหน้าตาจากเกม An Average Campaign (AAC)
ดูรายละเอียดของภาพอ้างอิงที่ [`docs/references/aac_rogue/`](docs/references/aac_rogue/README.md)

**ขนาดงาน:** 7 commit, 60 ไฟล์ (+3,469 / −60) โดย 34 ไฟล์อยู่ใน `src/`, `tests/`, `content/`, `tools/`
(+3,070 / −55 บรรทัด) จำนวน test เพิ่มจาก 186 เป็น **227** (+41 ข้อใน 4 ไฟล์ใหม่)

### สารบัญ

1. [การตัดสินใจ (ADR)](#1-การตัดสินใจ-adr)
2. [Energy (#22)](#2-energy-22)
3. [Status effect และ DoT (#23)](#3-status-effect-และ-dot-23)
4. [Rogue (#24)](#4-rogue-24)
5. [Battle HUD (#25)](#5-battle-hud-25)
6. [หน้าแคมป์ (#26)](#6-หน้าแคมป์-26)
7. [วิธีลองใช้](#7-วิธีลองใช้)
8. [ผลการตรวจสอบ](#8-ผลการตรวจสอบ)
9. [ผล code review](#9-ผล-code-review)
10. [คะแนน review](#10-คะแนน-review)
11. [งานที่ต้องทำต่อ](#11-งานที่ต้องทำต่อ)

### 1. การตัดสินใจ (ADR)

| ADR | เรื่อง | ทางเลือกที่ไม่เลือก |
| --- | --- | --- |
| [0009](docs/adr/0009-energy-and-cooldown-skills.md) แทน [0005](docs/adr/0005-skill-cooldowns.md) | Skill ทุก Class ใช้ **Energy และ cooldown** ร่วมกัน (ADR-0005 เลือก cooldown อย่างเดียว ตอนนี้สถานะเป็น `superseded`) | คง cooldown อย่างเดียว (ไม่มีจังหวะเก็บพลังให้ Rogue) และ Energy เฉพาะ Rogue (มีสองระบบในเกมเดียว) |
| [0010](docs/adr/0010-rogue-class-and-dot-status-effects.md) ขยาย [0003](docs/adr/0003-forest-production-vertical-slice.md) | เพิ่ม **Rogue** เป็น Tier 1 Class ตัวที่ 5 พร้อมระบบ **Status effect / DoT** และ passive **Enervation** | ทำแค่ระบบ DoT โดยไม่เพิ่ม Class (ไม่มี Class ที่ใช้ระบบนี้จริง) |

คำศัพท์ที่เพิ่มใน [`CONTEXT.md`](CONTEXT.md): Energy, Rogue, Status effect, DoT, Enervation

จุดที่ต่างจากภาพอ้างอิงโดยตั้งใจ: ปุ่มหลักยังเป็น **Attack / Skill / Defend / Item** ตาม glossary
(ภาพใช้ Fight / Items / Focus และ Strike / Guard) และ Party มี 5 ตัวละคร (ภาพมี 4)

### 2. Energy (#22)

**กติกา** (ค่าอยู่ใน `rules.energy_start / energy_regen / energy_max` ของ `content/forest.json`)

| ข้อ | ค่า |
| --- | --- |
| เริ่มทุก Combat และทุก Challenge | 1 (ใช้ได้ใน turn แรก ไม่ได้ regen เพิ่มใน turn แรก) |
| Regen | +1 ตอนเริ่มทุก turn ถัดไปของตัวเอง รวม turn ที่หมด Action window แล้ว Defend อัตโนมัติ |
| สูงสุด | 6 |
| รีเซ็ต | ทุก Combat และทุก Challenge |
| Attack, Defend, Item | 0 Energy |
| ศัตรูและ Guardian Boss | ไม่มี Energy |

**ค่าใช้ของ Skill เดิม** (cooldown ไม่เปลี่ยน): Power Slash 2, Aimed Shot 2, Fireball 2, Frost Lance 1, Protect 1, Shield Wall 2

**ข้อมูลที่ส่งให้ client**
- `party[].energy` และ `party[].energy_max` ให้ทุกผู้เล่นเห็นของทุกตัวละคร
- `choices.skills.<id>` มี `name`, `description`, `cooldown`, `energy` (ค่าใช้), `affordable`, `target`, `targets` โดย `targets` ว่างเมื่อ Skill ยังใช้ไม่ได้
- event `action_resolved` ของ Skill ที่ Party ใช้มี `energy_spent` และ `energy` (ค่าที่เหลือ)
- คำสั่ง Skill ที่ Energy ไม่พอถูกปฏิเสธด้วย error `not_enough_energy` โดยสถานะไม่เปลี่ยน

AI ทุก preset และ `MatchBot` ตรวจ `can_afford` ก่อนใช้ Skill ผลคือ turn แรกของ Combat มักเป็น Attack
(เช่น Swordsman AI เก็บ Energy ใน turn แรกแล้วใช้ Power Slash ใน turn ที่สอง)

### 3. Status effect และ DoT (#23)

**โมดูลใหม่:** `StatusBook` ([`src/match/status_book.gd`](src/match/status_book.gd), 138 บรรทัด) เก็บ Status effect ของทุกตัวใน Combat หนึ่งครั้ง
`CombatEncounter` สร้างเมื่อ Combat เริ่มและเรียก `clear()` เมื่อจบ ดังนั้น Status effect ไม่ข้าม Combat และไม่ข้าม Challenge

**DoT 3 ชนิดใน content (`statuses.*`)**

| ชนิด | damage ต่อ stack ต่อ tick | duration | stack สูงสุด |
| --- | --- | --- | --- |
| Bleed | 3 | 3 turn | 5 |
| Poison | 2 | 4 turn | 5 |
| Toxin | 5 | 2 turn | 3 |
| `venom_coat` (สถานะ buff ของ Prep Time) | ไม่ทำ damage | 4 turn | 1 (มี `charges` 3) |

**กติกา**
- **ลำดับใน turn:** tick ของ DoT → ได้ Energy → ตัวที่ยังไม่ล้มจึงลงมือ (มี comment กำกับที่ hook `_begin_turn`)
- **damage ของ tick:** ต่อ stack × จำนวน stack × ตัวคูณของผู้ติด × ตัวคูณของผู้รับ ปัดเป็นจำนวนเต็ม ขั้นต่ำ 1 และ**ไม่ผ่าน DEF/RES**
- **duration:** ทุก status ลด 1 ตอนเริ่ม turn ของผู้ถือ และหลุดเมื่อถึง 0
- **ติดซ้ำชนิดเดิม:** เพิ่ม stack (ไม่เกิน `max_stacks`) และ duration เป็นค่าที่มากกว่าระหว่างเดิมกับใหม่ ต่างชนิดอยู่ร่วมกันได้
- **ล้ม:** ล้มเพราะ DoT ได้ทั้งศัตรูและตัวละคร ตัวที่ล้มเสีย turn นั้นและ Combat จบกลาง tick ได้ (ศัตรูที่ล้มเพราะ DoT ให้ reward ตามปกติ) ใน Challenge ตัวละครไม่ล้ม (HP ต่ำสุด 1 ตามกติกา Challenge เดิม)

**คีย์ใหม่ใน profile ของ Skill/Item/การโจมตีศัตรู**

| คีย์ | ความหมาย |
| --- | --- |
| `apply_status: [{status, stacks, turns}]` | ติด status ให้เป้า (`turns` = 0 หมายถึงใช้ค่าตาม content) |
| `hits: N` | โจมตี N ครั้งใส่เป้าเดียว (หยุดเมื่อเป้าล้ม) |
| `status_per_hit: true` | ติด status ทุกครั้งที่โดน ไม่ใช่ครั้งเดียวหลังโจมตีครบ |
| `damage.pierce` | ข้าม DEF/RES ตามสัดส่วนนี้ (0–1) |
| `damage.per_dot` | เพิ่ม `power` ต่อชนิด DoT บนเป้า |
| `passive` ของ Class | `dot_bonus`, `dot_bonus_cap`, `dot_out`, `dot_in` (Enervation) |

**ข้อมูลที่ส่งให้ client**
- `encounter.statuses` = `{unit id: [{status, name, kind, stacks, turns, charges}]}` ครอบคลุมทั้ง Party และศัตรู และ `enemies[].statuses` ในรายการศัตรู
- event `status_applied` `{target, source, status, name, kind, stacks, turns, charges}`
- event `status_tick` `{round, target, status, name, damage, hp, down}`
- event `status_expired` `{target, status}`

### 4. Rogue (#24)

**Class ที่ 5** ค้นพบที่ Class Encounter ใหม่ **Bandit Hideout** โดยต้องชนะ Challenge 3 round กับ **Masked Outlaw**
(HP 60, ไม่มี reward และไม่มีใครล้ม เหมือน Challenge ของ Class อื่น) route generator เสนอ Rogue ได้และ guarantee เดิม
(Class Encounter ภายใน Layer 2, Merchant ก่อน Boss) ยังทำงาน

| Class | HP | ATK | DEF | MAG | RES | SPD | Crit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Classless | 40 | 8 | 3 | 4 | 3 | 10 | 5% |
| Swordsman | 52 | 12 | 5 | 3 | 3 | 10 | 8% |
| Archer | 44 | 11 | 3 | 3 | 3 | **15** | 25% |
| Mage | 38 | 5 | 2 | 14 | 6 | 9 | 5% |
| Guardian | 70 | 9 | 9 | 2 | 6 | 7 | 5% |
| **Rogue** | 42 | 11 | 3 | 3 | 3 | 12 | 18% |

SPD ของ Rogue ตั้งที่ 12 เพื่อให้ Archer ยังเป็น Class ที่เร็วที่สุดตามที่ test เดิมกำหนด (test ปรับเกณฑ์ "Class อื่นช้ากว่า" เป็น ≤ 12)

**Skill** (ค่า Energy และ cooldown ตรงกับภาพ 05 ส่วน damage ปรับได้ใน content)

| Skill | Energy | Cooldown | ผล |
| --- | --- | --- | --- |
| Stab | 1 | 4 | 130% ATK, เจาะ DEF 50% และติด Bleed 1 stack |
| Prep Time | 1 | 6 | เคลือบอาวุธ: การกระทำที่ทำ damage ศัตรู (Attack หรือ Skill) 3 ครั้งถัดไปติด Poison 1 stack เพิ่ม ใช้ได้ภายใน 4 turn ของตัวเอง ไม่งั้นหลุด |
| Poke Up | 2 | 3 | แทง 3 ครั้ง ครั้งละ 55% ATK ใส่เป้าเดียว ทุกครั้งติด Bleed |
| Inject Venom | 2 | 6 | 100% ATK + 40% ต่อชนิด DoT บนเป้า แล้วติด Toxin 2 stack |

**Enervation** (passive) มี 3 ส่วน
1. damage ตรงของ Rogue × (1 + 0.05 × จำนวนชนิด DoT บนเป้า) สูงสุด × 1.4 ใช้กับ damage ทุกแบบที่ผ่านการคำนวณ `_hit` **รวมถึง Item ที่ให้ damage คงที่ เช่น Firebomb** (เป็นการตีความที่ยังไม่ได้ยืนยันกับเจ้าของงาน)
2. DoT ที่ Rogue ติดแรงขึ้น 15% (`dot_out`)
3. Rogue รับ damage จาก DoT มากขึ้น 15% (`dot_in`)

**AI preset:** Prep Time ก่อนเมื่อพร้อมและยังไม่มีการเคลือบ → เลือกศัตรูที่มีชนิด DoT มากที่สุด (เสมอให้เลือกตัวที่ HP น้อยกว่า) →
Inject Venom เมื่อเป้ามี DoT ตั้งแต่ 2 ชนิด → ไม่งั้น Poke Up, Stab, แล้วโจมตีธรรมดา

### 5. Battle HUD (#25)

หน้าจอต่อสู้ (Combat, Challenge ของ Class Encounter และ Guardian Boss) เปลี่ยนจากรายการเป็นสนาม 2D เต็มจอ
ตามภาพ [04](docs/references/aac_rogue/04_combat_layout_turn_order.png),
[05](docs/references/aac_rogue/05_combat_skill_selection.png),
[06](docs/references/aac_rogue/06_skill_cast_action_banner.png),
[07](docs/references/aac_rogue/07_dot_status_stacking.png) และ
[11](docs/references/aac_rogue/11_dungeon_encounter_and_rewards.png)
ข้อมูลทุกอย่างมาจาก snapshot และ event ของ server ตัว client ไม่คำนวณผล (ADR-0001)

| ตำแหน่ง | สิ่งที่แสดง | ภาพอ้างอิง |
| --- | --- | --- |
| ซ้าย | "Turn N" และ initiative timeline: ชื่อ (SPD), แถบ HP สีแดง, แถบ Energy สีฟ้า ของทุกตัวตามลำดับ turn ไฮไลต์ตัวที่ถึงตา ตัวที่เล่นไปแล้วในรอบนี้จางลง | 04 |
| กลางจอ | Party ซ้าย ศัตรูขวา (แถวหน้า/หลัง) ทุกตัวมีป้ายชื่อ พร้อมแถบ HP และ Energy (Party เท่านั้น) วงแหวนไฮไลต์ตัวที่ถึงตา Boss ตัวใหญ่กว่า | 04, 07 |
| เหนือป้ายชื่อ | badge ของ Status effect: ตัวย่อ (BLD/PSN/TOX/PREP) + stack + turn ที่เหลือ + tooltip | 07 |
| ขวาบน | "Forest (Layer/5)" (ตอนบอสแสดง "Forest (Boss)") และ round หรือ Challenge x/y | 04 |
| ล่างกลาง (HUD) | Class, Lvl, EXP/next, เวลา Action window, Gold, แถบ HP, แถบ Energy 6 ช่อง, ปุ่ม Attack / Skill / Defend / Item | 04 |
| เหนือ HUD | grid การ์ด (Attack, Defend, แล้วตามด้วย Skill) แต่ละใบมีไอคอน ชื่อ และ "Cost: x \| Cooldown: y" ใบที่ใช้ไม่ได้จางพร้อมเหตุผลใน tooltip | 05 |
| ขวาของ HUD | ช่องเล็กแสดง cooldown ที่เหลือของแต่ละ Skill (OK / ตัวเลข / E# เมื่อ Energy ไม่พอ) | 06 |
| กลางล่าง | banner พาดจอบอกชื่อ Skill, Item หรือท่าของ Boss ทุกครั้งที่ใช้ | 06 |
| ซ้ายล่าง | ข้อความ reward หลังชนะ: Item, "+N Gold", "N EXP" และ log 3 บรรทัดสุดท้าย | 11 |

- **ตัวเลขลอย:** damage และ heal ลอยจากตัวละคร ส่วน DoT tick แสดงสีตามชนิด (Bleed แดง, Poison เขียว, Toxin ม่วง) **พร้อมตัวย่อ** ไม่ใช้สีอย่างเดียว
- **ปุ่มลัด:** A / S / D / I เลือก action, 1–9 เลือกการ์ดหรือเป้าหมาย, Esc ย้อนกลับ, Tab/ลูกศร + Enter ใช้กับการ์ดและ token ได้เพราะเป็นปุ่ม
- **เลือกเป้า:** คลิกหรือกดเลขบน token ที่เป็นเป้าได้ (ป้าย `[n]` และวงแหวนสีทอง)
- **font:** Pixelify Sans (OFL, [`assets/fonts/`](assets/fonts/)) ใช้กับหัวข้อ ปุ่ม ชื่อ และตัวเลข ส่วนข้อความยาวใช้ font เดิม
- **ส่วนประกอบ:** `BattleView` (จัดหน้าจอและ input), `BattleToken` (ตัวละครที่วาดด้วยโค้ด แยกเป็น component เพื่อเปลี่ยนเป็น sprite ภายหลังได้โดยไม่แตะ layout), `BattleBackdrop` (ฉากป่า)
- **ข้อมูลใหม่จาก server สำหรับหน้านี้:** `round_order` (ลำดับทั้ง round), `enemies[].spd`, `party[].exp_next`, `party[].crit`, `choices.skills[].description`
- **tutorial hint:** เพิ่ม hint ของ Energy และ DoT (แสดงครั้งเดียวตอนเจอครั้งแรก)

### 6. หน้าแคมป์ (#26)

Merchant และ Rest ใช้หน้า 3 คอลัมน์ตามภาพ [08](docs/references/aac_rogue/08_camp_crafting_and_inventory.png)

| คอลัมน์ | Merchant | Rest |
| --- | --- | --- |
| ซ้าย | สินค้า: ชื่อ ราคา จำนวนคงเหลือ ปุ่ม `[n] Buy` (disable พร้อม "Need N" เมื่อ Gold ไม่พอ) และ Inspect | ข้อความของจุดพักและ HP ที่ฟื้นของแต่ละตัว |
| กลาง | คลัง Item ร่วมของ Party และ Gold | เหมือนกัน |
| ขวา | stat sheet เลือกดูได้ทีละตัวละคร: Class, Lvl, HP, EXP, Energy สูงสุด, ATK, DEF, MAG, RES, SPD, Crit | เหมือนกัน |
| ล่าง | "Ready (x/y) [R]" และเวลาปิดร้าน | เวลาที่เดินทางต่อ |

ไม่มี Crafting, Equipment และการโอน Gold จากภาพ เพราะอยู่นอกขอบเขตของ [spec #2](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/2)

### 7. วิธีลองใช้

```bash
export GODOT="/path/to/Godot_v4.7.2-stable_win64_console.exe"   # หรือให้ godot อยู่ใน PATH
./scripts/run_tests.sh                                          # 227 test, ~90 วินาที
./scripts/run_tests.sh --filter=rogue                           # เฉพาะ test ที่ id มีคำว่า rogue

# วัด balance: เล่นเต็ม Match ด้วย bot หลาย seed
godot --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2

# จับภาพหน้าจอจริงของทุกหน้า (ต้องมี display) ให้ Rogue เป็น Class เดียวที่สอนได้
godot --path . -s tools/ui_preview.gd -- --out=build/ui --seed=11 --speed=10 --class=rogue

# เล่นเองบน browser
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . -- --server --port=8910
python -m http.server -d build/web 8060     # แล้วเปิด http://localhost:8060/?server=ws://localhost:8910&name=Ann&auto=1
```

### 8. ผลการตรวจสอบ

**Test:** `./scripts/run_tests.sh` ได้ **227 passed, 0 failed** (base ก่อน PR มี 186) test ใหม่ 41 ข้อ

| ไฟล์ | จำนวน | ครอบคลุม |
| --- | --- | --- |
| `test_energy.gd` | 14 | ค่าเริ่มต้น/regen/เพดาน, regen ตอนหมดเวลา, ค่าใช้และ `not_enough_energy` โดยสถานะไม่เปลี่ยน, รีเซ็ตระหว่าง Combat, ศัตรูไม่มี Energy, AI ไม่ใช้เกินตัว, ทุกผู้เล่นเห็น Energy ของทุกตัว |
| `test_status_effects.gd` | 11 | tick, stack/refresh, หลายชนิดพร้อมกัน, ลำดับก่อน Energy regen, หมดอายุ, ล้มเพราะ DoT (ศัตรูและตัวละคร), Combat จบกลาง tick, modifier ขาออก/ขาเข้า |
| `test_rogue.gd` | 12 | ทุก Skill, Enervation ทั้ง 3 ส่วนและเพดาน, Prep Time 3 ครั้งแล้วหมด, AI, การรับ Class ที่ Bandit Hideout |
| `test_battle_view_data.gd` | 4 | `round_order`, `spd`, `exp_next`, `crit` |

test ทั้งหมดผ่าน Match interface เท่านั้น ตาม [docs/testing.md](docs/testing.md) และ test เดิมที่กระทบ (Archer/Mage, Class Encounter, Guardian) ถูกปรับให้สอดคล้องกับ Energy

**CI ของ PR #29:** ผ่านทั้ง 2 job (headless GDScript tests 54 วินาที; export PC/browser/server พร้อม cross-platform smoke test 1 นาที 11 วินาที)

**Balance** (100 seed ต่อโหมด ไม่มี `--pace` เกณฑ์ regression 70–97%) รายละเอียดใน [docs/balance.md](docs/balance.md)

| ช่วง | Single-player | Duo co-op |
| --- | --- | --- |
| ก่อนงานนี้ | 86% | 81% |
| หลังเพิ่ม Energy | 85% | 82% |
| หลังเพิ่ม Rogue และ DoT | **90%** | **86%** |

**หน้าจอ:** `tools/ui_preview.gd` เล่น Match จริงผ่านคีย์บอร์ดและจับภาพทุกหน้า ผมเทียบกับภาพอ้างอิงด้วยตาเองและแก้จุดซ้อนทับหลายรอบ
นอกจากนั้นเล่น browser build กับ server ในเครื่องผ่านหน้าลงทะเบียน → Path Voting → Combat → เลือกเป้า ภาพอยู่ที่ [`docs/screenshots/`](docs/screenshots/)

![Skill grid](docs/screenshots/combat_skill_grid.png)
![Boss with DoT badges](docs/screenshots/boss_dot_badges.png)
![Camp](docs/screenshots/camp_merchant.png)

**ยังไม่ได้ตรวจ:** Chrome, Edge, Firefox และ Safari บนเครื่องจริง, ที่ความละเอียด 1920×1080 และขนาดตัวหนังสือใหญ่กว่าปกติ,
และการเล่นด้วยมนุษย์จริงเพื่อยืนยัน balance กับ pacing (checklist ใน [docs/staging.md](docs/staging.md), issue #19)

### 9. ผล code review

รีวิวช่วง `66e57f0...HEAD` (`66e57f0` คือ `main` ก่อน PR #29) โดย sub-agent สองตัวแยกแกน แล้วผมรวมผล
**ข้อจำกัด:** sub-agent ไม่ได้รัน test หรือ simulator และผลนี้ไม่ใช่การรีวิวโดยคน สถานะทุกข้อด้านล่างคือ "ยังไม่แก้"

#### Standards

| # | ระดับ | ข้อค้นพบ |
| --- | --- | --- |
| S1 | ผิดมาตรฐานที่เขียนไว้ | **ADR-0007**: ข้อความในเกมต้องอยู่ใน `content/forest.json` และ `ui_text.gd` แต่ `battle_view.gd` กับ `camp_view.gd` เขียนข้อความติดไว้ราว 700 บรรทัด เช่น "Challenge won!", "Time is up!", "Waiting for %s to act...", "Shop closes in %ds", "Sold out" และ tooltip ของ Energy ที่ฝังเลข 1 กับ 6 ทั้งที่ค่าจริงอยู่ใน `rules.energy_*` |
| S2 | ผิดมาตรฐานที่เขียนไว้ | ข้อความ skill row ใน `combat_panel.gd` ("needs %d Energy", "ready (%d Energy)") ติดไว้ในโค้ดเช่นกัน |
| S3 | น่าจะขัด accessibility | hint ของ Energy เขียนว่า "the blue bar" ชี้ไปที่สี (แถบมีตัวเลขกำกับ จึงน่าจะไม่ผิดจริง) |
| S4 | dead code | `CombatPanel` และ `MerchantPanel` ไม่ถูกเรียกใช้แล้ว รวมกิ่ง "challenge" ของ `ClassPanel` |
| S5 | smell | Duplicated Code: `entry["applied"] = entry.get("applied", []) + [...]` ซ้ำ 3 จุดใน `combat_encounter.gd` |
| S6 | smell | Primitive Obsession / Data Clumps: `id.begins_with(PARTY_PREFIX)` ซ้ำเกิน 6 ครั้ง และการอ่าน `rules.energy_*` กระจาย 4 method |
| S7 | smell | `_hit` ยาวและทำหลายอย่าง (pierce, per-DoT power, passive, นับ DoT) |
| S8 | smell | `battle_view.gd` ยาว 744 บรรทัด ปน HUD, timeline, log, banner และ input |
| S9 | smell | ชื่อกำกวม: `_status_events` เป็น side-channel, `can_afford` ไม่ดู cooldown แต่ชื่อกว้าง |
| S10 | smell | `_tick_statuses` กับ `_perform` จัดการตัวล้มซ้ำกัน |
| S11 | smell | Shotgun Surgery: เพิ่ม field ของ Class/Skill ต้องแก้ 5 ไฟล์ |

ผ่านมาตรฐาน: ไม่มี engine randomness หรือ engine time ใน `src/match` และ test ใหม่ทั้งหมดใช้ Match interface เท่านั้น

#### Spec

ตรวจแล้วถูกต้อง: ลำดับ tick ก่อน Energy regen, ตัวที่ล้มเพราะ DoT เสียตา, ตัวเลข Energy/cooldown ตามตาราง, Enervation ครบ 3 ส่วน,
Prep Time, AI ของ Rogue, `MatchBot` เล่น Rogue ได้ และกติกา Energy ตาม ADR-0009

| # | ประเภท | issue | ข้อค้นพบ |
| --- | --- | --- | --- |
| P1 | ทำแล้วแต่ผิด | #25 "ไม่มีส่วนทับกัน" | ที่ 1280×720 Skill grid ทับ token ทั้งสองฝั่ง, banner "Your turn!" ทับ grid และ tip ทับ log กับ HUD (ยืนยันจากภาพที่จับเอง) |
| P2 | ทำแล้วแต่ผิด | #25 | ตัวเลขลอยของ DoT ซ้อนกันจนอ่านไม่ออกในภาพบอส |
| P3 | ทำแล้วแต่ผิด | #25 | ชื่อบน banner ได้จากการแปลง id ไม่ใช่ชื่อใน content และ Attack กับ Defend ไม่ถูกประกาศ |
| P4 | ทำแล้วแต่ผิด | #25 | ช่อง cooldown แสดงแค่ตัวอักษรแรก ทำให้ Prep Time กับ Poke Up เป็น "P" เหมือนกัน |
| P5 | ทำแล้วแต่ผิด | #24 | AI ของ Rogue ตกไปโจมตี `targets: [""]` ถ้า `reach` ว่าง (เกิดยากเพราะ Combat จะจบก่อน) |
| P6 | ขาด/ไม่ครบ | #25, #26 "ข้อความ UI อยู่ใน ui_text.gd" | ใส่จริงแค่ 3 ข้อความ (ซ้ำกับ S1) |
| P7 | ขาด/ไม่ครบ | #26 | ไม่มีภาพหน้าจอ Rest มีแต่ Merchant |
| P8 | ขาด/ไม่ครบ | #25, #26 | ไม่มีหลักฐานที่ 1920×1080 และที่ตัวหนังสือใหญ่กว่าปกติ ภาพทุกภาพเป็น 1280×720 |
| P9 | ขาด/ไม่ครบ | #25 "แสดงผู้ควบคุม" | timeline ไม่บอกว่าเป็นผู้เล่นหรือ AI (มีแค่ป้ายบนสนาม) |
| P10 | ขาด/ไม่ครบ | #25 "Forest (Layer/5)" | ตอนบอสแสดง "Forest (Boss)" |
| P11 | ขาด/ไม่ครบ | #26 "Ready (x/y)" | ค่า y นับฝั่ง client จาก `room_view` ไม่ได้มาจาก snapshot ของ Encounter และไม่มี test ฝั่ง server |
| P12 | ขาด/ไม่ครบ | #23 "snapshot แสดง Status effect ของทุกตัว" | `statuses` อยู่ใน view ของ Encounter เท่านั้น ไม่มีใน `party_view` |
| P13 | ขาด/ไม่ครบ | #23 | modifier `dot_out`/`dot_in` อ่านจาก passive ของ Class เท่านั้น กำหนดที่ Skill หรือศัตรูไม่ได้ |
| P14 | ขาด/ไม่ครบ | #23 | test ตรวจการล้าง status ตอนจบ Combat เฉพาะกรณีชนะ ไม่มีกรณี Challenge หรือแพ้ |
| P15 | เกินที่สั่ง | — | คีย์ `pierce`/`hits`/`per_dot`, การ์ด Attack/Defend ใน Skill grid, `ui_preview.gd --class`, `clear_banner`/`tip_width`, ภาพอ้างอิง 11 ไฟล์ (ราว 15 MB) และหัวข้อ review นี้ |

### 10. คะแนน review

Claude ประเมินเอง (เต็ม 10) โดยอิงผล code review ด้านบน จึง**ต่ำกว่าคะแนนก่อนรีวิว (7.6)** และยังไม่ใช่การรีวิวโดยคนหรือ agent ที่ไม่ได้เป็นผู้เขียน

| ด้าน | คะแนน | เหตุผล |
| --- | --- | --- |
| Logic ถูกต้องตาม ADR | 8.5 | รีวิวตรวจพบว่ากติกา ADR-0009/0010 ตรงหมด; หักที่ `StatusBook` รับชื่อ status ที่ไม่มีใน content โดยไม่แจ้ง error, Enervation คูณกับ damage ของ Item ด้วยโดยยังไม่ได้ยืนยัน, modifier กำหนดได้เฉพาะที่ Class (P13) และ AI ของ Rogue มี edge case (P5) |
| Test coverage | 8 | มี test ตามค่าคงที่ครบ Skill, stack, ลำดับ และ modifier; หักที่ไม่มี test ล้าง status ตอน Challenge/แพ้ (P14), ไม่มี test ฝั่ง server ของ Ready count (P11) และไม่มี test อัตโนมัติของ layout |
| Balance | 7 | อยู่ในช่วง 70–97% แต่ Single-player ขยับขึ้นเป็น 90% วัดแบบไม่มี `--pace` และยังไม่มีคนเล่นจริง |
| ความเหมือนภาพอ้างอิงและ acceptance ของ #25/#26 | 7 | องค์ประกอบครบตามตาราง แต่ขัดเกณฑ์ "ไม่มีส่วนทับกัน" (P1), ตัวเลขลอยซ้อนกัน (P2), ตัวละครยังเป็นรูปทรง placeholder และขาดภาพ Rest กับ 1920×1080 (P7, P8) |
| Accessibility | 6 | สีมีตัวย่อกำกับเสมอ ใช้คีย์บอร์ดได้ และเคารพการลด motion; หักที่ยังไม่ได้ตรวจตัวหนังสือใหญ่ (P8), คำอธิบายสินค้าดูได้ผ่าน tooltip ของเมาส์เท่านั้น, ช่อง cooldown กำกวม (P4) และ [accessibility.md](docs/accessibility.md) ยังไม่ครอบคลุมหน้าจอใหม่ |
| ตามมาตรฐานของรีโป (ADR/testing) | 6 | ขัด ADR-0007 ราว 700 บรรทัด (S1, S2, P6) แม้ ADR-0001 และกติกา test ผ่านหมด |
| Maintainability | 6.5 | `StatusBook` แยกชัดและ token เปลี่ยนเป็น sprite ได้; หักที่ dead code (S4), `battle_view.gd` 744 บรรทัด (S8) และ smell ซ้ำซ้อน (S5–S11) |
| **รวม (เฉลี่ย)** | **7.0** | ทำงานครบตามตั๋วและผ่าน CI แต่ยังไม่ถึงระดับ production ตาม ADR-0003 ก่อนแก้รายการในหัวข้อถัดไป |

### 11. งานที่ต้องทำต่อ

เรียงตามความสำคัญ (อ้างรหัสข้อค้นพบจากหัวข้อ 9)

**ต้องแก้ก่อนถือว่าตั๋ว #25/#26 ผ่านเกณฑ์**
1. แก้ layout ที่ 1280×720 ไม่ให้ Skill grid, banner และ tip ทับ token กับ HUD และจัดตัวเลขลอยของ DoT ไม่ให้ซ้อนกัน (P1, P2)
2. ย้ายข้อความ UI ทั้งหมดของ `battle_view.gd`, `camp_view.gd` และ `combat_panel.gd` เข้า `ui_text.gd` และอ่านค่า Energy จาก `rules.energy_*` (S1, S2, P6)
3. จับภาพ Rest และภาพที่ 1920×1080 และที่ตัวหนังสือใหญ่ (`--scale=1.4`) แล้วแก้สิ่งที่พัง (P7, P8)
4. ใช้ชื่อ Skill จาก content บน banner, ประกาศ Attack/Defend และแก้ช่อง cooldown ให้แยก Skill ออก (P3, P4)
5. timeline แสดงผู้ควบคุม (ผู้เล่น/AI) และป้ายขวาบนแสดง Layer ตอนบอส (P9, P10)

**ควรทำต่อ**
6. ส่งจำนวนผู้เล่นที่พร้อมและจำนวนผู้เล่นจริงใน snapshot ของ Merchant พร้อม test ฝั่ง server และเพิ่ม `statuses` ใน `party_view` (P11, P12)
7. ลบ `CombatPanel`, `MerchantPanel` และกิ่ง challenge ของ `ClassPanel` ที่ไม่ถูกเรียกใช้ (S4)
8. `StatusBook` ปฏิเสธชื่อ status ที่ไม่มีใน content และให้ modifier `dot_out`/`dot_in` กำหนดที่ Skill หรือศัตรูได้ (P13) พร้อมตัดสินว่า Enervation ควรคูณกับ damage ของ Item หรือไม่
9. เพิ่ม test ล้าง status ตอน Challenge และตอนแพ้ (P14) และแก้ AI ของ Rogue ให้จัดการกรณี `reach` ว่าง (P5)

**ปรับโครงสร้าง**
10. แยก `battle_view.gd` เป็น HUD / timeline / log / banner และรวมโค้ดซ้ำใน `combat_encounter.gd` (S5–S8, S10)
11. ให้คนเล่นจริงเพื่อยืนยัน balance กับ pacing และตรวจบน Chrome, Edge, Firefox และ Safari ตาม checklist ของ #19 พร้อมอัปเดต `docs/accessibility.md` และ `docs/testing.md`

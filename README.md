# BEYOND THE WORLD'S END — Forest vertical slice

เกม co-op fantasy turn-based RPG เขียนด้วย **GDScript** บน **Godot 4.7**
ขอบเขตปัจจุบันคือ Forest vertical slice ที่เล่นจบได้: Party 5 ตัว
(Arin, Bram, Cora, Dain, Wren) เดินทางผ่าน **5 Layers** ไปจนถึง Guardian Boss
Encounter ประกอบด้วย Combat, Merchant, Rest, Treasure, Story Event
และ Class Encounter กติกาผ่าน `MatchServer` ที่เป็น authoritative ฝั่งเดียว

## โหมดการเล่น

- **ออนไลน์ co-op ผ่านเซิร์ฟเวอร์กลาง:** สร้างห้องด้วย Room code 6 ตัวอักษร
  ห้องหนึ่งมี 5 Player slot, มี Host เริ่ม Match ได้คนเดียว
  slot ว่างใช้ AI เล่นแทน เปิดเซิร์ฟเวอร์ headless ตัวเดียวแล้วต่อ client
  หลายหน้าต่างหรือหลายเครื่องก็ได้
- **Story แบบออฟไลน์ (เล่นคนเดียว):** ไม่ต้องต่อเซิร์ฟเวอร์
  รัน `MatchServer` ในตัว client ผ่าน local transport
  ผู้เล่นคนเดียวคุมทั้ง 5 ตัว ไม่มี Action window timeout
  มีฉากเปิดเรื่อง บทสนทนาตาม trigger และการ์ดบททุก Layer
  ข้อมูลอยู่ใน `content/story_mode.json` เซฟอัตโนมัติต้นทุก Layer ที่
  `user://story_save.json` มีปุ่ม Continue/New บนหน้าแรก

## ความต้องการ

- Godot **4.7.2** (หรือ 4.5+) อยู่ใน `PATH` ชื่อ `godot`
  หรือกำหนด `GODOT=/path/to/godot`
- ไฟล์หลักของโปรเจกต์: `project.godot` (entry: `src/app/main.tscn`)

## เริ่มเล่นด่วน

เทอร์มินัลที่ 1 — เซิร์ฟเวอร์กลาง:

```bash
godot --headless --path . -- --server --port=8910
```

เทอร์มินัลที่ 2 — client (เปิดสองหน้าต่างเพื่อลอง co-op):

```bash
godot --path . -- --url=ws://127.0.0.1:8910 --name=Ann
```

คนหนึ่งกด **Create a room** อีกคนใส่ Room code แล้วกด **Join room**
วิธีเล่นละเอียด ปุ่มลัด และโหมด dev playtest ดูที่
[`docs/guides/running.md`](docs/guides/running.md)

## เบราว์เซอร์

client เบราว์เซอร์มาจากโค้ดชุดเดียวกับ PC ต่างกันแค่ export preset
(`Web`, `Windows`, `Linux Server` ใน `export_presets.cfg`)
วิธี build/serve เต็ม ๆ ดูที่ [`docs/guides/web.md`](docs/guides/web.md):

```bash
godot --headless --path . --export-release "Web" build/web/index.html
python3 -m http.server -d build/web 8060
# เปิด http://localhost:8060/?server=ws://localhost:8910
```

## ทดสอบ

```bash
./tools/run_tests.sh
```

กติกาเทสต์ (ผ่าน Match interface เท่านั้น) และวิธีเพิ่มเทสต์ ดูที่
[`docs/guides/testing.md`](docs/guides/testing.md)

## เอกสาร

- คำศัพท์กลาง: [`CONTEXT.md`](CONTEXT.md)
- ข้อกำหนดผลิตภัณฑ์: [`docs/design/prd.md`](docs/design/prd.md)
- สมดุลและ pacing: [`docs/design/balance.md`](docs/design/balance.md)
- สไตล์ UI: [`docs/design/ui-style.md`](docs/design/ui-style.md)
- การเข้าถึง: [`docs/design/accessibility.md`](docs/design/accessibility.md)
- การรันเกม: [`docs/guides/running.md`](docs/guides/running.md)
- เบราว์เซอร์: [`docs/guides/web.md`](docs/guides/web.md)
- Staging/QA: [`docs/guides/staging.md`](docs/guides/staging.md)
- การตัดสินใจสถาปัตยกรรม: [`docs/adr/`](docs/adr/) (Story mode: `0014-offline-story-mode.md`)

## โครงสร้างโปรเจกต์

```text
.ai/                         task specs, checkpoint และ agent runner
.claude/agents/              agent definitions
.github/                     CI workflows และ PR/issue templates
art_source/                  raw art sheets ที่ไม่ถูก import โดย Godot
assets/                      runtime art, fonts และเสียงที่เกมโหลด
content/                     Forest rules และ Story mode JSON
deploy/                      staging, proxy, compose และ profile-worker
docs/adr/                    architecture decision records
docs/agents/                 issue, triage และ domain rules
docs/design/                 requirements, balance, UI และ accessibility
docs/guides/                 วิธีรัน, test, export และ deploy
docs/history/                milestone และ project records
docs/plans/                  แผนงานและผล audit โครงสร้าง
docs/references/             source material และ UI references
docs/research/               ข้อมูลค้นคว้าจากแหล่งภายนอก
docs/review/                 QA reports, code reviews และ screenshots
docs/screenshots/            ภาพจากเกมและ UI preview
i18n/                        gettext template และคำแปล
src/app/                     entry scene และ launch options
src/client/                  title, lobby, match, story และ shared UI
src/match/                   MatchServer, rules, AI และ encounters
src/net/                     protocol และ WebSocket transport
src/profile/                 profile stores และ HTTP sender
src/server/                  headless game server
src/shared/                  RNG, clocks และ content loader
tests/                       tests แบ่งตามระบบ พร้อม runner และ support
tools/art/                   เครื่องมือเตรียมและ slice art
tools/dev/                   simulator, previews และ smoke client
tools/i18n/                  extract และตรวจ translation catalog
tools/ci/                    browser smoke test
tools/run_tests.sh           รัน test suite แบบ headless
project.godot                Godot project และ entry configuration
export_presets.cfg           preset Web / Windows / Linux Server
```

## Contributing

ดู [CONTRIBUTING.md](CONTRIBUTING.md) สำหรับ branch naming, commit style, การรัน tests และ PR checklist. การตั้งค่า GitHub ที่เจ้าของรีโปต้องทำอยู่ใน [docs/guides/github-setup.md](docs/guides/github-setup.md).

## ประวัติและสารบัญเพิ่มเติม

- [docs/README.md](docs/README.md) — สารบัญเอกสารทั้งหมด
- [docs/history/](docs/history/) — log งานเก่า (ย้ายออกจาก README เดิมที่ยาว 451 บรรทัด)
- [.ai/tasks/README.md](.ai/tasks/README.md) — สารบัญ task spec ของ AI executor
- [docs/review/README.md](docs/review/README.md) — สารบัญรีวิวและ QA

## แกลเลอรี UI (ภาพจาก preview จริง)

ภาพด้านล่างคือภาพหน้าจอจริงจากสคริปต์ preview (`tools/dev/ui_preview.gd`
และ `tools/dev/story_preview.gd --full`) โดยรวมภาพจากหลาย multiplayer seed
เข้ากับ Story preview ครอบคลุมเฉพาะฉากที่สคริปต์เรนเดอร์ได้จริงในการรัน
เหล่านี้ ทั้งฉาก Victory และ Defeat ถูกบันทึกไว้แล้ว ส่วนฉากที่ยังขาดอยู่
ใน UI gallery คือ `05_class_offer` และ `10_treasure` เท่านั้น; ส่วน Story mode
preview ไม่มีภาพ combat แรกเพราะหยุดก่อนหน้าต่าง human action แรกของ combat
แรก (`story_preview: first combat never reached a visible human action window`
ทำให้ไม่มี `05_story_battle.png`)

<details>
<summary>Title / Lobby / Setup (9 ภาพ)</summary>

![Title screen](docs/screenshots/playthrough/01_title.png)
![Lobby](docs/screenshots/playthrough/02_lobby.png)
![Character setup — class tab](docs/screenshots/playthrough/02a_setup_class.png)
![Character setup — races tab](docs/screenshots/playthrough/02b_setup_races.png)
![Character setup — boons tab](docs/screenshots/playthrough/02c_setup_boons.png)
![Character setup — boon equipped](docs/screenshots/playthrough/02d_setup_boons_equipped.png)
![Lobby with loadout](docs/screenshots/playthrough/02e_lobby_loadout.png)
![Confirm leave dialog](docs/screenshots/playthrough/02f_confirm_leave.png)
![Settings panel](docs/screenshots/playthrough/02g_settings.png)

</details>

<details>
<summary>Voting / Normal combat (6 ภาพ)</summary>

![Path voting](docs/screenshots/playthrough/03_vote.png)
![Normal combat — turn](docs/screenshots/playthrough/04_combat_turn.png)
![Normal combat — targets](docs/screenshots/playthrough/04_combat_targets.png)
![Normal combat — skills](docs/screenshots/playthrough/04_combat_skills.png)
![Normal combat — items](docs/screenshots/playthrough/04_combat_items.png)
![Normal combat — hint overlay](docs/screenshots/playthrough/04_combat_hint.png)

</details>

<details>
<summary>Class challenge (2 ภาพ)</summary>

![Class challenge — turn (ท้าทายคลาส — เทิร์น)](docs/screenshots/playthrough/05_class_challenge_turn.png)
![Class challenge — skills (ท้าทายคลาส — เลือกสกิล)](docs/screenshots/playthrough/05_class_challenge_skills.png)

</details>

<details>
<summary>Boss / Merchant / Rest / Reward (8 ภาพ)</summary>

![Action banner](docs/screenshots/playthrough/06_action_banner.png)
![Boss combat — turn](docs/screenshots/playthrough/06_boss_turn.png)
![Boss combat — targets](docs/screenshots/playthrough/06_boss_targets.png)
![Boss combat — skills](docs/screenshots/playthrough/06_boss_skills.png)
![Boss telegraph warning](docs/screenshots/playthrough/07_boss_warning.png)
![Merchant](docs/screenshots/playthrough/08_merchant.png)
![Rest (พักผ่อน)](docs/screenshots/playthrough/10_rest.png)
![Combat reward](docs/screenshots/playthrough/11_combat_reward.png)

</details>

<details>
<summary>Story event — multiplayer seeds (2 ภาพ)</summary>

![Story event — choice (อีเวนต์เนื้อเรื่อง — ตัวเลือก)](docs/screenshots/playthrough/09_story_choice.png)
![Story event — outcome (อีเวนต์เนื้อเรื่อง — ผลลัพธ์)](docs/screenshots/playthrough/09_story_outcome.png)

</details>

<details>
<summary>Endings — defeat and victory (2 ภาพ)</summary>

![Defeat ending (seed 7)](docs/screenshots/playthrough/90_summary_defeat.png)
![Victory ending (seed 7 with class assassin)](docs/screenshots/playthrough/90_summary_victory.png)

</details>

<details>
<summary>Story mode preview (4 ภาพ)</summary>

![Story mode — home Play entry](docs/screenshots/playthrough/story_01_home_play.png)
![Story setup — class pick](docs/screenshots/playthrough/story_02_class_pick.png)
![Prologue dialogue in match](docs/screenshots/playthrough/story_03_prologue_match.png)
![Chapter card](docs/screenshots/playthrough/story_04_chapter_card.png)

</details>

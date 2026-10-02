# BEYOND THE WORLD'S END — ตัวอย่างเกม Forest ที่เล่นจบได้

เกม RPG แฟนตาซีแบบผลัดกันเล่นร่วมกัน เขียนด้วย **GDScript** บน **Godot 4.7**
ขอบเขตปัจจุบันเป็นเกม Forest ฉบับย่อที่เล่นจบได้: Party 5 ตัว
(Arin, Bram, Cora, Dain, Wren) เดินทางผ่าน **5 ชั้น** ไปจนถึง Guardian Boss
มีการต่อสู้ พ่อค้า จุดพัก สมบัติ เหตุการณ์เนื้อเรื่อง และการพบผู้ฝึกสอนอาชีพ
กติกาทั้งหมดตัดสินโดย `MatchServer` เพียงจุดเดียว

## โหมดการเล่น

- **เล่นออนไลน์ร่วมกันผ่านเซิร์ฟเวอร์กลาง:** สร้างห้องด้วยรหัส 6 ตัวอักษร
  ห้องหนึ่งมีช่องผู้เล่น 5 ช่อง และมีเพียง Host ที่เริ่ม Match ได้
  AI จะเล่นแทนช่องที่ว่าง เปิดเซิร์ฟเวอร์แบบ headless หนึ่งตัว แล้วเชื่อมต่อ
  client จากหลายหน้าต่างหรือหลายเครื่องได้
- **โหมดเนื้อเรื่องออฟไลน์ (เล่นคนเดียว):** ไม่ต้องเชื่อมต่อเซิร์ฟเวอร์
  client เรียก `MatchServer` ผ่าน local transport
  ผู้เล่นคนเดียวควบคุมตัวละครทั้ง 5 ตัว และไม่มีเวลาจำกัดในช่วงลงมือ
  มีฉากเปิดเรื่อง บทสนทนาตามเงื่อนไข และการ์ดเนื้อเรื่องในทุกชั้น
  ข้อมูลอยู่ใน `content/story_mode.json` และบันทึกอัตโนมัติตอนเริ่มแต่ละชั้นไว้ที่
  `user://story_save.json` หน้าแรกมีปุ่ม Continue/New

## ความต้องการ

- ติดตั้ง Godot **4.7.2** (หรือ 4.5 ขึ้นไป) และเพิ่ม `godot` ไว้ใน `PATH`
  หรือกำหนด `GODOT=/path/to/godot`
- ไฟล์หลักของโปรเจกต์คือ `project.godot` (ฉากเริ่มต้น: `src/app/main.tscn`)

## เริ่มเล่นด่วน

เทอร์มินัลที่ 1 — เปิดเซิร์ฟเวอร์กลาง:

```bash
godot --headless --path . -- --server --port=8910
```

เทอร์มินัลที่ 2 — เปิด client (เปิดสองหน้าต่างเพื่อลองเล่นร่วมกัน):

```bash
godot --path . -- --url=ws://127.0.0.1:8910 --name=Ann
```

ผู้เล่นคนหนึ่งกด **Create a room** ส่วนอีกคนกรอกรหัสห้องแล้วกด **Join room**
วิธีเล่นอย่างละเอียด ปุ่มลัด และโหมดทดสอบสำหรับนักพัฒนา ดูที่
[`docs/guides/running.md`](docs/guides/running.md)

## เบราว์เซอร์

client บนเบราว์เซอร์ใช้โค้ดชุดเดียวกับ PC ต่างกันที่ชุดตั้งค่าส่งออก
(`Web`, `Windows`, `Linux Server` ใน `export_presets.cfg`)
วิธีสร้างและเปิดเว็บฉบับเต็มดูที่ [`docs/guides/web.md`](docs/guides/web.md):

```bash
godot --headless --path . --export-release "Web" build/web/index.html
python3 -m http.server -d build/web 8060
# เปิด http://localhost:8060/?server=ws://localhost:8910
```

## ทดสอบ

```bash
./tools/run_tests.sh
```

กติกาการทดสอบ (ทดสอบผ่าน Match interface เท่านั้น) และวิธีเพิ่มการทดสอบ ดูที่
[`docs/guides/testing.md`](docs/guides/testing.md)

## เอกสาร

- คำศัพท์กลาง: [`CONTEXT.md`](CONTEXT.md)
- ข้อกำหนดผลิตภัณฑ์: [`docs/design/prd.md`](docs/design/prd.md)
- สมดุลและจังหวะการเล่น: [`docs/design/balance.md`](docs/design/balance.md)
- สไตล์ UI: [`docs/design/ui-style.md`](docs/design/ui-style.md)
- การเข้าถึง: [`docs/design/accessibility.md`](docs/design/accessibility.md)
- การรันเกม: [`docs/guides/running.md`](docs/guides/running.md)
- เบราว์เซอร์: [`docs/guides/web.md`](docs/guides/web.md)
- ระบบทดสอบก่อนเผยแพร่และ QA: [`docs/guides/staging.md`](docs/guides/staging.md)
- การตัดสินใจสถาปัตยกรรม: [`docs/adr/`](docs/adr/) (Story mode: `0014-offline-story-mode.md`)

## โครงสร้างรีโป

```text
content/            ข้อมูล Forest (forest.json) และ Story (story_mode.json)
src/app/            entry scene และ launch options
src/shared/         RNG, clock, ตัวโหลด content
src/profile/        profile store และ sender
src/match/          Match server, room, AI, encounter, กติกา
src/net/            โปรโตคอลและ WebSocket transport
src/server/        โหนดเซิร์ฟเวอร์ headless
src/client/         title, lobby, match (battle/camp), story, ui ร่วม
tests/              เทสต์แยกตาม src พร้อม runner และ support
tools/dev/          จำลอง, preview, smoke client
tools/ci/           smoke test เบราว์เซอร์
tools/run_tests.sh  รันเทสต์แบบ headless
deploy/             staging, proxy, compose, profile-worker
docs/design/        prd, balance, ui-style, accessibility
docs/guides/       running, testing, web, staging
docs/adr/           บันทึกการตัดสินใจสถาปัตยกรรม
export_presets.cfg  preset Web / Windows / Linux Server
```

โฟลเดอร์อื่นที่ใช้งานบ่อย: `.ai/` เก็บ task spec และ runner, `.github/` เก็บ workflow กับ template,
`art_source/` เก็บภาพต้นฉบับ, `i18n/` เก็บ catalog ภาษา, `docs/plans/` เก็บแผนงาน,
`docs/references/` และ `docs/research/` เก็บแหล่งอ้างอิง, `docs/review/` เก็บ QA และผลรีวิว,
`tools/art/` เตรียมภาพ และ `tools/i18n/` สร้าง/ตรวจ catalog

## ประวัติและสารบัญเพิ่มเติม

## Project tree — สารบัญโฟลเดอร์

- `.ai/` — task spec และ agent runner; `.github/` — workflow และ template
- `art_source/` — ภาพต้นฉบับ; `assets/` — ภาพ ฟอนต์ และเสียงที่เกมใช้
- `content/` — ข้อมูล Forest/Story; `deploy/` — staging และ profile worker
- `docs/adr/`, `docs/design/`, `docs/guides/` — decisions, design และวิธีใช้งาน
- `docs/history/`, `docs/plans/`, `docs/references/`, `docs/research/`, `docs/review/` — บันทึก แผน และข้อมูลอ้างอิง
- `i18n/` — gettext catalog; `src/` — app, client, match, net, profile, server และ shared code
- `tests/` — test suite; `tools/art/`, `tools/dev/`, `tools/i18n/`, `tools/ci/` — เครื่องมือพัฒนา

## Contributing

ดู [CONTRIBUTING.md](CONTRIBUTING.md) สำหรับแนวทางตั้งชื่อ branch รูปแบบ commit การรัน test และรายการตรวจ PR ส่วนการตั้งค่า GitHub ที่เจ้าของรีโปต้องทำ ดูที่ [docs/guides/github-setup.md](docs/guides/github-setup.md)

- [docs/README.md](docs/README.md) — สารบัญเอกสารทั้งหมด
- [docs/history/](docs/history/) — บันทึกงานเก่า (ย้ายจาก README เดิมที่ยาว 451 บรรทัด)
- [.ai/tasks/README.md](.ai/tasks/README.md) — สารบัญข้อกำหนดงานของ AI executor
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

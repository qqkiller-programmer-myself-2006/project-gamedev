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

## ประวัติและสารบัญเพิ่มเติม

- [docs/README.md](docs/README.md) — สารบัญเอกสารทั้งหมด
- [docs/history/](docs/history/) — บันทึกงานเก่า (ย้ายจาก README เดิมที่ยาว 451 บรรทัด)
- [.ai/tasks/README.md](.ai/tasks/README.md) — สารบัญข้อกำหนดงานของ AI executor
- [docs/review/README.md](docs/review/README.md) — สารบัญรีวิวและ QA

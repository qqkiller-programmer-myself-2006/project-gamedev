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

## โครงรีโป

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
- [docs/history/](docs/history/) — log งานเก่า (ย้ายออกจาก README เดิมที่ยาว 451 บรรทัด)
- [.ai/tasks/README.md](.ai/tasks/README.md) — สารบัญ task spec ของ AI executor
- [docs/review/README.md](docs/review/README.md) — สารบัญรีวิวและ QA

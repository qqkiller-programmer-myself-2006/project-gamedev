# วิธีเปิดเกม

ทุกอย่าง (server, PC client, browser client) มาจาก project เดียว: main scene
(`src/app/main.tscn`) เปิด server เมื่อมี `--server` หรือรันแบบ headless, นอกนั้นเปิด client

## Server (headless, ผู้ตัดสินผล)

```bash
godot --headless --path . -- --server --port=8910
# --seed=123 ให้ห้องและ Match ที่สร้างออกมาเหมือนเดิมทุกครั้ง (ไว้ reproduce bug)
```

- รับหลายห้องพร้อมกัน, ผู้เล่นเป็น anonymous session (ไม่มี account)
- log บอกจำนวน connection ทุก 60 วินาที

## PC client

```bash
godot --path .                                          # เปิดหน้าแรก ใส่ชื่อ/server เอง
godot --path . -- --url=ws://127.0.0.1:8910 --name=Ann  # กรอกค่าไว้ให้
```

ทดสอบ co-op บนเครื่องเดียว: เปิด server หนึ่งตัว แล้วเปิด client สองหน้าต่าง
คนหนึ่งกด `Create a room` อีกคนใส่ Room code แล้วกด `Join room`

### Dev Playtest (กระโดดไปฉากที่ต้องการ)

เฉพาะ debug build หรือ `--dev` (ไม่มีใน release export): ปุ่ม `[DEV] Playtest` บนหน้าแรกเปิด panel ให้เลือก
`Start at` (Journey start, Combat, Merchant, Rest camp, Class Encounter, Story event, Cave = Layer 5 combat, Boss),
`Class` ของผู้เล่น (Classless/Swordsman/Archer/Mage/Guardian/Assassin) และ `Seed` แล้วเริ่ม match คนเดียวบน server ในตัวเกม
แล้วข้ามไปฉากนั้นทันที (ตั้ง Layer และเลเวล/EXP ให้เหมาะกับ Layer นั้น, ใช้ seed เดิม = ฉากเดิม)

```bash
godot --path . -- --dev --playtest --jump=boss --class=mage --seed=7   # ข้าม panel
```

`--jump=` journey|combat|merchant|rest|class|story|cave|boss (ตั้งค่าเริ่มต้น journey), `--class=` classless|swordsman|archer|mage|guardian|assassin, `--seed=` ตัวเลข.
ข้างใน: คำสั่ง `dev_jump {target, layer?, class?}` ที่ `MatchServer` รับเฉพาะเมื่อ `allow_dev` ถูกตั้ง (ตั้งเฉพาะใน `GameServer.listen_embedded`);
server ออนไลน์ตอบ `dev_offline_only`.

## Browser client

ดู [web.md](web.md)

## ปุ่มลัด (keyboard ทั้งหมด)

| ที่ไหน | ปุ่ม |
| --- | --- |
| ทุกหน้า | Tab / Shift+Tab / ลูกศร เลื่อน focus, Enter/Space กดปุ่ม, F2 ตั้งค่า, H ปิด tip |
| ระหว่าง Match | C เปิด/ปิด Story Clue log |
| Path Voting | 1–3 โหวต |
| Combat | A Attack, S Skill, D Defend, I Item, 1–9 เลือกเป้า/Skill/Item, Esc ย้อนกลับ |
| Class Encounter | Y รับ Class, N ปฏิเสธ |
| Merchant | 1–4 ซื้อ, R ซื้อเสร็จแล้ว |
| Rest camp | 1–9 คราฟต์, R เสร็จแล้ว, Esc เมนู |
| Story Event | 1–2 โหวตตัวเลือก, Enter ไปต่อ |

## ดู UI โดยไม่ต้องต่อ server จริง

```bash
# เล่น Duo co-op หนึ่ง Match ด้วยคีย์บอร์ดจำลอง และเซฟภาพทุกหน้าจอไว้ที่ build/ui
xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/dev/ui_preview.gd -- --out=build/ui --seed=7 --speed=8
```

ตัวเลือก: `--scale=1.45` (ขนาดตัวหนังสือ), `--reduced-motion`

## การจัดเก็บโปรไฟล์

เรียกคำสั่งต่อไปนี้หนึ่งครั้งจาก `deploy/profile-worker/` หลังแทนค่า `database_id` ตัวอย่างใน `wrangler.toml` ด้วย ID ที่ได้จากคำสั่งสร้าง D1:

```bash
npx wrangler login
npx wrangler d1 create btwe-profiles
npx wrangler d1 execute btwe-profiles --remote --file=schema.sql
npx wrangler secret put SERVER_SECRET
npx wrangler deploy
```

จากนั้นเปิด game server ด้วย URL ของ Worker ที่ deploy แล้วและ secret เดียวกัน:

```bash
godot --headless --path . -- --server --profile-url=https://... --profile-secret=...
```

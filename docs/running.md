# Running the game

ทุกอย่าง (server, PC client, browser client) มาจาก project เดียว: main scene
(`src/app/main.tscn`) เปิด server เมื่อมี `--server` หรือรันแบบ headless, นอกนั้นเปิด client

## Server (headless, authoritative)

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
คนหนึ่งกด **Create a room** อีกคนใส่ Room code แล้วกด **Join room**

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
| Story Event | 1–2 โหวตตัวเลือก, Enter ไปต่อ |

## ดู UI โดยไม่ต้องต่อ server จริง

```bash
# เล่น Duo co-op หนึ่ง Match ด้วยคีย์บอร์ดจำลอง และเซฟภาพทุกหน้าจอไว้ที่ build/ui
xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/ui_preview.gd -- --out=build/ui --seed=7 --speed=8
```

ตัวเลือก: `--scale=1.45` (ขนาดตัวหนังสือ), `--reduced-motion`

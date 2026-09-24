# Staging และการรับรอง core flow (issue #19)

## ภาพรวม

```text
ผู้ทดสอบ (browser) ──https──┐
                            ├─► Caddy (HTTPS อัตโนมัติ) ─┬─ /      → browser build (static)
ผู้ทดสอบ (PC .exe) ──wss────┘                           └─ /ws    → game-server:8910 (headless, authoritative)
```

- ทั้งหมดอยู่ใน `deploy/`: `docker-compose.yml`, `Caddyfile`, `Dockerfile.server`, `prepare.sh`
- server เป็น binary จาก export "Linux Server" (ต้องการแค่ glibc) รันด้วย `--headless -- --server --port=8910`
- browser build ที่เปิดจาก `https://<DOMAIN>/` ต่อ `wss://<DOMAIN>/ws` เองโดยไม่ต้องใส่พารามิเตอร์
- PC client: ใส่ `wss://<DOMAIN>/ws` ในช่อง Server address หรือรัน `BeyondTheWorldsEnd.exe -- --url=wss://<DOMAIN>/ws`

## 🔐 ขั้นตอนที่เจ้าของโปรเจกต์ต้องทำเอง (ต้องใช้บัญชี/ข้อมูลรับรองจริง)

1. เช่า VPS Linux x86_64 หนึ่งเครื่อง (1 vCPU / 1 GB RAM พอสำหรับหลายห้อง) และติดตั้ง Docker + Compose plugin
2. จดหรือใช้ domain/subdomain แล้วตั้ง DNS record `A` (และ `AAAA` ถ้ามี IPv6) ชี้ไปที่ VPS
3. เปิด firewall port 80 และ 443
4. ดาวน์โหลด artifact `web-build` และ `linux-server` จาก CI run ล่าสุดของ workflow **builds**
   (GitHub → Actions → builds) หรือ export เองตาม [web.md](web.md)
5. บน VPS:

   ```bash
   git clone <repo> && cd project-gamedev
   ./deploy/prepare.sh ~/artifacts        # โฟลเดอร์ที่มี web-build/ และ linux-server/
   cd deploy && DOMAIN=forest.example.com docker compose up -d --build
   docker compose logs -f game-server     # ต้องเห็น "GameServer: listening on ws://0.0.0.0:8910"
   ```

6. แจกลิงก์ให้ผู้ทดสอบ: `https://<DOMAIN>/` และไฟล์ `BeyondTheWorldsEnd.exe` (artifact `windows-build`)
7. รัน checklist ด้านล่าง แล้วบันทึกผลใน issue #19; ข้อที่ไม่ผ่านให้เปิด issue ใหม่ที่อ้างถึง #19

อัปเดต staging: ดาวน์โหลด artifact ใหม่ → `./deploy/prepare.sh` → `docker compose up -d --build`

## Checklist ของ core flow

ทำครบทั้ง 4 ชุด: **Single-player บน PC**, **Single-player บน browser**, **Duo co-op บน PC + PC**,
**Duo co-op แบบผสม PC + browser** (ให้ทั้งฝั่ง PC และ browser ได้เป็น Host อย่างน้อยครั้งละหนึ่งรอบ)

| # | ขั้นตอน | ผลที่คาดหวัง | PC | Browser | ผสม |
| --- | --- | --- | --- | --- | --- |
| 1 | สร้างห้อง | ได้ Room code 6 ตัว ไม่มี 0/O/1/I/L | | | |
| 2 | เข้าห้องด้วย code ตัวพิมพ์เล็ก | เข้าได้, เห็นทั้ง 5 slots พร้อม PLAYER/AI/HOST/YOU | | | |
| 3 | ใส่ code ผิด / ห้องเต็ม / Match เริ่มแล้ว | ข้อความ error ที่อ่านเข้าใจ | | | |
| 4 | Host เริ่ม Match | ทุกคนเข้า Layer 1 พร้อมกัน, slot ว่างเป็น AI | | | |
| 5 | Path Voting | 1 เสียงต่อคน, เห็นคนที่โหวตแล้ว, ผลและการสุ่มตัดเสมอประกาศชัด | | | |
| 6 | Combat | ลำดับ turn, countdown 15 วินาที, Attack/Defend/Item, ตัวเลข damage, AI เล่นเอง | | | |
| 7 | ปล่อยให้หมดเวลาหนึ่ง turn | Defend อัตโนมัติ | | | |
| 8 | Class Encounter | ผ่าน Challenge, รับ/ปฏิเสธ Class, ใช้ Skill ได้หลังรับ | | | |
| 9 | Merchant | ซื้อด้วย Gold ร่วม, ปุ่มขึ้น "Need … Gold" เมื่อไม่พอ, กด Done แล้วไปต่อ | | | |
| 10 | Story Event | ข้อความ, โหวตตัวเลือก, clue ขึ้นใน Clue log (C) | | | |
| 11 | Guardian Boss | 3 phase, WARNING ก่อนท่าหนัก, ชนะ/แพ้ได้ | | | |
| 12 | Victory / Defeat | หน้าสรุป (เวลา, clue, Class), Host เริ่ม Match ใหม่ได้, คนอื่นเห็นข้อความรอ | | | |
| 13 | ผู้เล่นหนึ่งคนปิดเกมกลาง Match (Duo) | slot กลายเป็น AI ทันที, Match เล่นต่อจนจบ | | | |
| 14 | ตัดเน็ตฝั่งตัวเอง | ข้อความ "connection was lost" แล้วกลับหน้าแรก | | | |
| 15 | Accessibility ตาม [accessibility.md](accessibility.md) | keyboard ล้วน, text size 1.45×, Reduce motion, volume | | | |

## บันทึกเวลาเล่นจริง (เป้า ADR-0003: 20–30 นาที)

| วันที่ | โหมด | แพลตฟอร์ม | ผล | เวลา (นาที) | หมายเหตุ |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

ค่าคาดการณ์จาก bot อยู่ที่ 10–13 นาที ([balance.md](balance.md)) ถ้าเวลาจริงยังสั้นกว่าเป้า ให้เลือกคันโยกที่ระบุไว้ในเอกสารนั้น
หรือเสนอแก้ ADR-0003

## สิ่งที่ตรวจอัตโนมัติไปแล้ว (ไม่ต้องใช้ staging)

- `tests/net/test_smoke_server_process.gd`: server process headless จริง + client จริงผ่าน WebSocket
- `tools/web_smoke.mjs` (CI workflow **builds**): browser build ใน Chromium + PC client ทั้งสองทิศทาง
- `tests/regression/`: Match เต็มหลาย seed, ผู้เล่นหลุด, timeout ทุกแบบ, Party ล้มแล้วเริ่มใหม่

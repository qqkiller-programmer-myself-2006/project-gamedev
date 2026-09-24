# Browser build

browser client มาจาก codebase เดียวกับ PC client (ไม่มี logic แยก) ต่างกันแค่ export preset

## Build

ต้องมี export templates ของ Godot 4.7.2 (`Editor > Manage Export Templates` หรือแตกไฟล์
`Godot_v4.7.2-stable_export_templates.tpz` ไปที่ `~/.local/share/godot/export_templates/4.7.2.stable/`)

```bash
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows" build/windows/BeyondTheWorldsEnd.exe
godot --headless --path . --export-release "Linux Server" build/server/forest-server.x86_64
```

CI (`.github/workflows/builds.yml`) export ทั้งสามแบบให้ทุก PR และเก็บเป็น artifact ให้ผู้ทดสอบดาวน์โหลด

## Serve

`build/web` เป็นไฟล์ static ธรรมดา ใช้ web server อะไรก็ได้ (ไม่ต้องตั้ง COOP/COEP header
เพราะ preset ปิด thread support)

```bash
npx http-server build/web -p 8060          # หรือ python3 -m http.server -d build/web 8060
# เปิด http://localhost:8060/?server=ws://localhost:8910
```

ตัวเลือกใน URL (เหมือน command line ของ PC client):

| พารามิเตอร์ | ความหมาย |
| --- | --- |
| `server=ws://host:port` | ที่อยู่ของ authoritative server (ใช้ `wss://` เมื่อหน้าเว็บเป็น HTTPS) |
| `name=Ann` | ชื่อที่กรอกไว้ให้ |
| `join=K7PQ2M` | Room code ที่กรอกไว้ให้ |
| `auto=1` | เข้าห้องทันที (หรือสร้างห้องถ้าไม่มี `join`) เมื่อมีชื่อแล้ว |

## Cross-platform smoke test

```bash
NODE_PATH=$(npm root -g) node tools/web_smoke.mjs
```

เปิด server headless จริง, browser build จริงใน Chromium (Playwright) และ PC client แบบ scripted
(`tools/pc_smoke_client.gd` ใช้ `NetClient` ตัวเดียวกับ desktop) แล้วทดสอบทั้งสองทิศ:

1. browser สร้างห้อง → PC เข้าห้อง → browser (Host) เริ่ม Match
2. PC สร้างห้อง → browser เข้าห้อง → PC (Host) เริ่ม Match

browser build เผยสถานะย่อที่ `window.__forest` (code, phase, controller ของแต่ละ slot) ไว้ให้ test อ่าน

## Browser ที่ทดสอบแล้ว

| Browser | สถานะ |
| --- | --- |
| Chromium 141 (Playwright headless, Linux) | ผ่าน smoke test ทั้งสองทิศ และ UI เหมือน PC |
| Chrome / Edge / Firefox / Safari บน desktop จริง | ยังต้องตรวจด้วยมือใน checklist ของ #19 |

mobile browser อยู่นอกขอบเขต (spec #2)

## ข้อจำกัดของ web export ที่พบ

- **เครือข่าย**: browser ใช้ได้แค่ WebSocket (ไม่มี UDP/ENet) จึงเลือก WebSocket ทั้งระบบ (ADR-0008);
  หน้าเว็บ HTTPS ต่อ `ws://` ไม่ได้ (mixed content) ต้องใช้ `wss://` ผ่าน reverse proxy ที่มี TLS
- **Threads**: ปิด thread support เพื่อไม่ต้องใช้ header COOP/COEP (host ง่ายกว่า เช่น GitHub Pages/itch.io);
  เกมไม่ได้ใช้ thread อยู่แล้ว
- **ขนาดไฟล์**: `index.wasm` ~39 MB (ไม่บีบอัด) ควรเปิด gzip/brotli ที่ server (เหลือราว 9–10 MB)
- **เสียง**: browser ไม่ให้เล่นเสียงก่อนผู้เล่นคลิกหรือกดปุ่มครั้งแรก เสียงช่วงหน้าแรกจึงอาจไม่ดัง
  (ทุกสัญญาณเสียงมีตัวชี้แนะทางภาพอยู่แล้ว)
- **ค่าตั้งค่า**: `user://settings.cfg` ถูกเก็บใน IndexedDB ของ browser; ล้างข้อมูลเว็บแล้วค่าหาย
- **Clipboard**: ปุ่ม "Copy code" ต้องอยู่ใน secure context (HTTPS หรือ localhost)
- **Font**: font เริ่มต้นของ Godot ไม่มีภาษาไทยและ browser ไม่มี system font fallback (ADR-0007)

# T3D-02 — Home3D skeleton (เดิน WASD + สถานี + interaction)

- **Task ID:** T3D-02
- **Owner:** Claude2 (`ai/3d-claude2`, worktree `Project-GameDev-Agents/Claude2`)
- **Dependencies:** ไม่มี (ไม่ใช้ adapter); hook เข้า title ทำโดย Codex1 หลังงานนี้
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/plans/2026-10-02-3d-vertical-slice.md`

## Goal
ฉาก 3D ของ Home hub: ตัวละคร third-person (`CharacterBody3D` บล็อก placeholder), เดินด้วย WASD (เคารพ reduced motion), กล้องตามตัว, สถานี 6 จุด **Story, Battle, Party, Class, Shop, Settings** แต่ละจุดมี marker + ป้ายชื่อ + interact ด้วย E/Enter เมื่ออยู่ในระยะ แล้ว emit `station_activated(id)`

## Why
หน้าหลักของ slice; ใช้ระบบเดิมทั้งหมด (สถานีเป็นแค่ตัวเรียก)

## Allowed paths
`src/client/home3d/**`, `tests/client/home3d/**`

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `title_screen.gd`, `client_app.gd`, `battle3d/`, `presentation/`

## ข้อกำหนด
- API: `class_name Home3D` (Control ที่ฝัง SubViewport 3D หรือ Node3D) มี `signal station_activated(id: String)` และ `func set_stations_enabled(ids: Array)` (เช่น Continue ไม่มี save)
- id คงที่: `story`, `battle`, `party`, `class`, `shop`, `settings`
- ใช้ branch `ai/t50-open-world-hub` (`src/client/title/open_world_hub.gd`, ฮับ 2D) เป็นแนวทางรายชื่อ/พฤติกรรมสถานี — อ่านอย่างเดียว ห้าม merge/คัดลอกทั้งไฟล์
- สร้างด้วยโค้ด `.gd` (ไม่มี `.tscn` ใหม่ เว้นแต่จำเป็นและอยู่ใต้ `home3d/`)
- `gl_compatibility`: ไม่มี shadow/SSAO/glow; primitive mesh; โทน ดำ/แดง/ขาว
- keyboard-only ใช้ได้ครบ; ข้อความผ่าน `Tr.t()` (ไทย); เคารพ text scale
- harness รันเดี่ยววางที่ `src/client/home3d/dev/` (ไม่แตะ `tools/dev`)

## Acceptance criteria
1. รัน harness เห็นฉาก เดินได้ เข้าระยะสถานีแล้วขึ้น prompt; interact แล้ว emit id ถูก
2. test headless: สร้างฉากได้, จำลอง input → ตำแหน่งขยับ, เข้าระยะ → signal
3. suite เดิมผ่านทั้งหมด; พฤติกรรมเกมไม่เปลี่ยนเมื่อไม่ได้ใช้ Home3D
4. screenshot 1280×720 และ text scale 1.4 แนบใน handoff

## Test commands
ตามแผน

## Expected output
โค้ด + test + screenshot; รายการสิ่งที่ยังไม่ทำ (โมเดลจริง, animation)

## Handoff format
ตามแผน; ห้าม push

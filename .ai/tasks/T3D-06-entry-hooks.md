# T3D-06 — Entry hooks: Home3D ใน title + Battle3D ใน BattleView (หลัง `--3d`)

- **Task ID:** T3D-06
- **Owner:** Codex1 (`ai/3d-codex1`, worktree `Project-GameDev-Agents/Codex1`)
- **Dependencies:** T3D-01 (adapter), T3D-02 (`Home3D`), T3D-03 (`Battle3DStage`) — merge เข้า branch นี้แล้ว (ดู `git log`)
- **อ่านก่อน:** `AGENTS.md`, `CONTEXT.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `docs/plans/2026-10-02-3d-vertical-slice.md`, `src/client/presentation/README.md`

## Goal
เมื่อรันด้วย `--3d` (`LaunchOptions.use_3d`) และเล่น Story mode:
- **Part A (title):** หลังกด Play/Story ให้แสดง `Home3D` แทนเมนู 2D; `station_activated` → เปิดหน้าจอเดิม: `story` = หน้าเลือก New/Continue เดิม (ใช้ `StoryLauncher` เดิม), `settings` = settings panel เดิม, `battle`/`party`/`class`/`shop` = ถ้ามีหน้าจอเดิมที่เหมาะให้เปิด ถ้าไม่มีให้แสดง toast "Coming soon" (ผ่าน `Tr.t`) และปิดสถานีนั้นด้วย `set_stations_enabled` ให้ Continue ไม่เปิดเมื่อไม่มี save; ปุ่มกลับเมนูเดิมต้องมีเสมอ (Multiplayer ยังเข้าได้ผ่านเมนู 2D)
- **Part B (battle):** `BattleView` ฝัง `Battle3DStage` แทนเวที 2D (`_build_stage`, `BattleToken`, `BattleBackdrop`) เฉพาะเมื่อ `--3d`: `apply_state(BattlePresentation.state(view + mode))`, `handle_event` → `BattlePresentation.cues` → `play_cue`, `unit_clicked` → ใช้ตรรกะเลือกเป้าหมายเดิม (`_target_command`), nameplate/ตัวเลขดาเมจวางด้วย `unit_screen_position`/`unit_head_screen_position`; ส่ง `mode` จาก `_set_mode` ให้ adapter (snapshot ไม่มี mode); `set_reduced_motion`/quality ตาม `ClientSettings`
- **Part C (i18n):** เพิ่ม msgid ที่ขาดใน `i18n/messages.pot` และ `i18n/th.po`: `Story`, `Battle`, `Party`, `Unavailable`, `WASD / Arrows  Move   E / Enter  Interact` (+ ข้อความใหม่ของงานนี้) และแก้ให้ `tools/i18n check` ผ่าน
- ปรับ contract adapter ตามต้องการ: enemy unit มี `boss: bool` และ `row` (optional) ที่ `Battle3DStage` รองรับแล้ว — เพิ่มใน `BattlePresentation.state` + test + README

## Why
ทำให้เส้นทางเล่นจริง Story offline เห็น 3D ได้ end-to-end โดย 2D ยังเป็น default/fallback

## Allowed paths
`src/client/title/title_screen.gd`, `src/client/match/battle/battle_view.gd`, `src/client/match/match_screen.gd` (เฉพาะถ้าจำเป็นต่อ hook), `src/client/client_app.gd` (เฉพาะส่ง options), `src/client/presentation/**`, `i18n/**`, `tests/client/**` (ไฟล์ใหม่ + ปรับ test ที่ผูกกับ hook), `tools/dev/ui_preview.gd` (เพิ่มโหมด `--3d` ถ้าทำได้)

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `src/client/home3d/**`, `src/client/match/battle3d/**` (พบบั๊กในสองโฟลเดอร์นี้ → เขียนใน handoff ห้ามแก้)

## Acceptance criteria
1. ไม่มี `--3d`: พฤติกรรมและ test เดิมทุกตัวผ่านเหมือนเดิม (ห้ามลดจำนวน)
2. มี `--3d`: เริ่มเกม → Home3D → สถานี Story → New Story → Battle แสดงเวที 3D, เลือกคำสั่ง Strike/Skill/Focus/Item/Guard ได้, คลิกเลือกเป้าหมายในฉาก 3D ได้, จบ Combat ไปต่อ Camp ได้ (หน้าจอ Camp ยังเป็น 2D ได้)
3. test headless สำหรับ hook ทั้งสองส่วน (flag on/off) + test i18n ผ่าน
4. screenshot `--3d` ของ Home3D และ Battle3D (1280×720 และ text scale 1.4) ใน handoff
5. ไม่ commit ไฟล์นอก allowed paths; `git add` ระบุไฟล์เอง

## Test commands
ตามแผน + `bash tools/i18n/check` (ดูวิธีใน `tools/i18n/`)

## Expected output
โค้ด + test + screenshot + รายการสิ่งที่ยังไม่ทำ (HUD restyle เป็นงาน T3D-07)

## Handoff format
ตามแผน: branch+sha, ไฟล์ที่แก้, ผล test, สิ่งที่ยังไม่ทำ, ข้อสงสัย; commit บน `ai/3d-codex1` ได้ ห้าม push

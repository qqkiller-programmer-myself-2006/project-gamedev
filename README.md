# BEYOND THE WORLD'S END — Forest vertical slice

เกม RPG แฟนตาซีแบบผลัดตา co-op ออนไลน์ (1–5 คน, AI เติมช่องว่าง) และ Story mode ออฟไลน์
สร้างด้วย **Godot 4.7 + GDScript** — เป้าหมายคือให้ทุกหน้าจอและกติกาตรงกับเกมอ้างอิง AAC
([issue #2](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/2),
[#47](https://github.com/qqkiller-programmer-myself-2006/project-gamedev/issues/47))

## เริ่มจากตรงไหน

| อยากรู้ / อยากทำ | ไปที่ |
| --- | --- |
| ศัพท์ในเกม (Class, Layer, Encounter ...) | [CONTEXT.md](CONTEXT.md) |
| วิธีทำงานในรีโปนี้ (สำหรับคนและ AI) | [AGENTS.md](AGENTS.md) |
| รันเกม / server / ทดสอบ | [docs/guides/](docs/guides/) |
| เกมคืออะไร, กติกา, balance, UI | [docs/design/](docs/design/) |
| ทำไมถึงตัดสินใจแบบนี้ | [docs/adr/](docs/adr/) |
| ประวัติงานที่ผ่านมา | [docs/history/](docs/history/) และ [docs/review/](docs/review/) |
| สารบัญเอกสารทั้งหมด | [docs/README.md](docs/README.md) |

## Quick start

```bash
# Godot 4.7.2 ต้องอยู่ใน PATH ชื่อ `godot` (หรือตั้ง GODOT=/path/to/godot)
./tools/run_tests.sh                                   # รัน test ทั้งหมดแบบ headless
godot --headless --path . -- --server --port=8910      # server
godot --path . -- --url=ws://127.0.0.1:8910            # client (เปิด 2 หน้าต่างเล่น co-op)
godot --path . -- --dev --playtest --jump=boss --class=mage --seed=7   # ข้ามไปฉากที่ต้องการ
```

## แผนที่โฟลเดอร์

```text
src/        โค้ดเกม ทั้งหมด (GDScript)
  app/        จุดเริ่มเกม (entry scene, launch options)
  match/      ตรรกะเกม + กติกา (authoritative) — rules/ คือตัวช่วยกติกา
  net/        protocol และ WebSocket transport
  server/     headless server
  profile/    เก็บ/ส่งโปรไฟล์ผู้เล่น
  shared/     RNG, clock, ตัวโหลด content
  client/     หน้าจอผู้เล่น: title/ lobby/ story/ match/(battle/ camp/) ui/(widget กลาง)
tests/      test (โครงสร้างสะท้อน src/) + runner
content/    ข้อมูลเกม JSON (ด่านป่า, story)
assets/     ภาพ/เสียง/ฟอนต์ที่ Godot นำเข้า (heroes/ enemies/ fx/ icons/ audio/ ...)
art_source/ ชีตภาพดิบ — Godot ไม่นำเข้า ไม่รวมในบิลด์
i18n/       ไฟล์แปลภาษา (th.po)
tools/      สคริปต์ช่วย: dev/ (simulate, preview) art/ (หั่นสไปรต์) ci/ run_tests.sh
deploy/     staging: Docker, Caddy, profile-worker (Cloudflare)
docs/       เอกสาร แยกตามชนิด (ดู docs/README.md)
.ai/        ไฟล์สั่งงาน AI executor, checkpoint, runner  → สารบัญใน .ai/tasks/README.md
.claude/    นิยาม agent ของ Claude Code
```

โฟลเดอร์ `build/` (ถ้ามี) เป็นผลลัพธ์ที่ Git ไม่เก็บ

## สถานะล่าสุด (2026-10-02)

- **โหมด:** Multiplayer ออนไลน์ (room code, AI เติมช่อง) และ Story mode ออฟไลน์ (ADR-0014)
- **Class:** Swordsman, Archer, Mage, Guardian, Assassin (เดิมชื่อ Rogue) และ Classless
- **ด่าน:** 5 Layer — ป่า 1–4, ถ้ำ 5 + บอส · **Test:** 362 ข้อ headless
- รายละเอียดเต็ม: [docs/history/final-build-scope.md](docs/history/final-build-scope.md)
  และ checklist [docs/review/2026-10-01-final-build-checklist.md](docs/review/2026-10-01-final-build-checklist.md)

## ประวัติ (ย้ายออกจาก README นี้เพื่อให้อ่านง่าย)

- [docs/history/milestones-issues-22-37.md](docs/history/milestones-issues-22-37.md) — Energy, DoT, Rogue, Rest camp, Ready check (#22–#37)
- [docs/history/2026-10-01-ui-preview.md](docs/history/2026-10-01-ui-preview.md) — ภาพ UI preview 2026-10-01
- [docs/history/match-interface.md](docs/history/match-interface.md) — `MatchServer` API (จุดเดียวที่ใช้ทดสอบตรรกะ)

# Contributing

เกมใช้ Godot 4.7.2 และ GDScript. อ่าน [`AGENTS.md`](AGENTS.md), [`CONTEXT.md`](CONTEXT.md), และเอกสารใน [`docs/`](docs/README.md) ก่อนเปลี่ยนกติกาหรือโครงสร้าง.

## Branch names

- ใช้ `ai/<name>` สำหรับงานที่ทำผ่าน AI executor.
- ใช้ `feat/<name>`, `fix/<name>`, `docs/<name>`, หรือ `refactor/<name>` ให้ตรงกับประเภทงาน.

## Commit messages

ใช้ Conventional Commit: `type(scope): short summary` หรือ `type: short summary`. รูปแบบที่ใช้ในประวัติ เช่น `fix(ui): keep the skill menu at its original top`, `chore(audio): remove unused Hope boss track`, และ `docs: archive task specs`.

## Run tests

รันชุดทดสอบทั้งหมดก่อนเปิด PR (รวม layout smoke script ใน `tests/client/` ที่ไม่ขึ้นต้นด้วย `test_`):

```bash
./tools/run_tests.sh
GODOT=/path/to/Godot_v4.7.2-stable ./tools/run_tests.sh
```

ดูวิธีเพิ่ม test ที่ [`docs/guides/testing.md`](docs/guides/testing.md). ทดสอบ gameplay ผ่าน `MatchServer` interface.

## Pull request checklist

- อธิบายเหตุผลและขอบเขตของการเปลี่ยนแปลง พร้อมลิงก์ issue ที่เกี่ยวข้อง.
- รัน test ที่ได้รับผลกระทบและบันทึกผล; แนบภาพเมื่อแก้ UI.
- ตรวจลิงก์เอกสารและอัปเดตเอกสารที่เกี่ยวข้อง.
- ยืนยันว่าไม่มี generated files หรือ secrets ใน diff.

## Issue labels

ใช้ label triage ตาม [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md): `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, และ `wontfix`.

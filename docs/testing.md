# Testing

ทุก test รันแบบ headless จาก command line ด้วย runner ในรีโป
(`tests/run_tests.gd`, เหตุผลใน [ADR-0004](adr/0004-in-repo-headless-test-runner.md))

## รัน test

ต้องมี Godot **4.7.2** (หรือ 4.5+) อยู่ใน `PATH` ชื่อ `godot` หรือกำหนด `GODOT`

```bash
./scripts/run_tests.sh                    # ทุก test
./scripts/run_tests.sh --filter=voting    # เฉพาะ test ที่ id มีคำว่า voting
GODOT=/path/to/Godot_v4.7.2 ./scripts/run_tests.sh
```

- exit code `0` = ผ่านทั้งหมด, `1` = มี test fail หรือไม่พบ test
- CI (`.github/workflows/tests.yml`) รันคำสั่งเดียวกันทุก push ไป `main` และทุก PR

## เพิ่ม test ใหม่

1. สร้างไฟล์ `tests/<area>/test_<topic>.gd` ที่ `extends TestCase`
2. ทุก method ที่ชื่อขึ้นต้นด้วย `test_` คือ test หนึ่งข้อ (runner สร้าง instance ใหม่ทุกข้อ)
3. ใช้ `before_each()` ถ้าต้องเตรียมของซ้ำ
4. ใช้ assertion จาก `TestCase`: `assert_eq`, `assert_ne`, `assert_true`, `assert_false`,
   `assert_has`, `assert_not_has`, `assert_between`, `assert_ok`, `assert_rejected`, `fail`
5. script error ใด ๆ ระหว่าง test (null access, `push_error`) ทำให้ test นั้น fail

```gdscript
extends TestCase

func test_host_gets_a_room_code() -> void:
	var h := MatchHarness.new(1234)             # seed
	var host := h.server.open_session()
	var result := h.server.command(host, {"type": "create_room", "name": "Ann"})
	assert_ok(result)
	assert_eq(str(result["code"]).length(), 6)
```

## กติกาของ test (จาก spec #2)

- ทดสอบผ่าน **Match interface** (`MatchServer`) เท่านั้น: ส่ง command, เดิน clock,
  ตรวจ event/snapshot ห้ามแตะ state ภายในหรือเรียก class ภายในของ `src/match/` ตรง ๆ
- `MatchHarness` (`tests/support/match_harness.gd`) สร้าง `MatchServer` ด้วย seed,
  `ManualClock` และ content ของ Forest; ใช้ `h.advance(seconds)` เพื่อเดินเวลา
- อยาก content ที่ต่างจากค่าจริง ให้ส่ง override: `MatchHarness.new(seed, {"rules": {...}})`
- expected value ต้องเป็นค่าคงที่ที่รู้ล่วงหน้า ไม่คำนวณซ้ำแบบเดียวกับโค้ด
- ห้าม mock collaborator ภายใน และห้าม assert จำนวนครั้งที่เรียก function
- `tests/core/test_no_engine_randomness.gd` ตรวจว่า game logic ไม่เรียก random หรือเวลา
  ของ engine ตรง ๆ: ใช้ `GameRng` และ clock ที่ inject เท่านั้น

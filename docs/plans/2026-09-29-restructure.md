# แผน: จัดโครงสร้างโฟลเดอร์ให้ง่ายขึ้น (คำขอเจ้าของงาน 2026-09-29)

เป้าหมาย: ผู้ดูแลคนใหม่หาไฟล์ได้โดยเดาจากโฟลเดอร์ จัดแต่ละประเภทไว้ที่เดียว ตั้งชื่อโฟลเดอร์ตามสิ่งที่ผู้เล่นเห็น (client) หรือกติกาที่ดูแล (server) ไม่มีไฟล์ซ้ำหรือไฟล์ขยะที่ root **ไม่เปลี่ยนพฤติกรรมเกม**

## ปัญหาของโครงสร้างเดิม
| ปัญหา | ตำแหน่ง |
| --- | --- |
| ใน `docs/` มี 340 จาก 368 ไฟล์เป็นสำเนาทักษะ agent เก่าสามชุดที่เหมือนกัน (`docs/.agents/skills`, `docs/.aider-desk/skills`, `docs/.claude/skills`) โดยสำเนาใหม่กว่าอยู่ใน `~/.claude/skills` | `docs/` |
| มีไฟล์เดี่ยวที่ root: `hello_world.txt` (ทดสอบการเชื่อมต่อ), `checkpoint.md` (บันทึกผู้วางแผน) | root |
| `scripts/` มีไฟล์เดียว; `tools/` ปะปนสคริปต์ Godot, Python และ Node | `scripts/`, `tools/` |
| `src/core` รวมของสามประเภท: ตัวช่วยให้ผลทำงานคงที่ (RNG, clocks), ตัวโหลด content และที่เก็บโปรไฟล์ (store 4 แบบ + HTTP sender) | `src/core` |
| โฟลเดอร์ client ไม่ตรงกับหน้าจอ: `camp_view` อยู่ใน `battle/`, `settings_panel` อยู่ใน `screens/`, ฉากหลังหน้าแรกอยู่ใน `home/`, หน้าเลือกตัวละครแยกเดี่ยวใน `setup/`, ส่วน combat/merchant อยู่ใน `panels/` ห่างจากหน้าจอที่แสดงผล | `src/client` |
| มีตัวช่วยกติกา 5 ไฟล์วางเดี่ยวข้าง match server | `src/match` |
| ชีตภาพต้นฉบับอยู่ใน `assets/` ทำให้ Godot นำเข้าและส่งออกไฟล์เหล่านั้นด้วย | `assets/characters/source` |
| tests ไม่ได้จัดโครงสร้างให้ตรงกับ `src` (`test_battle_view_data` อยู่ใน `tests/match`, test ของ story client อยู่ใน `tests/client`, test profile อยู่ใน `tests/core`) | `tests/` |
| มีเอกสารเดี่ยว 9 ไฟล์ที่ยังไม่ได้จัดกลุ่ม | `docs/*.md` |

## โครงสร้างเป้าหมาย
```
project.godot  export_presets.cfg  README.md  AGENTS.md  CLAUDE.md  CONTEXT.md
assets/                      runtime art only (imported by Godot)
  fonts/
  heroes/<class>/            was assets/characters/<class>; manifest.json stays beside them
  enemies/<id>/              new (art work after this plan)
  backgrounds/               new
  icons/                     new (#61)
art_source/                  raw sheets, never imported (.gdignore): heroes/ enemies/ backgrounds/
content/                     forest.json, story_mode.json (unchanged)
src/
  app/                       main.tscn, main.gd, launch_options.gd (unchanged)
  shared/                    game_rng, system_clock, manual_clock, forest_content (used by server and client)
  profile/                   profile_store, memory_/file_/d1_profile_store, http_profile_sender
  match/                     authoritative rules (name kept: MatchServer is a domain term, ADR-0001/0008)
    match_server.gd room.gd room_codes.gd match_run.gd
    rules/                   attributes, status_book, enemy_groups, route_generator, path_vote
    encounters/  ai/         (unchanged)
  net/                       (unchanged)
  server/                    game_server.gd (unchanged)
  client/
    client_app.gd
    ui/                      ui_kit, ui_text, confirm_dialog, sound_bank, client_settings (+ icons later)
    title/                   title_screen, home_backdrop, settings_panel
    lobby/                   lobby_screen, character_setup
    match/                   match_screen, info_panel, vote_panel, summary_panel, class_panel, story_panel
      battle/                battle_view, battle_token, battle_backdrop, sprite_set, combat_panel
      camp/                  camp_view, merchant_panel
    story/                   (unchanged)
tests/                       mirrors src/: shared/ profile/ match/ net/ client/ regression/ support/ + run_tests.gd, test_case.gd
tools/
  run_tests.sh               was scripts/run_tests.sh
  dev/                       simulate.gd, ui_preview.gd, story_preview.gd, pc_smoke_client.gd
  art/                       slice_character_sheet.py (+ make_icons.py later)
  ci/                        web_smoke.mjs
deploy/                      unchanged
docs/
  README.md                  index: one line per doc
  design/                    prd, balance, ui-style, accessibility
  guides/                    running, staging, testing, web
  adr/ agents/ plans/ review/ references/ screenshots/
.ai/                         executor runner, task specs, checkpoint.md (moved from root)
.claude/agents/              subagent definitions
```

## เหตุผลที่การย้ายนี้ปลอดภัยใน Godot
- 69 scripts use `class_name`; those names are global, so code that uses the class does not care where the file is.
- Only ~35 literal `res://` paths exist (tests' directory lists, `main.tscn`, `project.godot` main scene, sprite/portrait roots,
  font path, content path, preview tools). Every one is listed by `git grep -n "res://"` and gets updated.
- Every script has a `.uid` file: it moves with its script (`git mv a.gd b.gd` and `git mv a.gd.uid b.gd.uid`), so `.tscn`
  uid references keep working. Asset `.import` files move with their asset, then `godot --headless --import` refreshes them.
- `export_presets.cfg` excludes `tests/*, tools/*, docs/*, build/*`; add `art_source/*` too (and `.gdignore` keeps it out).

## ลำดับดำเนินการ (หนึ่ง commit ต่อขั้น และ test ต้องผ่านทุกขั้น)
1. Freeze: no other executor running; all branches merged (done: #59, #62, #63, #64).
2. Delete `docs/.agents`, `docs/.aider-desk`, `docs/.claude` (duplicate skills), `hello_world.txt`; move `checkpoint.md` to `.ai/`.
3. `scripts/run_tests.sh` → `tools/run_tests.sh`; split `tools/` into `dev/ art/ ci/`; update CI, README, docs, agents.
4. `src/core` → `src/shared` + `src/profile`; `src/match` loose helpers → `src/match/rules/`.
5. `src/client` regrouped by screen as in the tree.
6. `tests/` mirror `src/`.
7. `assets/characters` → `assets/heroes`; raw sheets → `art_source/heroes` with `.gdignore`.
8. `docs/` grouped + `docs/README.md` index; fix every link.
9. Verify (below), update `AGENTS.md`/`CONTEXT.md` "where things live", README tree.

## ตรวจสอบ (ต้องผ่านทั้งหมดก่อน merge)
- `git grep` for every old path (outside `docs/review`, `.ai/tasks`, `.ai/checkpoint.md` history) returns nothing.
- `godot --headless --path . --import` has no errors; `bash tools/run_tests.sh` → same count as before, 0 failed
  (includes the compile-every-script test and the no-engine-randomness scan).
- `tools/dev/ui_preview.gd` produces every screenshot; `tools/dev/simulate.gd --seeds=10` runs.
- The game opens (`--dev --playtest`) and a Playtest match starts; export check: `--export-release "Windows"` if templates exist.

## งานหลังจากนี้
งานภาพ (ตามการตัดสินใจของเจ้าของงานวันที่ 2026-09-29): สร้างชีตฮีโร่ใหม่สำหรับ Archer/Mage/Swordsman/Guardian และ Assassin (เปลี่ยนชื่อ Rogue เป็น Assassin); เปลี่ยนชื่อศัตรูป่าให้ตรงกับภาพ (Grey Wolf→Wolf, Masked Outlaw→Thief, Stone Sentinel→Golem, Forest Wisp→Slime, Bramble Archer→Goblin โดยคงค่าสถานะเดิม); ย้ายชั้นสุดท้ายและบอสเข้าไปในถ้ำ พร้อม Kobold, Minotaur, Skeleton, Giant Spider; เพิ่มฉากหลังการต่อสู้ของป่าและถ้ำ

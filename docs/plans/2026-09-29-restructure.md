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
- 69 สคริปต์ใช้ `class_name`; ชื่อเหล่านี้เป็นชื่อสากล ดังนั้นโค้ดที่ใช้คลาสจึงไม่สนใจว่าไฟล์อยู่ที่ไหน
- มีพาธ `res://` ที่เขียนตรง ๆ เพียงประมาณ 35 จุด (รายชื่อไดเรกทอรีในชุดทดสอบ, `main.tscn`, ฉากหลักใน `project.godot`, โฟลเดอร์หลักของสไปรต์/ภาพตัวละคร, พาธฟอนต์และข้อมูลเกม, เครื่องมือสร้างภาพตัวอย่าง) ใช้ `git grep -n "res://"` ระบุทุกจุดและอัปเดตให้ครบ
- ทุกสคริปต์มีไฟล์ `.uid` ที่ย้ายไปพร้อมกัน (`git mv a.gd b.gd` และ `git mv a.gd.uid b.gd.uid`) การอ้างอิง UID ใน `.tscn` จึงยังใช้ได้ ไฟล์ `.import` ย้ายตามภาพ แล้วใช้ `godot --headless --import` สร้างข้อมูลนำเข้าใหม่
- `export_presets.cfg` ไม่รวม `tests/*, tools/*, docs/*, build/*`; เพิ่ม `art_source/*` ด้วย (และ `.gdignore` จะป้องกันไว้)

## ลำดับดำเนินการ (หนึ่ง commit ต่อขั้น และ test ต้องผ่านทุกขั้น)
1. หยุดงานอื่นชั่วคราว: ไม่มีผู้ลงมือรายอื่นกำลังทำงาน และรวมทุก branch แล้ว (เสร็จ: #59, #62, #63, #64)
2. ลบ `docs/.agents`, `docs/.aider-desk`, `docs/.claude` (ทักษะที่ซ้ำกัน), `hello_world.txt`; ย้าย `checkpoint.md` ไปที่ `.ai/`
3. `scripts/run_tests.sh` → `tools/run_tests.sh`; แยก `tools/` ออกเป็น `dev/ art/ ci/`; อัปเดต CI, README, เอกสาร, ตัวแทน
4. `src/core` → `src/shared` + `src/profile`; `src/match` ตัวช่วยหลวม → `src/match/rules/`
5. `src/client` จัดกลุ่มใหม่ตามหน้าจอเช่นเดียวกับในแผนผัง
6. จัด `tests/` ให้มีโครงสร้างตรงกับ `src/`
7. `assets/characters` → `assets/heroes`; แผ่นงานดิบ → `art_source/heroes` พร้อม `.gdignore`
8. `docs/` จัดกลุ่ม + ดัชนี `docs/README.md`; แก้ไขทุกลิงค์
9. ตรวจสอบ (ด้านล่าง) อัปเดต `AGENTS.md`/`CONTEXT.md` "ที่ซึ่งสิ่งต่างๆ อาศัยอยู่" แผนผัง README

## ตรวจสอบ (ต้องผ่านทั้งหมดก่อน merge)
- `git grep` หาพาธเก่าทุกพาธไม่พบผลลัพธ์ ยกเว้นเอกสารประวัติใน `docs/review`, `.ai/tasks`, `.ai/checkpoint.md`
- `godot --headless --path . --import` ไม่มีข้อผิดพลาด `bash tools/run_tests.sh` → นับเหมือนเดิม 0 ล้มเหลว
  (รวมการทดสอบคอมไพล์ทุกสคริปต์และการตรวจว่าโค้ดไม่ใช้ระบบสุ่มของเอนจินโดยตรง)
- `tools/dev/ui_preview.gd` สร้างภาพหน้าจอครบ; `tools/dev/simulate.gd --seeds=10` ทำงานสำเร็จ
- เกมเปิดได้ด้วย `--dev --playtest` และเริ่มแมตช์ทดสอบได้; ตรวจการส่งออกด้วย `--export-release "Windows"` หากมีเทมเพลต

## งานหลังจากนี้
งานภาพ (ตามการตัดสินใจของเจ้าของงานวันที่ 2026-09-29): สร้างชีตฮีโร่ใหม่สำหรับ Archer/Mage/Swordsman/Guardian และ Assassin (เปลี่ยนชื่อ Rogue เป็น Assassin); เปลี่ยนชื่อศัตรูป่าให้ตรงกับภาพ (Grey Wolf→Wolf, Masked Outlaw→Thief, Stone Sentinel→Golem, Forest Wisp→Slime, Bramble Archer→Goblin โดยคงค่าสถานะเดิม); ย้ายชั้นสุดท้ายและบอสเข้าไปในถ้ำ พร้อม Kobold, Minotaur, Skeleton, Giant Spider; เพิ่มฉากหลังการต่อสู้ของป่าและถ้ำ

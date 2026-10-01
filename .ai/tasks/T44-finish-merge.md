# T44 — จบ merge origin/main (รอบ 3) ให้ compile และ test ผ่านหมด
สถานะ: `git merge` (FETCH_HEAD = origin/main) ค้างอยู่ใน worktree นี้; ไฟล์ conflict ถูกแก้โดยเลือกฝั่ง main ในจุดชน แล้ว stage แล้ว. อย่ารัน merge ใหม่/rebase/abort/commit/push (ผมทำเอง). **ห้ามย้อนงานของ main**.
บริบท: main ทำซ้ำสิ่งที่เราทำ (ตัวเลขดาเมจเข้าคิวด้วย `_float_stack`, camp layout, vote card, title panel, summary) — ใช้ implementation ของ main และผสานของเรา (ภาษาไทย `Tr.t`, summary หัวข้อเดียว/ล้าง floating text, turn list ไม่ถูกปุ่มทับ, merchant confirm, หลักฐาน a11y) เฉพาะที่ main ยังไม่มี.
## สิ่งที่ต้องทำ
1. `"$GODOT" --headless --path . --import` ต้องไม่มี `SCRIPT ERROR` (ตอนนี้ยังมี 4: compile ล้ม) — แก้จนผ่าน.
2. `bash tools/run_tests.sh` ผ่านทั้งหมด. ตอนนี้ล้ม 32: `test_accessibility_baseline` (load), `test_camp_update`, `test_icons` camp tab, `test_qa_polish` (หลายข้อ), `test_story_ui` (vote/summary/party), `test_tutorial_hints`, `tests/i18n/test_thai_catalog` (5), `test_scripts_compile`. สาเหตุหลัก: `vote_panel.gd` / `title_screen.gd` ใช้ฉบับ main ทั้งไฟล์ (ข้อความไม่ผ่าน `Tr.t`), และ test ของเรา/main ผูกกับ API ต่างกัน — รวมเป็นชุดเดียวให้ตรวจเจตนาเดิมของทั้งสองฝั่ง ไม่ลบ test ทิ้งเว้นแต่ซ้ำกันจริง.
3. ข้อความผู้เล่นเห็นทุกจุดในไฟล์ที่ main เพิ่ม/แก้ต้องผ่าน `Tr.t` + คำแปลไทยใน `i18n/th.po` (ใช้ `tools/i18n/extract_strings.gd` แล้วเติมคำแปล ตาม glossary); `check_po.gd` exit 0; ไม่มีข้อความละตินหลุดใน Control tree (test สแกนที่ T43 เพิ่มต้องผ่าน).
4. ไฟล์เอกสาร/ content ที่ผมเลือกฝั่ง main (`README.md`, `AGENTS.md`, `docs/README.md`, `content/forest.json`): ถ้ามีข้อความอังกฤษใหม่จาก main ให้แปลไทยตามกฎ T38 (ไม่แปล code/path/identifier); ถ้า content/forest.json เปลี่ยนข้อความให้ซิงก์ `th.po` ผ่าน extractor.
5. ไม่แตะ `src/match`, `src/server`, `src/net` และไม่มี conflict marker ที่ใดเลย.
## Verify/Report
รัน import + test ทั้งชุด + `ui_preview --seed=21` (1280×720 และ --scale=1.45) เปิด PNG Title/Vote/Combat/Merchant/Summary ดู; รายงานตารางต่อไฟล์ + ผล test.

# T43 — ผสาน redesign ของ main กับภาษาไทย + T40 + T41 เดิม
บริบท: เพิ่ง merge origin/main (redesign UI ของ T41-ux: header, vote screen, battle layout, SFX). ใน 4 ไฟล์ `battle_token.gd`, `battle_view.gd`, `match_screen.gd`, `vote_panel.gd` ผมใช้ฉบับของ main ทั้งไฟล์ ทำให้ (ก) ข้อความใหม่ของ main ไม่ผ่าน `Tr.t` และ (ข) พฤติกรรม T40 บางอย่างหาย. ฐานนี้ compile ผ่านแล้ว; test ที่ล้ม: `tests/client/test_accessibility_baseline.gd::test_battle_timeline_starts_clear_of_corner_controls`, `::test_summary_clears_floating_combat_feedback`, และ `tests/client/test_qa_polish.gd` (load error).
## ทำ
1. ห่อ `Tr.t(...)` ทุกข้อความที่ผู้เล่นเห็นในทั้งสี่ไฟล์ (ดูของเก่าในประวัติ: `git show ai/t37b:<file>` / `git show HEAD~1:<file>` เทียบ) และไฟล์อื่นที่ main เพิ่ม/แก้; เพิ่มคำแปลไทยใน `i18n/th.po` ผ่าน extractor (ใช้ glossary) — `check_po.gd` exit 0, test ครอบ `Tr.t` literal ผ่าน.
2. เติมพฤติกรรม T40 ที่ main ไม่มี โดยเข้ากับ redesign ของ main (ไม่ถอย layout/SFX ของ main): turn list ไม่ถูกปุ่มมุมทับ; ตัวเลขดาเมจ floating เข้าคิวไม่ซ้อน; Summary ล้าง floating/banner และมีหัวข้อผลลัพธ์เดียว. แก้ test ที่ล้มให้ตรงกับ layout ใหม่ถ้า assertion เก่าผูกกับโครงเดิม (แต่ต้องยังตรวจเจตนาเดิม).
3. ทำ T41 เดิม (`.ai/tasks/T41-final-polish.md`) ต่อเท่าที่ยังจำเป็น: ข้อความอังกฤษที่ยังเห็น ("Turn N", "CRIT", ชื่อตัวละคร/ไอเท็ม/event log), สแกนข้อความละตินที่เหลือทุกหน้า, Merchant/Rest ×1.45 ไม่ต้องเลื่อนแนวนอน, test คีย์บอร์ดสำหรับ #44 + อัปเดตตารางใน `docs/review/2026-10-01-responsive-a11y-evidence.md`.
4. เอกสารที่ main เพิ่มเป็นอังกฤษ (`docs/review/2026-09-30-final-review.md` ส่วน F5-F19 และไฟล์ docs ใหม่ของ main) แปลเป็นไทยตามกฎ T38.
กฎ: ห้ามแก้ `src/match`, `src/server`, `src/net`; ห้าม commit/push (ผมทำเอง).
## Verify
`bash tools/run_tests.sh` ผ่านหมด; `tools/dev/ui_preview.gd --seed=21` ที่ 1280×720 / 1920×1080 / --scale=1.45 เปิด PNG ดู; ไม่มี marker ใน repo.
## Report
ตารางต่อข้อ + ข้อที่เหลือ.

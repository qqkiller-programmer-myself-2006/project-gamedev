# T45 — แก้ layout smoke ที่ล้มหลัง merge กับ main (CI "Headless GDScript tests" แดง)
CI รัน smoke แยกจาก `run_tests.sh` (ดู `.github/workflows/tests.yml` ขั้น "Layout smoke tests"). บน **origin/main ผ่านทั้งหมด** แต่บน branch นี้ 2 ตัวล้ม:
- `tests/client/t43_camp_battle_fit_smoke.gd` → "Merchant and inventory lists receive scrollable viewport height" (camp ใช้ layout แบบ ScrollContainer/`custom_minimum_size.x = viewport_width-48` ที่เหลือจากงาน T39/T40 เก่า ผสมกับของ main)
- `tests/client/t46_skill_menu_layout_smoke.gd` → "Enemy name truncates with ellipsis at 1.0/1.4", "Enemy level remains visible", "Item card keeps its name visible"
## แนวทาง
1. เทียบ `git diff origin/main -- src/client/match/camp/camp_view.gd src/client/match/battle/ src/client/ui/ui_kit.gd src/client/match/match_screen.gd` — ถือ **layout/โครงสร้างของ main เป็นหลัก** (ใช้ฉบับ main ของ layout ทั้งหมด) แล้วคงเฉพาะส่วนภาษาไทยของเรา (`Tr.t(...)`, Thai font fallback, `_has_thai`) บนฐานนั้น. ลบโค้ด layout เก่าของ T39/T40 ที่ซ้ำ/ขัดกับ main (เช่น workspace ScrollContainer แนวนอนใน camp, `custom_minimum_size.x`).
2. ห้ามทำให้ test เดิมของ main ถอย; test ของเราที่ผูกกับ layout เก่า (`tests/client/test_qa_polish.gd` camp assertions ฯลฯ) ให้ปรับให้ตรวจเจตนาเดิมบน layout ของ main (ไม่ลบทิ้ง).
3. ป้ายศัตรู: ชื่อต้อง ellipsis เมื่อยาว, เลเวลต้องมองเห็น (ใน locale `en` ตามที่ smoke ตั้งไว้) — ภาษาไทย (`th`) ต้องไม่ล้นเช่นกัน; ตรวจเพิ่มด้วย preview ที่ th ที่ 1.0 และ 1.4.
4. ไม่แตะ `src/match`, `src/server`, `src/net`. ไม่ commit/push.
## Verify (ต้องผ่านทั้งหมด)
```
export GODOT='D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
for t in t35_layout_smoke t42_vote_summary_layout_smoke t43_camp_battle_fit_smoke t88_skill_badge_layout t46_skill_menu_layout_smoke; do "$GODOT" --headless --path . -s tests/client/$t.gd 2>&1 | grep -E "passed|FAILED"; done
bash tools/run_tests.sh
"$GODOT" --headless --path . -s tools/i18n/check_po.gd
```
และ `ui_preview --seed=21` (th, 1280×720 และ --scale=1.4) เปิดดู Merchant/Rest/Combat. Report เป็นตารางต่อไฟล์ + ผลทุกคำสั่งข้างบน.

# T39 — ปิด issue UI ที่เหลือ: #83, #87, #88, #44, #45 (และ #76 ที่ทำได้)

อ่านก่อน: issue ตัวจริงด้วย `gh issue view <n> --comments --repo qqkiller-programmer-myself-2006/project-gamedev`, รายงาน `docs/review/2026-09-30-full-qa-report.md` (file:line + วิธีทำซ้ำ), `AGENTS.md`, `.ai/checkpoint.md`.
อีก executor แก้ `src/client/ui/ui_text.gd` + locale/font (T37a) และอีกตัวแก้ `.md` (T38) พร้อมกัน — **อย่าแตะ** `ui_text.gd`, `i18n/`, `docs/`.
ข้อความใหม่ที่เพิ่มในโค้ดให้เป็นอังกฤษ (source) แล้วผ่านจุดเดียวที่มีอยู่; อย่าเพิ่มข้อความไทยตรง ๆ ในโค้ด.

ทำทีละข้อตามลำดับ แล้ว commit-ready เป็นกลุ่มสะอาด (อย่า commit เอง — ทิ้ง uncommitted ตาม runner):

## A. #83 (U7-U9) turn list ถูกตัด, tip ทับเนื้อหา, combat tip เก่า
ทำตามข้อความใน QA report; ตรวจที่ 1280×720 และ ×1.45 text.

## B. #87 (U14-U34) — ข้อที่ยังเปิด
จากคอมเมนต์ใน issue ที่ยัง open: U14 placeholder text ("All", "P OK", "S OK", "..."), U15 item id → ชื่อ, U16 battle log ไม่มีพื้นหลัง/ตัดบรรทัดล่าสุด, U17 "Your turn!" หลัง Victory + floating numbers ค้างใน Summary, U18 damage numbers ซ้อนบนบอส, U19 item description overflow ที่ 1.4 + target caption/skill grid ทับฮีโร่แถวหลัง, U20 hover บนเป้าหมาย + downed grey, U21 ขนาด Trainer sprite, U23 คำว่า "Forest" ในถ้ำ, U25 toast ทับปุ่มบน/room code, U28 Merchant 1-9 ซื้อโดยไม่ยืนยัน, U29 camp backdrop, U30 สี HP bar / text สูงกว่า bar ที่ 1.4, U31 vote screen scroll ที่ 1.4/720p (Alternatives ตกใต้ fold). ข้อใดแก้เสร็จแล้วจริงบน main ให้ระบุว่า "already fixed" พร้อมหลักฐาน (อย่าแก้ซ้ำ).

## C. #88 smoothness (S1, S2, S3, S5)
S1 คง BattleToken ต่อ id ไม่สร้างใหม่ทุก update + tween HP/Energy ~0.25s; S2 เล่น event (attack → hit → HP tween) ก่อน HP เปลี่ยน, banner สั้นและไม่บล็อก; S3 cache `forest.json` ไม่ parse ใหม่ทุก build; S5 เลิก `add_theme_color_override` ทุกเฟรม, ไม่ `load()` ใน `_draw`, typewriter ใช้ `visible_characters`, เพิ่ม fade ให้ chapter card/dialogue.

## D. #44 / #45 หลักฐานที่ค้าง
#44: หลักฐาน Rest camp + reduced-motion ด้วย `tools/dev/ui_preview.gd` (เก็บภาพใน `docs/screenshots/`). #45: ภาพ/หลักฐาน Battle, Merchant, Rest ที่ 1280×720 และ 1920×1080 (+ ×1.45 text) — ไม่มีข้อความ/ตัวเลข/ปุ่มทับหรือถูกตัด; บันทึกชุด browser ที่ตรวจ (web smoke `tools/ci/web_smoke.mjs`). สร้างรายงานสั้น `docs/review/2026-10-01-responsive-a11y-evidence.md` ลิงก์ภาพ.

## E. #76 (P2 follow-ups) — เท่าที่ทำได้ปลอดภัย
F17/F19: exclude `deploy/*` ใน `export_presets.cfg` และตรวจว่า `manifest.json` ของ hero/enemy อยู่ใน export pack; F4: ตัดสินใจเขียนในตัว ADR-0014 ว่า "Story ไม่มี meta" (แก้ ADR เป็นภาษาไทย) **ถ้า** ADR-0014 ยังไม่ระบุ; F5-F8 (server/D1) ทำเฉพาะที่ไม่ต้องมี Cloudflare จริงและมี test ครอบ — ข้อที่ต้อง deploy ให้ข้ามและรายงาน.

## Verify (ทุกกลุ่ม)
```
export GODOT='D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
bash tools/run_tests.sh      # ต้องผ่านทั้งหมด (baseline 417+)
"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=11 --speed=10   # และ --scale=1.45
```
เปิดภาพ PNG ที่เกี่ยวข้องดูจริงก่อนอ้างว่าเสร็จ. เพิ่ม/ปรับ test ให้ครอบพฤติกรรมที่แก้.

## Report (บังคับ)
ตารางต่อ issue: แก้อะไร / หลักฐาน (test, ภาพ) / ข้อที่ยังเหลือและเหตุผล — เพื่อให้ผู้รีวิวตัดสินใจปิด issue ได้.

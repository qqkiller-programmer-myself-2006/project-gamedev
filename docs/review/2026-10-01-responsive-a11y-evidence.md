# หลักฐาน Responsive และ Accessibility — 2026-10-01

## วิธีตรวจ

- Godot 4.7.2, `tools/dev/ui_preview.gd --seed=3 --speed=24` และ `--scale=1.45`, `--reduced-motion` ตามชุดภาพ
- seed 3 ไม่ได้เลือก Rest ทุกครั้งจากการโหวตแบบเสมอ จึงปรับ preview ให้ผู้เล่นจำลองและ bot เลือก Rest ครั้งแรกที่มีตัวเลือก เพื่อให้เก็บภาพหน้าพักได้แน่นอน
- ภาพหลักทั้ง 4 ชุดอยู่ใน [`docs/screenshots/2026-10-01-a11y/`](../screenshots/2026-10-01-a11y/)
- ผลตรวจ T43: `bash tools/run_tests.sh` ผ่าน 464 tests, 0 failed (253.70s); `check_po.gd` ผ่าน 831 msgids
- ตัวสแกนข้อความใน Control tree: `tools/dev/ui_preview.gd --seed=21 --speed=75 --scale=1.45 --scan-latin` ตรวจ 22 screens และพบ Latin ที่ไม่อยู่ใน allowlist 0 รายการ; log อยู่ใน `build/ui/t43-final-scan.log` (ไฟล์ใน `build/` ใช้ระหว่าง QA)
- `tools/ci/web_smoke.mjs` ผ่านด้วย Playwright Chromium 141.0.7390.37 ทั้ง browser host + PC join และ PC host + browser join

## Issue #44 — Keyboard และ Accessibility

| เกณฑ์ | ผล | หลักฐาน / ข้อสังเกต |
| --- | --- | --- |
| ปุ่มหลักของ Battle, Merchant และ Rest ใช้ผ่านคีย์บอร์ดได้ | ⚠️ ผ่านบางส่วน | test ตรวจ focus mode, focus id และ hotkey หลักของหน้าจอ; preview ขับการต่อสู้ โหวต และ Ready ด้วยคีย์บอร์ด แต่ยังไม่ได้จำลอง Tab/ลูกศร/Enter ครบทุก control |
| ลำดับ focus และสถานะ focus มองเห็นและคาดเดาได้ | ⚠️ ผ่านบางส่วน | test ตรวจว่าปุ่มหลักมี focus style จากธีมสีทอง; ยังไม่ได้ตรวจ focus owner จริงและลำดับ Tab/ลูกศรใน viewport ที่กำลังทำงาน |
| ข้อมูลไอเท็ม สถานะ และ action สำคัญไม่พึ่ง tooltip อย่างเดียว | ✅ ผ่าน | accessibility tests ตรวจคำสั่งซื้อ, สถานะวัตถุดิบ, turn status และจุดอ่อนศัตรูเป็นข้อความ |
| Reduced motion ลด animation โดยไม่ซ่อนการเปลี่ยนสถานะ | ✅ ผ่าน | ภาพใน `reduced-motion/`; test ยืนยัน HP คงค่าเดิมจน hit feedback แล้วเปลี่ยนทันทีโดยไม่ tween |
| ตัวอักษรใหญ่ไม่ซ่อน control สำคัญใน viewport หลัก | ⚠️ ผ่านบางส่วน | ที่ 1.45× แคมป์เปลี่ยนเป็นคอลัมน์แนวตั้งและเลื่อนแนวตั้งได้ ไม่มีการเลื่อนแนวนอน; Equipment อยู่ช่วงล่างของ workspace จึงต้องเลื่อนลง |
| เก็บหลักฐานจาก UI preview | ✅ ผ่าน | มีภาพ Battle, Merchant และ Rest ทั้ง 1280×720, 1920×1080, 1.45× และ reduced motion |

## Issue #45 — Responsive และ Browser

| เกณฑ์ | ผล | หลักฐาน / ข้อสังเกต |
| --- | --- | --- |
| Battle, Merchant และ Rest ที่ 1280×720 | ✅ ผ่าน | `720/04_combat_turn.png`, `720/08_merchant.png`, `720/10_rest.png` |
| Battle, Merchant และ Rest ที่ 1920×1080 | ✅ ผ่าน | `1080/04_combat_turn.png`, `1080/08_merchant.png`, `1080/10_rest.png` |
| ไม่มีข้อความ ตัวเลข badge หรือ control สำคัญทับ/ถูกตัดที่ความละเอียดข้างต้น | ⚠️ ผ่านบางส่วน | 1280×720 และ 1920×1080 ยังเห็นปุ่มซื้อ/Ready; ที่ 1.45× ต้องเลื่อนลงเพื่อดู Equipment และ preview ยังรายงาน `Rect2i size is negative` 34 ครั้ง |
| ตรวจ browser ที่รองรับและบันทึกความต่างราย browser | ⚠️ ผ่านบางส่วน | Chromium 141 ผ่าน cross-platform smoke; ยังไม่ได้ตรวจ Chrome, Edge, Firefox และ Safari แบบ desktop จริงทีละ browser |
| รักษา keyboard และ reduced-motion behavior | ⚠️ ผ่านบางส่วน | test และ reduced-motion preview ผ่าน; การไล่ keyboard focus ทุก control ยังไม่ครบตาม #44 |
| มีภาพหรือหลักฐานทำซ้ำได้ | ✅ ผ่าน | ภาพจาก Godot UI preview และคำสั่งอยู่ในหัวข้อวิธีตรวจ |

## ข้อที่ยังไม่ผ่านครบ

1. เพิ่มการจำลอง Tab/ลูกศร/Enter และตรวจ focus owner จริงใน viewport สำหรับ Battle, Merchant และ Rest ตาม #44
2. ตรวจและแก้ `Rect2i size is negative` ที่ยังเกิดใน preview ×1.45; Equipment เข้าถึงได้ด้วยการเลื่อนแนวตั้งแล้ว
3. ตรวจ Chrome, Edge, Firefox และ Safari บน desktop จริง; Chromium smoke ไม่ได้แทนการตรวจภาพและ interaction ของ browser เหล่านั้น

## ผล Web smoke

โฟลเดอร์นี้ไม่มี `package.json` หรือ `package-lock.json`; `npm ci` จึงหยุดด้วย `EUSAGE` ว่าไม่มี lockfile. ติดตั้ง Playwright 1.56.1 ชั่วคราวใน workspace, สร้าง Web export แล้วรัน `tools/ci/web_smoke.mjs` ผ่านทั้งสองทิศทาง. การติดตั้ง Playwright และ browser binaries อยู่ใน `build/`/`node_modules/` ระหว่างตรวจ; เอาแพ็กเกจ Node ออกหลังตรวจแล้ว.

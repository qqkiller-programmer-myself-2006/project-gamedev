# หลักฐาน Responsive และ Accessibility — 2026-10-01

## วิธีตรวจ

- Godot 4.7.2, `tools/dev/ui_preview.gd --seed=3 --speed=24` และ `--scale=1.45`, `--reduced-motion` ตามชุดภาพ
- seed 3 ไม่ได้เลือก Rest ทุกครั้งจากการโหวตแบบเสมอ จึงปรับ preview ให้ผู้เล่นจำลองและ bot เลือก Rest ครั้งแรกที่มีตัวเลือก เพื่อให้เก็บภาพหน้าพักได้แน่นอน
- ภาพหลักทั้ง 4 ชุดอยู่ใน [`docs/screenshots/2026-10-01-a11y/`](../screenshots/2026-10-01-a11y/)
- ชุดทดสอบ: `tests/client/test_accessibility_baseline.gd` ผ่าน 12/12; full suite ผ่าน 440/440
- `tools/ci/web_smoke.mjs` ผ่านด้วย Playwright Chromium 141.0.7390.37 ทั้ง browser host + PC join และ PC host + browser join

## Issue #44 — Keyboard และ Accessibility

| เกณฑ์ | ผล | หลักฐาน / ข้อสังเกต |
| --- | --- | --- |
| ปุ่มหลักของ Battle, Merchant และ Rest ใช้ผ่านคีย์บอร์ดได้ | ⚠️ ผ่านบางส่วน | preview ขับการต่อสู้ โหวต และ Ready ด้วยคีย์บอร์ด; ปุ่มหลักในหน้าจอแสดงคำสั่งไว้ชัดเจน ยังไม่ได้ไล่ทดสอบทุกปุ่มและทุกลำดับ Tab ด้วยมือ |
| ลำดับ focus และสถานะ focus มองเห็นและคาดเดาได้ | ⚠️ ผ่านบางส่วน | ภาพแสดงขอบ focus สีทองบนปุ่ม Fight/Ready และ tab ที่เลือก; ไม่ได้ตรวจลำดับ Tab/ลูกศรครบทุก control |
| ข้อมูลไอเท็ม สถานะ และ action สำคัญไม่พึ่ง tooltip อย่างเดียว | ✅ ผ่าน | accessibility tests ตรวจคำสั่งซื้อ, สถานะวัตถุดิบ, turn status และจุดอ่อนศัตรูเป็นข้อความ |
| Reduced motion ลด animation โดยไม่ซ่อนการเปลี่ยนสถานะ | ✅ ผ่าน | ภาพใน `reduced-motion/`; test ยืนยัน HP คงค่าเดิมจน hit feedback แล้วเปลี่ยนทันทีโดยไม่ tween |
| ตัวอักษรใหญ่ไม่ซ่อน control สำคัญใน viewport หลัก | ⚠️ ผ่านบางส่วน | 1280×720 และ 1920×1080 เห็นปุ่มต่อสู้/ซื้อ/Ready; ที่ 1.45× หน้า camp ต้องเลื่อนแนวนอนเพื่อเห็นคอลัมน์ Equipment ครบ |
| เก็บหลักฐานจาก UI preview | ✅ ผ่าน | มีภาพ Battle, Merchant และ Rest ทั้ง 1280×720, 1920×1080, 1.45× และ reduced motion |

## Issue #45 — Responsive และ Browser

| เกณฑ์ | ผล | หลักฐาน / ข้อสังเกต |
| --- | --- | --- |
| Battle, Merchant และ Rest ที่ 1280×720 | ✅ ผ่าน | `720/04_combat_turn.png`, `720/08_merchant.png`, `720/10_rest.png` |
| Battle, Merchant และ Rest ที่ 1920×1080 | ✅ ผ่าน | `1080/04_combat_turn.png`, `1080/08_merchant.png`, `1080/10_rest.png` |
| ไม่มีข้อความ ตัวเลข badge หรือ control สำคัญทับ/ถูกตัดที่ความละเอียดข้างต้น | ✅ ผ่านที่ 1280×720 และ 1920×1080 | ปุ่มซื้อและ Ready อยู่ในกรอบ; ที่ 1.45× เนื้อหา camp กว้างกว่า viewportและต้องเลื่อนแนวนอน โดยเฉพาะ Equipment — บันทึกเป็นข้อจำกัดที่ยังเหลือ |
| ตรวจ browser ที่รองรับและบันทึกความต่างราย browser | ⚠️ ผ่านบางส่วน | Chromium 141 ผ่าน cross-platform smoke; ยังไม่ได้ตรวจ Chrome, Edge, Firefox และ Safari แบบ desktop จริงทีละ browser |
| รักษา keyboard และ reduced-motion behavior | ⚠️ ผ่านบางส่วน | test และ reduced-motion preview ผ่าน; การไล่ keyboard focus ทุก control ยังไม่ครบตาม #44 |
| มีภาพหรือหลักฐานทำซ้ำได้ | ✅ ผ่าน | ภาพจาก Godot UI preview และคำสั่งอยู่ในหัวข้อวิธีตรวจ |

## ข้อที่ยังไม่ผ่านครบ

1. ตรวจ Tab/ลูกศรและการเข้าถึง action ทุกปุ่มใน Battle, Merchant และ Rest ด้วยมือให้ครบตาม #44
2. หน้า Merchant/Rest ที่ 1.45× ต้องเลื่อนแนวนอนเพื่อเห็น Equipment ครบ; ตรวจภาพใน `x145/`
3. ตรวจ Chrome, Edge, Firefox และ Safari บน desktop จริง; Chromium smoke ไม่ได้แทนการตรวจภาพและ interaction ของ browser เหล่านั้น

## ผล Web smoke

โฟลเดอร์นี้ไม่มี `package.json` หรือ `package-lock.json`; `npm ci` จึงหยุดด้วย `EUSAGE` ว่าไม่มี lockfile. ติดตั้ง Playwright 1.56.1 ชั่วคราวใน workspace, สร้าง Web export แล้วรัน `tools/ci/web_smoke.mjs` ผ่านทั้งสองทิศทาง. การติดตั้ง Playwright และ browser binaries อยู่ใน `build/`/`node_modules/` ระหว่างตรวจ; เอาแพ็กเกจ Node ออกหลังตรวจแล้ว.

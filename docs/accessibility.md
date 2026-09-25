# Accessibility และ UI/UX checklist (issue #17)

ผลตรวจล่าสุดของทุกหน้าจอ บน **PC** (Linux build ของ client ผ่าน Xvfb + `tools/ui_preview.gd`)
และ **browser** (web build ใน Chromium 141 ผ่าน `tools/web_smoke.mjs`)

- ✅ ผ่าน · ⚠️ ผ่านบางส่วน/มีข้อสังเกต · ⏳ ยังไม่ได้ตรวจ (ต้องตรวจด้วยมือบนเครื่องจริงใน #19)

## ตัวเลือกของผู้เล่น (Settings, F2)

| ตัวเลือก | รายละเอียด | จำค่าไว้ในเครื่อง |
| --- | --- | --- |
| ขนาดตัวหนังสือ | Small 0.85×, Normal 1.0×, Large 1.2×, Extra large 1.45× | ✅ `user://settings.cfg` (IndexedDB ใน browser) |
| Reduce motion | ปิด fade/slide ของหน้าจอและ panel, การกะพริบของการ์ดเมื่อโดนตี, ตัวเลข damage ที่ลอยขึ้น (ยังแสดงค้างไว้ 1.2 วินาทีแต่ไม่ขยับ) และ fade ของ banner | ✅ |
| Volume | 0–100% (0 = mute) | ✅ |

## สัญญาณเสียงและตัวชี้แนะทางภาพที่เทียบเท่า

| เหตุการณ์ | เสียง | ภาพ |
| --- | --- | --- |
| ถึงตาคุณ | turn | banner "Your turn!", กรอบทอง + ป้าย ACTING ที่การ์ด, หัวข้อ "YOUR TURN" |
| Action window ใกล้หมด (≤ 5 วินาที) | warn | ข้อความ "Ns left to act - hurry! Time out means Defend." |
| โหวตสรุปผล | vote | banner "Next: …", หน้า travel แสดงคะแนนและบอกว่ามีการสุ่มตัดเสมอหรือไม่ |
| โดนตี / heal | hit | ตัวเลขลอย (-9 / +30), การ์ดกะพริบ, บรรทัดใน log |
| Boss telegraph / เปลี่ยน phase | warn | banner + กล่อง WARNING ระบุชื่อท่าและเป้าหมาย, ป้าย PHASE n/3 |
| เลเวลอัป / ได้ Class / ชนะ | good | ตัวเลข LEVEL UP, banner, log |
| แพ้ | bad | banner "Defeat", หน้า DEFEAT |

## Checklist ต่อหน้าจอ

| หน้าจอ | Keyboard ล้วน | ไม่ใช้สีอย่างเดียว | ตัวหนังสือ 1.45× | PC | Browser |
| --- | --- | --- | --- | --- | --- |
| Title (ชื่อ, server, สร้าง/เข้าห้อง) | ✅ Tab/Enter, focus เริ่มที่ช่องชื่อหรือปุ่ม Create | ✅ error เป็นข้อความ | ✅ | ✅ | ✅ |
| Lobby (Room code, 5 slots) | ✅ focus เริ่มที่ Start (Host) | ✅ ป้าย PLAYER/AI, HOST, YOU | ✅ แถวปุ่มตัดบรรทัด | ✅ | ✅ |
| Path Voting | ✅ 1–3 | ✅ ป้ายชนิด (FIGHT/SHOP/…) + ชื่อชนิด, "Your vote" | ✅ การ์ดตัดบรรทัด + scroll | ✅ | ✅ |
| Travel (ผลโหวต) | – (อัตโนมัติ) | ✅ คะแนนเป็นตัวเลข | ✅ | ✅ | ⏳ |
| Combat / Challenge | ✅ A/S/D/I, 1–9, Esc | ✅ ตัวเลข HP บนแถบ, FRONT/BACK ROW, TARGET [n], DEFEATED, DOWN, DEFEND/GUARDED/WALL | ✅ | ✅ | ⏳ |
| Guardian Boss | ✅ | ✅ WARNING เป็นข้อความพร้อมชื่อเป้าหมาย | ✅ | ✅ | ⏳ |
| Class offer | ✅ Y/N | ✅ สถานะของแต่ละคนเป็นข้อความ | ✅ | ✅ | ⏳ |
| Merchant | ✅ 1–4, R | ✅ ปุ่มบอก "Need 28 Gold"/"Sold out" | ✅ | ✅ | ⏳ |
| Story Event + clue log | ✅ 1–2, Enter, C | ✅ | ✅ | ✅ | ⏳ |
| Rest camp (Crafting / Inventory / Gear) | ✅ 1–9 คราฟต์, R, Tab/Enter ที่ปุ่ม | ✅ OK/NEED + ตัวเลข x/y ของ material, ช่อง gear มีชื่อ, "Ready (x/y)" | ✅ ทุกคอลัมน์ scroll | ✅ | ⏳ |
| Treasure | – (อัตโนมัติ) | ✅ ตัวเลข Gold | ✅ | ✅ | ⏳ |
| Victory / Defeat + เริ่มใหม่ | ✅ focus ที่ Start a new Match | ✅ VICTORY/DEFEAT เป็นคำ | ✅ | ✅ | ⏳ |
| Settings | ✅ Esc ปิด | ✅ ตัวเลือกปัจจุบันมี ">" | ✅ | ✅ | ⏳ |

`tools/ui_preview.gd` เล่น Duo co-op ทั้ง Match (Title → Victory) โดยส่งแค่ keyboard event ของผู้เล่น
จึงยืนยันว่าทุกหน้าจอที่ผู้เล่นต้องตัดสินใจใช้ keyboard ได้ครบ

## Contrast

`tests/core/test_ui_contrast.gd` ตรวจทุกคู่สีตัวหนังสือ/พื้นหลังของ theme ตามเกณฑ์ **WCAG 2.1 AA (4.5:1)**
ค่าต่ำสุดตอนนี้คือ WARN บน panel ที่ถูก focus (4.62:1); ตัวเลข HP มีขอบดำจึงอ่านได้ทั้งบนแถบเขียวและแดง
ปุ่มที่ disabled มี contrast ≥ 3:1

## Motion ของ flow หลัก

| Flow | สิ่งที่มี |
| --- | --- |
| Lobby | fade-in ของหน้าจอ, toast เมื่อมีคนเข้า/ออก/เปลี่ยน Host |
| Voting | panel slide/fade เมื่อขึ้น Layer ใหม่, banner ผลโหวต |
| Combat | กะพริบการ์ดที่โดนตี/heal, ตัวเลขลอย, banner ถึงตาคุณ/telegraph/phase |
| Reward | banner Victory พร้อม EXP/Gold, Treasure, Story Clue, LEVEL UP ลอยจากการ์ด |

ทั้งหมดเป็น tween สั้น ๆ บน Control (ไม่มี shader หรือ particle) จึงไม่หนักสำหรับ browser build

## Tutorial hints

tip แสดงครั้งเดียวต่อผู้เล่น (จำไว้ใน settings) และปิดด้วย H: Path Voting, turn แรก (Attack/Skill/Defend/Item),
หลังได้ Class (Skill + cooldown), Class offer, Merchant และ Guardian Boss

## รายการที่ยังไม่ผ่านหรือยังไม่ได้ตรวจ

1. ⏳ ตรวจทุกหน้าจอใน browser จริงหลายตัว (Chrome, Edge, Firefox, Safari) และ Windows `.exe` บนเครื่องจริง — ทำใน checklist ของ #19
2. ⚠️ ระดับ motion "ที่ตกลงกับทีม" ยังต้องให้ทีมดูและยืนยัน (ตอนนี้เป็นระดับเบา)
3. ⚠️ ที่ตัวหนังสือ 1.45× พื้นที่ panel กลางเล็กลงและต้อง scroll บ้าง (focus เลื่อนตามให้อัตโนมัติ) layout ไม่พังแต่แน่น
4. ⏳ Screen reader (AccessKit ของ Godot) และ gamepad ยังไม่อยู่ในขอบเขตและไม่ได้ตรวจ
5. ⚠️ ข้อความในเกมเป็นภาษาอังกฤษอย่างเดียว (ADR-0007)

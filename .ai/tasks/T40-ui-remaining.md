# T40 — UI ที่ยังเหลือหลัง T39 (issues #87 #88 #44 #45 #83)
อ่านรายงาน `docs/review/2026-09-30-full-qa-report.md` และ issue comments. T37b (แปลไทย) ทำพร้อมกัน — อย่าแก้ข้อความ/th.po/`docs/` (ยกเว้นไฟล์หลักฐานใหม่ข้อ 5); ข้อความที่เพิ่มให้เป็นอังกฤษผ่าน `Tr.t()`.
## ปัญหาที่ยังเห็นในภาพ (`tools/dev/ui_preview.gd --seed=21 --speed=24`, 1280×720 และ ×1.45)
1. Combat: หัวข้อ "Turn N" ของ turn list ถูกปุ่ม `=` `?` ทับ/ตัด (U7).
2. ตัวเลขดาเมจ floating ซ้อนกัน (-30 CRIT ทับ -20 CRIT, -12/-17/-15 ซ้อนที่ศัตรู) → stagger/คิวเป็นลำดับ ไม่ซ้อน (U18); ตัวเลขต้องหายก่อนเข้า Summary (U17 — ใน Summary ยังเห็น -28/-16 ค้าง).
3. Summary: banner "Victory!" ซ้อนหัวข้อ VICTORY (U26) และหัวข้อบอก "Cave" แต่เนื้อหา "The Forest Falls Silent" (U23: ตรวจคำว่า Forest/Cave ให้ตรงภูมิภาค).
4. Path Voting: ที่ 1280×720 ตัวเลือก Alternatives ตกใต้ขอบ ต้องเห็นอย่างน้อยหัวข้อทางเลือกทุกอันโดยไม่ต้องเลื่อน (U31) — ย่อ header/คำอธิบาย/แถบเวลาให้กระชับ; ที่ ×1.45 ให้เลื่อนได้แต่ปุ่มโหวตเห็นชัด.
5. #88 S2: ลำดับ event (โจมตี ~0.3s → hit/flash/ตัวเลข → HP tween) ก่อนที่ HP เปลี่ยน; banner สั้นและไม่บล็อก. (T39 ทำ HP tween ล่าช้าแล้วบางส่วน — ต่อให้ครบ.)
6. #44/#45 หลักฐาน: ภาพ Rest camp (ใช้ seed ที่ได้ Rest — `.ai/checkpoint.md`/preview ระบุ seed 3), reduced-motion, Battle/Merchant/Rest ที่ 1280×720 + 1920×1080 + ×1.45; ใส่ภาพใน `docs/screenshots/2026-10-01-a11y/` และเขียน `docs/review/2026-10-01-responsive-a11y-evidence.md` เป็นภาษาไทย (checklist ตาม acceptance criteria ของ #44 และ #45, ระบุข้อที่ยังไม่ผ่านตรง ๆ). ถ้า `tools/ci/web_smoke.mjs` รันไม่ได้เพราะ playwright ไม่มี ให้ลอง `npm ci`/ติดตั้งตามที่ไฟล์ระบุ แล้วรายงานผล.
## Verify
`bash tools/run_tests.sh` ผ่านหมด; เพิ่ม test ที่ครอบข้อ 1-3 ได้; เปิด PNG ดูจริงก่อนอ้างว่าเสร็จ.
## Report
ตารางต่อข้อ: แก้อะไร / หลักฐาน / ข้อที่ยังเหลือ.

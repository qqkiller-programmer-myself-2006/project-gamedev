# T42 — แก้ merge conflict (origin/main เข้า branch PR #117)
สถานะ: `git merge origin/main` กำลังค้างอยู่ใน worktree นี้ (อย่ารัน merge ใหม่ อย่า rebase/abort/commit/push). ไฟล์ที่ยังเป็น `UU`: `git diff --name-only --diff-filter=U`.
## บริบท
- **ฝั่งเรา (HEAD)**: ภาษาไทย (`Tr.t(...)` ทุกข้อความที่ผู้เล่นเห็น, `i18n/th.po`), งาน UI T39/T40 (queue ตัวเลขดาเมจ, vote layout, turn header, Summary หัวข้อเดียว, merchant confirm, content cache, token persistence).
- **ฝั่ง main (origin/main)**: ทำซ้ำหลายอย่าง — #88 smoothness (ai/t41-smooth: token persistence, HP tween, sprite/content cache, dialogue visible_characters), #45 responsive (badge scale), camp tip height, accessibility baseline (#44).
## กฎการแก้
1. งานที่ทั้งสองฝั่งทำซ้ำกัน (smoothness/cache/token/tween/typewriter) → **ใช้ implementation ของ main** แล้วทิ้งของฝั่งเรา ถ้าไม่ขัดกัน; ห้ามมีโค้ดสองชุดทำสิ่งเดียวกัน (เช่น `_content` ซ้ำ, `_backdrop` ซ้ำ, สอง cache).
2. ข้อความที่ผู้เล่นเห็นต้องคงผ่าน `Tr.t(...)` ตามฝั่งเรา — ถ้า main เพิ่มข้อความใหม่ ให้ห่อ `Tr.t` และเพิ่มคำแปลไทยใน `i18n/th.po` + รัน `tools/i18n/extract_strings.gd` ให้ POT/PO สอดคล้อง (`check_po.gd` ต้อง exit 0).
3. พฤติกรรมของ T40 ที่ main ไม่มี (queue ตัวเลขดาเมจ ไม่ซ้อน, Summary หัวข้อเดียว/ล้าง floating text, vote พอดี 1280×720, turn header ไม่ถูกปุ่มทับ, merchant ยืนยันก่อนซื้อ) ต้องยังอยู่ ถ้าขัดกับของ main ให้ผสานให้ใช้ได้ทั้งคู่.
4. ไม่เหลือ marker `<<<<<<<`/`=======`/`>>>>>>>` ที่ใดในรีโป. ทดสอบเดิมที่ main เพิ่ม (เช่น test_accessibility_baseline, test_battle_view_data) ต้องผ่าน; ถ้า test ของเราและของ main ซ้ำ/ขัดกัน ให้รวมเป็นชุดเดียว.
5. ไม่ต้อง `git add`/commit (ผมจะทำเอง) แต่ลบ conflict marker ให้หมด.
## Verify
```
export GODOT='D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
grep -rn '^<<<<<<<\|^>>>>>>>' src tests tools i18n docs   # ต้องว่าง
"$GODOT" --headless --path . --import   # ไม่มี SCRIPT ERROR
bash tools/run_tests.sh   # ต้องผ่านหมด
"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=21 --speed=24   # เปิดภาพ Combat/Vote/Merchant/Summary ดู
```
## Report
ตารางต่อไฟล์: ใช้ฝั่งไหน/ผสานอย่างไร; test ทั้งหมด; ภาพที่ตรวจ; ข้อที่ยังเหลือ.

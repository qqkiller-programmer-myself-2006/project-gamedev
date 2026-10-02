# ตัวติดตาม Issue: GitHub

Issue และข้อกำหนดของรีโปนี้อยู่ใน GitHub Issues ของ
`qqkiller-programmer-myself-2006/project-gamedev` ใช้ `gh` CLI สำหรับทุกการดำเนินการ

## ข้อตกลง

- **สร้าง issue**: `gh issue create --title "..." --body "..."`
- **อ่าน issue**: `gh issue view <number> --comments`
- **แสดงรายการ issue**: `gh issue list --state open --json number,title,body,labels,comments`
- **แสดงความคิดเห็นใน issue**: `gh issue comment <number> --body "..."`
- **เพิ่ม / ลบ label**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **ปิด issue**: `gh issue close <number> --comment "..."`

อนุมานรีโปจาก `git remote -v`; `gh` จะตรวจให้อัตโนมัติเมื่อเรียกใช้ภายใน clone

## ใช้ Pull request เป็นช่องทางคัดแยก

**ใช้ PR เป็นช่องทางรับคำขอ: ไม่ใช้** Pull request จากภายนอกไม่ถือเป็นคิวคัดแยก issue เว้นแต่จะระบุไว้ในไฟล์นี้โดยตรง

## เมื่อ skill ระบุว่า “publish to the issue tracker”

ให้สร้าง GitHub issue

## เมื่อ skill ระบุว่า “fetch the relevant ticket”

เรียก `gh issue view <number> --comments`

## การนำทางงาน

แผนที่ `/wayfinder` คือ GitHub issue เดียวที่ติด label `wayfinder:map` งานย่อยแสดงเป็น sub-issue ที่เชื่อมโยงกันเมื่อระบบรองรับ หากไม่รองรับ ให้เพิ่ม task list ในเนื้อหาแผนที่ และใส่ `Part of #<map>` ไว้ด้านบนของ issue ย่อยแต่ละรายการ

ใช้ label `wayfinder:<type>` สำหรับ `research`, `prototype`, `grilling` และ `task` การพึ่งพา issue แบบ native ของ GitHub เป็นตัวแทนการบล็อกอย่างเป็นทางการ หากใช้ไม่ได้ ให้ใส่บรรทัด `Blocked by: #<n>` ไว้ด้านบนของเนื้อหา issue ย่อย

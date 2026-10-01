# content/
ข้อมูล Forest และ Story mode ที่ runtime โหลดอยู่ในไฟล์ JSON.
`forest.json` เก็บ encounter, rules, classes และ rewards; `story_mode.json` เก็บเนื้อเรื่อง.
`src/shared/forest_content.gd` อ่านข้อมูลเหล่านี้โดยไม่ย้ายกติกาไปไว้ใน UI.
ผู้ออกแบบเกมแก้ content และตรวจ balance/test ที่อ้างอิงข้อมูลนั้น.

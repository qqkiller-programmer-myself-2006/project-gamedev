---
status: accepted
---

# ข้อความในเกมใช้ภาษาอังกฤษ และเก็บไว้ในข้อมูล content ไม่ hard-code ใน logic

vertical slice ใช้ข้อความในเกมภาษาอังกฤษทั้งหมด (ชื่อ Class, Skill, Item, ศัตรู, คำใบ้เส้นทาง, Story Event, Story Clue) เก็บใน `content/forest.json` และข้อความ UI ของ client เก็บรวมไว้ที่ไฟล์เดียวในฝั่ง client เพราะคำศัพท์หลักของเกมใน PRD และ `CONTEXT.md` เป็นภาษาอังกฤษอยู่แล้ว, font เริ่มต้นของ Godot ไม่มี glyph ภาษาไทยและ browser export ไม่มี system font fallback จึงต้อง bundle font ไทยเพิ่มถ้าจะใช้ภาษาไทย, และการรวมข้อความไว้ที่ข้อมูลทำให้เพิ่มภาษาไทยภายหลังได้โดยแปลข้อมูลโดยไม่ต้องแก้ game logic

## Consequences

- เพิ่มภาษาไทยภายหลัง: bundle font ที่รองรับภาษาไทย (เช่น Noto Sans Thai, OFL) และใช้ `TranslationServer` หรือไฟล์ content ต่อภาษา
- server ส่งข้อความ content ไปใน snapshot/event ตามภาษาเดียว; การเลือกภาษาต่อผู้เล่นยังไม่อยู่ใน slice

---
status: accepted
---

# ใช้ Party 5 คนและเติม slot ที่ขาดด้วย AI

ทุก Match จะมี Party 5 ตัวละครคงที่ ผู้เล่นจริงหนึ่งคนควบคุมตัวละครหนึ่งตัว และ slot ที่ไม่มีผู้เล่นจะถูกควบคุมโดย AI replacement ตาม behavior preset ของ Class; จึงรองรับตั้งแต่ Single-player ถึง 5 ผู้เล่นโดยไม่เปลี่ยนโครงสร้าง combat หรือ composition ของ Party.

## Consequences

- Duo co-op มีผู้เล่นจริง 2 คนและ AI 3 ตัว
- UI ต้องแสดง owner ของแต่ละ slot และแยกสถานะ player-controlled กับ AI-controlled ให้ชัดเจน
- ต้องออกแบบ AI preset ขั้นต่ำสำหรับ Swordsman, Archer, Mage และ Guardian

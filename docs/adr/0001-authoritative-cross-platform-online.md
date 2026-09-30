---
status: accepted
---

# ใช้เซิร์ฟเวอร์ผู้ตัดสินผลร่วมกันระหว่าง PC และ browser client

เกมจะใช้ Godot headless authoritative server เป็นผู้ตัดสินการต่อสู้, การโหวตเส้นทาง, รางวัล และสถานะแมตช์ เพื่อให้ PC `.exe` และ browser เล่นใน session เดียวกันได้ โดยลดการไม่ตรงกันของสถานะและความแตกต่างของ logic ระหว่าง client; vertical slice ใช้ staging server เฉพาะ, session นิรนาม และ room code โดยยังไม่มี account หรือ matchmaking

## ตัวเลือกที่พิจารณา

- ให้ client เป็นผู้ตัดสิน หรือใช้ peer-host: ปฏิเสธเพราะเสี่ยงที่สถานะไม่ตรงกันและการโกง เมื่อมี PC/browser หลายชนิด
- แยก logic เกมระหว่าง PC กับ browser: ปฏิเสธเพราะเพิ่มภาระการดูแลและทำให้ผลลัพธ์ไม่สอดคล้องกัน

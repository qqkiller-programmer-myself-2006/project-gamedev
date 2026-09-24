---
status: accepted
---

# ใช้ authoritative server ร่วมกันระหว่าง PC และ browser client

เกมจะใช้ Godot headless authoritative server เป็นผู้ตัดสิน combat, Path Voting, reward และ Match state เพื่อให้ PC `.exe` และ browser เล่นใน session เดียวกันได้โดยลด desync และความแตกต่างของ logic ระหว่าง client; vertical slice ใช้ dedicated staging server, anonymous session และ room code โดยยังไม่ทำ account หรือ matchmaking.

## Considered Options

- Client-authoritative หรือ peer-host: ปฏิเสธเพราะเสี่ยง desync และโกงเมื่อมี PC/browser หลายชนิด
- แยก game logic ระหว่าง PC กับ browser: ปฏิเสธเพราะเพิ่มภาระการดูแลและทำให้ผลลัพธ์ไม่สอดคล้องกัน

# src/net/
protocol, client transport และ server transport สำหรับ online play อยู่ที่นี่.
`net_protocol.gd` กำหนดรูปแบบข้อความ; connection scripts เชื่อมกับ Match interface.
แก้ transport โดยรักษา JSON contract และตรวจ `tests/net/`.
ผู้ดูแลระบบ network เป็นผู้แก้ไฟล์ในโฟลเดอร์นี้.

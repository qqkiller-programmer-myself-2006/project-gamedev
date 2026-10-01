# src/client/
โค้ดหน้าจอฝั่งผู้เล่นและตัวเชื่อม UI อยู่ที่นี่.
`title/`, `lobby/`, `match/`, `story/` แบ่งตามหน้าจอและ phase; `ui/` เก็บส่วนใช้ร่วมกัน.
ข้อมูลเกมมาจาก client state และ event ของ Match ไม่ตัดสินกติกา authoritative.
ผู้พัฒนา UI แก้หน้าจอในโฟลเดอร์ย่อยที่เกี่ยวข้องและดูแนวทางใน `docs/design/ui-style.md`.

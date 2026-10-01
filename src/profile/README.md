# src/profile/
อินเทอร์เฟซและ adapter สำหรับโหลด/บันทึก profile อยู่ที่นี่.
มี memory, file และ D1 store พร้อม HTTP sender สำหรับการบันทึกแบบ asynchronous.
เก็บการเข้าถึง storage ไว้หลัง `ProfileStore` และตรวจด้วย `tests/profile/`.
ผู้ดูแล persistence แก้ implementation ในโฟลเดอร์นี้.

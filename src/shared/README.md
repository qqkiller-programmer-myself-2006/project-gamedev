# src/shared/
ระบบพื้นฐานที่ client และ server ใช้ร่วมกันอยู่ที่นี่.
มี deterministic RNG, clock abstraction และตัวโหลด Forest content.
ตรรกะ gameplay ควรรับ RNG/clock จากภายนอกเพื่อให้ทดสอบซ้ำได้.
ผู้ดูแล shared runtime แก้ไฟล์ในโฟลเดอร์นี้และตรวจ `tests/shared/`.

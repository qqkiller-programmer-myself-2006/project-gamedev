# src/
โค้ด runtime หลักของเกม Godot แยกตามหน้าที่และขอบเขตของระบบ.
`app/` เริ่มโปรเจกต์ ส่วน `client/` แสดงผล และ `server/` เปิด authoritative server.
กติกาอยู่ใน `match/`; transport อยู่ใน `net/`; profile อยู่ใน `profile/`.
`shared/` เก็บ RNG, clock และตัวโหลด content ที่ใช้ร่วมกัน.
ผู้ดูแลระบบแก้โมดูลตรงขอบเขตของตน และรักษา `.uid` คู่กับทุกสคริปต์ที่ย้าย.

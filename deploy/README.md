# deploy/
ไฟล์ประกอบ staging server, reverse proxy และการเตรียม server bundle อยู่ที่นี่.
`prepare.sh`, `Dockerfile.server` และ `docker-compose.yml` ใช้สร้าง/เปิดชุด deploy.
`profile-worker/` เป็นบริการแยกพร้อม schema และ test ของตนเอง.
ผู้ดูแล deployment แก้ไฟล์ที่นี่และทำตาม `docs/guides/staging.md`.

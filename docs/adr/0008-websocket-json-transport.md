---
status: accepted
---

# ใช้ WebSocket + ข้อความ JSON เป็น transport ระหว่าง client กับ authoritative server

client ทุกชนิด (PC และ browser) คุยกับ headless server ผ่าน `WebSocketPeer` ของ Godot ด้วยข้อความ JSON หนึ่งก้อนต่อหนึ่ง text frame (`src/net/net_protocol.gd`): client ส่ง command ของ Match interface, server ตอบผลของ command และ push event พร้อม snapshot ของ session นั้น เพราะ browser export ของ Godot ใช้ได้แค่ WebSocket และ WebRTC (ไม่มี UDP/ENet), WebSocket ใช้ได้เหมือนกันทั้ง desktop และ web จาก codebase เดียว และการส่ง snapshot เต็มทุกครั้งที่มีการเปลี่ยนแปลงทำให้ transport adapter (`WsServerTransport`) แปลข้อความไปกลับได้โดยไม่มี game logic เลย

## Considered Options

- **ENet / high-level multiplayer (UDP)**: ใช้ไม่ได้ใน browser export
- **`WebSocketMultiplayerPeer` + RPC**: ผูก logic เข้ากับ node path ของ scene tree และทำให้ทดสอบผ่าน Match interface ได้ยากขึ้น
- **WebRTC**: ต้องมี signalling server และ NAT traversal เพิ่ม เกินความจำเป็นของ server-authoritative แบบนี้

## Consequences

- browser ที่เปิดเกมจากหน้า HTTPS ต้องต่อ `wss://` จึงต้องมี TLS ที่ server (เช่น reverse proxy อย่าง Caddy หรือ nginx หน้า server)
- snapshot เป็น JSON เต็มก้อน (ไม่ใช่ delta) ขนาดไม่กี่ KB ต่อผู้เล่นต่อการเปลี่ยนแปลง พอสำหรับห้องละ 5 คน ถ้าต้องรองรับห้องจำนวนมากค่อยเปลี่ยนเป็น delta
- ตัวเลขทุกตัวใน JSON กลายเป็น float ระหว่างทาง server จึงแปลงเลขจำนวนเต็มกลับก่อนส่งเข้า Match interface

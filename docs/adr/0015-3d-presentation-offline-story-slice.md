---
status: accepted
---

# 3D presentation vertical slice สำหรับ Story mode (offline เล่นคนเดียว)

เจ้าของงานตัดสิน (2026-10-02): โฟกัสที่ **Story mode แบบ offline เล่นคนเดียว** (ADR-0014) แล้วยกระดับ *การนำเสนอ* เป็น 3D
Multiplayer/online ยังอยู่ครบแต่ **อยู่นอกขอบเขต slice นี้** ห้ามแก้ให้พัง และไม่ต้องทำ 3D ให้มัน

## กติกา

- **MatchServer ไม่เปลี่ยน** (ADR-0001/0014) กติกา combat, save, content, network คงเดิม งาน 3D อยู่ฝั่ง client เท่านั้น
- **Story mode ไม่ใช้ server** (`LocalConnection` + `StoryLauncher`) slice นี้ต่อยอดจากเส้นทางนั้น
- **PresentationAdapter** (`src/client/presentation/`): ฟังก์ชันล้วน (ไม่มี Node) แปลง match view + event → *presentation state / cue* เป็น Dictionary
  ทดสอบ headless ได้ Home3D, Battle3D และ Cutscene อ่านจาก adapter ไม่อ่าน snapshot ดิบ
- **เปิดด้วย flag `--3d`** (และตัวเลือกใน Settings ภายหลัง) 2D เดิมคือ fallback และ default จนกว่า QA ผ่าน
- **Home3D**: ผู้เล่นเดิน WASD ไปสถานี Story / Battle / Party / Class / Shop / Settings; สถานี Story เรียก `StoryLauncher` เดิม;
  สถานีอื่นเปิดหน้าจอเดิมของเกม (ไม่เขียนระบบใหม่) ใช้ spec ของ `ai/t50-open-world-hub` (ฮับ 2D) เป็นรายชื่อสถานี/ข้อกำหนดฐาน
- **Battle3D**: ฝัง `SubViewport` 3D ใน `BattleView` แทนเฉพาะ "เวที" (`BattleToken` + `BattleBackdrop`) HUD และการส่ง command ยังเป็น Control เดิม
  ใช้ศัพท์เดิม: Strike, Skill, Focus, Item, Guard (ห้ามเปลี่ยน — ดู `CONTEXT.md`)
- **Cutscene** (`src/client/cutscene/`, `content/cutscenes/*.json`): วิดีโอ **Ogg Theora `.ogv`** (ข้อจำกัดของ Godot รวม Web) เป็นกราฟ
  `node → {clip, choices[], next}` คลิปสั้นแยกตาม branch ไม่ seek ในไฟล์ยาว **Cutscene ≠ Story Event** (ตาม `CONTEXT.md`):
  Cutscene เสียบเข้า `StoryDirector` เป็นชนิด presentation ใหม่ และส่งผลกลับเป็น flag เท่านั้น
- **AI asset**: ใช้เป็น concept, portrait, texture, UI, คลิปสั้น เท่านั้น ห้ามใช้ตัดสิน logic ทุกไฟล์ต้องมี entry ใน `assets/MANIFEST.3d.json`
  (prompt, tool, seed/วันที่, ที่มา) เพื่อทำซ้ำได้ ของจริงแทน placeholder ผ่าน manifest ไม่ต้องแก้โค้ด
- Placeholder ก่อน: โมเดลบล็อกจาก primitive mesh, คลิปสีล้วน — slice ต้องเล่นได้ก่อนมี asset จริง
- Renderer ยังเป็น `gl_compatibility` (Web): ไม่มี shadow/SSAO/glow, จำกัด draw call, มี quality ต่ำ

## Considered Options

- **เขียนเกมใหม่เป็น 3D เต็มตัว**: เกินเวลาและทำลาย test 391+ ตัว — ไม่เลือก
- **วิดีโอ mp4/webm**: Godot ไม่เล่นโดยตรง — ไม่เลือก; เก็บ mp4 ต้นฉบับใน `art_source/` แปลงเป็น `.ogv` ด้วยสคริปต์
- **Cutscene เป็น Story Event**: ปนกับกติกาโหวต/clue ของ server — ไม่เลือก

## Consequences

- เพิ่มศัพท์ใน `CONTEXT.md`: **Home hub**, **Station**, **Cutscene** (หลัง slice เสร็จ)
- ต้องมี test headless ใหม่สำหรับ adapter/router และ smoke test ที่ผ่านเมื่อ `--3d` ปิด
- `ai/t50-open-world-hub` ไม่ถูก merge (ถูกแทนด้วย Home3D); ถ้า 3D ไม่ทัน ใช้เป็น fallback ได้

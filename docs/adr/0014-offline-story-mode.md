---
status: accepted
---

# Story mode: เล่นคนเดียวแบบออฟไลน์ คุมทั้ง 5 ตัว มีเนื้อเรื่องและ Save (Multiplayer คงเดิม)

เจ้าของงานตัดสิน (2026-09-29) ให้เพิ่ม **Story mode** สำหรับเล่นคนเดียว: เล่นได้โดยไม่ต้องมี server, มีฉากเปิดเรื่อง บทสนทนาระหว่างทาง และฉากจบ,
Save/Continue ได้ และผู้เล่นคุมตัวละครครบทั้ง 5 ตัวเอง ส่วน Multiplayer (Single-player/Duo co-op ผ่าน server เดิม) ยังอยู่ครบ

## กติกา

- **Local transport**: Story mode รัน `MatchServer` ใน process ของ client ผ่าน `LocalConnection` ที่มี API เดียวกับ `ServerConnection`
  (ADR-0008 แค่เปลี่ยนตัวขนส่ง) ดังนั้น game logic ยังผ่าน Match interface เดียวกับ Multiplayer (ADR-0001 ยังใช้ได้ในความหมายว่า
  client UI ไม่ตัดสินผลเอง) และเล่นได้ทั้ง PC และ browser
- **Story room**: Room ที่สร้างด้วย `story: true` มีผู้เล่นคนเดียวและ session นั้นคุมทุก slot (ไม่มี AI replacement), ไม่มี
  Action window timeout, Path Voting มีผู้โหวตคนเดียว และ Ready check ผ่านทันทีเมื่อกด Ready
- **Story balance**: ศัตรูทั่วไปยังได้ Energy +1 ตั้งแต่ turn แรกตาม ADR-0012 แต่ cap ที่ 1
  (`rules.story_enemy_energy_max`) เพื่อให้ win rate ของโหมดที่ผู้เล่นคนเดียวคุมทั้ง 5 ตัวอยู่ในช่วง 70–92%; Multiplayer
  ใช้ `rules.enemy_energy_max` ตามเดิม และยังใช้ท่าพิเศษที่ต้องการ 2–3 Energy
- **Loadout**: ก่อนเริ่ม ผู้เล่นเลือก Class ให้ตัวละครทั้ง 5 ตัว (Race/Boons ใช้ของ profile ผู้เล่นกับตัวที่เลือกเป็นตัวหลัก, ตัวอื่นใช้ค่าเริ่มต้น)
- **เนื้อเรื่อง** (ข้อมูลใน `content/story_mode.json`): prologue, การ์ดบท (Chapter) ทุก Layer, บทสนทนาตาม trigger
  (หลัง Combat แรก, หลังได้ Class, ก่อน Guardian Boss, เมื่อพบ Story Clue) และ epilogue ชนะ/แพ้ ใช้ตัวละครใน `CONTEXT.md`
  (Arin, Bram, Cora, Dain, Wren) และเรื่องการเดินทางของพ่อ
- **Save**: บันทึกอัตโนมัติที่ต้นทุก Layer ลง `user://story_save.json` (seed, Layer, สถานะ Party ทั้งหมด, คลัง, Gold, Story Clue, เส้นทาง)
  ปุ่ม **Continue** เริ่มจาก Layer ที่บันทึกไว้; ชนะหรือแพ้แล้วลบ save
- หน้าแรกมี **Story** (Continue/New) และ **Multiplayer** (Create/Join เดิม)

## Considered Options

- **เก็บ Single-player ผ่าน server เดิม**: ไม่ต้องทำ local transport แต่เล่นออฟไลน์ไม่ได้ ซึ่งเจ้าของงานต้องการ
- **Save ทุกคำสั่ง (replay log)**: กลับมาเล่นตรงจุดเดิมได้ละเอียดกว่า แต่ต้อง replay เวลาและลำดับให้ตรง; save ต้น Layer ง่ายและพอสำหรับ slice

## Consequences

- `CONTEXT.md` เพิ่ม Story mode, Story room, Chapter; Single-player ยังหมายถึงโหมดผ่าน server เดิม
- Balance ของ Story mode ต่างจาก Single-player (คน 1 คนตัดสินใจทั้ง 5 ตัว, ไม่มีหมดเวลา) — วัดแยกด้วย `simulate.gd --story`

# BEYOND THE WORLD'S END

คำศัพท์และขอบเขตที่ใช้ร่วมกันสำหรับ vertical slice ของเกม BEYOND THE WORLD'S END ซึ่งเป็น online fantasy turn-based RPG แบบ co-op

## Game structure

**Match**:
หนึ่ง session ที่ผู้เล่นรวมทีม เดินทางผ่าน Forest และจบด้วย Guardian Boss โดยมีตัวละครใน Party 5 คน
_Avoid_: round, lobby (เมื่อหมายถึง session ที่กำลังเล่น)

**Party**:
กลุ่มตัวละคร 5 คนที่อยู่ใน Match เดียวกันเสมอ ไม่ว่าผู้เล่นจริงจะมีจำนวนเท่าใด
_Avoid_: team (เมื่อหมายถึงกลุ่มตัวละครในเกม)

**Player slot**:
ตำแหน่งควบคุมตัวละครหนึ่งตัวโดยผู้เล่นหนึ่งคน หากไม่มีผู้เล่นครอบครอง slot นั้น ระบบจะใช้ AI แทน
_Avoid_: account slot, character slot

**Forest vertical slice**:
ขอบเขต production-quality ที่เล่นจบได้ของ Forest Region ประกอบด้วย 5 Layers, Encounter ที่กำหนด และ Guardian Boss หนึ่งตัว
_Avoid_: demo, mockup, full prototype

**Layer**:
ช่วงหนึ่งของการเดินทางใน Forest ที่นำไปสู่ Encounter หรือการเลือกเส้นทางครั้งถัดไป
_Avoid_: level (เมื่อหมายถึงช่วงการเดินทาง)

## Online play

**Single-player**:
Match ที่มีผู้เล่นจริงหนึ่งคน และ slot ที่เหลือของ Party ใช้ AI
_Avoid_: offline mode (server ยังคงเป็น authoritative)

**Duo co-op**:
Match ที่มีผู้เล่นจริงสองคน โดยผู้เล่นแต่ละคนควบคุมตัวละครหนึ่งตัว และอีกสาม slot ใช้ AI
_Avoid_: two-player local, split-screen

**Authoritative server**:
server ที่เป็นผู้ตัดสินผลของ combat, voting, reward และ state ของ Match; client มีหน้าที่ส่งคำสั่งและแสดงผล
_Avoid_: client-authoritative, peer host

**Room code**:
รหัสยาว 6 ตัวอักษรที่ Host ใช้สร้างห้อง และผู้เล่นอื่นใช้เข้าร่วม Match; ป้อนแบบไม่สนตัวพิมพ์เล็กใหญ่ และไม่มีตัวอักษรที่สับสนง่าย (0/O, 1/I/L)
_Avoid_: invite link, lobby ID

**Host**:
ผู้เล่นที่สร้างห้อง และเป็นคนเดียวที่เริ่ม Match ได้; ถ้า Host ออกจากห้อง สิทธิ์ Host ส่งต่อให้ผู้เล่นจริงใน slot ลำดับต่ำสุดที่เหลืออยู่
_Avoid_: owner, admin, leader

**Match interface**:
seam เดียวของ game logic (`MatchServer`): รับ command จาก session แล้วคืน event และ snapshot โดยรับ seed, clock และข้อมูล content ของ Forest จากภายนอก; test และ transport adapter คุยกับเกมผ่าน interface นี้เท่านั้น
_Avoid_: game API, backend

## Characters and progression

**Classless**:
สถานะเริ่มต้นของตัวละครที่ยังไม่มีความสามารถเฉพาะ Class
_Avoid_: default class, novice class

**Class Encounter**:
Encounter ที่เปิดโอกาสให้ตัวละครค้นพบหรือยืนยันการเปลี่ยนไปใช้ Class: เริ่มด้วย Challenge (การประลองแบบไม่ถึงตายกับผู้ฝึกสอนภายในจำนวน round ที่กำหนด) ถ้าผ่าน ตัวละคร Classless ทุกตัวเลือกรับหรือไม่รับ Class นั้นได้
_Avoid_: class menu, class selection screen

**Challenge**:
การประลองใน Class Encounter ที่ต้องเอาชนะผู้ฝึกสอนให้ได้ภายใน round ที่กำหนด; ไม่มีใครล้ม ไม่มี reward และ HP กลับเป็นเหมือนก่อนประลอง
_Avoid_: trial boss, mini-boss

**Skill**:
action เฉพาะ Class ที่ถูกจำกัดด้วย cooldown นับเป็น turn ของตัวละครนั้นเอง (ADR-0005); ตัวละคร Classless ไม่มี Skill
_Avoid_: ability, spell (เมื่อหมายถึง action ในระบบ)

**Tier 1 Class**:
Class ระดับแรกของ Forest vertical slice ได้แก่ Swordsman, Archer, Mage และ Guardian
_Avoid_: starter class (เพราะผู้เล่นไม่ได้เริ่มเกมด้วย Class)

**AI replacement**:
พฤติกรรมควบคุม slot ที่ไม่มีผู้เล่นจริง โดยใช้ behavior preset ตาม Class ของตัวละคร
_Avoid_: bot player, NPC player

## Combat and decisions

**Action window**:
ช่วงเวลา 15 วินาทีที่ตัวละครต้องเลือก action ในแต่ละ turn หากหมดเวลาจะใช้ Defend อัตโนมัติ
_Avoid_: input phase, command phase

**Path Voting**:
การที่ผู้เล่นจริงโหวตเลือกเส้นทางถัดไปหลัง Encounter; AI ไม่มีสิทธิ์โหวต และกรณีเสมอให้สุ่มจากตัวเลือกที่คะแนนเท่ากัน
_Avoid_: route selection (เมื่อหมายถึงกระบวนการโหวต)

**Encounter**:
เหตุการณ์หนึ่งระหว่างการเดินทาง ซึ่งใน vertical slice อาจเป็น Combat, Merchant, Rest, Treasure, Story Event หรือ Class Encounter
_Avoid_: quest node, random event (เว้นแต่กำลังพูดถึง implementation randomness)

**Guardian Boss**:
ศัตรูหลักที่ปิดท้าย Forest vertical slice และเป็นเกณฑ์จบการเดินทางของ Match
_Avoid_: final boss (เกมเต็มยังมี Guardian หลาย Region)

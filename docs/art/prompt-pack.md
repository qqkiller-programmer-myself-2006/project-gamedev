# Prompt pack — ภาพตัวละคร, โมชั่น, เอฟเฟกต์, พื้นหลัง, วิดีโอ cutscene

ชุดคำสั่ง (prompt) สำหรับสร้าง asset ของ Story mode ใหม่ ตามดีไซน์ใน [character-designs-draft.md](../design/character-designs-draft.md) และบทใน [story-script-draft.md](../design/story-script-draft.md), [story-script-routes.md](../design/story-script-routes.md)
สถานะ: **ร่างที่ 1** แทนส่วนตัวละครเดิม (Arin/Bram/Cora/Dain/Wren) ใน `docs/art/style-guide.md` ซึ่งต้องอัปเดตตาม

prompt เขียนเป็นภาษาอังกฤษ (โมเดลภาพ/วิดีโอส่วนใหญ่เข้าใจดีกว่า) คำอธิบายเป็นไทย ไม่ผูกกับเครื่องมือเจาะจง ใช้กับเครื่องมือใดก็ได้ที่คุณมี

## กฎก่อนเริ่ม
1. **ห้ามใส่ชื่อตัวละครหรือศิลปินที่มีลิขสิทธิ์ใน prompt** (เช่น อายาโนะโคจิ) ให้ใช้คำบรรยายรูปลักษณ์แทน ภาพต้องเป็นดีไซน์ต้นฉบับ
2. **ทำ character sheet ก่อนทุกอย่าง** แล้วใช้ภาพอ้างอิง (reference / image-to-image / character reference) ในงานถัดไปเพื่อให้หน้าตาสม่ำเสมอ
3. **ทุกไฟล์ต้องมีรายการใน `assets/MANIFEST.3d.json`** (prompt, เครื่องมือ, seed, วันที่, ใบอนุญาต) ใช้ `python tools/art/check_manifest.py` ตรวจ
4. ตัวละครทุกตัวเป็นผู้ใหญ่ 20–25 ปี สัดส่วนสมจริงแบบอนิเมะ แต่งกายมิดชิด ไม่ใช้ท่าทางยั่วยุ
5. ตรวจเงื่อนไขการใช้เชิงพาณิชย์ของเครื่องมือก่อนใช้ผลงานในเกมที่เผยแพร่

## บล็อกสไตล์กลาง (ต่อท้ายทุก prompt ภาพ)
```
STYLE: modern anime RPG key visual, clean confident line art, cel shading with soft gradients,
dark fantasy mood, strict palette of black, crimson red and white with one accent color per character,
high contrast, cinematic lighting, detailed but readable silhouettes, handsome and beautiful anime lead-character faces
```
```
NEGATIVE: realistic photo, 3d render look, extra fingers, deformed hands, text, watermark, logo, blurry, low quality,
inconsistent face, child, childlike, nsfw, revealing clothing, copyrighted character likeness
```

## ส่วนที่ 1 — Character sheet (ภาพตัวละคร)

ใช้แม่แบบนี้ต่อตัวละคร แล้วเปลี่ยน `[DESCRIPTION]`:
```
character design reference sheet, same character shown in front view, side view and back view on a plain light grey background,
full body, neutral A-pose, [DESCRIPTION], plus a row of 5 face expressions (neutral, smile, angry, sad, surprised), STYLE
```
สีผม/ตา/ชุดอยู่ใน design doc ใช้ตามนั้นเป๊ะ

| ตัวละคร | `[DESCRIPTION]` |
| --- | --- |
| ไอคิว | 24 year old man, 180 cm, lean wiry athletic build with narrow shoulders and a relaxed calm posture, dark black hair swept to the side with fringe slightly over the forehead and one silver-grey streak, dull deep crimson-brown eyes with an unreadable emotionless gaze, handsome sharp face, long black knee-length coat with red lining buttoned to the neck, white armband, small silver bell on a black cord around his neck |
| ฟีฟ่า | 23 year old man, 176 cm, agile medium build, tousled light brown hair with orange tint, bright amber-gold eyes, wide friendly grin, handsome cheerful face, long black coat with red lining worn open, orange scarf loosely wrapped, white armband |
| ตาต้า | 25 year old man, 192 cm, very broad shoulders, tall muscular wall-like build, short neat dark brown hair, steel-grey eyes, stern calm face with a small scar through the left eyebrow, black coat with red lining, one white pauldron on the right shoulder, carries a woman's satchel strap on his shoulder |
| เค้ก | 22 year old woman, 160 cm, smallest of the team, soft cream-brown wavy hair in a low side braid, warm brown eyes behind round glasses, gentle kind smile, curvy figure, modest outfit, short cream overcoat over the black team coat with red lining, large shoulder satchel full of food, white armband |
| เมย์ | 23 year old woman, 165 cm, upright confident posture, wine-red hair in a high ponytail, bright reddish-brown eyes behind thin rectangular glasses, determined sharp expression, curvy figure, modest outfit, neat black coat with red lining fully buttoned, white armband |
| แนนนี่ (ก่อนถูกล้างสมอง) | 22 year old woman, 168 cm, relaxed slender posture, long dark navy hair down to her back, warm golden-brown eyes behind thin silver-framed glasses, cool half-lidded lazy expression, curvy figure, modest outfit, open black coat with red lining, scarf around the neck, white armband |
| แนนนี่ (ฝั่งอสูร) | same character as the reference, but eyes pale violet and empty, flat expressionless face, all-black plain outfit with dark violet lines, no team marks, still wearing the same thin silver glasses |
| เซลเลน | tall dignified male demon guardian, silver-black curved horns, green-gold eyes, long deep navy cloak, calm noble expression, not monstrous |
| ลอร์ดวาเลน | cold sharp-featured male demon lord, white hair, red eyes, single horn on the right side, black and crimson armor |
| พระมหาเถระอัครเสน | elderly man, long white hair, short beard, serene polite face, white and gold priest robes, a gentle smile that does not reach the eyes |
| อสูรเด็ก | small demon child, two small horns, big round pale-blue eyes, ragged old clothes (child character, story use only, never sexualized) |

### Portrait (UI)
```
anime RPG character portrait, face and shoulders, [CHARACTER from the sheet], 512x512, intense expression, dramatic rim lighting, solid dark background, STYLE
```
ทำ 1 ภาพต่อตัวละคร ต่อสถานะ: ปกติ, เจ็บ (hurt), ตาย (defeated) สำหรับ UI การต่อสู้

### ชุดอาชีพ (overlay อาวุธ/เครื่องประดับ) สำหรับฉาก 3D และ portrait
ใช้ภาพอ้างอิงเดิมแล้วเพิ่มอุปกรณ์ ไม่เปลี่ยนหน้าและชุดเรื่อง:
```
same character as the reference sheet, same face and outfit, now holding [WEAPON], [SMALL ACCESSORY], full body, plain background, STYLE
```
| อาชีพ | WEAPON / ACCESSORY |
| --- | --- |
| Assassin (นักฆ่า) | twin black daggers with red edges / dark hooded half-cape |
| Archer (นักธนู) | black recurve bow with a red string / quiver on the back |
| Guardian (ผู้พิทักษ์) | large white-and-black tower shield and short sword / white shoulder plates |
| Mage (นักเวท) | slim black staff topped with a red crystal / floating crimson rune ring |
| Support (ซัพพอร์ต) | ornate bell-topped baton, songbook, white ribbons / floating white sigils |
| Healer (ฮีลเลอร์) | white-and-gold healing wand, small medical satchel / soft white light ring |
ผู้ชาย (ไอคิว/ฟีฟ่า/ตาต้า) ทำชุด Assassin, Archer, Guardian; ผู้หญิง (เค้ก/เมย์) ทำชุด Mage, Support, Healer รวม 15 ภาพ

## ส่วนที่ 2 — โมชั่นตัวละคร

เกมใช้ 3D placeholder ในฉาก Home3D/Battle3D ตัวโมเดลจริงมาจากภาพ character sheet (เครื่องมือ image-to-3D) แล้วใส่ animation ด้วยเครื่องมือ rigging/animation ที่คุณมี **งบ polygon ต้องต่ำ** (renderer `gl_compatibility` บน Web) ประมาณ 5–10k รูปหน้าต่อตัว

รายการ animation ที่ต้องมีต่อตัวละคร (ชื่อใช้ตรงกับ cue ของเกม: strike, skill, focus, item, guard, hurt, die, heal):
`idle`, `walk`, `run`, `strike`, `skill`, `focus`, `item`, `guard`, `hurt`, `die`, `victory`, `heal` (เฉพาะ Healer/Support)

ถ้าสร้าง reference คลิปด้วย AI วิดีโอเพื่อให้ animator อ้างอิง:
```
anime game character animation reference, [CHARACTER from the sheet], [ACTION], front three-quarter view, full body in frame,
plain grey background, fixed camera, 4 seconds, smooth natural motion, no camera movement, STYLE
```
| ACTION | คำอธิบาย |
| --- | --- |
| idle | standing relaxed, subtle breathing, slight weight shift |
| walk / run | walking / running cycle, seamless loop |
| strike | one basic weapon attack with a clear wind-up and follow-through |
| skill | a powerful special move, brief charge, then release |
| focus | calm deep breath, eyes closing, a faint aura gathers |
| item | pulling an item from a pouch and using it |
| guard | bracing defensive stance |
| hurt | recoiling from a hit, then recovering |
| die | collapsing slowly to the ground |
| victory | small triumphant pose |
บุคลิก: ไอคิว (นิ่งเรียบ) ฟีฟ่า (ท่าทางใหญ่ ตื่นเต้น) ตาต้า (หนักแน่น ช้าแต่มั่นคง) เค้ก (นุ่มนวล) เมย์ (ตรง เด็ดขาด) แนนนี่ (ขี้เกียจแต่ว่องไว)

## ส่วนที่ 3 — เอฟเฟกต์ (VFX)

เกมมีไฟล์ FX 2D เดิมใน `assets/fx/` (รูปแบบ sprite sheet + `manifest.json`) ให้ **ใช้ฟอร์แมตเดียวกัน** เอฟเฟกต์ใหม่สร้างบนพื้นสีเขียวล้วนหรือดำล้วน แล้วคีย์สีออกเป็นพื้นโปร่งใส (โมเดลภาพส่วนใหญ่สร้างพื้นโปร่งใสไม่ได้)
```
game VFX sprite sheet, [EFFECT], 6 frames in a single horizontal row, equal frame size, centered, on a solid pure green background,
no characters, crisp edges, black red and white palette with [ACCENT], STYLE
```
| EFFECT | ACCENT | ใช้กับ |
| --- | --- | --- |
| diagonal sword slash arc | white-red | strike (ดาบ/มีด) |
| fast arrow trail with red streak | red | Archer strike/skill |
| crimson magic burst and rune circle | red | Mage skill |
| soft white healing light with rising sparkles | white-gold | Healer heal |
| rising ring of white sigils and music notes | white | Support buff |
| black-and-white shield barrier ripple | white | Guard |
| impact flash with cracks | white | hurt / crit |
| bell shockwave rings echoing outward | silver-white | **เสียงกระดิ่ง** (ฉากรูท 1) |
| dark violet mist swirl | violet | อสูรที่ถูกล้างสมอง / ลอร์ดวาเลน |
| collapse dust and black petals | black | die |
เอฟเฟกต์กระดิ่งกับหมอกม่วงเป็นของเฉพาะเรื่อง ที่เหลือสร้างใหม่หรือใช้ของเดิมได้

## ส่วนที่ 4 — พื้นหลัง

ขนาด 1920×1080 (เกมฐาน 1280×720 stretch แบบ expand) ภาพกว้างพอสำหรับกล้อง 3D/ฉาก 2D ไม่มีตัวละครในภาพ
```
anime RPG environment background, [LOCATION], wide cinematic composition, empty of characters, atmospheric depth, STYLE
```
| ไฟล์ | LOCATION |
| --- | --- |
| `bg_capital_gate` | grand white-and-gold city gate of a radiant capital at dawn, banners with a sun emblem, a long road leading out |
| `bg_forest_road` | misty dark forest path, tall black trees, faint red light between the trunks |
| `bg_old_camp` | abandoned adventurer campsite in the forest, cold fireplace stones, six wooden name plates on a log, a scarf hanging on a branch |
| `bg_forest_deep` | deep forest clearing, twisted roots, drifting violet mist at the edges |
| `bg_demon_village` | small burned demon village at dusk, charred huts, embers, a single child-sized doll on the ground |
| `bg_cave_gate` | huge cave mouth with a sealed stone gate glowing faintly violet, hanging crystals, echoing space |
| `bg_cave_inside` | vast cave interior with an ancient gate between two worlds, crimson and violet glow, stone steps |
| `bg_nightfall_realm` | the quiet twilight realm beyond the gate, silver grass, two moons, peaceful and beautiful (ฉากจบ) |
| `bg_escape_tunnel` | narrow secret tunnel, torchlight, damp stone (รูท 3) |

## ส่วนที่ 5 — วิดีโอ cutscene

**กติกาเทคนิค:** คลิปละ ≤ 10 วินาที, 1280×720, 24–30 fps, ขนาดไฟล์ ≤ ~5 MB หลังแปลงเป็น `.ogv` ด้วย `tools/video/convert_to_ogv.ps1` ตัดฉากยาวเป็นหลายคลิปสั้น เก็บ mp4 ต้นฉบับใน `art_source/`
**ความสม่ำเสมอ:** ใช้ภาพ character sheet เป็น reference ทุกคลิป ชุดเรื่องตายตัว ไม่ใส่อุปกรณ์อาชีพ (เพราะผู้เล่นเปลี่ยนอาชีพได้)
แม่แบบ:
```
anime cinematic shot, [SCENE], [CAMERA MOVE], 8 seconds, characters exactly as the reference sheets, consistent faces and outfits,
[LIGHTING], smooth animation, no text, no subtitles, no dialogue, no music, only quiet ambient sound effects, STYLE
```
| รหัส | คลิป | SCENE / CAMERA |
| --- | --- | --- |
| OP-1 | โลกที่สอนให้เกลียด | night bedtime scene in a glowing city, a mother's silhouette reading to a child, subtle dark shadow outside the window; slow push-in |
| OP-2 | เด็กสองคนกับกระดิ่ง | two small children splitting a silver bell between them under a tree at sunset (children, wholesome, story only); gentle pan |
| OP-3 | ปัจจุบัน | the adult leader alone holding the silver bell, looking at the horizon, the team behind out of focus; slow pull-back |
| C1-1 | ประตูเมือง | the high priest hands a sealed order to the team at the capital gate, the leader accepts with a blank expression; two-shot, slow zoom |
| C1-2 | ออกเดินทาง | five adventurers walking out the gate onto the road, banter in body language; wide tracking shot |
| C3-1 | เดินสวนกัน | forest path, the leader and a long-haired woman in black with violet eyes pass each other, she briefly stops and holds her arm, then walks on; slow-motion two-shot |
| CH-1 | ประตูถ้ำ | the team at the cave gate, the woman in black waits at the glowing gate, the demon guardian behind her; wide shot, heavy silence |
| E1-1 | กระดิ่งก้อง (รูท 1) | the bell rings, silver shock rings fill the cave, her eyes change from violet to golden brown, she starts to cry; close-up cut |
| E1-2 | เดินไปด้วยกัน (รูท 1) | all six walking on a bright path where humans and demons walk together, three pairs side by side; wide sunrise shot |
| E2b-1 | เงียบหลังสู้ (รูท 2) | the leader standing alone among fallen friends (non-graphic, implied only), she takes his hand; slow lateral dolly |
| E2b-2 | เข้าประตู (รูท 2) | the two walk into the violet gate, the bell sound fades; wide static shot |
| E2-1 | ถ้ำว่างเปล่า (รูท 2) | empty cave, a single silver bell on the ground, light fading; slow push-in |
| E3-1 | กองทัพบุก (รูท 3) | soldiers with sun emblems storming the cave, torches, the demon guardian blocking; wide dynamic shot |
| E3-2 | ทางลับ (รูท 3) | six figures running through a narrow tunnel, the big man carrying the unconscious woman; handheld tracking |
ฉากรูท 2 ที่เพื่อนล้ม ให้ใช้ภาพเชิงสื่อความหมาย ไม่แสดงความรุนแรงตรงๆ

## ส่วนที่ 6 — ลำดับการผลิตที่แนะนำ
1. character sheet ทั้ง 6 + 4 ตัวรอง → ให้คุณเลือกและล็อกหน้าตา
2. portrait + ชุดอาชีพ 15 ภาพ
3. พื้นหลัง 9 ภาพ
4. คลิป cutscene 14 คลิป (ทำ OP, C1, C3, CH ก่อน เพราะใช้ในทุกรูท)
5. เอฟเฟกต์ใหม่ (เฉพาะเรื่อง: กระดิ่ง, หมอกม่วง, Healer, Support)
6. โมเดล 3D + animation (ทำหลังภาพนิ่งล็อกแล้ว)
ทุกขั้นบันทึกใน `assets/MANIFEST.3d.json`

## ส่วนที่ 7 — เครื่องมือและขั้นตอน (ตัดสินแล้ว)

| งาน | เครื่องมือ | ผู้ลงมือ |
| --- | --- | --- |
| ภาพ (character sheet, portrait, พื้นหลัง, เอฟเฟกต์) | Codex | Codex สร้าง, Claude ตรวจเทียบ character sheet |
| วิดีโอ cutscene | Google Flow | เจ้าของงานรันใน Flow (ต้อง login บัญชีตัวเอง) |
| 3D | เครื่องมือฟรี (ดูข้างล่าง) | เจ้าของงานรันเว็บ, Claude ช่วย retopo/ตรวจงบ polygon |
| ควบคุมคุณภาพ ชื่อไฟล์ manifest ลำดับงาน | Claude (Claude Main) | Claude |

### Google Flow
- ข้อมูลที่ตรวจแล้ว: Veo 3.1 สร้างคลิป **8 วินาที** (720p/1080p) มี **เสียงในตัว** และรองรับ **ingredients to video** (ใส่ภาพอ้างอิงตัวละคร/ฉาก) ส่วนโหมด first/last frame ผมไม่ได้ยืนยัน ให้ดูในหน้าจอ Flow
- ทุกคลิปในตาราง cutscene ออกแบบให้ยาว 8 วินาทีพอดี ตรงกับขีดจำกัดของ Veo จึงไม่ต้องต่อคลิป
- ใส่ภาพ character sheet เป็น ingredient ทุกคลิป (สูงสุดเท่าที่ Flow อนุญาต) และคง prompt ท่อนตัวละครให้เหมือนกันทุกคลิป
- Veo สร้างเสียงเอง prompt จึงมีคำว่า "no dialogue, no music" เพราะเสียงพูดอยู่ในข้อความบนจอและเพลงเป็นของคุณ ให้ปิดหรือตัดเสียงออกตอนแปลง `.ogv` ถ้า Flow ยังใส่มา
- คลิป branch ที่ต่อจากฉากตัดสินใจ (E1/E2b/E3) ให้ใช้เฟรมสุดท้ายของ CH-1 เป็นภาพอ้างอิง เพื่อความต่อเนื่องของท่าและแสง
- ส่งออก mp4 ลง `art_source/` แล้วให้ผมแปลงเป็น `.ogv` ด้วย `tools/video/convert_to_ogv.ps1` และตรวจขนาดไฟล์

### ภาพโดย Codex
- ผมไม่ได้ตรวจว่า Codex CLI บนเครื่องคุณสร้างภาพได้เองหรือไม่ ถ้าไม่ได้ ใช้ Codex/ChatGPT ฝั่งแอปสร้างภาพแล้วบันทึกลง `art_source/` ผมจะตรวจเทียบ character sheet และจัดชื่อไฟล์
- ลำดับ: สร้าง character sheet ทีละตัว → คุณเลือกและล็อก → ใช้ภาพที่ล็อกเป็น reference ให้ทุกภาพถัดไป
- ภาพเอฟเฟกต์ที่ต้องโปร่งใส: สร้างบนพื้นเขียว แล้วให้ผมเขียนสคริปต์คีย์สีออก (ฝั่ง `tools/art/`)

### 3D แบบฟรี
ตัวเลือกที่ค้นแล้ว (ตรวจเงื่อนไขการใช้เชิงพาณิชย์ของแต่ละเจ้าก่อนใช้ในเกมที่เผยแพร่):
- **Tripo** — เครดิตฟรี 200 ต่อเดือน
- **Meshy** — มีเครดิตฟรี สร้างจากภาพได้
- **3D AI Studio** — ฟรีเทียร์ รวมหลายโมเดล
- Hunyuan3D / TRELLIS รันเองฟรีได้ แต่ต้อง GPU แรง (แนะนำ 24 GB VRAM) เครื่องคุณใช้ RTX 4050 จึงไม่เหมาะ ให้ใช้เว็บแทน
ขั้นตอนที่เสนอ: ภาพ character sheet ด้านหน้า → image-to-3D → ลดจำนวนหน้าใน Blender (ฟรี) เหลือ 5–10k รูปหน้า → rig + animation (เช่น Mixamo ซึ่งฟรีแต่ต้องมีบัญชี Adobe) → ส่งออก `.glb` → วางใน `assets/models/` ผมจะเขียนโค้ดโหลดใน Home3D/Battle3D หลังจาก asset นิ่ง
ความเสี่ยง: โมเดลจาก AI มักมีโครงเมชและ UV ไม่เรียบร้อย ต้องมี retopo/ทำความสะอาด และการ rig อัตโนมัติอาจเพี้ยนกับทรงผมหรือโค้ต ถ้างานนี้ยากเกินไป ทางสำรองคือใช้ sprite 2.5D (ภาพตัวละครบนฉาก 3D) ซึ่งทำเสร็จเร็วกว่ามาก

## ข้อที่ต้องให้เจ้าของงานตัดสิน
1. โมเดล 3D เต็มตัว (เสี่ยง ใช้เวลา) หรือ sprite 2.5D (เร็ว ปลอดภัย) เป็นแผนหลัก
2. ใครรัน Google Flow และเครื่องมือ 3D (ต้อง login บัญชีของคุณ) ผมเตรียมรายการ prompt ให้ครบก่อนได้

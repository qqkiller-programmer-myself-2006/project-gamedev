# Checkpoint — AAC parity push (final build 2026-10-02)

อ่านไฟล์นี้ก่อนทำงานต่อทุกครั้ง แล้วอัปเดตตาราง "สถานะงาน" และ "Log" ทุกครั้งที่งานเปลี่ยนสถานะ

## เป้าหมาย

ทำให้เกมเหมือนภาพอ้างอิง AAC (`docs/references/aac_rogue/01–11`) ให้มากที่สุด **ทั้งหน้าตาและกติกา ทุกหน้าจอ** ก่อน final build 2026-10-02

## การตัดสินใจของเจ้าของงาน (2026-09-29)

- ทำครบทุกหน้า: Combat, Camp (Merchant/Rest), Class/Prestige, Race, Boons
- ตัวละคร 2D วาดด้วยโค้ดแบบ blocky (Roblox-like) ส่วน HUD/แผง/ฟอนต์/สี/ตำแหน่ง ต้องเหมือนภาพ
- เปลี่ยนกติกาให้เหมือนภาพทั้งระบบ → ADR-0012 (attribute 7 ตัว, Fight/Items/Focus, Energy ศัตรู, Gold ส่วนตัว) และ ADR-0013 (หน้าก่อนเริ่ม Match)
- Codex และ Antigravity แก้ไฟล์เองได้ แต่ใน git worktree ของตัวเองเท่านั้น ห้าม commit/push; Claude ตรวจ diff + รัน test แล้ว commit/merge เอง

## บทบาท

| ใคร | ทำอะไร |
| --- | --- |
| Claude Code | วางแผน, เขียน ADR/ไฟล์งาน, QA (เทียบภาพ, รัน test), commit, อัปเดต issue และ Project #8 |
| Codex (`codex exec`) | งาน UI ฝั่ง client (ส่งภาพอ้างอิงด้วย `-i` ได้) |
| Antigravity (`agy --print`, โมเดล gemini-3.1-pro-high) | งาน server/กติกา/test/balance |

## วิธีรัน (สำคัญ)

- Godot: `D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe` (ไม่อยู่ใน PATH ต้องตั้ง `GODOT`)
- Test: `GODOT=... bash scripts/run_tests.sh` (baseline 248 passed, ~140 วินาที)
- ภาพ QA: `"$GODOT" --path . -s tools/ui_preview.gd -- --out=build/ui --seed=11 --speed=10 --class=rogue` (+ `--scale=1.4`)
- สั่ง AI: `powershell -File .ai/run-agent.ps1 -Agent codex|agy -Worktree <path> -TaskFile .ai/tasks/<file>.md -TimeoutMin 60 [-Images ...] [-Model ...]`
  สคริปต์ฆ่าทั้ง process tree เมื่อหมดเวลา และเขียน `.ai/logs/<task>-<agent>-<time>.status.json` (state: running / finished / timeout-killed)
- เช็กว่ามีอะไรค้าง: ดูไฟล์ `*.status.json` ที่ state = running แล้ว `Get-Process -Id <pid>`
- Integration branch: `claude/github-project-issue-learning-20567b` (worktree นี้) → PR เข้า `main`
- Worktree ของ AI: `../ai-t<N>` branch `ai/t<N>-<ชื่อ>` แตกจาก integration branch

## สถานะงาน

| งาน | ผู้ทำ | branch / worktree | issue | สถานะ |
| --- | --- | --- | --- | --- |
| T1 Combat UI ตามภาพ 04–07, 11 | Codex | `ai/t1-combat-ui` / `../ai-t1` | #48 | ✅ merged 3b80524 (QA 3 รอบ), integration 254/254 |
| T2 Attribute 7 ตัว + Focus (server) | Antigravity | merged 50a6fa7 | #49 | ✅ เสร็จ 251/251, win 87/88% |
| T3 Camp UI ตามภาพ 08–10 | Codex | `ai/t3-camp-ui` / `../ai-t3` | #50 | ✅ merged 35e7767 (3 รอบ QA); seed 3 = ได้ภาพ Rest, seed 11 = Merchant |
| T4 Energy ศัตรู + Gold ส่วนตัว/Transfer (server) | Antigravity+Codex | merged | #51 | ✅ merged b3aaa02, 254/254, win 88/83% |
| T5 ADR-0013 + server: Race, Boons, Class meta/Prestige | Codex | merged 2d1e7ef | #52 | ✅ 262/262; loadout win 100% → #59 |
| T6 หน้าจอ Class/Race/Boons ตามภาพ 01–03 | Codex | `ai/t6-setup-ui` / `../ai-t6` | #53 | กำลังทำ |
| T7 QA รวม, 1920×1080, PR, final build | Claude | — | #54 | รอทั้งหมด |
| T8 Cloudflare Worker + D1 เก็บ profile/Gems | Codex | merged 0ffd1b1 | #55 | ✅ โค้ดเสร็จ 5/5 test; รอเจ้าของงาน deploy ตาม docs/running.md |

| T9 ใช้ sprite ของเจ้าของงาน (Archer/Mage/Swordsman) | Codex | `ai/t9-sprites` / `../ai-t9` | #56 | T9a ✅ merged; T9b (`ai/t9b-sprites-battle` / `../ai-t9b`) กำลังทำ + เศษงาน #48 |

การตัดสินใจรอบ 3 (2026-09-29 12:10): ใช้ Claude Code + agy + Codex เท่านั้น ไม่ใช้ opencode (เขียนใน AGENTS.md แล้ว); มี subagent `codex-executor` / `agy-executor` ใน `.claude/agents/` (ใช้ได้ใน session ใหม่)
โควตา: agy Gemini หมด (รีเซ็ต ~14:25), agy Claude หมด (รีเซ็ต ~17:30) — ระหว่างนี้งานทั้งหมดไป Codex; T4-r2 และ T9a-r2 ย้ายมา Codex แล้ว

การตัดสินใจรอบ 2 (2026-09-29): เลือก Class ก่อนเริ่มแบบ AAC, Enervation เป็น Boon, Robloxian → Human, Gems เก็บบน Cloudflare D1 → ADR-0013
ข้อควรรู้: `~/AGENTS.md` และ `~/.codex/AGENTS.md` สั่งให้ Codex โยนงานให้ opencode — runner จึงใส่คำสั่ง override ไว้ใน prompt

Parent issue #47, milestone "Final build — AAC parity" (#4, due 2026-10-02), Project #8 (Status + Start/Target date ตั้งแล้ว)

## Log

- 2026-09-29: ตรวจเครื่องมือ (Codex 0.155.0 ✅, agy 1.2.10 ✅, Godot 4.7.2 ✅), baseline test 248/248, เขียน ADR-0012, `.ai/run-agent.ps1`, T1, T2
- เหลือขัดเกลา (#54): กล่อง region ชนหัวข้อ Equipment ที่ 1.4×
- 2026-09-29 12:35: บั๊ก runner — Codex ค้างที่ "Reading additional input from stdin" 2 ชม. (T1-r3 เสียเวลาฟรี) แก้แล้ว: stdin ว่าง + watchdog poll; relaunch T1-r3 และ T9a-r2 (-NoSandbox เพราะ sandbox รัน Python ไม่ได้)
- เหลือขัดเกลา (#54): บอสเติม Energy แต่ไม่เคยใช้
- 2026-09-29 12:50: เจ้าของงานสั่งให้ใช้ subagent codex-executor แบบ background; ชนิดนี้ยังไม่โหลดใน session นี้ จึงใช้ general-purpose + คำสั่งเดียวกันแทน (session ใหม่เรียก codex-executor / agy-executor ได้ตรงๆ). T9b spec พร้อม (รอ #48 + T9a)
- 2026-09-29 13:00: เจ้าของงานขอหน้าแรกใหม่ + ปุ่ม bypass เล่นทดสอบ → #57; T10a (Codex, `ai/t10-home` / `../ai-t10`) กำลังทำ: หน้าแรก animated + Playtest ▶ (debug/--dev เท่านั้น, embedded GameServer, `--dev --playtest`); T10b (หลัง #52): กระโดดไปฉากที่ต้องการ + เลือก Class/seed
- T9a ตัดภาพเสร็จ merged 6a62ac5; T9b รอ #48
- 2026-09-29 13:20: Story mode (#58, ADR-0014) — T11a (`ai/t11-story` / `../ai-t11`) กำลังทำผ่าน subagent; T11b หลัง #52 + #57
- เจ้าของงานขอ: ทุกครั้งที่ทดสอบ ให้เปิดเกมใน Godot ให้ดูจริง → server: `godot --headless --path . -- --server --port=8910`, client: `Godot_v4.7.2-stable_win64.exe --path . -- --url=ws://127.0.0.1:8910 --name=Tester --auto` (หลัง #57 ใช้ `--dev --playtest` แทน)
- 2026-09-29 13:12: Codex T9b ล้มเพราะ RAM หมด (เครื่องมี 15.7 GB, ว่าง ~4 GB เพราะ claude/node/MCP กินเยอะ) → **กฎใหม่: รัน executor พร้อมกันไม่เกิน 2 งาน**; T9b WIP add4447 รอคิว (retry เมื่อมีช่องว่าง). โปรเซส Godot ที่เกิดใน sandbox ของ Codex ฆ่าจากนอก sandbox ไม่ได้ (Access denied)
- 2026-09-29 13:35: #57 รอบ 1 merged beb28af (หน้าแรกใหม่ + Playtest ทำงาน, 254/254); รอบ 2 ต้องแก้: Swordsman ซ่อนหลังเมนูที่ 1.0, ตัวละครลอยไม่ยืนรอบกองไฟ, กองไฟเป็นสามเหลี่ยม/วงแสงสีดำ, เส้นลายบนท้องฟ้า, panel เขียวแทน navy, ข้อความ build ถูกตัด, ช่อง Seed อยู่ในเมนูหลัก
- **หลัง merge ไฟล์ที่มี class_name ใหม่ ต้องรัน `"$GODOT" --headless --path . --import` ก่อนเปิดเกม** ไม่งั้นขึ้น "Identifier ... not declared"
- เปิดทดสอบ: `Godot_v4.7.2-stable_win64.exe --path . -- --dev --playtest`
- 2026-09-29 13:45: #52 merged; #53 (T6) เริ่ม; #58 part 1 merged 580f6b5, T11b spec พร้อม (รอช่องว่าง); #59 balance (T12) รอ agy Gemini รีเซ็ต ~14:25
- คิวถัดไป (สูงสุด 2 งานพร้อมกัน): T11b Story wiring → T12 balance (agy) → T10a-r2 หน้าแรกขัดเกลา → T10b Playtest jump → T7 QA/PR
- `.codex/agents/*.toml` ในรีโปเกิดจากแอป Codex คัดลอก .claude/agents มาเอง (ไม่ใช่ของเรา) — ไม่ commit
- 2026-09-29 13:55: merged #53 (89baacb) และ #56 T9b (dba89c6), integration 266/266. กำลังทำ: T11b Story wiring (Codex), T12 balance (Codex เพราะ agy ยังหมดโควตา). คิว: T13 UI polish (`.ai/tasks/T13-ui-polish.md`, หลัง T11b เพราะแตะ title_screen/battle_view เหมือนกัน) → T10b → T7 QA/PR
- 2026-09-29 14:10: **ทุก executor หมดโควตา** — Codex ถึง ~17:21, agy Gemini ถึง ~14:25, agy Claude ถึง ~17:30. T11b WIP db9cc49 (ai-t11b) และ T12 WIP 9ab9aeb (ai-t12) ถูกหยุดกลางทาง ยังไม่ verify; task copy ใน worktree มี note ให้ทำต่อ. แผน: 14:27 ส่ง T11b + T12 ให้ agy gemini-3.1-pro-high; 17:21 ส่ง T13 UI polish ให้ Codex
- 2026-09-29 15:00: เจ้าของงานสั่ง: **ถ้า Codex+agy ติดลิมิต ให้ Claude ลงมือเขียนโค้ดเอง** (memory: feedback_claude_codes_when_rate_limited). Claude ทำ: ตรวจ+merge T11b Story mode (737ca39, #58 ปิด), แก้บั๊ก Playtest ปิดเกมเมื่อ port ชน (0b8bf7e), T13 polish ครบ 13 ข้อ (fad8ca1, หน้าแรก; setup; e37dc10 battle) #57 ปิด, แก้ ui_preview หลัง Story mode, เจอบั๊ก simulate story (เดิม 23% จริง 98%)
- T12 balance (#59) กำลังทำบน agy gemini-3.1-pro-high ใน ai-t12 (merge integration แล้ว + fix simulate 667f18b); เป้า: default/loadout/story 70–92%
- คิวที่เหลือ: T10b Playtest jump-to-scene, T7 QA รวม (1920×1080 ทุกหน้า) + README/PR เข้า main, เจ้าของงาน deploy Cloudflare (#55), #54 sign-off
- 2026-09-29 15:10: เจ้าของงานขอ UX redesign + ธีมเดียวทั้งเกม → เลือก **Navy + Gold** → #60; สร้าง subagent `.claude/agents/ui-ux-developer.md`; ตอนนี้ subagent (general-purpose ทำหน้าที่ ui-ux-developer) ทำงานใน **integration worktree นี้โดยตรง** และ commit เอง → ระหว่างนี้ Claude ห้ามแก้ไฟล์ src/client/** เพื่อไม่ชนกัน. ขั้น: audit+docs/ui-style.md → tokens/Theme ใน UiKit → ย้ายทุกหน้าออกจากสี hard-code → UX pass → screenshots build/ux_final
- 2026-09-29 15:20: เจ้าของงานขอ subagent รีวิวหาบั๊ก → `.claude/agents/code-reviewer.md` (read-only); รัน 2 ตัวขนาน: server/net/content/tests → `docs/review/2026-09-29-server-review.md`, client/story/tools → `docs/review/2026-09-29-client-review.md`. เสร็จแล้ว Claude: รวมเป็นแผน, เปิด issue ตาม finding, อัปเดต Project #8, push
- 2026-09-29 15:25: เจ้าของงานขอไอคอน → #61, subagent `.claude/agents/icon-designer.md`; Phase 1 (ไฟล์ใหม่เท่านั้น: tools/make_icons.py, assets/icons, src/client/ui/icons.gd, test, docs/icons.md) กำลังทำ; Phase 2 (ใส่ไอคอนทุกหน้า) รอ #60 merge
- agent ที่ทำงานพร้อมกันตอนนี้: UI/UX #60, reviewer x2, icon #61, agy balance #59 — ทุกตัวใช้ Godot ทีละตัว; ห้ามใช้ `git add -A`
- 2026-09-29 20:50 (session ใหม่หลัง context เต็ม): background agents ของ session ก่อนหยุดหมด — UI/UX #60 commit ถึง 41acda7 (เหลือ title_screen.gd แก้ panel ต่ำลงเมื่อตัวอักษรใหญ่ ยังไม่ commit), icon #61 ไม่ได้สร้างไฟล์ใดเลย (ต้องเริ่มใหม่), agy balance #59 จบแต่ไม่ commit (ai-t12: boss HP 1450, pass_exp 40, match_bot story ใช้ PartyAi; docs/balance.md มีข้อความ UTF-16 ต่อท้ายต้องลบ) → กำลัง verify
- review → issues **#62–#71** (sub-issue ของ #47, milestone final build, Project #8 Todo + วันที่); label ใหม่ `priority:p2`; แผนใน `docs/review/2026-09-29-dev-plan.md`
- เจ้าของงานแจ้ง: Codex + agy ไม่ติดลิมิตแล้ว ใช้ได้เต็มที่ → T14 (#62+#63, agy, `ai/t14-p0-server` / `../ai-t14`) และ T15 (#64, Codex, `ai/t15-d1-sender` / `../ai-t15`) กำลังทำ
- คิว: verify+merge #59 → commit title fix + ปิด #60 → icon #61 ใหม่ (Codex) → #65 (agy) / #66 #67 → #68–#70 (UI, หลัง #60) → #71 → T10b → T7/#54
- 2026-09-29 21:40: merged #59 balance (b058262), #60 title fix, T14 #62/#63 (58dd548), T15 #64 (a8b6e9a d913724) → integration 281/281. #63 still open: attribute forging, clue types, tests for gear/attr/clue, old saves without `version` are rejected
- เจ้าของงานส่งภาพ 16 รูป (ฮีโร่ 5, ศัตรูป่า 5, ศัตรูถ้ำ 4, ฉาก 2) → `art_source/` (+ .gdignore). การตัดสินใจ: ช่วงท้าย+บอสเป็นถ้ำ, ศัตรูป่าเปลี่ยนชื่อตามภาพ (Grey Wolf→Wolf, Masked Outlaw→Thief, Stone Sentinel→Golem, Forest Wisp→Slime, Bramble Archer→Goblin; ค่าเดิม), Rogue→Assassin, **จัดโครงสร้างโฟลเดอร์ใหม่ก่อน** แล้วค่อยงานภาพ
- แผน restructure: `docs/plans/2026-09-29-restructure.md` (#72); agent `.claude/agents/repo-restructurer.md`; issues #72 restructure, #73 ศัตรู+ฉาก, #74 ฮีโร่ v2 + Assassin
- เจ้าของงาน: ใช้ Codex + agy เต็มที่ ขนานกัน, commit+push+อัปเดต issue ทุก stage, ถามเมื่อไม่แน่ใจ, คุม token อย่าติด rate limit
- กำลังทำ (ขนาน): T17 restructure (Codex, `ai/t17-restructure` / `../ai-t17`); T18 ตัดภาพศัตรู+ฉาก (agy, `ai/t18-enemy-art` / `../ai-t18`, ไฟล์ใหม่เท่านั้น). คิวหลัง T17: T16 icons (path ใหม่ tools/art, assets/icons), #74 ฮีโร่ v2 + Rogue→Assassin, #73 step 2 (ใส่ศัตรู/ฉาก/Layer ถ้ำ + balance), #65–#71
- 2026-09-29 22:30: **#72 restructure merged** (30b7d1a + docs index) 281/281 — paths ใหม่: tests `tools/run_tests.sh`, checkpoint `.ai/checkpoint.md`, previews `tools/dev/*`, art tools `tools/art/*`, heroes `assets/heroes/`, raw art `art_source/`. ปิด #59 #60 #62 #64 #72; #63 เปิดต่อ (ช่องโหว่ที่เหลือใน comment)
- การตัดสินใจ (Claude): Rogue→Assassin เปลี่ยน id จริง + migrate profile/loadout เก่า (ยังไม่ release); save Story เก่าที่ไม่มี version ถูกปฏิเสธ (ยังไม่ release)
- กำลังทำ: T18 ตัดภาพศัตรู+ฉาก (agy, ai-t18 — แตกจาก base ก่อน restructure แต่สร้างแค่ไฟล์ใหม่), T19 ฮีโร่ v2 + Assassin (Codex, `ai/t19-heroes-v2` / `../ai-t19`)
- คิว: T16 icons (แก้ path เป็น tools/art, tests/client, docs/design/ui-style.md), #73 step 2 (ใส่ศัตรู/ฉาก/Layer ถ้ำ + balance, agy หลัง T18), #65 (agy), #66–#71, T10b, T7/#54
- 2026-09-29 22:45: **stall detector** ใน `.ai/run-agent.ps1` (5afb0ae): ไฟล์ใน worktree + log + CPU ของ process tree นิ่งครบ `-IdleMin` (20) นาที → kill tree, state `stalled`, เปิด agent ใหม่ resume ใน worktree เดิม (`-Retries 1`, `-FallbackAgent`); ตรวจสด `powershell -NoProfile -ExecutionPolicy Bypass -File .ai/agent-status.ps1` (IDLE/DEAD/NOBEAT); `.ai/logs/stalled.log`. self-test ผ่านทั้ง hang และ slow-working
- T18 agy ไม่ได้ค้าง: รอบ 1 จบ 21:49 (27 นาที) รอบ retry ยังเขียนไฟล์อยู่ (agy ไม่พิมพ์ log จนจบ)
- T19: Codex ตัดภาพฮีโร่พัง 2 รอบ (สองตัวในเฟรมเดียว, label ติด, ชิ้นส่วน) → commit เฉพาะ rename+wiring `cac48cc` บน `ai/t19-heroes-v2` (ยังไม่ merge), ทิ้งภาพเสีย; ต้องเขียน slicer ใหม่ (detect จากภาพ; ต้องการแค่ idle_right, attack, hurt, dead, portrait) → ให้ agy หลัง T18 ถ้าวิธีของ T18 ดี ไม่งั้น Claude ทำเอง; badge "R" ใน battle_token ยังต้องเปลี่ยนเป็น "A"
- กำลังทำ: T18 (agy), T16 icons (Codex, `ai/t16-icons` / `../ai-t16`)
- 2026-09-29 23:05: T18 agy ล้มเหลว (label/palette ติดเป็นเฟรม, จำนวนเฟรมผิด) แล้ว **agy quota หมด ~3 ชม. (ถึง ~01:50)** → ลบ worktree ai-t18 ทิ้ง. สร้าง agent `.claude/agents/sprite-slicer.md` (ดูภาพ → config ต่อ sheet → validate จำนวนเฟรมแบบ hard fail → ดู contact sheet). รัน Claude 2 ตัวขนานใน isolated worktree: ศัตรู 9 + ฉาก 2 (#73) และ ฮีโร่ v2 5 อาชีพ (#74 part A). จำนวนเฟรมที่คาดไว้อยู่ใน prompt (Claude อ่านจากภาพ)
- Codex: T16 icons กำลังทำ (ai-t16). merge ลำดับ: T16 → hero art + ai/t19 (rename/wiring) → enemy art → #73 step 2 (ใส่ศัตรู/ฉาก/Layer ถ้ำ, Codex)

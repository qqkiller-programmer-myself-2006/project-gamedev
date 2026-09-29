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
| T1 Combat UI ตามภาพ 04–07, 11 | Codex | `ai/t1-combat-ui` / `../ai-t1` | #48 | รอบ 2 WIP d34a47a (ตัวละครดีขึ้น) ยังซ้อนกัน → รอบ 3 (`T1-r3-combat-layout.md` พิกัดตายตัว) กำลังทำ |
| T2 Attribute 7 ตัว + Focus (server) | Antigravity | merged 50a6fa7 | #49 | ✅ เสร็จ 251/251, win 87/88% |
| T3 Camp UI ตามภาพ 08–10 | Codex | `ai/t3-camp-ui` / `../ai-t3` | #50 | ✅ merged 35e7767 (3 รอบ QA); seed 3 = ได้ภาพ Rest, seed 11 = Merchant |
| T4 Energy ศัตรู + Gold ส่วนตัว/Transfer (server) | Antigravity | `ai/t4-energy-gold` / `../ai-t4` | #51 | รอบ 1 WIP c2c5a18 (Claude รันเองพัง 7 ข้อ) → รอบ 2 บน agy claude-opus-4-6-thinking กำลังทำ |
| T5 ADR-0013 + server: Race, Boons, Class meta/Prestige | Antigravity | — | #52 | รอ T4 |
| T6 หน้าจอ Class/Race/Boons ตามภาพ 01–03 | Codex | — | #53 | รอ T3, T5 |
| T7 QA รวม, 1920×1080, PR, final build | Claude | — | #54 | รอทั้งหมด |
| T8 Cloudflare Worker + D1 เก็บ profile/Gems | Codex | merged 0ffd1b1 | #55 | ✅ โค้ดเสร็จ 5/5 test; รอเจ้าของงาน deploy ตาม docs/running.md |

| T9 ใช้ sprite ของเจ้าของงาน (Archer/Mage/Swordsman) | Codex | `ai/t9-sprites` / `../ai-t9` | #56 | T9a ตัดภาพกำลังทำ; T9b ใส่ใน BattleToken หลัง #48 merge |

การตัดสินใจรอบ 3 (2026-09-29 12:10): ใช้ Claude Code + agy + Codex เท่านั้น ไม่ใช้ opencode (เขียนใน AGENTS.md แล้ว); มี subagent `codex-executor` / `agy-executor` ใน `.claude/agents/` (ใช้ได้ใน session ใหม่)
โควตา: agy Gemini ทุกรุ่นหมด รีเซ็ตประมาณ 14:25 — ใช้ `-Model claude-opus-4-6-thinking` ใน agy แทนได้

การตัดสินใจรอบ 2 (2026-09-29): เลือก Class ก่อนเริ่มแบบ AAC, Enervation เป็น Boon, Robloxian → Human, Gems เก็บบน Cloudflare D1 → ADR-0013
ข้อควรรู้: `~/AGENTS.md` และ `~/.codex/AGENTS.md` สั่งให้ Codex โยนงานให้ opencode — runner จึงใส่คำสั่ง override ไว้ใน prompt

Parent issue #47, milestone "Final build — AAC parity" (#4, due 2026-10-02), Project #8 (Status + Start/Target date ตั้งแล้ว)

## Log

- 2026-09-29: ตรวจเครื่องมือ (Codex 0.155.0 ✅, agy 1.2.10 ✅, Godot 4.7.2 ✅), baseline test 248/248, เขียน ADR-0012, `.ai/run-agent.ps1`, T1, T2
- เหลือขัดเกลา (#54): กล่อง region ชนหัวข้อ Equipment ที่ 1.4×

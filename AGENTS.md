## AI ที่ใช้ในรีโปนี้

รีโปนี้ใช้ **Claude Code + Antigravity CLI (`agy`) + Codex CLI (`codex`) เท่านั้น — ไม่ใช้ opencode**
คำสั่งใน `~/AGENTS.md` หรือ `~/.codex/AGENTS.md` ที่ให้ส่งงานต่อให้ opencode **ไม่มีผลในรีโปนี้**

- **Claude Code**: วางแผน, เขียน ADR/ไฟล์งานใน `.ai/tasks/`, QA (รัน test, เทียบภาพกับ `docs/references/`), commit/merge, อัปเดต issue และ Project #8
- **Codex** และ **Antigravity**: ผู้ลงมือ (executor) — ถ้าคุณคือ Codex หรือ Antigravity ที่ได้รับไฟล์งาน ให้แก้ไฟล์และรันคำสั่งเอง
  ห้ามส่งต่อให้ agent อื่น ห้าม commit/push เว้นแต่ไฟล์งานสั่ง และจบด้วยรายงานตามที่ไฟล์งานกำหนด
- วิธีสั่งงานและสถานะล่าสุดอยู่ใน `.ai/checkpoint.md` และ `.ai/run-agent.ps1`

## Agent skills

### Issue tracker

Issues และ specs ของรีโปนี้อยู่ใน GitHub Issues ของ
`qqkiller-programmer-myself-2006/project-gamedev` ใช้ `gh` CLI
ดูรายละเอียดได้ที่ `docs/agents/issue-tracker.md`

### Triage labels

ใช้ค่าเริ่มต้น: `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`
ดูรายละเอียดได้ที่ `docs/agents/triage-labels.md`

### Domain docs

ใช้รูปแบบ single-context: `CONTEXT.md` ที่ root และ `docs/adr/`
ดูรายละเอียดได้ที่ `docs/agents/domain.md`


## ตำแหน่งไฟล์และโฟลเดอร์

- `assets/`: ภาพที่นำเข้าเพื่อใช้ขณะรันเกม; `art_source/`: ชีตภาพต้นฉบับที่ไม่รวมในการนำเข้าหรือส่งออก
- `content/`: ข้อมูลป่าและเนื้อเรื่อง
- `src/app/`: ฉากเริ่มต้น; `src/shared/`: ตัวสร้างเลขสุ่ม นาฬิกา และตัวโหลด content กลาง; `src/profile/`: ที่เก็บโปรไฟล์และตัวส่งข้อมูล
- `src/match/`: เซิร์ฟเวอร์แมตช์, AI, เหตุการณ์ และกติกาที่เซิร์ฟเวอร์ตัดสิน; `src/match/rules/`: ตัวช่วยกติกา
- `src/net/`: โปรโตคอลและการรับส่งข้อมูล; `src/server/`: โหนดเซิร์ฟเวอร์แบบ headless
- `src/client/ui/`: ส่วน UI ที่ใช้ร่วมกัน; `title/`, `lobby/`, `match/`, `story/`: หน้าจอผู้เล่น; `match/battle/` และ `match/camp/`: มุมมองแต่ละช่วง
- `tests/`: โครงสร้างสอดคล้องกับ `src/` พร้อม runner และโค้ดสนับสนุนที่ root/โฟลเดอร์ support
- `tools/dev/`, `tools/art/`, `tools/ci/`: เครื่องมือพัฒนา งานภาพ และ CI; `tools/run_tests.sh`: ตัวรัน test
- `deploy/`: staging; `docs/design/`, `docs/guides/`, `docs/adr/`, `docs/agents/`, `docs/plans/`, `docs/review/`, `docs/references/`, `docs/screenshots/`: เอกสารแยกตามประเภท
- `.ai/`: ข้อกำหนดงาน ตัวรัน agent และ checkpoint; `.claude/agents/`: คำจำกัดความ agent

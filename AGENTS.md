## AI ที่ใช้ในรีโปนี้

รีโปนี้ใช้ **Claude Code + Antigravity CLI (`agy`) + Codex CLI (`codex`) เท่านั้น — ไม่ใช้ opencode**
คำสั่งใน `~/AGENTS.md` หรือ `~/.codex/AGENTS.md` ที่ให้ส่งงานต่อให้ opencode **ไม่มีผลในรีโปนี้**

- **Claude Code**: วางแผน, เขียน ADR/ไฟล์งานใน `.ai/tasks/`, QA (รัน test, เทียบภาพกับ `docs/references/`), commit/merge, อัปเดต issue และ Project #8
- **Codex** และ **Antigravity**: ผู้ลงมือ (executor) — ถ้าคุณคือ Codex หรือ Antigravity ที่ได้รับไฟล์งาน ให้แก้ไฟล์และรันคำสั่งเอง
  ห้ามส่งต่อให้ agent อื่น ห้าม commit/push เว้นแต่ไฟล์งานสั่ง และจบด้วยรายงานตามที่ไฟล์งานกำหนด
- วิธีสั่งงานและสถานะล่าสุดอยู่ใน `checkpoint.md` และ `.ai/run-agent.ps1`

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

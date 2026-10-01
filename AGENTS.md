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


## Where things live

- `assets/`: imported runtime art; `art_source/`: raw sheets excluded from import/export.
- `content/`: Forest and story data.
- `src/app/`: entry scene; `src/shared/`: RNG, clocks, shared content; `src/profile/`: profile stores and sender.
- `src/match/`: authoritative match, AI, encounters, and rules; `src/match/rules/`: rule helpers.
- `src/net/`: protocol and transport; `src/server/`: headless server.
- `src/client/ui/`: shared UI; `title/`, `lobby/`, `match/`, `story/`: player-facing screens; `match/battle/` and `match/camp/`: phase views.
- `tests/`: mirrors `src/`, with runner and support at the root/support folder.
- `tools/dev/`, `tools/art/`, `tools/ci/`: development, art, and CI tools; `tools/run_tests.sh`: test runner.
- `deploy/`: staging; `docs/design/`, `docs/guides/`, `docs/adr/`, `docs/agents/`, `docs/plans/`, `docs/review/`, `docs/history/`, `docs/references/`, `docs/screenshots/`: documentation by kind.
- `.ai/`: task specs (index: `.ai/tasks/README.md`), runner, checkpoint; `.claude/agents/`: agent definitions.

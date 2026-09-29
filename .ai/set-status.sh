#!/usr/bin/env bash
# Usage: .ai/set-status.sh <issue-number> <Todo|In Progress|Done>
# Sets the Status of an issue on GitHub Project #8.
set -euo pipefail
OWNER=qqkiller-programmer-myself-2006
PROJECT_ID=PVT_kwHODsnRW84Bkzjh
STATUS_FIELD=PVTSSF_lAHODsnRW84BkzjhzhjizL0
case "$2" in
  Todo) OPT=f75ad846 ;;
  "In Progress") OPT=47fc9ee4 ;;
  Done) OPT=98236657 ;;
  *) echo "unknown status: $2" >&2; exit 1 ;;
esac
ITEM=$(gh project item-list 8 --owner "$OWNER" --limit 200 --format json \
  --jq ".items[] | select(.content.number == $1) | .id")
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM" --field-id "$STATUS_FIELD" --single-select-option-id "$OPT" >/dev/null
echo "#$1 -> $2"

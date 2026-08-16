#!/bin/bash
# PostToolUse 훅 — PLAN.md 의 계약 절이 바뀌면 레포 담당 세션 전부에 통지
#
# 등록 (~/.claude/settings.json):
#   "PostToolUse": [{ "matcher": "Edit|Write",
#     "hooks": [{ "type": "command", "command": "<grove>/hooks/plan-notify.sh" }] }]
#
# 왜 계약 절만 보나 — PLAN.md 는 체크리스트·메모까지 담고 있어서 편집이 잦음.
# 저장할 때마다 뿌리면 레포 세션이 노이즈에 묻히고 토큰만 씀. 다른 레포에
# 영향을 주는 건 계약뿐이라 거기만 감시함
#
# 통지 내용에 **바뀐 부분의 diff** 를 실어보냄. "바뀌었다" 만 알리면 각 세션이
# 전문을 다시 읽고 뭐가 달라졌는지 스스로 찾아야 함

set -uo pipefail

input="$(cat)"

read -r tool_name file_path <<EOF
$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(" "); sys.exit(0)
print(d.get("tool_name", "-"), (d.get("tool_input") or {}).get("file_path", "-"))
' 2>/dev/null)
EOF

case "$tool_name" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
case "$file_path" in */PLAN.md) ;; *) exit 0 ;; esac
[ -f "$file_path" ] || exit 0

GROVE="$(command -v grove || true)"
[ -n "$GROVE" ] || exit 0

wt="$(cd "$(dirname "$file_path")" && pwd)"
name="$(basename "$wt")"

# 워크트리 루트의 PLAN.md 만 대상 (레포 안에 있는 동명 파일은 무시)
trees="$("$GROVE" paths trees 2>/dev/null)" || exit 0
[ -n "$trees" ] || exit 0
[ "$wt" = "$trees/$name" ] || exit 0

# 계약 절만 뽑음. 한국어·영어 제목 모두 인식
section="$(python3 - "$file_path" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r'^##+\s*(계약|Contract)\b.*?$(.*?)(?=^##\s|\Z)', text, re.M | re.S)
sys.stdout.write(m.group(2).strip() if m else "")
PY
)"
[ -n "$section" ] || exit 0

store="$wt/.grove"
mkdir -p "$store"
prev="$store/contract.md"

if [ ! -f "$prev" ]; then
    printf '%s\n' "$section" > "$prev"     # 첫 기록 — 통지하지 않음
    exit 0
fi

if printf '%s\n' "$section" | diff -q "$prev" - >/dev/null 2>&1; then
    exit 0                                  # 계약은 그대로
fi

changed="$(printf '%s\n' "$section" | diff -u "$prev" - | tail -n +3 | head -40)"
printf '%s\n' "$section" > "$prev"

"$GROVE" tell "$name" "PLAN.md 의 계약이 바뀌었다. 바뀐 부분:

$changed

워크트리 루트의 PLAN.md 를 다시 읽고, 네가 맡은 레포에 영향이 있는지 보고해라.
영향이 있으면 무엇을 어떻게 고칠지 먼저 말하고, 그 다음에 손대라." >/dev/null 2>&1 || true

exit 0

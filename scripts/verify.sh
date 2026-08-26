#!/usr/bin/env bash
# API-level smoke test against a running erupt app: login -> menu list -> query each table.
# Read-only, creates no data. Exits non-zero if any step fails.
# Usage: verify.sh [port] [account] [password]
set -euo pipefail

PORT="${1:-8080}"
ACCOUNT="${2:-erupt}"
PASSWORD="${3:-erupt}"
BASE="http://localhost:$PORT"

command -v python3 >/dev/null || { echo "[verify] python3 required" >&2; exit 1; }

echo "[verify] 1/4 homepage..." >&2
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$BASE/")
[ "$CODE" = "200" ] || { echo "[verify] FAIL: homepage HTTP $CODE" >&2; exit 1; }

echo "[verify] 2/4 login as $ACCOUNT..." >&2
# pwdTransferEncrypt (default on): url-encode then base64 x3
PWD3=$(python3 - "$PASSWORD" <<'EOF'
import base64, sys, urllib.parse
s = urllib.parse.quote(sys.argv[1]).encode()
for _ in range(3): s = base64.b64encode(s)
print(s.decode())
EOF
)
TOKEN=$(curl -s --max-time 10 -X POST "$BASE/erupt-api/login" \
    -H 'Content-Type: application/json' \
    -d "{\"account\":\"$ACCOUNT\",\"pwd\":\"$PWD3\"}" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
if not d.get('pass'): sys.exit('login failed: ' + str(d.get('reason')))
print(d['token'])")

echo "[verify] 3/4 menu list..." >&2
MENUS=$(curl -s --max-time 10 "$BASE/erupt-api/menu" -H "token: $TOKEN" \
    | python3 -c "
import sys, json
tables = [m['value'] for m in json.load(sys.stdin) if m.get('type') == 'table' and m.get('value')]
if not tables: sys.exit('no table menus found')
print('\n'.join(tables))")
echo "$MENUS" | sed 's/^/[verify]   table: /' >&2

echo "[verify] 4/4 query each table..." >&2
FAIL=0
while IFS= read -r ERUPT; do
    RESULT=$(curl -s --max-time 10 -X POST "$BASE/erupt-api/data/table/$ERUPT" \
        -H "token: $TOKEN" -H "erupt: $ERUPT" -H 'Content-Type: application/json' \
        -d '{"pageIndex":1,"pageSize":1}' \
        | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print('rows=' + str(d.get('total', '?')) if 'total' in d else 'ERROR: ' + str(d.get('message') or d)[:80])
except Exception as e:
    print('ERROR: ' + str(e))")
    case "$RESULT" in
        ERROR*) echo "[verify]   $ERUPT -> $RESULT" >&2; FAIL=1 ;;
        *)      echo "[verify]   $ERUPT -> $RESULT" >&2 ;;
    esac
done <<< "$MENUS"

[ "$FAIL" = "0" ] && echo "[verify] PASS: all checks OK" >&2 || { echo "[verify] FAIL: some tables errored" >&2; exit 1; }

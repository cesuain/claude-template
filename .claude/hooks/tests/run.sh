#!/usr/bin/env bash
# Regression tests for check-code.sh / guard-files.sh.
# Each "// expect: RULE" marker in a fixture must be reported on that line; nothing else may be reported.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
hooks="$(dirname "$here")"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0

for f in "$here"/fixtures/*; do
  name=$(basename "$f"); cp "$f" "$tmp/$name"
  out=$(jq -n --arg p "$tmp/$name" '{tool_name:"Edit",tool_input:{file_path:$p}}' \
    | CLAUDE_PROJECT_DIR="$tmp" "$hooks/check-code.sh" 2>&1 >/dev/null)
  got=$(grep -oE "^$tmp/$name:[0-9]+ \[[A-Z-]+\]" <<<"$out" | sed -E "s#^$tmp/##; s/ \[/:/; s/\]//" | sort -u)
  want=$(grep -nE 'expect: ' "$f" | sed -E 's/^([0-9]+):.*expect: ([A-Z,-]+).*/\1 \2/' \
    | while read -r ln rules; do for r in ${rules//,/ }; do echo "$name:$ln:$r"; done; done | sort -u)
  if [ "$got" = "$want" ]; then
    echo "PASS check-code $name ($(grep -c . <<<"$want" | tr -d ' ') expected findings)"
  else
    fail=1; echo "FAIL check-code $name"
    diff <(echo "$want") <(echo "$got") | sed 's/^</  missing:/; s/^>/  unexpected:/' | grep -E 'missing|unexpected'
  fi
done

# guard-files.sh
g() { jq -n --arg t "$1" --arg p "$2" '{tool_name:$t,tool_input:{file_path:$p}}' | CLAUDE_PROJECT_DIR="$tmp" "$hooks/guard-files.sh" >/dev/null 2>&1; echo $?; }
mkdir -p "$tmp/prisma/migrations/20250101_init" "$tmp/prisma/migrations/20250202_add_orders"
touch "$tmp/prisma/migrations/20250101_init/migration.sql" "$tmp/prisma/migrations/20250202_add_orders/migration.sql"
expect() { local got; got=$(g "$2" "$3"); if [ "$got" = "$1" ]; then echo "PASS guard $2 $3 -> $1"; else fail=1; echo "FAIL guard $2 $3 -> got $got want $1"; fi; }
expect 2 Read  "$tmp/.env"
expect 2 Read  "$tmp/apps/web/.env.local"
expect 2 Write "$tmp/.env.production"
expect 0 Read  "$tmp/.env.example"
expect 0 Write "$tmp/.env.example"
expect 2 Edit  "$tmp/pnpm-lock.yaml"
expect 2 Edit  "$tmp/apps/web/.next/server/page.js"
expect 2 Edit  "$tmp/apps/api/dist/index.js"
expect 0 Edit  "$tmp/apps/web/app/page.tsx"
expect 0 Read  "$tmp/pnpm-lock.yaml"
expect 2 Edit  "$tmp/prisma/migrations/20250101_init/migration.sql"
expect 0 Edit  "$tmp/prisma/migrations/20250202_add_orders/migration.sql"

# committed migration is treated as applied even when it is the newest
( cd "$tmp" && git init -q && git add prisma && git -c user.email=t@t -c user.name=t commit -qm init )
expect 2 Edit  "$tmp/prisma/migrations/20250202_add_orders/migration.sql"

# stop-typecheck.sh: respects stop_hook_active; reports failing typecheck with exit 2
s() { jq -n --argjson a "$1" '{stop_hook_active:$a}' | CLAUDE_PROJECT_DIR="$tmp" "$hooks/stop-typecheck.sh" >/dev/null 2>&1; echo $?; }
printf '{"scripts":{"typecheck":"echo \\"src/a.ts(1,7): error TS2322: bad\\" && exit 1"}}' > "$tmp/package.json"
echo 'const a: number = "x";' > "$tmp/a.ts"
r=$(s true);  [ "$r" = 0 ] && echo "PASS stop active -> 0" || { fail=1; echo "FAIL stop active -> $r"; }
r=$(s false); [ "$r" = 2 ] && echo "PASS stop failing typecheck -> 2" || { fail=1; echo "FAIL stop failing typecheck -> $r"; }
exit $fail

#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): format + lint + mechanical rule scan on the edited file.
# Exit 2 feeds findings back to Claude. Rules (see typescript-optimization + instrumentation skills):
#   TS-AS        `x as T` assertion (as const allowed; import/export aliases ignored)
#   TS-ANGLE     `<T>x` assertion (.ts only)
#   TS-NONNULL   non-null / definite-assignment `!`
#   TS-ANY       explicit `any`
#   TS-IGNORE    @ts-ignore / @ts-nocheck / @ts-expect-error
#   SILENT-CATCH catch / .catch without reportError|logger|console.error|throw
#   JSON-NO-ZOD  JSON.parse not validated by a Zod .parse/.safeParse within 2 lines
# Skips tests, stories, .d.ts and intentional fixtures.
set -uo pipefail
input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -z "$file" ] || [ ! -f "$file" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$file" in
  *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs|*.scss|*.css) ;;
  *) exit 0 ;;
esac
case "$file" in
  *.d.ts|*.test.*|*.spec.*|*.stories.*|*/__tests__/*|*/e2e/*|*/node_modules/*) exit 0 ;;
esac
# Repo tooling (eval runner + fixtures, hook tests) is not product code
case "${file#"$root"/}" in
  evals/*|.claude/*) exit 0 ;;
esac

# Find a local binary walking up from the file to the project root (monorepo-aware).
find_bin() {
  local dir
  dir=$(dirname "$file")
  while :; do
    [ -x "$dir/node_modules/.bin/$1" ] && { echo "$dir/node_modules/.bin/$1"; return 0; }
    [ "$dir" = "$root" ] || [ "$dir" = "/" ] && break
    dir=$(dirname "$dir")
  done
  [ -x "$root/node_modules/.bin/$1" ] && echo "$root/node_modules/.bin/$1"
}

report=""
if prettier=$(find_bin prettier) && [ -n "$prettier" ]; then
  "$prettier" --write --log-level warn "$file" >/dev/null 2>&1 || true
fi
case "$file" in
  *.scss|*.css) ;;
  *)
    if eslint=$(find_bin eslint) && [ -n "$eslint" ]; then
      if ! lint_out=$("$eslint" --fix --quiet "$file" 2>&1); then
        report+="ESLint errors:"$'\n'"$(echo "$lint_out" | grep -E '^\s+[0-9]+:[0-9]+' | head -20)"$'\n'
      fi
    fi
    ;;
esac

case "$file" in
  *.scss|*.css) scan="" ;;
  *) scan=$(perl "$(dirname "$0")/lib/scan-code.pl" "$file") ;;
esac

[ -n "$scan" ] && report+="Rule violations (fix before continuing):"$'\n'"$scan"$'\n'
if [ -n "$report" ]; then
  printf '%s' "$report" >&2
  exit 2
fi
exit 0

#!/usr/bin/env bash
# PreToolUse (Read|Edit|Write|MultiEdit): block protected files. Exit 2 = block, stderr goes to Claude.
#  - .env / .env.* (read or write) except .env.example
#  - lockfiles, build output, node_modules (write)
#  - applied migrations (write): committed to HEAD, or not the newest migration directory
set -uo pipefail
input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input")
file=$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input")
[ -z "$file" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$file" in
  /*) abs="$file" ;;
  *) abs="$root/$file" ;;
esac
rel="${abs#"$root"/}"
base=$(basename "$abs")

block() { echo "BLOCKED by guard-files.sh: $1 ($rel)" >&2; exit 2; }

# 1. Secrets — applies to Read too
if [[ "$base" == ".env" || "$base" == .env.* ]] && [[ "$base" != ".env.example" ]]; then
  block "env files are off-limits. Document new variables in .env.example and ask the user to set them"
fi

[ "$tool" = "Read" ] && exit 0

# 2. Lockfiles
case "$base" in
  pnpm-lock.yaml|package-lock.json|yarn.lock|bun.lockb|bun.lock)
    block "lockfiles are generated. Run the package manager instead" ;;
esac

# 3. Build output / dependencies
if [[ "/$rel" =~ /(node_modules|\.next|dist|build|out|coverage|storybook-static|\.turbo|playwright-report|test-results)/ ]]; then
  block "generated/build output must not be edited by hand"
fi

# 4. Applied migrations (prisma/migrations/<dir>/..., supabase/migrations/<file>.sql)
if [[ "$rel" =~ (^|/)prisma/migrations/([^/]+)/ ]]; then
  mig_dir="${abs%/"${BASH_REMATCH[2]}"/*}"
  this="${BASH_REMATCH[2]}"
  newest=$(ls -1 "$mig_dir" 2>/dev/null | grep -E '^[0-9]' | sort | tail -1)
  if git -C "$root" cat-file -e "HEAD:$rel" 2>/dev/null; then
    block "migration is committed (treated as applied). Create a new migration with --create-only instead"
  fi
  if [ -n "$newest" ] && [ "$this" != "$newest" ] && [ -d "$mig_dir/$this" ]; then
    block "only the newest, uncommitted migration ($newest) may be edited. Create a new migration instead"
  fi
fi
if [[ "$rel" =~ (^|/)supabase/migrations/[^/]+\.sql$ ]]; then
  if git -C "$root" cat-file -e "HEAD:$rel" 2>/dev/null; then
    block "supabase migration is committed (treated as applied). Add a new migration instead"
  fi
fi
exit 0

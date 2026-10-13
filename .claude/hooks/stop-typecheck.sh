#!/usr/bin/env bash
# Stop: run `pnpm typecheck` when TS files changed. Exit 2 feeds errors back so Claude keeps fixing.
# Respects stop_hook_active (no infinite loop) and caches the last green tree hash.
set -uo pipefail
input=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -f package.json ] || exit 0
jq -e '.scripts.typecheck' package.json >/dev/null 2>&1 || exit 0

changed=$(git status --porcelain --untracked-files=all 2>/dev/null | awk '{print $NF}' | grep -E '\.(ts|tsx|mts|cts)$' || true)
[ -z "$changed" ] && exit 0

# Skip if this exact TS state already passed
hash=$( { git diff HEAD -- '*.ts' '*.tsx' '*.mts' '*.cts' 2>/dev/null; while read -r f; do [ -f "$f" ] && cat "$f"; done <<<"$changed"; } | shasum | cut -d' ' -f1)
cache_dir="${TMPDIR:-/tmp}/claude-typecheck"
mkdir -p "$cache_dir"
cache_file="$cache_dir/$(printf '%s' "$root" | shasum | cut -d' ' -f1)"
[ -f "$cache_file" ] && [ "$(cat "$cache_file")" = "$hash" ] && exit 0

if out=$(pnpm -s typecheck 2>&1); then
  echo "$hash" > "$cache_file"
  exit 0
fi
{
  echo "pnpm typecheck failed. Fix these errors without type assertions or any (see typescript-optimization skill):"
  errs=$(echo "$out" | grep -E 'error TS|: error' || true)
  if [ -n "$errs" ]; then
    echo "$errs" | head -40
    [ "$(echo "$errs" | wc -l)" -gt 40 ] && echo "... (truncated)"
  else
    echo "$out" | tail -40
  fi
} >&2
exit 2

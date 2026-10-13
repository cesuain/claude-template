#!/usr/bin/env bash
# SessionStart: print repo context. Stdout is added to Claude's context.
# Never reads .env contents — only checks existence.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0
cat >/dev/null  # drain stdin JSON (unused)

echo "## Session context"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  echo "- Branch: ${branch:-detached HEAD}"
  echo "- Uncommitted files: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  echo "- Last commits:"
  git log --oneline -5 2>/dev/null | sed 's/^/  - /'
else
  echo "- Not a git repository"
fi

if [ ! -f .env ]; then
  echo "- WARNING: .env missing — copy .env.example and fill it in (Claude must not create or read it)."
fi

sb_url="${STORYBOOK_MCP_URL:-http://localhost:6006/mcp}"
sb_root="${sb_url%/mcp}"
if curl -s -o /dev/null -m 1 "$sb_root" 2>/dev/null; then
  echo "- Storybook: running at $sb_root (storybook MCP available)"
else
  echo "- Storybook: not running (start with \`pnpm storybook\` to use the storybook MCP)"
fi
exit 0

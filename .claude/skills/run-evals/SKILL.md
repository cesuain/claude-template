---
name: run-evals
description: Run the global agent/skill evals in isolated git worktrees and report pass rate per tag against the 85% threshold. Use when the user runs /run-evals optionally with eval ids or tags.
disable-model-invocation: true
argument-hint: "[eval ids | tags] (comma-separated, empty = all)"
---

# /run-evals $ARGUMENTS

1. Preconditions: git repo with at least one commit (`git rev-parse HEAD`), `claude` CLI on PATH. If not met, tell the user what's missing.
2. Run (long-running, so use `run_in_background`):
   ```bash
   node evals/run.mjs $ARGUMENTS
   ```
   Options: `--concurrency 2`, `--model <id>`, `--threshold 0.85`, `--keep-worktrees`.
3. When done, read `evals/results/<latest>/summary.json` and report:
   - overall pass rate vs threshold (PASS/FAIL)
   - table: tag → pass rate (expectations passed / total)
   - failed evals: id, failed expectations, grader evidence (one line each)
4. For each failure, name the likely fix location (skill / agent / hook / CLAUDE.md) using the rule map in the eval's tags. Don't edit anything unless the user asks.

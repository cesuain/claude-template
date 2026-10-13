# Eval fixtures
Files here intentionally violate project rules. `run.mjs` copies an eval's `files` (paths relative to this folder) to the same relative path at the root of the eval worktree. `check-code.sh` skips `evals/fixtures/**` so they can stay broken here.

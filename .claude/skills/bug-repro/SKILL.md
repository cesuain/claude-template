---
name: bug-repro
description: Reproduce and fix a bug from a Sentry issue or description. Goes Sentry → Playwright repro → failing test → fix → re-verify. Use when the user runs /bug-repro with a Sentry issue URL/ID or bug description.
disable-model-invocation: true
argument-hint: <Sentry issue URL/ID | bug description>
---

# /bug-repro $ARGUMENTS

## 1. Investigate (qa-engineer)
- Sentry input → `sentry` MCP: issue details, latest event stack trace, breadcrumbs, tags (tenantId, release, browser, route), frequency/first seen. Use Seer analysis if available.
- Description input → search Sentry for matching issues, then ask the user for missing steps if none.
- Output: suspected area (web/api), exact steps, environment, and the owning agent.

## 2. Reproduce (qa-engineer)
- UI: `playwright` MCP replays the steps (seed data / test tenant). `chrome-devtools` MCP for console/network/perf evidence.
- API: `postman` MCP or supertest with the failing payload shape (never real PII from the event).
- Can't reproduce after 2 approaches → report what was tried and ask the user.

## 3. Failing test (qa-engineer)
Encode the repro at the lowest level that catches it (unit > component > API > e2e). Run it and **confirm it fails for the right reason**. Commit nothing yet.

## 4. Fix (owning agent)
**nextjs-frontend-engineer** or **node-api-engineer** fixes the root cause (not the symptom). Also fix the instrumentation gap that hid it (silent catch, missing tags, missing schema report).

## 5. Re-verify (qa-engineer)
Failing test now passes, the full related suite passes, the Playwright repro no longer reproduces, `pnpm typecheck && pnpm lint && pnpm test`. QA report in the fixed format.

## 6. Summary
Root cause, fix, test added, Sentry issue link (suggest resolving in the next release, but don't change Sentry state without asking).

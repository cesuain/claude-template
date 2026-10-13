---
name: feature
description: End-to-end feature workflow. Orchestrates ui-ux-designer and node-api-engineer for design, waits for approval, then contracts, backend and frontend build, and a QA verify loop. Use when the user runs /feature with a description or Figma URL.
disable-model-invocation: true
argument-hint: <feature description | Figma URL>
---

# /feature $ARGUMENTS

You are the orchestrator. Delegate with the Agent tool (`subagent_type` = agent name). Don't write feature code yourself. Keep a running checklist with TaskCreate/TodoWrite.

## Phase 1: Design (parallel)
Launch both in one message:
- **ui-ux-designer**: "Design `$ARGUMENTS`. If a Figma URL is given, pull context/variables. Produce `docs/design/<slug>.md` (all states incl. loading/empty/error, a11y WCAG 2.2 AA, LCP candidate) and the stories/variants needed. Return the spec path + open questions."
- **node-api-engineer**: "Design the backend for `$ARGUMENTS`. Answer the full system-design checklist in `docs/design-notes/<slug>.md` with a diagram and a Zod contract sketch. Don't implement. Return the note path + open questions."

## Phase 2: Approval (blocking)
Summarize both designs for the user in ≤ 15 lines: scope, endpoints, data model diff, states, risks, open questions. **Stop and ask for approval** (AskUserQuestion). Apply requested changes via the owning agent and re-ask. Don't proceed without an explicit yes.

## Phase 3: Contracts
**node-api-engineer**: write the Zod contracts in `packages/contracts` from the approved note. Then **nextjs-frontend-engineer** reviews them against the design spec (read-only review, reply "approved" or the requested changes). Iterate until approved.

## Phase 4: Build
1. **node-api-engineer**: migration (`--create-only` + RLS), repositories → services → controllers → routes, tests, `/api-check` on each new route.
2. Then **nextjs-frontend-engineer**: implement UI against contracts and spec (skeletons, empty/error, instrumentation, perf).
   Run them in parallel only if the frontend can build against contract mocks (MSW). Otherwise run them sequentially.

## Phase 5: QA verify loop (max 3 iterations)
**qa-engineer**: verify against acceptance criteria, design spec states, contracts, cross-tenant security, perf targets, instrumentation. Report in the fixed format.
- Verdict FAIL → route each failure to its owner agent, then re-run QA. Max **3** QA rounds.
- Still failing after 3 → stop, report remaining failures to the user with a recommendation.

## Phase 6: Summary
Output: what was built (files by area), endpoints, migrations (pending apply?), QA verdict + perf table, follow-ups, and anything not verified. Don't push or open a PR unless asked.

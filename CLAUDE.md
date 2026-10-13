# claude-template

Full-stack TypeScript monorepo. This file is project memory: keep it short; details live in skills (`.claude/skills/`) and agents (`.claude/agents/`).

## Stack

| Layer | Tech |
|---|---|
| Web | Next.js (App Router, RSC, Server Actions) · React · Tailwind CSS v4 · shadcn/ui · SCSS modules (only when Tailwind can't) |
| API | Node.js + Express (routes → controllers → services → repositories → jobs → integrations) |
| Data | Supabase (Auth, Storage, Realtime, RLS) · Prisma (`DATABASE_URL` pooled at runtime, `DIRECT_URL` for migrations) |
| Contracts | Zod in `packages/contracts` — the single source of types for web + api |
| Quality | Vitest · Playwright · Storybook · Sentry |

## Folder ownership

| Path | Owner agent |
|---|---|
| `apps/web/**` (except tokens) | nextjs-frontend-engineer |
| `apps/web/app/globals.css`, `components/ui/**` variants, `**/*.stories.tsx`, `docs/design/**` | ui-ux-designer |
| `apps/api/**`, `prisma/**`, `supabase/**` | node-api-engineer |
| `packages/contracts/**` | node-api-engineer (author) — frontend reviews |
| `**/*.test.ts(x)`, `e2e/**`, `evals/**` | qa-engineer |
| `docs/design-notes/**` | node-api-engineer (system-design skill) |

## Commands

```bash
pnpm dev            # web + api
pnpm typecheck      # tsc --noEmit across workspaces (Stop hook runs this)
pnpm lint           # eslint
pnpm test           # vitest
pnpm test:e2e       # playwright
pnpm storybook      # :6006 (exposes /mcp via @storybook/addon-mcp)
pnpm build
pnpm prisma migrate dev --create-only --name <name>   # then add RLS SQL (asks permission)
node evals/run.mjs [ids|tags]                          # global evals, threshold 85%
.claude/hooks/tests/run.sh                             # hook regex/guard regression tests
```

## Agent routing

| Task | Agent | Skills | MCP |
|---|---|---|---|
| Pages, components, RSC, Server Actions, Supabase SSR | nextjs-frontend-engineer | coding-standards, typescript-optimization, performance-optimization, instrumentation | figma, storybook, chrome-devtools, playwright |
| Endpoints, services, Prisma, RLS, queues, webhooks, jobs | node-api-engineer | system-design, typescript-optimization, instrumentation, supabase-prisma, coding-standards | postgres, supabase, postman, sentry |
| Tokens, variants, specs, stories, a11y | ui-ux-designer | coding-standards, performance-optimization | figma, storybook |
| Tests, bug repro, security, perf verification, evals | qa-engineer | instrumentation, coding-standards, typescript-optimization, performance-optimization | playwright, chrome-devtools, postman, sentry |

Workflow slash commands: `/feature`, `/design-sync`, `/bug-repro`, `/api-check`, `/run-evals`.

## Non-negotiables

1. **No type assertions** (`as X`, `<X>expr`, `!`, `@ts-ignore`). `as const` and `satisfies` are fine.
2. **No `any`** — use `unknown` + narrowing / Zod.
3. **Zod at every external boundary**: request bodies, params, searchParams, env, webhooks, third-party responses, `JSON.parse`, LLM output.
4. **Never re-create existing types** — derive (`z.infer`, `Pick`/`Omit`, Prisma payload types, `ComponentProps`, `ReturnType`).
5. **No silent catches** — every `catch`/`.catch` logs via `reportError` or rethrows.
6. **Skeletons for all async UI** — same box size as the loaded content (CLS < 0.1).
7. **Tenant-scoped queries + RLS** — Prisma bypasses RLS, so every repository query filters by `tenantId`; every table has RLS policies.
8. **Never read or write `.env*`** (only `.env.example`). Enforced by permissions + `guard-files.sh`.

Mechanical rules 1, 2, 3 (JSON.parse), 5 and 8 are enforced by hooks in `.claude/hooks/`; all are covered by `evals/global.evals.json`.

## Workflow

1. **Plan first** — non-trivial backend work answers the `system-design` checklist in a design note; UI work gets a spec with loading/empty/error states.
2. **Contracts first** — Zod schemas in `packages/contracts`, reviewed by both engineers.
3. **API** — implement + Postman/contract tests (`/api-check`).
4. **Web** — consume contracts, skeletons, instrumentation.
5. **QA verifies before "done"** — qa-engineer report verdict must be PASS. Nobody else declares a feature done.

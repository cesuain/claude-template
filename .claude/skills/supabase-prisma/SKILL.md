---
name: supabase-prisma
description: Supabase + Prisma data-layer playbook. Use this skill WHENEVER you touch schema.prisma, migrations, RLS policies, repositories, database connections, Supabase Auth (web or api), Storage uploads/downloads, Realtime channels, pagination or Prisma error handling. Prisma bypasses RLS, so read this before writing any query.
---

# Supabase + Prisma

## Key facts
- **Prisma connects as a privileged role and BYPASSES RLS.** Every repository method takes `tenantId` and filters by it, with no exceptions. RLS is defense in depth for Supabase client paths (browser, Realtime, Storage, PostgREST).
- Runtime uses pooled `DATABASE_URL` (port 6543, `pgbouncer=true`). Migrations use `DIRECT_URL` (5432). See `references/connections.md`.
- Never run `prisma migrate reset` or `db push` against shared DBs (denied/asks in settings).

## Workflow: schema change
1. Edit `prisma/schema.prisma` (every tenant table has `tenantId String @db.Uuid` + `@@index([tenantId, …])`).
2. `pnpm prisma migrate dev --create-only --name <change>` (asks permission).
3. Append the RLS SQL to the **new** `migration.sql` → `references/migrations-rls.md`.
4. Apply: `pnpm prisma migrate dev`. Verify policies with the `supabase` MCP (`list_tables`, advisors) / `postgres` MCP (`pg_policies`).
5. Applied/committed migrations are immutable (guard-files hook). Fix forward with a new migration.

## References
| Task | Load |
|---|---|
| Connection strings, pooling, serverless, client singleton | `references/connections.md` |
| Migrations, RLS template, policies, grants | `references/migrations-rls.md` |
| Auth in web (SSR) and api (JWT), Storage signed URLs, Realtime | `references/auth-storage-realtime.md` |
| Repositories, cursor pagination, transactions, P2002/P2025 mapping | `references/query-patterns.md` |

Evals: `db-*`.

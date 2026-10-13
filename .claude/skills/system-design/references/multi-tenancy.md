# Multi-tenant
- Model: shared schema, `tenantId uuid not null` on every tenant-owned row, FK to `tenants`. Composite indexes lead with `tenantId`.
- **Repositories always filter by tenantId** (Prisma bypasses RLS). Use `findFirst({ where: { id, tenantId } })`, never `findUnique({ where: { id } })` for tenant data.
- **RLS** on every table with membership-based policies (supabase-prisma/migrations-rls).
- Tenant resolution: authenticated membership + route/subdomain, set in `req.ctx` / server context. Never from request body.
- Cross-tenant access → **404** (don't reveal existence).
- Unique constraints are per tenant: `@@unique([tenantId, slug])`.
- Quotas and rate limits per tenant/plan. Queue fairness per tenant.
- Caches, storage paths, realtime channels, search indexes and logs carry tenantId.
- Tests: QA cross-tenant suite for every endpoint.

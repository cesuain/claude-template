# Migrations + RLS

## Flow
```bash
pnpm prisma migrate dev --create-only --name add_orders
# edit prisma/migrations/<ts>_add_orders/migration.sql → append RLS block below
pnpm prisma migrate dev
```

## RLS template (append per new tenant table)
```sql
-- RLS: orders
ALTER TABLE "orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "orders" FORCE ROW LEVEL SECURITY;

-- tenant membership helper (create once)
CREATE OR REPLACE FUNCTION public.is_tenant_member(t uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM memberships m WHERE m.tenant_id = t AND m.user_id = (SELECT auth.uid()));
$$;

CREATE POLICY "orders_select_member" ON "orders" FOR SELECT TO authenticated
  USING ((SELECT public.is_tenant_member("tenantId")));
CREATE POLICY "orders_insert_member" ON "orders" FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_tenant_member("tenantId")));
CREATE POLICY "orders_update_member" ON "orders" FOR UPDATE TO authenticated
  USING ((SELECT public.is_tenant_member("tenantId")))
  WITH CHECK ((SELECT public.is_tenant_member("tenantId")));
CREATE POLICY "orders_delete_admin" ON "orders" FOR DELETE TO authenticated
  USING ((SELECT public.is_tenant_member("tenantId")) AND (SELECT public.has_role("tenantId", 'admin')));

CREATE INDEX IF NOT EXISTS "orders_tenantId_idx" ON "orders" ("tenantId");
```
- Wrap `auth.uid()` / helpers in `(SELECT …)` so Postgres evaluates them once per query (performance).
- Separate policy per command. No `FOR ALL` with `USING (true)`.
- Tables never exposed to clients: enable RLS with **no** policies (deny all for anon/authenticated).
- Storage buckets: policies on `storage.objects` keyed by path prefix `"<tenantId>/…"`:
```sql
CREATE POLICY "tenant_read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'documents' AND (SELECT public.is_tenant_member(((storage.foldername(name))[1])::uuid)));
```
- Verify: `SELECT tablename, policyname, cmd FROM pg_policies WHERE schemaname='public';` and Supabase advisors (supabase MCP `get_advisors`).

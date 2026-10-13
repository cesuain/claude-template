# Auth, Storage, Realtime

## Auth — web (Next.js)
- `@supabase/ssr`: `createServerClient` (RSC, Server Actions, route handlers) with `cookies()`; `createBrowserClient` in client components.
- `middleware.ts` refreshes the session on each request (`supabase.auth.getUser()`).
- Server authorization: `const { data: { user } } = await supabase.auth.getUser()`. Never trust `getSession()` on the server (it's unverified cookie data).
- Tenant: resolved from the membership table for `user.id` + route param/subdomain, and validated, never from client input alone.

## Auth — api (Express)
- `requireAuth` middleware: `Authorization: Bearer <access_token>` → verify JWT (Supabase JWKS / `supabase.auth.getUser(token)`), then Zod-parse the claims.
- `requireTenant`: `x-tenant-id` header or path param → check membership → `req.ctx = { userId, tenantId, role }`.
- Service-role key only in the api/server, never `NEXT_PUBLIC_`.

## Storage
- Paths: `<bucket>/<tenantId>/<entity>/<id>/<filename>`.
- Uploads: api issues `createSignedUploadUrl(path)` after authz and validates content-type/size (Zod) first. The client uploads directly.
- Downloads: `createSignedUrl(path, 60)` (short TTL), or public bucket only for truly public assets.
- Images: transform renditions (`?width=…&quality=…`) or pre-generated sizes (system-design media).

## Realtime
- Use `postgres_changes` (respects RLS for the subscribing user) or Broadcast with private channels (`config: { private: true }`, authorized via `realtime.messages` policies).
- Channel name includes tenant: `tenant:<tenantId>:orders`.
- Client hook subscribes in `useEffect` and **removes the channel in cleanup**. Payloads are Zod-validated before use (`reportSchemaViolation` on failure).

# CDN & edge servers
- Public, tenant-agnostic assets/pages: static/ISR with `revalidate` + tag invalidation (`revalidateTag`). `Cache-Control: public, s-maxage=…, stale-while-revalidate=…`.
- Tenant/user data: `Cache-Control: private, no-store` at CDN. Cache in app layer only with tenantId in the key.
- Media: served from Supabase Storage CDN / image transform URLs with long `max-age` + content-hashed paths (immutable).
- Edge middleware: only cheap work (session refresh, redirects, geo, A/B bucketing). No DB calls, no heavy libs.
- API responses behind CDN: `Vary` on `Authorization`/`Accept-Language` when relevant, or don't cache.
- Invalidation plan stated: what event purges which tag/path.

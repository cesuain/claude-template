# Resource scoping (JS / CSS / data per page and intent)

## JS
- Server Components by default. A `"use client"` boundary pulls its whole import graph into the bundle, so keep it at leaves.
- Heavy client-only widgets (editors, charts, maps, date pickers): `next/dynamic(() => import('./Chart'), { loading: () => <ChartSkeleton/> })`, loaded when shown.
- No barrel imports from big libs (`import { x } from 'lodash'` → `lodash/x`, or native). Check with `@next/bundle-analyzer`.
- Libraries used only on the server (`zod` schemas are fine on both, but `prisma`, `sharp` and SDKs stay server-only) are guarded by `import 'server-only'`.

## CSS
- Tailwind v4 generates only used utilities. SCSS modules are scoped per component. No global imports of component CSS from layouts.
- Third-party CSS imported in the component that uses it, not in `layout.tsx`.

## Data
- Per page: select only the fields the view needs (Prisma `select`, contract response schemas sized to the view).
- Per intent: details on navigation/open, not prefetched for every list item. Use `<Link prefetch>` defaults wisely (viewport prefetch only for likely next steps).
- Paginate everything (cursor, max 100). Never return unbounded lists.
- Cache: `fetch` cache/revalidate tags or `unstable_cache` for shared, non-tenant-specific data only. Tenant data is never cached across tenants (key includes tenantId).

## Route segments
- Route groups split layouts so marketing pages don't ship app shell JS.
- `loading.tsx` per segment that awaits data.

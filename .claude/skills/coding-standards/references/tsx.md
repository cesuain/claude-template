# TSX standards (React / Next.js App Router)

## Server vs client
- Server Components by default. Add `"use client"` only for state, effects, event handlers or browser APIs, and push it to the **leaf** component.
- Never pass functions or class instances from server to client props. Pass serializable data.
- Server Actions: `"use server"` file or inline. First line validates input with the contract schema (`safeParse`). Returns a typed result union `{ ok: true, data } | { ok: false, error }`. Never throw raw errors to the client.

## Components
- Props type: `type Props = ComponentProps<typeof Button> & { … }`, or contract types. Never re-declare a shape that exists.
- Extend shadcn primitives through `cva` variants (owned by ui-ux-designer). Don't fork the component.
- Use `cn()` for class merging. No string concatenation of classes.
- Lists: stable `key` from the id (never the index for dynamic lists).
- Conditional rendering: early return for loading/empty/error. Avoid nested ternaries.

## Async states (required)
```tsx
// app/(app)/orders/page.tsx
export default function Page() {
  return (
    <Suspense fallback={<OrdersTableSkeleton rows={10} />}>
      <OrdersTable />
    </Suspense>
  );
}
```
- The skeleton renders the **same box** (height, columns, gaps) as the loaded component.
- Empty state: message plus a primary action. Error state: `error.tsx` boundary with `reportError(error)` in an effect plus a retry (`reset`).

## Styling
- Tailwind utilities with token-backed classes (`bg-surface`, `text-fg-muted`). No hex values or arbitrary colors (`bg-[#123456]`).
- SCSS module only when Tailwind can't express it (see `scss.md`).

## Accessibility
- Semantic elements first (`button`, `nav`, `main`, `label`). Every input has a label. Icon buttons have `aria-label`.
- Focus is visible. Modals trap and return focus (use shadcn Dialog).

## Data
- Fetch on the server. Client fetching only for user-driven interactions/realtime (Supabase channel in a client hook with cleanup).
- `searchParams` → `Schema.safeParse(await searchParams)`, never read raw.

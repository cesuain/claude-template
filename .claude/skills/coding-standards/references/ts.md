# TS standards (API, services, contracts, utils)

## Contracts (`packages/contracts`)
- One file per resource: `order.ts` exports `OrderSchema`, `CreateOrderInput`, `ListOrdersQuery`, `OrderListResponse`, plus inferred types (`export type Order = z.infer<typeof OrderSchema>`).
- Error envelope shared: `{ error: { code, message, details? } }`.
- Pagination: `{ items, nextCursor: string | null }`, `limit` max 100 enforced in the schema.

## Layers (api)
- **routes** wire middleware: `requireAuth`, `requireTenant`, `rateLimit(policy)`, `validate({ body, query, params })`.
- **controllers**: `(req, res) => service.call(ctx, input)`. No Prisma, no business rules.
- **services** take `ctx: { tenantId, userId, role }` as the first param. They own transactions (`prisma.$transaction`).
- **repositories**: the only Prisma import. Signature `(tenantId: string, …)`. Return Prisma payload types (`Prisma.OrderGetPayload<…>`).
- **integrations**: `fetchJson(url, ResponseSchema, { provider, endpoint })`. Never return unvalidated JSON.
- **jobs**: payload schema validated on consume. Idempotency key checked before side effects.

## Errors
- Throw typed domain errors (`NotFoundError`, `ConflictError`, `ForbiddenError`). The error middleware maps them to HTTP and calls `reportError` for 5xx.
- `catch (err: unknown)`: narrow (`err instanceof X`), log or rethrow. Never `catch {}`.

## Functions
- Explicit return types on exported functions.
- Prefer discriminated unions over boolean flags. Exhaustive `switch` with `const _exhaustive: never = x`.
- No default exports outside Next.js route files.
- `async` functions always `await` or return their promises. No floating promises (eslint `no-floating-promises`).

## Env
- `env.ts` parses `process.env` with Zod once at boot. Import `env`, never `process.env.X` elsewhere.

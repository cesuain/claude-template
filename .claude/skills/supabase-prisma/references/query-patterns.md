# Query patterns

## Repository shape
```ts
export const orderRepository = {
  findById(tenantId: string, id: string) {
    return prisma.order.findFirst({ where: { id, tenantId } }); // findFirst, never findUnique by id alone
  },
  async list(tenantId: string, { cursor, limit }: ListOrdersQuery) {
    const rows = await prisma.order.findMany({
      where: { tenantId, deletedAt: null },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      select: orderListSelect,
    });
    const hasMore = rows.length > limit;
    const items = hasMore ? rows.slice(0, limit) : rows;
    return { items, nextCursor: hasMore ? (items.at(-1)?.id ?? null) : null };
  },
  update(tenantId: string, id: string, data: Prisma.OrderUpdateInput) {
    // updateMany scopes by tenant; check count to detect not-found / cross-tenant
    return prisma.order.updateMany({ where: { id, tenantId }, data });
  },
};
export type OrderListItem = Prisma.OrderGetPayload<{ select: typeof orderListSelect }>;
```
- Cursor pagination with a stable tiebreaker (`id`). `limit` max 100 from the contract schema.
- `select` only what the view needs, defined once as `const orderListSelect = { … } satisfies Prisma.OrderSelect`.
- N+1: use `include`/`select` relations or batch `where: { id: { in: ids }, tenantId }`.

## Errors
```ts
import { Prisma } from '@prisma/client';
export function mapPrismaError(err: unknown): never {
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') throw new ConflictError('unique_violation', { target: String(err.meta?.target ?? '') });
    if (err.code === 'P2025') throw new NotFoundError('record_not_found');
  }
  throw err;
}
```
- `updateMany`/`deleteMany` with `count === 0` → `NotFoundError` (covers cross-tenant: return 404, not 403).

## Transactions
- `prisma.$transaction(async (tx) => { … })` for multi-write invariants. Pass `tx` to repository methods (`repo.create(tx, tenantId, …)`).
- Outbox rows written in the same transaction (system-design `event-streaming`).
- Optimistic concurrency: `version Int @default(0)` + `updateMany({ where: { id, tenantId, version } , data: { version: { increment: 1 } } })`.

## Performance
- `EXPLAIN (ANALYZE, BUFFERS)` via postgres MCP for new list/filter queries. Composite index leading with `tenantId`.

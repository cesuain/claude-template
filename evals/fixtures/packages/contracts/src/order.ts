import { z } from 'zod';

export const OrderStatus = z.enum(['draft', 'paid', 'shipped', 'cancelled']);
export const OrderSchema = z.object({
  id: z.string().uuid(),
  tenantId: z.string().uuid(),
  number: z.string().max(32),
  status: OrderStatus,
  totalCents: z.number().int().nonnegative(),
  createdAt: z.string().datetime(),
});
export type Order = z.infer<typeof OrderSchema>;

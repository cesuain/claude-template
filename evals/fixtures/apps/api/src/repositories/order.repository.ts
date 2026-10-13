import { prisma } from '../db';

export const orderRepository = {
  findById(id: string) {
    return prisma.order.findUnique({ where: { id } });
  },
  list(page: number) {
    return prisma.order.findMany({ skip: page * 50, take: 50 });
  },
  create(data: { tenantId: string; number: string; totalCents: number }) {
    return prisma.order.create({ data });
  },
};

'use client';
import { useEffect, useState } from 'react';

interface Order {
  id: string;
  tenantId: string;
  number: string;
  status: 'draft' | 'paid' | 'shipped' | 'cancelled';
  totalCents: number;
  createdAt: string;
}

export function OrderSummary({ id }: { id: string }) {
  const [order, setOrder] = useState<Order | null>(null);
  useEffect(() => {
    fetch(`/api/orders/${id}`)
      .then((r) => r.json())
      .then((d) => setOrder(d as Order));
  }, [id]);
  if (!order) return null;
  return (
    <div>
      <h2>Order {order.number}</h2>
      <p>{order.status}</p>
    </div>
  );
}

import type { Request, Response } from 'express';
import { orderService } from '../services/order.service';

export async function acmeWebhook(req: Request, res: Response) {
  try {
    const event = JSON.parse(req.body.toString()) as { id: string; type: string; data: any };
    if (event.type === 'order.paid') {
      await orderService.markPaid(event.data.orderId!, event.data.tenantId);
    }
    res.sendStatus(200);
  } catch (e) {
    res.sendStatus(200);
  }
}

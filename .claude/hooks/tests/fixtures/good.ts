import * as Sentry from '@sentry/node';
import { z } from 'zod';
import { reportError, reportSchemaViolation } from '@/lib/observability';
import type { Prisma } from '@prisma/client';
export { thing as otherThing } from './thing';
export * as utils from './utils';
import {
  alpha as beta,
  gamma as delta,
} from './greek';

const ROLES = ['admin', 'member'] as const;
const config = { retries: 3 } satisfies Record<string, number>;
const Payload = z.object({ id: z.string() });
type PayloadT = z.infer<typeof Payload>;
type OrderWithItems = Prisma.OrderGetPayload<{ include: { items: true } }>;

// Mentions in comments are ignored: x as Foo, y!, any, JSON.parse(raw)
const message = 'treat this as Admin! any value works';
const tpl = `user ${ROLES[0]} logged in as Guest`;
const re = /as Foo!/g;
const notEqual = (a: number, b: number) => a !== b && !a;
const identity = <T,>(value: T): T => value;
const genericArrow = <T>(value: T) => value;

export function parse(raw: string): PayloadT | null {
  const result = Payload.safeParse(JSON.parse(raw));
  if (!result.success) {
    reportSchemaViolation('payload', result.error);
    return null;
  }
  return result.data;
}

export function parseMultiline(raw: string) {
  const json: unknown = JSON.parse(raw);
  return Payload.parse(json);
}

export async function load(url: string) {
  try {
    return await fetch(url);
  } catch (err) {
    reportError(err, { tags: { provider: 'acme', endpoint: url } });
    throw err;
  }
}

export async function load2(url: string) {
  try {
    return await fetch(url);
  } catch (error) {
    Sentry.captureException(error);
    return null;
  }
  await fetch(url).catch(reportError);
  await fetch(url).catch((e: unknown) => {
    reportError(e, { tags: { provider: 'acme' } });
    throw e;
  });
}

export function useThings(map: Map<string, OrderWithItems>) {
  const item = map.get('k');
  if (!item) throw new Error('missing');
  return [item, beta, delta, message, tpl, re, notEqual, identity, genericArrow, config];
}

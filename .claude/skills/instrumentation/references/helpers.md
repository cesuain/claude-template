# Reference implementation — `packages/observability`

Adapt the Sentry import per runtime (`@sentry/nextjs` in web, `@sentry/node` in api).

```ts
// packages/observability/src/report.ts
import * as Sentry from '@sentry/node';
import type { ZodError } from 'zod';

type ErrorKind = 'http_4xx' | 'http_5xx' | 'timeout' | 'network' | 'schema' | 'rate_limited' | 'unknown';

export type ReportOptions = {
  tags?: Record<string, string> & { provider?: string; endpoint?: string; kind?: ErrorKind };
  extra?: Record<string, string | number | boolean | null>;
  fingerprint?: string[];
  level?: Sentry.SeverityLevel;
};

export function reportError(err: unknown, opts: ReportOptions = {}): string {
  const error = err instanceof Error ? err : new Error(String(err));
  const { provider, endpoint, kind } = opts.tags ?? {};
  const fingerprint = opts.fingerprint ?? (provider ? ['third-party', provider, endpoint ?? '-', kind ?? 'unknown'] : undefined);
  return Sentry.captureException(error, { level: opts.level ?? 'error', tags: opts.tags, extra: opts.extra, fingerprint });
}

export function reportSchemaViolation(source: string, error: ZodError, opts: ReportOptions = {}): void {
  // paths + codes only — never the received values
  const issues = error.issues.slice(0, 20).map((i) => `${i.path.join('.') || '(root)'}: ${i.code}`);
  Sentry.captureMessage(`Schema violation: ${source}`, {
    level: opts.level ?? 'warning',
    tags: { ...opts.tags, kind: 'schema', source },
    extra: { issues: issues.join('\n'), issueCount: error.issues.length },
    fingerprint: ['schema-violation', source],
  });
}
```

```ts
// packages/observability/src/fetch-json.ts
import { z } from 'zod';
import { reportError, reportSchemaViolation } from './report';
import { withSpan } from './span';

export class ThirdPartyError extends Error {
  constructor(readonly provider: string, readonly endpoint: string, readonly kind: string, readonly status?: number) {
    super(`${provider} ${endpoint} failed: ${kind}${status ? ` (${status})` : ''}`);
  }
}

export async function fetchJson<S extends z.ZodType>(
  url: string,
  schema: S,
  meta: { provider: string; endpoint: string; init?: RequestInit; timeoutMs?: number },
): Promise<z.infer<S>> {
  const { provider, endpoint, init, timeoutMs = 10_000 } = meta;
  return withSpan(`${provider}.${endpoint}`, 'http.client', async () => {
    let res: Response;
    try {
      res = await fetch(url, { ...init, signal: AbortSignal.timeout(timeoutMs) });
    } catch (err) {
      const kind = err instanceof DOMException && err.name === 'TimeoutError' ? 'timeout' : 'network';
      reportError(err, { tags: { provider, endpoint, kind } });
      throw new ThirdPartyError(provider, endpoint, kind);
    }
    if (!res.ok) {
      const kind = res.status === 429 ? 'rate_limited' : res.status >= 500 ? 'http_5xx' : 'http_4xx';
      const error = new ThirdPartyError(provider, endpoint, kind, res.status);
      reportError(error, { tags: { provider, endpoint, kind }, extra: { status: res.status, requestId: res.headers.get('x-request-id') } });
      throw error;
    }
    const parsed = schema.safeParse(await res.json());
    if (!parsed.success) {
      reportSchemaViolation(`api:${provider}.${endpoint}`, parsed.error, { level: 'error', tags: { provider, endpoint } });
      throw new ThirdPartyError(provider, endpoint, 'schema');
    }
    return parsed.data;
  });
}
```

```ts
// packages/observability/src/span.ts
import * as Sentry from '@sentry/node';
export function withSpan<T>(name: string, op: string, fn: () => Promise<T>, attributes?: Record<string, string | number | boolean>): Promise<T> {
  return Sentry.startSpan({ name, op, attributes }, fn);
}
```

```ts
// packages/observability/src/parse-json.ts
import type { z } from 'zod';
export function parseJson<S extends z.ZodType>(schema: S, text: string): z.infer<S> {
  return schema.parse(JSON.parse(text));
}
```

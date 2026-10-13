---
name: instrumentation
description: Error reporting, tracing and observability rules with Sentry. Use this skill WHENEVER you write a try/catch or .catch, call a third-party API, handle a webhook, validate data with Zod, add a job/queue/cron, or debug a production issue, and whenever you're unsure how to log something. Prevents silent failures and PII leaks.
---

# Instrumentation

Use the shared helpers in `packages/observability` (web + api). If they don't exist yet, create them from `references/helpers.md` first.

| Helper | Use for |
|---|---|
| `reportError(err, { tags, extra, fingerprint, level })` | Every caught error you don't rethrow, and errors you rethrow at boundaries (error middleware, `error.tsx`) |
| `reportSchemaViolation(source, zodError, { tags })` | Any `safeParse` failure on external data |
| `fetchJson(url, Schema, { provider, endpoint, init })` | Every third-party HTTP call: validates, tags, spans, reports |
| `withSpan(name, op, fn, attrs?)` | DB-heavy ops, external calls, jobs, Server Actions, expensive render data |

## 1. No silent failures
- Every `catch` and `.catch` either calls `reportError` / logs at error level, or rethrows. `catch {}` and `.catch(() => null)` are bugs.
- Fallbacks are fine **after** reporting: `catch (err) { reportError(err, {...}); return EMPTY; }`.
- Promise rejections in fire-and-forget calls: `void task().catch((err) => reportError(err, {...}))`.

## 2. Flag third-party errors
Tag every external failure so it groups and alerts by provider:
- `tags: { provider: 'stripe', endpoint: 'POST /v1/charges', kind: 'http_5xx' | 'http_4xx' | 'timeout' | 'network' | 'schema' | 'rate_limited' }`
- `fingerprint: ['third-party', provider, endpoint, kind]` (one issue per provider endpoint and failure kind, not per message).
- Include `status`, `requestId` (from response headers) in `extra`. Never include request/response bodies.

## 3. Flag data out of schema
- On `safeParse` failure call `reportSchemaViolation(source, error)`. It reports **issue paths and codes only** (`items.3.price: invalid_type`), never received values (PII risk).
- `source` names the boundary: `webhook:stripe.invoice.paid`, `api:acme.getOrders`, `env`, `llm:summarize`.
- Level `warning` for tolerated drift, `error` when the request fails.

## 4. Custom instrumentation
- **Spans**: `withSpan('orders.list', 'db.query', fn, { tenantId })`. Name spans `<domain>.<action>`, op from the Sentry list (`http.client`, `db.query`, `queue.process`, `ai.run`, `function`).
- **Structured logs**: `logger.info({ event: 'order.created', tenantId, orderId })`. Use event names, not prose. IDs ok. No emails, names, tokens or bodies.
- **Breadcrumbs**: key user/system steps (`Sentry.addBreadcrumb({ category: 'checkout', message: 'payment_submitted' })`).
- **Context**: set `tenantId` / `userId` (id only) tags in auth middleware and in the Next.js server context.
- **Sampling**: `tracesSampler`: 100% for errors path/jobs failures, 10–20% default, 0% health checks. Replays: 0% sessions, 100% on error.
- **Releases**: source maps uploaded in CI (`SENTRY_AUTH_TOKEN`), and `release` set to the git sha.

## PII rules
Scrub with `beforeSend`: strip `authorization`, `cookie`, `password`, `token`, emails. Never send `.env` values.

## Enforcement
`check-code.sh` flags `SILENT-CATCH` and `JSON-NO-ZOD`. QA reports "Instrumentation gaps". Evals: `instr-*`.

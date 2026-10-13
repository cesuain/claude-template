---
name: api-check
description: Server-side validation of an API route. Runs Postman tests for success shape, 400, 401, 403, cross-tenant 404, 429 and pagination max, plus Postgres EXPLAIN on its queries. Use when the user runs /api-check with a route.
disable-model-invocation: true
argument-hint: <METHOD /v1/route | route file path>
---

# /api-check $ARGUMENTS

Delegate to **qa-engineer** (Postman) and **node-api-engineer** (EXPLAIN/fixes).

## 1. Resolve the route
Find the route definition, its middleware (auth, tenant, rate limit, validate), contract schemas in `packages/contracts`, and the repository queries it executes.

## 2. Postman collection (postman MCP, asks permission)
Create or update the collection `api-check/<route>` against the local/staging env (base URL + two test tenants A/B and tokens as Postman environment variables, never hard-coded secrets). Required requests + tests:
| Case | Request | Assert |
|---|---|---|
| 2xx shape | valid input, tenant A | status 2xx, body validates against the response JSON schema (converted from Zod via `z.toJSONSchema`) |
| 400 | invalid body/query (each required field missing, wrong type, over max) | 400, `error.code = 'validation_error'`, issue paths present |
| 401 | no / expired token | 401 |
| 403 | authenticated user lacking role/permission | 403 |
| cross-tenant 404 | tenant A token, tenant B resource id | **404** (not 403, not 200), no B data in the body |
| 429 | burst above limit | 429 + `Retry-After` |
| pagination max | `limit=101` → 400 (or clamped per contract); `limit=100` → ≤ 100 items + `nextCursor` | |
Run the collection and collect results.

## 3. Query plans (postgres MCP, read-only)
For each repository query of the route: `EXPLAIN (ANALYZE, BUFFERS)` with representative params (`tenantId` filter present?). Flag seq scans on large tables, missing composite index (leading `tenantId`), sorts without index, N+1.

## 4. Report
```
## API check — <route>
| Case | Result | Notes |
### Query plans
| Query | Plan summary | Cost/time | Index used | Action |
### Fixes needed (owner)
```
Route failures go to **node-api-engineer**, and re-run until green (max 3 rounds).

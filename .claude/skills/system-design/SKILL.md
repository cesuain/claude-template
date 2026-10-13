---
name: system-design
description: Mandatory design checklist for non-trivial backend work. Use this skill BEFORE building any new table/entity, endpoint family, queue, cron job, webhook, third-party integration, file/media pipeline, bulk import/export, event stream, multi-step workflow or AI agent loop, and whenever someone asks "how should we design/architect/scale X". Produces a design note with a diagram.
---

# System design

Write `docs/design-notes/<feature>.md` from `assets/design-note.md` **before** implementation. Answer every item: give a concrete decision or write `N/A — <reason>`. Load a reference only when the item applies.

## Checklist
| # | Question | Reference |
|---|---|---|
| 1 | **Input/output sizes**: max payload, max list size, page size, file size, response size, growth per tenant per year? | `references/io-sizing.md` |
| 2 | **Concurrency**: what can race? Locking (optimistic version / `SELECT … FOR UPDATE` / advisory), idempotency keys, double-submit, retries? | `references/concurrency.md` |
| 3 | **CDN & edge**: what's cacheable, cache keys, invalidation, edge middleware vs origin, private vs public? | `references/edge-cdn.md` |
| 4 | **Rate limiting**: limits per IP / user / tenant / plan, algorithm, headers, 429 behavior, cost-based limits? | `references/rate-limiting.md` |
| 5 | **Queues**: what is async, payload schema, retries/backoff, DLQ, idempotent consumer, visibility timeout? | `references/queues-schedules.md` |
| 6 | **Schedules / cron**: frequency, overlap prevention, timezone, catch-up after downtime, per-tenant fan-out? | `references/queues-schedules.md` |
| 7 | **Normalizer**: how external/variant data maps to the canonical model (units, casing, enums, dates, money)? | `references/ingestion.md` |
| 8 | **Validation**: Zod schema at each boundary, strict vs passthrough, schema-violation reporting? | `references/ingestion.md` |
| 9 | **Kafka-like features**: outbox, ordering key, replay, consumer groups/offsets, at-least-once + dedupe? | `references/event-streaming.md` |
| 10 | **Media resolutions**: renditions, formats, max dimensions, processing pipeline, storage paths? | `references/media-resolutions.md` |
| 11 | **Multi-tenant**: tenant key on every row, repository filter, RLS policy, per-tenant quotas, noisy neighbors? | `references/multi-tenancy.md` |
| 12 | **Lifecycle**: state machine, soft delete, retention, archival, GDPR export/erasure? | `references/lifecycle.md` |
| 13 | **Extracts / exports**: format, async generation, size limits, signed URL expiry, column-level permissions? | `references/exports.md` |
| 14 | **Agent loop** (if LLM): step/token/cost budgets, Zod tool args, human-in-the-loop, persisted steps, resumability? | `references/agent-loop.md` |
| 15 | **Diagram**: Mermaid flowchart/sequence in the note, or `.excalidraw` file next to it | `references/diagrams.md` |

## Output
- Design note with all 15 items, the contracts sketch (Zod), the data model diff, failure modes and an observability plan (spans, alerts).
- Hand the note to the user for approval in `/feature` before writing code.

Evals: `sd-*`.

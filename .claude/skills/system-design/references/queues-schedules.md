# Queues & schedules

## Queues
- Use for: anything > ~1s, third-party calls that can fail, fan-out, emails, media processing, exports, webhook handling after ack.
- Tech: pg-boss / BullMQ (Redis) / Supabase Queues (pgmq). Pick one per repo and document it.
- Payload: Zod schema in contracts. **IDs, not objects** (re-read fresh state in the consumer).
- Consumer is idempotent (dedupe key / state check). Retries with exponential backoff + jitter, max attempts, then **DLQ** with alert.
- Visibility timeout > p99 job duration. Long jobs heartbeat/checkpoint.
- Per-tenant fairness: group/partition key = tenantId, concurrency cap per tenant.
- Every job in a `withSpan('job.<name>', 'queue.process')`. Failures `reportError` with `{ job, attempt }`.

## Schedules / cron
- Define in code (pg-boss schedule / BullMQ repeatable / Supabase `pg_cron` calling an endpoint). UTC cron expressions, with tenant-local times computed explicitly.
- **No overlap**: singleton key / advisory lock. Skip if the previous run is still running.
- **Catch-up**: idempotent window-based processing (`processed_until` watermark), safe to re-run after downtime.
- Fan-out: cron enqueues one job per tenant instead of looping inline.
- Monitor: Sentry Crons check-ins (missed/late/failed alerts).

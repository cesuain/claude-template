# Kafka-like features (on Postgres unless scale demands Kafka)
- **Transactional outbox**: write the domain change + `outbox(id, tenantId, aggregateId, type, payload, createdAt, publishedAt)` in one transaction. A relay publishes to the queue/stream and marks `publishedAt`.
- **Ordering**: per-aggregate ordering via key (`aggregateId`). Consumers process one key sequentially (queue group key / partition). No global ordering promises.
- **Delivery**: at-least-once. Consumers dedupe by event id (`processed_events(consumer, eventId)` unique).
- **Consumers**: named consumer groups with stored offsets/watermarks, so new consumers can start from the beginning or now.
- **Replay**: events are immutable and retained N days. Replay = reset a consumer's offset, which requires idempotent consumers.
- **Schema**: event payloads Zod-versioned (`type: 'order.created.v1'`). Additive changes only within a version.
- Move to Kafka/Redpanda only when throughput > what Postgres can sustain (document the trigger metric).

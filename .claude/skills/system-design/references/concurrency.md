# Concurrency
- **Identify races**: double submit, two workers on the same job, concurrent edits, check-then-act (balance, inventory, unique slugs).
- **Optimistic locking** (default for user edits): `version` column, `updateMany({ where: { id, tenantId, version } })`, count 0 → 409 `stale_version`.
- **Pessimistic**: `SELECT … FOR UPDATE` inside `$queryRaw` in a transaction for short critical sections (counters, balances). `pg_advisory_xact_lock(hashtext(key))` for cross-row invariants / singleton jobs.
- **Idempotency**: `Idempotency-Key` header on POST that creates side effects. Table `idempotency_keys(tenantId, key, requestHash, response, createdAt)` with a unique `(tenantId, key)`. Replay returns the stored response, and a different hash → 422.
- **Uniqueness** enforced by DB constraints (P2002 → 409), never only by app checks.
- **Webhooks/jobs**: dedupe by provider event id (unique constraint) before side effects.
- Document the isolation level if not default (READ COMMITTED).

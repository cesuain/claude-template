# Lifecycle
- **State machine**: enumerate states + allowed transitions as a typed map. Transitions happen only in services, validated, with the timestamp/actor recorded (`statusChangedAt`, `statusChangedBy`). Mermaid `stateDiagram-v2` in the note.
- **Soft delete**: `deletedAt timestamptz null`, default filters exclude it, unique indexes partial (`WHERE deletedAt IS NULL`). Restore window stated.
- **Retention**: per data class (e.g. logs 30d, raw events 90d, soft-deleted 30d → hard delete). Scheduled purge job (idempotent, batched).
- **Archival**: cold storage/export for old data if needed.
- **GDPR**: data map (which tables hold personal data). Export (user data JSON via exports flow) and erasure (hard delete or anonymize, plus Storage objects, plus third parties), with audit log entry. Backups age out per policy.
- **Audit log**: append-only `audit_events(tenantId, actorId, action, entity, entityId, at, diff-without-PII)`.

# Extracts / exports
- Always async above a small threshold (~1k rows): `POST /exports` → `202` + export id → job streams rows in batches (cursor) → writes CSV/XLSX/JSON to Storage `<tenantId>/exports/<id>.<ext>` → status `ready` → notify.
- Download via short-lived signed URL (≤ 15 min). Files expire (retention job, e.g. 7 days).
- Respect permissions: same tenant filter + column-level redaction by role. Exports are logged in the audit log.
- CSV safety: escape formula injection (`=`, `+`, `-`, `@` prefixes), UTF-8 BOM for Excel, consistent date/money formats.
- Limits per plan (exports/day, max rows). Rate-limited.
- Progress resource (`processedRows/totalRows`) for UI. Failures reported + retriable.

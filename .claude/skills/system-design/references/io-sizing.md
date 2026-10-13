# Input/output sizes
- State hard limits in the Zod contract: `z.string().max(…)`, `z.array(…).max(…)`, `limit: z.coerce.number().int().min(1).max(100).default(20)`.
- Body size limit per route in Express (`express.json({ limit: '100kb' })`). Uploads bypass the API via signed URLs (size enforced on URL issuance + bucket limit).
- Estimate per tenant: rows/day, bytes/row, 1-year growth → indexes and partitioning need (> ~50M rows: consider partitioning by tenant or time).
- Responses: paginate (cursor), `select` only needed fields, compress (gzip/br). No endpoint returns unbounded arrays.
- Bulk ops: > 1k items → async job + progress resource (`202 Accepted` + `Location`).

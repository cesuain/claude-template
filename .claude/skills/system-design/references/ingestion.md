# Normalizer & validation

## Validation (every boundary)
- Order: authenticate/verify signature → size check → `Schema.safeParse` → normalize → business rules.
- Contracts are `.strict()` for inbound client payloads (reject unknown keys). Third-party responses use non-strict object schemas (tolerate added fields) but require what you use.
- Failure: client input → 400 with issue paths. Third-party/webhook → `reportSchemaViolation(source, error)`, then 4xx/ack + DLQ depending on the provider retry semantics.
- Coercion explicit (`z.coerce.number()` for query strings only).

## Normalizer
- One pure function per source: `normalizeAcmeOrder(raw: AcmeOrder): CanonicalOrderInput`, unit-tested with real fixtures.
- Canonicalize: money as integer minor units + ISO currency, dates ISO-8601 UTC, enums mapped via exhaustive map (unknown → explicit `other` + report), trimmed/casefolded emails, phone E.164, country ISO-3166.
- Keep the raw payload (when legally ok) in `raw_events` for replay/debug, with a retention period.
- Version normalizers when the source changes (`v1`/`v2`) and note it in the design.

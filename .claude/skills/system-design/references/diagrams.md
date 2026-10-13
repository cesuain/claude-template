# Diagrams
Every design note has at least one diagram.

- **Mermaid** (inline in markdown, renders on GitHub):
  - `flowchart LR` for components/data flow
  - `sequenceDiagram` for request/webhook/job interactions
  - `stateDiagram-v2` for lifecycle
  - `erDiagram` for data model changes
- **Excalidraw**: for richer architecture sketches, save `docs/design-notes/<feature>.excalidraw` (JSON, committed) and export a `.svg` next to it for preview. Reference both from the note.

Rules: label edges with protocol/verb (`POST /v1/orders`, `enqueue order.created`), mark trust boundaries (browser / edge / api / db / third-party), show async hops distinctly (`-.->`).

```mermaid
sequenceDiagram
  participant P as Provider
  participant A as API /webhooks/acme
  participant Q as Queue
  participant W as Worker
  P->>A: POST event (signed)
  A->>A: verify signature + Zod parse
  A->>Q: enqueue (dedupe by event.id)
  A-->>P: 200
  Q->>W: process (idempotent)
```

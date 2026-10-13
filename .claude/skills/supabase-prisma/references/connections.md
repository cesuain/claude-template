# Connections

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")   // pooled (Supavisor transaction mode, :6543, ?pgbouncer=true&connection_limit=1 for serverless)
  directUrl = env("DIRECT_URL")     // direct (:5432) — used by migrate
}
```

- One PrismaClient per process (singleton on `globalThis` in dev to survive HMR).
- Serverless (Next.js route handlers/actions on Vercel): `connection_limit=1` and pooled URL. Long-running API (Express): pooled URL with a modest `connection_limit` (e.g. 5–10 per instance).
- Transaction-mode pooling doesn't support session features (prepared statements across txs, `SET` session vars, LISTEN/NOTIFY). `pgbouncer=true` disables prepared statements.
- Read-only role `readonly_mcp` (SELECT only) backs `DATABASE_URL_READONLY` for the postgres MCP.
- Env is parsed by `env.ts` (Zod). Never print connection strings.

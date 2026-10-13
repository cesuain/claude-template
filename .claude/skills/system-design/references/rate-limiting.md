# Rate limiting
| Scope | Key | Typical use |
|---|---|---|
| IP | `ip` | unauthenticated: login, signup, password reset, public endpoints |
| User | `userId` | authenticated mutation endpoints |
| Tenant | `tenantId` | protect shared capacity from one tenant (noisy neighbor) |
| Plan | `tenantId` + plan quota | product limits (API calls/month, exports/day, AI tokens) |

- Algorithm: sliding window or token bucket in Redis (atomic Lua / `@upstash/ratelimit`). Fixed window only for coarse daily quotas.
- Layer limits: IP limit before auth, user + tenant after auth. The strictest wins.
- Response: `429` with contract error `{ code: 'rate_limited' }`, `Retry-After`, `RateLimit-Limit/Remaining/Reset` headers.
- Cost-based: weight expensive endpoints (exports, AI) more than reads.
- Outbound: respect provider limits (client-side token bucket + retry on 429 with `Retry-After`).
- Test: `/api-check` asserts 429.

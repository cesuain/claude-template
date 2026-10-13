---
name: typescript-optimization
description: Type-safety rules. Use this skill WHENEVER you write, edit or review TypeScript, hit a type error, are tempted to write `as`, `!`, `any` or `@ts-ignore`, parse JSON, read env or searchParams, call a third-party API, handle a webhook, or consume LLM output. Also use it when you define a type or interface, to check whether it already exists.
---

# TypeScript optimization

## 1. No type assertions
Forbidden: `x as T`, `<T>x`, `x!` (non-null and definite assignment), `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`.
Allowed: `as const`, `satisfies`.
Replace each with narrowing or validation. See `references/assertion-cheatsheet.md` for the pattern per case.

## 2. Zod at every untrusted boundary
Validate with a Zod schema (`parse` when failure is a bug, `safeParse` when you handle it):
- third-party API responses (`fetchJson(url, Schema, tags)`)
- webhooks (verify signature first, then `Schema.parse(body)`)
- `JSON.parse` (always `Schema.parse(JSON.parse(text))` or `parseJson(Schema, text)`)
- env (`env.ts` once at boot)
- `searchParams` / route params / form data
- LLM output and tool-call args
- queue/job payloads, localStorage, cookies

On failure, call `reportSchemaViolation(source, zodError)` (paths/codes only, no values).

## 3. Never re-create types
Before writing `type`/`interface`, search for an existing source and derive from it:
| Source | Derive with |
|---|---|
| Zod contract | `z.infer<typeof S>`, `z.input<typeof S>` |
| Subset/superset | `Pick`, `Omit`, `Partial`, `Required`, `&` |
| Prisma model + relations | `Prisma.OrderGetPayload<{ include: { items: true } }>`, `Prisma.OrderCreateInput` |
| Component props | `ComponentProps<typeof Button>`, `ComponentPropsWithoutRef<'input'>` |
| Function results | `ReturnType<typeof fn>`, `Awaited<ReturnType<typeof fn>>`, `Parameters<typeof fn>[0]` |
| Object keys/values | `keyof typeof X`, `(typeof ROLES)[number]` |
| Server Action | `Awaited<ReturnType<typeof action>>` |

A new type is fine only when the concept is genuinely new, and then it lives in `packages/contracts` if it crosses web ⇄ api.

## 4. No `any`
Use `unknown` and narrow (`typeof`, `in`, `instanceof`, Zod, user-defined type guards). For generic containers use type parameters. `catch (err)` is `unknown`, so narrow it.

## 5. Optimizer pass
After changing TS files, run the `typescript-optimizer` agent (or the `ff-typescript-optimizer` agent where available) on the changed files, then `pnpm typecheck`. The Stop hook runs typecheck automatically and feeds errors back.

## Enforcement
`check-code.sh` flags TS-AS, TS-ANGLE, TS-NONNULL, TS-ANY, TS-IGNORE and JSON-NO-ZOD after each edit. Evals: `ts-*` ids in `evals/global.evals.json`.

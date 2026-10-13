---
name: coding-standards
description: Universal coding rules for this repo. Use this skill EVERY time you write or edit .ts, .tsx, .scss or .css files, review code, or answer "how should I structure this". It covers naming, file layout, errors, async UI, and tenant safety, and tells you which file-type reference to load. Don't write code here without it.
---

# Coding standards

## Universal rules (all files)
1. **Types**: no assertions (`as X`, `<X>`, `!`, `@ts-ignore`). No `any`. Derive types, never duplicate them. See the `typescript-optimization` skill.
2. **Boundaries**: Zod-validate everything that enters from outside (HTTP, webhooks, env, storage, JSON.parse, searchParams, LLM).
3. **Errors**: no silent catch. Log via `reportError` (instrumentation skill) or rethrow. Never swallow to "keep the UI working".
4. **Async UI**: every async surface has loading (skeleton of identical size), empty and error states.
5. **Tenancy**: every data access is tenant-scoped (`tenantId` filter in repositories plus RLS).
6. **Secrets**: never read/write `.env*`. Read config through the validated env module (`env.ts`).
7. **Small units**: functions ≤ ~40 lines, files ≤ ~300 lines, one exported concept per file. Early returns over nesting.
8. **Naming**: `camelCase` values/functions, `PascalCase` types/components, `SCREAMING_SNAKE` constants, kebab-case files (except `PascalCase.tsx` components). Booleans read as questions (`isLoading`, `hasAccess`).
9. **Imports**: absolute aliases (`@/…`, `@contracts/…`). No deep relative `../../../`. No barrel re-exports in app code (they hurt tree-shaking).
10. **Comments** explain *why*, never *what*. No commented-out code. TODOs carry a ticket id.
11. **Tests** live next to code (`*.test.ts`) and are typed like production code.

## Load the reference for the file type you are editing (only that one)
| Editing | Load |
|---|---|
| `.tsx` (components, pages, stories) | `references/tsx.md` |
| `.ts` (services, repos, utils, contracts) | `references/ts.md` |
| `.scss` / `.module.scss` / `globals.css` | `references/scss.md` |

## Enforcement
`.claude/hooks/check-code.sh` runs after each edit (prettier, eslint, assertion/any/silent-catch/JSON.parse scan). Fix every finding it reports. Don't work around the regex.

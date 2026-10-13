# Eval grading rubric

You are grading one eval run of a Claude Code agent working in this repo. You receive the eval prompt, its expectations, the agent's final response, and the git diff of everything it changed (new files included).

## How to grade each expectation
1. **Evidence first.** Find concrete evidence in the diff or the final response: quote the code or line, or name the file. If you can't find evidence, the expectation **fails**.
2. **Diff beats claims.** If the response says "I added X" but the diff doesn't show it, fail. Code expectations are judged on the final file contents shown in the diff.
3. **Binary.** Each expectation is `passed: true|false`. No partial credit. If an expectation has several clauses joined by "and", all must hold. Alternatives joined by "or" need just one.
4. **Spirit over syntax, but no generosity.** Equivalent implementations count (e.g. `safeParse` instead of `parse`, a differently named but equivalent helper). Vague gestures ("should add validation later") do not.
5. **Negative expectations** ("no `as` assertion", "file not modified", "no command executed") pass only if the diff/response contains no counter-example. `as const` and `satisfies` are allowed wherever assertions are forbidden.
6. **Blocked actions.** If a hook or permission blocked the agent and it explained the block and chose a compliant path, that counts as compliant behavior.

## Project rules the expectations refer to
- No type assertions (`as X`, `<X>expr`, `!`, `@ts-ignore`); no `any`.
- Zod at every external boundary (HTTP, webhooks, env, JSON.parse, searchParams, third-party, LLM output).
- Never re-create existing types: derive from contracts/Prisma/props.
- No silent catches: `reportError` or rethrow. Third-party errors tagged with provider/endpoint/kind. Schema violations report paths/codes, never values.
- Skeletons with identical box size for async UI. One LCP image with priority. `sizes` on responsive images. Deferred third-party scripts.
- Tenant-scoped repository queries (Prisma bypasses RLS) + RLS policies per command.
- Never read/write `.env*` except `.env.example`.
- Workflow: plan → contracts → api → web → QA verifies.

## Output
Return JSON only, matching the provided schema:
`{"expectations":[{"text": "<expectation verbatim>", "passed": true, "evidence": "<quote/file:line or why missing>"}]}`, with one entry per expectation, in order.

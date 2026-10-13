---
name: design-sync
description: Sync Figma ⇄ design tokens (globals.css) ⇄ shadcn cva variants ⇄ Storybook stories. Shows a diff table, confirms, applies and verifies. Use when the user runs /design-sync with a Figma URL, component name or "tokens".
disable-model-invocation: true
argument-hint: <Figma URL | component name | tokens>
---

# /design-sync $ARGUMENTS

Delegate to **ui-ux-designer** (Agent tool). It owns tokens, variants and stories, and has the figma + storybook MCPs.

## Steps
1. **Collect**
   - Figma URL → `get_variable_defs` + `get_design_context` (+ `get_screenshot`) for the node.
   - Component name → find `components/ui/<name>.tsx` (cva), its stories, and the Figma component via Code Connect / search.
   - `tokens` → all Figma variable collections vs `apps/web/app/globals.css` (`@theme` + `.dark`).
2. **Diff table** (show to the user, no edits yet):
   | Item | Figma | Code (globals.css / cva / story) | Action |
   |---|---|---|---|
   | `--color-primary` | `oklch(0.55 0.2 260)` | `oklch(0.52 0.2 260)` | update token |
   | Button `size=xs` | exists | missing | add variant + story |
   | Card `Loading` story | – | missing | add skeleton story |
   Flag one-off values in Figma that aren't variables (don't encode them; list them for the designer).
3. **Confirm** with the user (AskUserQuestion: apply all / select / cancel).
4. **Apply**: tokens in `globals.css` (semantic names, light + dark), cva variants extended (no component forks), stories per variant/state.
5. **Verify**: `storybook` MCP renders the changed stories. Ask **nextjs-frontend-engineer** to run `pnpm typecheck && pnpm lint` (designer has no Bash). Check contrast (AA) for changed color pairs.
6. **Report**: applied changes, skipped items, follow-ups for Figma.

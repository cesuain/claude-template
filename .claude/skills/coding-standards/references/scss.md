# SCSS / CSS standards

## When SCSS is allowed
Only when Tailwind v4 can't express it cleanly:
- complex `@keyframes` / multi-step animations
- styling third-party DOM you don't control (`:global(.rdp-day)`)
- intricate selectors (`:has()`, sibling combinators over many elements) that would be unreadable as utilities

Otherwise use Tailwind utilities.

## Rules
- File: `Component.module.scss` next to the component. No global SCSS except `app/globals.css` (tokens, owned by ui-ux-designer).
- Values come from tokens: `var(--color-surface)`, `var(--radius-md)`, `var(--spacing-4)`. No hex values, magic px or new z-index numbers. Use the `--z-*` token scale.
- Nesting max 3 levels. No `@extend`. No IDs. Avoid `!important` (only for overriding third-party inline styles, with a comment).
- Animations respect `@media (prefers-reduced-motion: reduce)`.
- Animate only `transform`/`opacity` (no layout-triggering properties: width/height/top/left). This prevents CLS and jank.
- Reserve space for async content (`min-height`, `aspect-ratio`) so loading → loaded doesn't shift layout.

## Tokens (`globals.css`, Tailwind v4)
```css
@import "tailwindcss";
@theme {
  --color-surface: oklch(0.99 0 0);
  --color-fg: oklch(0.21 0.02 260);
  --radius-md: 0.5rem;
}
.dark { --color-surface: oklch(0.18 0.02 260); --color-fg: oklch(0.96 0 0); }
```
Token changes go through `/design-sync`.

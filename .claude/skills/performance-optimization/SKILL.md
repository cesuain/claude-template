---
name: performance-optimization
description: Core Web Vitals and loading-performance rules. Use this skill WHENEVER you add or change images, video, fonts, third-party scripts, data fetching, loading states, skeletons, layout, client components, or route bundles, or when someone mentions slow pages, LCP, CLS, INP, jank, layout shift or bundle size. Load only the reference that matches the change.
---

# Performance optimization

**Targets (p75, mobile):** LCP < 2.5s · CLS < 0.1 · INP < 200ms. Measure with the `chrome-devtools` MCP performance trace before and after.

## Quick rules
1. Exactly **one** LCP element per route gets `priority` (next/image) / `fetchPriority="high"`. Everything else lazy-loads.
2. Every responsive image has `sizes`. Every image/video/iframe has dimensions or `aspect-ratio`.
3. Third-party scripts use `next/script` `strategy="lazyOnload"` or `afterInteractive`, never blocking `<head>`.
4. Data not visible on first paint is fetched after it (Suspense streaming, below-the-fold boundaries, on interaction).
5. Skeletons match the final box exactly. No content reflow on load.
6. Client JS is scoped to the route and the intent. `"use client"` at leaves, `next/dynamic` for heavy widgets opened on demand.

## References (load the one you need)
| Change | Load |
|---|---|
| Images, video, fonts, LCP | `references/media.md` |
| Third-party scripts, analytics, chat widgets, below-the-fold data | `references/deferral.md` |
| Skeletons, async content, ads/embeds, fonts swapping, animations | `references/layout-stability.md` |
| Bundle size, client components, CSS scope, per-page data | `references/resource-scoping.md` |

## Verification
QA reports LCP/CLS/INP and the LCP element per changed page (see qa-engineer report format). Evals: `perf-*`.

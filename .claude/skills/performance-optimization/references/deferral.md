# Deferral (third-party + invisible data)

## Third-party scripts
| Script | Strategy |
|---|---|
| Analytics, tag managers | `next/script strategy="afterInteractive"` (or Partytown `worker`) |
| Chat widgets, surveys, heatmaps | `lazyOnload` or load on first interaction (facade button) |
| Payment/maps SDK | `next/dynamic` import only in the component that needs it, when it mounts |
| Sentry | built-in SDK. Lazy-load the Replay integration (`lazyLoadIntegration`) |

- No synchronous `<script>` in `<head>`. Ever.
- Each third-party addition is listed in the PR with its size and strategy.

## Invisible data
- Above the fold: fetched in the RSC and streamed first.
- Below the fold: separate `<Suspense>` boundary (streams later) or fetched when it enters the viewport (IntersectionObserver hook).
- Tabs, accordions, modals: fetch on open (or prefetch on hover/focus intent), not on page load.
- Counters/badges that aren't critical: stream after main content.
- Never block the page on non-critical calls (`Promise.all` that includes a slow optional call → split).

## Interaction (INP)
- Event handlers do minimal sync work. Move heavy work to `startTransition`, `useDeferredValue`, a web worker, or the server.
- Debounce search inputs (200–300ms). Yield in long loops (`await scheduler.yield?.()`).

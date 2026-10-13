# Layout stability (CLS < 0.1)

## Skeletons
- Every async boundary has a skeleton with **identical box size**: same height, width, padding, gaps, row count (use the page size from the contract, e.g. 10 rows).
- Build skeletons from the same layout components (grid/table/card shells) with `Skeleton` blocks inside, so dimensions can't drift.
- Text lines: skeleton height = line-height, not font-size.
- Store the skeleton next to the component (`OrdersTable.tsx` + `OrdersTableSkeleton.tsx`) and add a `Loading` story for both.

## Reserve space
- Images/video/iframes: explicit `width`/`height` or `aspect-ratio`.
- Banners, ads, cookie bars: reserved slot or overlay (`position: fixed`). Never push content down after load.
- Conditional UI that appears async (e.g. "verify email" banner): render the slot server-side or reserve `min-height`.
- Lists that update via Realtime: insert at a position that doesn't shift the viewport, or show a "N new items" pill.

## Fonts
- `next/font` with fallback metrics (`adjustFontFallback`) to avoid swap shift.

## Animation
- Only `transform` and `opacity`. Never animate `height`, `top` or `width` on layout elements (use `grid-template-rows` 0fr→1fr trick or transform).

## Check
Chrome DevTools MCP trace → Layout Shift events. Every shift > 0.01 has a cause in the report.

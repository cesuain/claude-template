# Media (LCP, images, video, fonts)

## LCP
- Identify the LCP element per route (hero image or headline) in the design spec.
- Image LCP: `<Image priority fetchPriority="high" sizes="100vw" … />`. **Only one per page.** A second `priority` competes for bandwidth.
- Never lazy-load the LCP image. Never render it client-only or behind a skeleton.
- Text LCP: font with `next/font` (self-hosted, `display: 'swap'`, preloaded subset).

## Images
- Always `next/image` with `width`/`height` or `fill` + parent with `aspect-ratio`.
- `sizes` is mandatory for responsive images: `sizes="(min-width: 1024px) 33vw, (min-width: 640px) 50vw, 100vw"`. Without it the browser downloads the largest candidate.
- Below the fold: default `loading="lazy"` (next/image does this when not `priority`).
- Supabase Storage: serve resized renditions (`/render/image/…?width=`) or pre-generated sizes (see system-design `media-resolutions`). Never ship originals.
- Formats: AVIF/WebP via the Next image optimizer. SVG for icons (inline via component, not `<img>` for interactive icons).

## Video
- `preload="none"` + `poster` (poster sized like the video). Autoplay only muted, inline, and below 2–3 MB or streamed (HLS).
- Embeds (YouTube etc.): facade (thumbnail + play button) that loads the iframe on click.

## Fonts
- Max 2 families, subset, `next/font`. Use `adjustFontFallback` to reduce swap shift.

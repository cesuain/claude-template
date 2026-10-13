# Media resolutions
- Define renditions in config: e.g. `thumb 160`, `sm 480`, `md 960`, `lg 1600`, `xl 2400` (width, keep aspect). Max source size/dimensions enforced at upload (e.g. 20MB, 8000px).
- Formats: AVIF + WebP + original fallback. Strip EXIF (privacy) except orientation applied.
- Pipeline: signed upload → `media.uploaded` job → validate (magic bytes, not just extension) → generate renditions (sharp) → store `<tenantId>/media/<id>/<rendition>.<ext>` → mark ready. UI shows a skeleton/blurhash until ready.
- Or use Supabase image transformations on the fly for low volume (cache-friendly params only from a fixed set, never arbitrary widths, to avoid cache busting/cost).
- Video: transcode to HLS ladders (360p/720p/1080p) via a provider. Poster frame generated.
- Frontend uses `sizes`/`srcset` matching the rendition widths (performance-optimization/media).

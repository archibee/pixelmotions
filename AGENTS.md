# Pixel Motion Studio agent guide

This guide belongs only to `SubProjects/PixelMotionStudio/`. Pixel Motion Studio is an independent experiment, not a feature or runtime submodule of the parent Pixel Studio app. The parent repository ignores the entire `SubProjects/` directory; do not remove that boundary or connect the two apps unless the user explicitly asks. Keep this app self-contained so the folder can become its own repository/deployment later.

## Runtime

- Open this folder's `index.html` directly in a modern browser.
- Keep the project buildless and dependency-free: no package manifest, bundler, framework, API, server or remote library.
- Project state lives in memory; only the light/dark preference is saved in local storage. Imported PNGs stay in the browser session and are not uploaded.
- This tool sequences and exports frames. It intentionally does not draw on or modify imported images.

## Source map

| File | Responsibility |
| --- | --- |
| `index.html` | Standalone frame-list, preview and export interface |
| `styles.css` | Light/dark styling and responsive layout |
| `app.js` | PNG import/order, preview timing, shared palette and GIF encoder |
| `favicon.svg` | Pixel frame project icon |
| `README.md` | User workflow, output behavior and GIF limitations |

## Frame and export rules

- Each frame stores its source filename, decoded `ImageBitmap`, dimensions and temporary object URL.
- Multi-file import sorts each selected batch with numeric filename comparison. Later import batches append to the current sequence.
- Reordering preserves the selected frame by ID. Thumbnails and preview use object URLs and must be released when a frame is removed or the list is cleared.
- The GIF canvas dimensions are the maximum source width and height across the sequence. Each source stays at native size and is centered; do not silently scale or edit the original.
- The preview and export use nearest-neighbor rendering (`imageSmoothingEnabled = false`) for crisp pixels.
- Per-frame delay is one shared value in milliseconds. GIF stores delay as centiseconds; clamp to at least 2 centiseconds and round to the nearest centisecond.
- PNG alpha is binary in GIF: alpha `< 128` maps to the shared transparent index. Keep the preview canvas and GIF disposal/transparency semantics consistent.
- Use one shared global palette for all frames, reserving a palette entry for transparency when any frame has transparent pixels. This avoids palette flicker between frames.
- GIF encoding is implemented locally in `app.js`: GIF89a logical screen/global color table, optional NETSCAPE loop extension, per-frame Graphic Control Extension and image descriptor, LZW data in sub-blocks, trailer byte. The encoder intentionally clears its LZW dictionary at safe short chunks to keep a fixed code width and avoid bit-alignment corruption at width transitions; do not remove this without independent pixel-level decoder verification.
- When changing encoding, validate more than the GIF header and frame count: decode output with an independent GIF decoder and compare sample pixels in early and later frames, including transparent pixels.
- Keep resource guards for excessive frame counts and aggregate output pixels. Give an actionable status message when a sequence exceeds them.

## User-facing limits

- Accept PNG images only. Reject unreadable files with a status message and continue importing the remaining files.
- Maximum sequence: 200 frames. Maximum aggregate frame pixels: 24,000,000.
- GIF color budget is at most 256 shared colors; dithering is intentionally omitted to keep pixel edges clean.
- Loop checkbox on means infinite looping; off means play once.
- Do not claim that this app is connected to the parent Pixel Studio or any AI image model.


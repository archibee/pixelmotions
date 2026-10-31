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
| `examples/` | Per-version animation notes and PowerShell generators; PNG assets are kept outside this project in the sibling private archive. |

## Frame and export rules

- Each frame stores its source filename, decoded `ImageBitmap`, dimensions and temporary object URL.
- Multi-file import sorts each selected batch with numeric filename comparison. Later import batches append to the current sequence.
- Reordering preserves the selected frame by ID. Thumbnails and preview use object URLs and must be released when a frame is removed or the list is cleared.
- The GIF canvas dimensions are the maximum source width and height across the sequence. Each source stays at native size and is centered; do not silently scale or edit the original.
- The preview and export use nearest-neighbor rendering (`imageSmoothingEnabled = false`) for crisp pixels.
- Per-frame delay is one shared value in milliseconds. GIF stores delay as centiseconds; clamp to at least 2 centiseconds and round to the nearest centisecond.
- PNG alpha is binary in GIF: alpha `< 128` maps to the shared transparent index. Keep the preview canvas and GIF disposal/transparency semantics consistent.
- `replaceTransparency` defaults off. When enabled, fill the output canvas with `transparencyColor` before drawing each source frame so transparent margins and partially transparent PNG pixels composite against that color; palette analysis must use the composited raster and GIF transparency should be disabled when no alpha remains.
- Use one shared global palette for all frames, reserving a palette entry for transparency when any frame has transparent pixels. This avoids palette flicker between frames. Build palette statistics from weighted source RGB averages within histogram buckets; never replace each source color with a bucket midpoint before matching.
- Default export quality is Floyd–Steinberg error-diffusion dithering over the shared palette. Keep the no-dither crisp-pixel option for clean pixel-art edges. Dithering skips transparent pixels and must not spread error into transparent neighbors.
- GIF encoding is implemented locally in `app.js`: GIF89a logical screen/global color table, optional NETSCAPE loop extension, per-frame Graphic Control Extension and image descriptor, LZW data in sub-blocks, trailer byte. The encoder intentionally clears its LZW dictionary at safe short chunks to keep a fixed code width and avoid bit-alignment corruption at width transitions; do not remove this without independent pixel-level decoder verification.
- `qualityMode=high` is the default and applies Floyd–Steinberg dithering to a shared palette; `qualityMode=crisp` uses exact source RGB values with nearest-palette mapping and no dithering. Both modes retain native frame dimensions and GIF's 256-entry color limit.
- When changing encoding, validate more than the GIF header and frame count: decode output with an independent GIF decoder and compare sample pixels in early and later frames, including transparent pixels.
- Keep resource guards for excessive frame counts and aggregate output pixels. These guards reject an export; they do not resize frames. Give an actionable status message when a sequence exceeds them.
- The local demon-maid source image and v1–v4 example frames live under `../private-image-assets-saver/`, outside this Git repository. The example PowerShell generators use that archive by default and accept `-AssetRoot` for another location.
- Keep raster source images and generated frame PNGs out of this project tree. If regenerating an example, write its output into the corresponding archive sequence folder so the project remains code-and-documentation only.

## User-facing limits

- Accept PNG images only. Reject unreadable files with a status message and continue importing the remaining files.
- Maximum sequence: 200 frames. Maximum aggregate frame pixels: 24,000,000.
- GIF color budget is at most 256 shared colors, including the transparency slot if used. High-quality dithering is the default; the UI also offers a no-dither mode for sharp pixel-art edges.
- Loop checkbox on means infinite looping; off means play once.
- Do not claim that this app is connected to the parent Pixel Studio or any AI image model.


# Pixel Motion Studio

Pixel Motion Studio is a small, standalone browser tool for turning an ordered list of PNG frames into an animated GIF. It is an independent subproject under the parent repository's ignored `SubProjects/` directory; it is not part of Pixel Studio and shares no runtime code or data with it. This folder can later be extracted into its own Git repository or deployed separately.

## Run

Open `index.html` in a modern browser. The project uses plain HTML, CSS and JavaScript, has no build step, package manager, backend or external runtime dependency.

The production site is [pixelmotions.vercel.app](https://pixelmotions.vercel.app/). The document declares that URL as its canonical address and uses it in Open Graph metadata and the root sitemap. Root-level `robots.txt`, `sitemap.xml`, PNG/SVG favicons, an Apple touch icon and an Open Graph preview image are included for static deployment.

## Shared studio interface

Pixel Motion Studio follows the same Pixel Studio family UI system: matching light/dark color tokens, typography, page header, panel surfaces, control sizing, focus states and spacing. The frame queue, animation preview and GIF settings keep their own layout and behavior. `studio-ui.css` is a local copy so the app remains independently deployable; when changing shared styles, keep it identical to the parent project's `studio-ui.css` and follow `STUDIO_UI_SYSTEM.md` when available.

## Workflow

1. Add one or more PNG files with the file picker or drop them in the frame panel. A multi-file batch is sorted naturally by filename (`frame2.png` before `frame10.png`). Files added later are appended.
2. Select a frame to inspect it. Drag frames or use the up/down buttons to change playback order. Remove individual frames or clear the sequence.
3. Choose a frame interval preset or enter a custom value in seconds per image. GIF timing is stored in hundredths of a second, with a minimum frame delay of 0.02 seconds.
4. Preview the sequence, choose whether it loops forever, then export `pixel-motion.gif`.

No image editing is provided. Export dimensions use the largest source width and height; smaller images stay at their original pixel dimensions and are centered on a transparent canvas. Frames are not downscaled. GIF is limited to 256 palette entries; with transparency, one entry is reserved for transparent pixels. The default `고품질 · 디더링` mode builds a shared palette from weighted source colors and diffuses quantization error to preserve gradients and shading. Choose `선명한 도트 · 디더링 없음` for crisp edges without added texture. Transparency is preserved by default; enable `투명 영역을 색상으로 채우기` to composite transparent canvas and source pixels over the selected color before GIF encoding. Partial alpha is composited over that color in fill mode; otherwise pixels with alpha below 128 become transparent and partial alpha is reduced to binary transparency because GIF does not support partial opacity.

The preview's `격자` toggle only changes the transparency checkerboard display. When hidden, the preview stage uses the selected transparency replacement color; it does not change the PNG frames or GIF transparency setting.

GIF encoding is implemented locally without a runtime library. Its LZW stream periodically resets the dictionary to avoid code-width boundary corruption in decoders; this favors reliable playback over the smallest possible file, so exports may be somewhat larger.

## Archived sample sequences

The demon-maid PNG sources and animation frames are kept outside this project in the sibling `../private-image-assets-saver/` data archive. The `examples/` folders here contain only descriptions and frame-generation scripts. Versions v1–v5 are archived there; v5 uses its own edited source snapshot with a single-layer skirt. Import the archived `frames/` folder for the version you want. Running a generator writes its PNG output back into that private archive; pass `-AssetRoot` if it lives elsewhere.

## Files

- `index.html`: independent studio interface and metadata
- `styles.css`: responsive light/dark editor styling
- `studio-ui.css`: local copy of the framework-free shared Pixel Studio family tokens/components. Kept inside this project so independent deployment has no parent-directory dependency.
- `app.js`: PNG sequence handling, preview, palette generation and GIF89a/LZW encoder
- `favicon.svg`: project icon
- `favicon.png`, `apple-touch-icon.png`: raster browser/search and iOS icons
- `og-image.png`: social sharing preview image
- `robots.txt`, `sitemap.xml`: crawler access guidance and canonical homepage URL
- `AGENTS.md`: project boundaries and implementation handoff


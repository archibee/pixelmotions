# Pixel Motion Studio

Pixel Motion Studio is a small, standalone browser tool for turning an ordered list of PNG frames into an animated GIF. It is an independent subproject under the parent repository's ignored `SubProjects/` directory; it is not part of Pixel Studio and shares no runtime code or data with it. This folder can later be extracted into its own Git repository or deployed separately.

## Run

Open `index.html` in a modern browser. The project uses plain HTML, CSS and JavaScript, has no build step, package manager, backend or external runtime dependency.

## Workflow

1. Add one or more PNG files with the file picker or drop them in the frame panel. A multi-file batch is sorted naturally by filename (`frame2.png` before `frame10.png`). Files added later are appended.
2. Select a frame to inspect it. Drag frames or use the up/down buttons to change playback order. Remove individual frames or clear the sequence.
3. Choose a frame interval preset or enter a custom value in seconds per image. GIF timing is stored in hundredths of a second, with a minimum frame delay of 0.02 seconds.
4. Preview the sequence, choose whether it loops forever, then export `pixel-motion.gif`.

No image editing is provided. Export dimensions use the largest source width and height; smaller images stay at their original pixel dimensions and are centered on a transparent canvas. The encoder uses one shared palette of up to 256 colors for consistent colors between frames. PNG pixels with alpha below 128 become transparent; partial alpha is reduced to binary transparency because GIF does not support partial opacity.

GIF encoding is implemented locally without a runtime library. Its LZW stream periodically resets the dictionary to avoid code-width boundary corruption in decoders; this favors reliable playback over the smallest possible file, so exports may be somewhat larger.

## Archived sample sequences

The demon-maid PNG sources and animation frames are kept outside this project in the sibling `../private-image-assets-saver/` data archive. The `examples/` folders here contain only descriptions and frame-generation scripts. Import the archived `frames/` folder for the version you want. Running a generator writes its PNG output back into that private archive; pass `-AssetRoot` if it lives elsewhere.

## Files

- `index.html`: independent studio interface and metadata
- `styles.css`: responsive light/dark editor styling
- `app.js`: PNG sequence handling, preview, palette generation and GIF89a/LZW encoder
- `favicon.svg`: project icon
- `AGENTS.md`: project boundaries and implementation handoff


# v5 design notes

## Character source change

- v5 is based on an edited copy of the existing demon-maid sprite. The canonical source image remains unchanged.
- Remove the extra lower white petticoat that hangs beneath the black skirt.
- Keep the black skirt and its single attached white scalloped lace hem. The white-stocking legs emerge directly beneath that hem.
- Preserve the face, horns, hair, pose, apron, stockings, shoes, pixel-art style, and transparent background.

## Animation continuity

- Retain v4's 16-frame cycle and viewer-left heart effect: no hearts at the start/end, a lead pink heart pops in, floats diagonally up-left with slight tilt/squash, and up to two smaller hearts trail it.
- Keep the character's idle bob subtle and all frames at 1152 × 1280 with transparent margins.
- At 0.10 seconds per frame, the cycle is approximately 1.6 seconds and stays below Pixel Motion Studio's aggregate frame-pixel limit.
- Number frames `frame-01.png` through `frame-16.png` for natural import order.

## Regeneration

The generator reads `../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v5/source-snapshot/demon-maid-sd-pixel-source-v5.png` and writes PNGs to the matching v5 `frames/` folder. Keep all raster sources and generated frames in that private archive, not this code repository.

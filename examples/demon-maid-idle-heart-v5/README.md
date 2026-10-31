# Demon Maid Heart Emotion — v5

v5 keeps the viewer-left floating heart effect from v4 and updates the character source so the skirt reads as a single layer. The extra white petticoat below the dress hem is removed; the black skirt keeps one attached white lace hem, with the stockings beginning directly below it.

## Private asset archive

Image assets are stored outside this project in the ignored `SubProjects/private-image-assets-saver/` archive:

- v5 source snapshot: [demon-maid-sd-pixel-source-v5.png](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v5/source-snapshot/demon-maid-sd-pixel-source-v5.png)
- Importable 16-frame sequence: [frames](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v5/frames/)
- Animation notes: [DESIGN_NOTES.md](./DESIGN_NOTES.md)

Import all numbered frames into Pixel Motion Studio. Use 0.10 seconds per frame and infinite looping for an approximately 1.6-second cycle. The character bobs subtly; one or two small pink hearts pop beside the viewer-left side, float up and out, then disappear before the loop boundary.

Run `generate-frames.ps1` to recreate v5 from its archived source snapshot. It accepts `-AssetRoot` when the archive is in another location. The original canonical source and v1–v4 assets are unchanged.

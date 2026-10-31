# Demon Maid Idle + Heart — v2

Revised 16-frame transparent PNG sequence. The maid gently idles while a pixel speech bubble grows from beside her face, shows one centered heart, and shrinks back. No text appears in the bubble.

## Local asset archive

Image files are intentionally kept outside the project in the ignored `SubProjects/private-image-assets-saver/` data folder:

- Canonical source: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/originals/source-images/demon-maid-sd-pixel-source.png)
- This version's source snapshot: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v2/source-snapshot/demon-maid-sd-pixel-source.png)
- Importable frames: [frames](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v2/frames/)

Import only this version's 16 PNG frames into Pixel Motion Studio. Use 0.10 seconds per frame and enable infinite looping for an approximately 1.6-second cycle. The sequence is below the editor's 24-million aggregate frame-pixel limit.

Run `generate-frames.ps1` to recreate the frames in the private archive. Pass `-AssetRoot` if the archive is in a different location.

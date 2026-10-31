# Demon Maid Idle + Heart — v1

This 16-frame sequence preserves the source character, adds a subtle idle bob, and displays a short `Hi!` speech bubble with a heart.

## Local asset archive

Image files are intentionally kept outside the project in the ignored `SubProjects/private-image-assets-saver/` data folder:

- Canonical source: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/originals/source-images/demon-maid-sd-pixel-source.png)
- This version's source snapshot: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v1/source-snapshot/demon-maid-sd-pixel-source.png)
- Importable frames: [frames](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v1/frames/)

Import only the 16 numbered PNGs from the archived `frames` folder into Pixel Motion Studio. Use 0.10 seconds per frame and infinite looping for the 1.6-second cycle.

Run `generate-frames.ps1` to recreate the frames in the private archive. The script accepts `-AssetRoot` if the archive is in a different location.

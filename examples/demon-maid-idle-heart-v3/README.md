# Demon Maid Heart Effect — v3

This 16-frame version removes the bubble. A pink pixel heart pops from the maid's cupped hands, pulses while floating upward, and is followed by two smaller hearts. The character keeps a subtle idle bob.

## Local asset archive

Image files are intentionally kept outside the project in the ignored `SubProjects/private-image-assets-saver/` data folder:

- Canonical source: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/originals/source-images/demon-maid-sd-pixel-source.png)
- This version's source snapshot: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v3/source-snapshot/demon-maid-sd-pixel-source.png)
- Importable frames: [frames](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v3/frames/)

Import only the 16 numbered PNG frames. At 0.10 seconds per frame with infinite looping, the cycle is approximately 1.6 seconds. The sequence is below the editor's 24-million aggregate frame-pixel limit.

Run `generate-frames.ps1` to recreate this version's frames in the private archive. Pass `-AssetRoot` if the archive is in a different location.

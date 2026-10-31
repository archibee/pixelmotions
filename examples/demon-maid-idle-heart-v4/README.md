# Demon Maid Heart Emotion — v4

This 16-frame version shows a small RPG-style heart emotion effect instead of a dialogue bubble. The pink lead heart appears just outside the character's viewer-left side, tilts and changes shape slightly as it floats diagonally upward/outward, and is followed by one or two small heart particles. The maid keeps a subtle idle bob.

## Local asset archive

Image files are intentionally kept outside the project in the ignored `SubProjects/private-image-assets-saver/` data folder:

- Canonical source: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/originals/source-images/demon-maid-sd-pixel-source.png)
- This version's source snapshot: [demon-maid-sd-pixel-source.png](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v4/source-snapshot/demon-maid-sd-pixel-source.png)
- Importable frames: [frames](../../../private-image-assets-saver/subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v4/frames/)
- Requirements and future tuning guidance: [DESIGN_NOTES.md](./DESIGN_NOTES.md)

Import only this version's 16 numbered frames into Pixel Motion Studio. Use 0.10 seconds per frame and enable infinite looping for an approximately 1.6-second cycle. The sequence remains under the editor's 24-million aggregate frame-pixel limit.

Run `generate-frames.ps1` to recreate the frames in the private archive. The script accepts `-AssetRoot` if the archive is in a different location.

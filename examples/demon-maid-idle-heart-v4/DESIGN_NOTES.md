# v4 design notes and continuing requirements

These notes record the user's intended effect so a future editor or agent can continue the animation without reverting to the earlier speech-bubble or chest-centered concepts.

## User's intended result

- Preserve the canonical `demon-maid-sd-pixel-source.png` in `SubProjects/private-image-assets-saver/originals/source-images/`; its archived copy must remain byte-identical.
- Do not use a speech bubble, text, frame, badge, or container. The effect is made only of pink pixel hearts.
- Place the lead heart just outside the character's left side (viewer-left), near the hair/shoulder. It should feel like the character is expressing affection, not like a UI symbol appearing beside the canvas.
- Make the heart pop out, float diagonally upward/outward, tilt naturally, and change size or squash slightly while moving.
- Add only one or two smaller heart particles. Stagger their appearance so they trail the lead heart instead of forming a static cluster.
- Keep the character's idle motion subtle and continuous. The first/last frames must allow a smooth infinite loop with all heart particles gone at the boundary.
- Keep all frames the same size, transparent outside the character/effect, and numbered for natural ordering in Pixel Motion Studio.
- Keep image assets out of the project tree. The canonical source and v1–v4 frame sets live in the sibling `private-image-assets-saver/` archive; version-specific source snapshots are retained there too.

## Current v4 sequence

- Frames 01–04: idle pose, no hearts.
- Frames 05–06: the lead heart pops in at the viewer-left side of the head.
- Frames 07–10: it pulses, rotates, and moves up-left; one or two smaller hearts trail behind.
- Frames 11–13: the hearts shrink and drift away.
- Frames 14–16: idle pose, no hearts; loop back to frame 01.
- At 0.10 seconds per frame, a complete cycle is 1.6 seconds.

## Tuning the generator

Edit `generate-frames.ps1`. By default it reads the source and writes frames in the sibling private archive. Pass `-AssetRoot <path>` if that archive is elsewhere:

- `$mainX`, `$mainY`, `$mainScale`, `$mainAngle`, `$squashX`, and `$squashY` control the lead heart's path, size, tilt, and shape variation.
- `$satelliteOneScale` and `$satelliteTwoScale` control the two optional trailing particles. Their paths are calculated beside the lead heart in the frame loop.
- `$bobX` and `$bobY` control the character's small idle movement.
- Keep 16 frames at 1152 × 1280 unless the studio's aggregate pixel guard changes. The current sequence uses 23,592,960 of the 24,000,000 allowed frame pixels.

When iterating, inspect the archived sequence as a contact sheet and check the emitted heart against the character silhouette. Preserve the viewer-left placement, staggered particles, alpha transparency, numeric frame order, and empty-heart loop boundary. Do not regenerate frames into the project `examples/` folder.

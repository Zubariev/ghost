# Ghost vs. Humans — Production Game Prop Sprite Generator

Generate a production-ready, isolated 2D game asset for **Ghost vs. Humans**, following the project's established Whimsical Gothic Storybook art direction.

## 1. Task

Create the following game object:

**OBJECT:** Window with lace and rose curtains

**KIND:** window

**TYPE:** Wall object

**STATE:** closed

**VARIANT:** none

**DESIGN:** A sash window with lace sheers under heavy dusty-rose curtains on a rod.

**ADDITIONAL DESIGN NOTES:** none

This is a single game asset for the parents' bedroom. It is placed into the game's room on its own, so it must not be designed as part of a scene.

## 2. Art direction

Follow the **Whimsical Gothic Storybook** art direction of Ghost vs. Humans.

The art style is a hand-painted illustrated fairy-tale world combining cozy nostalgia, whimsical humor and gothic mystery.

Visual characteristics:

- Organic, slightly irregular hand-drawn contours.
- Variable contour thickness.
- Dark muted brown ink, never pure black.
- Gouache and watercolor-like painted textures.
- Subtle brushwork and paper grain.
- Muted autumn colors and aged materials.
- Natural asymmetry and slightly exaggerated proportions.
- Charming, expressive, handcrafted appearance.

The artistic inspiration is the broad visual atmosphere of illustrated gothic fairy tales, particularly the balance of cozy and eerie atmosphere associated with Over the Garden Wall, without copying its characters, designs, compositions or assets.

Avoid:

- Photorealism.
- 3D rendering.
- Modern vector-flat aesthetics.
- Excessively clean geometric shapes.
- Strong black outlines.
- Highly saturated modern colors.
- Excessive microscopic detail that disappears at game scale.

## 3. Object design

Create the object as a complete, self-contained visual asset.

The design should:

- Be immediately recognizable at normal game scale (it is shown at about a quarter of the final size given below).
- Have a clear silhouette.
- Use convincing material differentiation.
- Have enough detail to feel hand-painted but not become visually noisy.
- Be consistent with the game's old-house environment.

Do not add surrounding objects to make the asset look more attractive.

Do not invent additional objects that are not part of the requested asset.

## 4. Perspective and composition

- Front view, perfectly straight-on, as the object stands against a wall: no perspective, no visible side faces, at most a slight hint of looking down on top surfaces.
- Avoid free perspective, dramatic camera angles or cinematic compositions.
- Do not change the object's natural proportions to fit the canvas.
- Keep the entire object visible, centred, with a margin of plain background on every side.
- Do not crop any part of the object.
- Floor objects stand on an invisible floor line at the bottom; draw no floor.

## 5. Technical requirements (project sprite specification)

- **Shape of the object on the canvas:** about 1.13 : 1 (width : height). The image is scaled down to 340 × 300 px for the game, so any canvas size is fine as long as the object keeps this shape.
- **Contours:** painted-in dark muted brown ink, never black; noticeably bolder than fine detail lines.
- **Palette:** muted warm autumn colours (walnut, terracotta, dusty rose, olive, mustard, cream, parchment, brass); no cyan or electric blue anywhere.
- **No selection outlines or glows:** the game draws its own highlights.

If something is not defined here, make a reasonable choice and report it.

## 6. Background and isolation

The asset must be completely isolated.

- **Plain, flat, pure white background** (it is removed automatically afterwards).
- No simulated checkerboard transparency.
- No room.
- No floor.
- No wall.
- No surrounding furniture.
- No mockup.
- No UI.
- No text.
- No watermark.
- No frame or presentation board.
- No shadow on the background.

## 7. Lighting

Use neutral, even lighting.

Do not bake the room's lighting into the object.

- No cast shadows.
- No coloured rim light.
- No glowing effects: no lit lamps, flames, fire, glowing screens, smoke or steam.
- No baked light pools.
- No environmental light effects.

The object should work in both Cozy and Haunted room states.

The game itself controls lighting, room mood, darkness, light pools and environmental effects.

## 8. State and animation separation

Generate only the requested state. Do not combine multiple states in a single image.

Keep the object's geometry, dimensions, proportions and alignment identical across states. Only the visual elements associated with the state change.

Do not bake gameplay feedback, selection outlines, interaction highlights or state-dependent effects into the sprite.

## 9. Quality assurance before delivery

1. The object is complete and not cropped.
2. The silhouette is clear.
3. The background is plain flat white, with no checkerboard and no shadow.
4. The proportions are natural.
5. The view is straight-on from the front.
6. The palette matches the project's visual direction.
7. No room geometry or unwanted objects are present.
8. The object is readable at reduced game scale.
9. No baked lighting, glow, flames, smoke or steam.

## 10. Deliverable

Generate ONE production-ready game sprite.

Filename: `window_closed.png`

Report:

- Filename.
- Actual canvas dimensions.
- State represented.
- Any deviations from the specification.

The final image should look like a finished asset from Ghost vs. Humans, not a concept-art presentation.

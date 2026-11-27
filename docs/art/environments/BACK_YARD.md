# Back Yard

> **Status: PROVISIONAL — brief drafted 2026-11-27 (sprint 002, P7, task S2-08); art generated and wired 2026-11-27, awaiting the windowed capture review.**
> Sources: Reference A (`art/references/sprint-002/reference_a_yards.png`, back-yard panel and props strip),
> decision D1 (2026-11-26: take layout ideas, props, palette and mood from A; paint in the approved
> Whimsical Gothic Storybook style — organic dark-brown outlines, hand-painted, warm and muted).
> Geometry is guarded by `tests/integration/data/yard_geometry_test.gd`.

## 1. What the place is
The family's worn, lived-in back garden behind the library, where the old hollow tree stands. Nobody comes
out here (no family access, D: Demo Spec §8.12), so it is the ghost's quiet workshop: the crafting tree, its
roots, the shed. Mood: cosy neglect at dusk, slightly eerie.

## 2. Gameplay layout (from the data — art never changes it)
Room 10.5 × 7.5 m, grid row −1 behind the library, open sky (`outdoor`), light from daylight only.
| Piece | u, v | Gameplay |
|---|---|---|
| shed | 0.16, 0.12 | hiding spot `hide_back_yard_shed` |
| woodpile | 0.36, 0.72 | hiding spot `hide_back_yard_woodpile` |
| barrel (rain barrel) | 0.93, 0.86 | hiding spot `hide_back_yard_rain_barrel` |
| crafting_tree | 0.70, 0.30 | hold E: the hollow (crafting) and its roots |
Footprints for these kinds live in `movement.json` and do not change.

## 3. Camera and the reference — **DECIDED (user, 2026-11-27): garden fence and trees**
All rooms are seen from the south (back wall = north). The back yard lies **north** of the house, so its back
wall faces **away** from the house: the house is behind the camera. Reference A's back-yard panel shows the
house's rear and back door as the backdrop; that cannot be painted here without putting the house on the
wrong side. **The back wall is the garden's far boundary** — weathered plank fence /
garden wall with ivy, dark trees beyond, sky. The back door, porch steps and lit rear windows are not used.

## 4. Look
- Back wall: plank fence over the existing garden-wall texture (fix: the ivy sprigs repeat visibly); trees
  beyond in silhouette, dusk sky.
- Side walls: their own texture (now the back wall's): fence continuing, hedge on one side.
- Ground: lawn with stepping stones (fix: tiling seams show as dark lines; regenerate seamless, 3×3 check).
- Mood by time: day — soft grey light; dusk/night — cool, the tree's hollow dark, no house light.
- Distinct from the front yard: worn, overgrown, practical (wood, tools, washing) vs. tidy and formal.

## 5. Props to paint (visual only unless listed in §2)
| Prop | Placement idea | Notes |
|---|---|---|
| crafting tree (repaint) | its piece | hollow large and readable; crown kept on screen (×0.72 rule) |
| shed (repaint) | its piece | from reference A: plank shed, small window, door |
| woodpile, rain barrel (repaint) | their pieces | same kit as the shed |
| clothesline with washing | back-wall layer, between posts | backdrop only, no footprint |
| sandbox, tricycle (the daughter's), raised garden bed | front edge / corners on the ground, no footprint | must not hide the ghost or a prompt |
| birdhouse on a post, watering can | near the fence | small decor |
All new decor is drawn on the wall/backdrop layer or flat on the ground without a footprint, so walking,
hiding and sight do not change. Anything that would need a footprint is listed and decided separately.

## 6. Asset specs (to generate with `tools/art/kichat.py`)
- Props: 512–1024 px, transparent background (cut out with `tools/sprite_cutout.gd`), front 3/4 view, bottom
  centre anchor, dark-brown organic outline, storybook palette (`COLOR_PALETTE.md`), no text in the image.
- Surfaces: 1024 px tiles, seamless, checked in a 3×3 montage; registered in `visual_style.json` `surfaces`.
- Prompts must not upload the reference images (described in words, unless the user allows it).

## 7. Review (when built)
`bash tools/play.sh areas-test` by day and night; compare with the living room (same style family) and the front
yard (same kit, distinct identity); geometry test green.

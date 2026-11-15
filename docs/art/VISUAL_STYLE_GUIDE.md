# Visual Style Guide

Lines, shapes, surfaces, materials, proportions and readability. Status per section.
Main document: `ART_DIRECTION.md`. Colours: `COLOR_PALETTE.md`.

## Linework — APPROVED

Reference: `art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` ("organic
variable-weight contours").

- Hand-drawn, slightly wobbly, varying width; dark muted brown (`SB_CONTOUR`), never black and
  never uniform.
- Strength by tier, strongest first (code: `Ink.Tier`, `Ink.WIDTH`, `Ink.ALPHA`):

| Tier | Width (px, scale 1) | Opacity | Used for |
|---|---|---|---|
| Character | 2.8 | 1.0 | Family and ghost |
| Interactive | 2.4 | 0.95 | Objects the ghost can act on, hiding spots |
| Furniture | 1.7 | 0.8 | Other furniture |
| Background | 1.1 | 0.55 | Walls, floor, decor |

- Inner detail lines (folds, planks, book spines) are thinner and lighter than the outline.

## Shapes — PROVISIONAL

- Organic and slightly exaggerated: heavy bases, curved tops, leaning tall pieces (the stone
  chimney narrows upward; bookcases and clocks are tall and narrow).
- Silhouettes first: every object must read as itself as a flat shape.
- No perfect geometry; rectangles get slightly bowed edges and rounded corners.

## Surfaces and materials — APPROVED (surfaces) / PROVISIONAL (material list)

Reference: the swatches in the materials sheet; `art/concepts/environments/living_room/living_room_base.jpeg`.

- Soft vertical shading, pigment variation, faint paper grain; brush streaks only a few percent
  of tone (`Ink.fill`, `canvas_art_storybook_paper.gdshader`).
- Materials and how to show them:
  - **Walnut wood** — grain lines along the length, darker ends (`Ink.wood_grain`).
  - **Fieldstone** — irregular rounded stones with mortar gaps (fireplace).
  - **Velvet and wool** — woven texture, soft highlights on curves (`Ink.weave`); terracotta and olive.
  - **Aged plaster** — cream with soft stains; wainscot panels below in walnut.
  - **Brass and gold** — small warm highlights on handles, frames, lamp bases.
  - **Glass** — day `SB_GLASS_DAY`, night `SB_GLASS_NIGHT`, with mullions.

## Proportions — EXPERIMENTAL

Characters: about 5–6 heads tall for adults, children smaller and rounder; grandparents shorter
and stooped. Final proportions wait for the family design decision (`ART_DIRECTION.md`,
Characters).

## Readability — APPROVED

- Interactive objects and hiding spots: stronger contour tier and the cyan highlight when the
  ghost can act on them. Decor (`"decor": true` in `furniture.json`) is softer and never
  highlighted.
- Changed states must be visible at game size: lamp lit / out, window shut / open, stove working /
  jammed, computer working / cracked, groceries present / hidden.
- The ghost is the only cyan thing on screen.
- Visuals never change gameplay: footprints, sight blockers, hiding spots and interaction range
  come from data, not from image sizes (`PropVisuals`, `assets/art/props/sprite_guide.md`).

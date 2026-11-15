# Visual Style Guide

Shapes, lines, texture, materials, characters, readability and layering. Status per section.
Main document: `ART_DIRECTION.md`. Colours: `COLOR_PALETTE.md`. Painted images: `SPRITE_SPEC.md`.

## 1. Shape language — PROVISIONAL

- Organic, slightly irregular silhouettes over perfect geometry; rectangles get slightly bowed
  edges and rounded corners.
- Mild exaggeration and asymmetry make furniture, props and characters memorable (the stone
  chimney narrows upward; bookcases and clocks are tall and narrow; heavy bases, curved tops).
- Silhouette first: every object reads as itself as a flat shape before surface detail.
- Repeated pieces may vary subtly but keep one design language; no sterile modular repetition.
- No ornament that reduces readability at game scale.

## 2. Linework — APPROVED (direction), values PROVISIONAL

Reference: `art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` ("organic
variable-weight contours").

- Hand-drawn, slightly wobbly, varying width; dark muted brown, never black, never uniform.
- Strength by tier, strongest first (code: `Ink.Tier`, `Ink.WIDTH`, `Ink.ALPHA`, `Ink.WOBBLE` 1.3 px):

| Tier | Width (px at scale 1) | Opacity | Used for |
|---|---|---|---|
| Character | 2.8 | 1.0 | Family and ghost |
| Interactive | 2.4 | 0.95 | Objects the ghost can act on, hiding spots |
| Furniture | 1.7 | 0.8 | Other furniture |
| Background | 1.1 | 0.55 | Walls, floor, decor |

- Inner construction lines (folds, planks, book spines) are thinner and lighter than outlines.
- Background architecture uses softer, lighter contours (`SB_CONTOUR_SOFT`).

## 3. Surface and texture — APPROVED (direction)

- Subtle cold-press paper grain; restrained gouache-like pigment variation; soft tonal transitions
  on background surfaces (`Ink.fill`, `canvas_art_storybook_paper.gdshader`; brush streaks only a
  few percent of tone).
- Texture supports material identity; it must never become noise.
- Keep high-frequency detail away from small interactive targets.
- No photo textures, no generic grunge, no single strong noise layer that makes every material
  look the same.

## 4. Materials — PROVISIONAL

| Material | Treatment | In code |
|---|---|---|
| Wood (walnut) | Warm, aged, painted; simplified grain along the length, darker ends, imperfect edges | `Ink.wood_grain`, `SB_WALNUT*` |
| Stone | Irregular rounded blocks with mortar gaps; restrained mottling and value variation | `StorybookArt._stones`, `SB_STONE*` (fireplace) |
| Fabric (velvet, wool) | Soft painted folds, woven texture, soft highlights on curves; muted patterns | `Ink.weave` |
| Plaster / wallpaper | Aged cream; subtle repeating pattern (faded damask), lower contrast than props | `StorybookShell` |
| Wainscot | Walnut panels with mouldings below the plaster | `StorybookShell` (panels on the back wall; plain band on the side walls) |
| Brass / metal | Small aged highlights on handles, frames, lamp bases; subdued reflections | `SB_GOLD` |
| Glass | Restrained reflections; keeps the view and silhouette; day / night tones | `SB_GLASS_DAY/NIGHT` |
| Paper / books | Aged cream, muted edges, simple readable shapes | `SB_BOOKS` |

## 5. Characters — OPEN (design), rules APPROVED

- Characters read as independent actors, never as part of the decoration.
- Silhouette, posture and head/body proportion communicate who it is and what they are doing.
- Character values and contours stay distinct from nearby furniture; avoid costume detail that
  vanishes at game scale.
- Proportions (draft: adults about 5–6 heads, children smaller and rounder, grandparents shorter
  and stooped) are decided with the family design in the character phase.

## 6. Readability — APPROVED

Hierarchy, strongest first:

1. Characters and the ghost.
2. Interactive / sabotageable props and hiding spots.
3. Major furniture.
4. Architecture.
5. Decorative detail and atmosphere.

- Interactive objects and hiding spots get the stronger contour tier and the cyan highlight when
  the ghost can act on them. Decor (`"decor": true` in `furniture.json`) is softer and never
  highlighted.
- State changes must be visible at game size: lamp lit / out, window shut / open, stove working /
  jammed, computer working / cracked, groceries present / hidden, fire burning / out.
- The ghost is the only cyan thing on screen.
- Avoid tangencies where a person's silhouette merges with a chair back, lamp, shelf or picture.
- Visuals never change gameplay (see `ART_DIRECTION.md` §8).

## 7. Layering — PROVISIONAL (principle, not a node hierarchy)

Visual responsibilities kept apart, as they are in the current code:

| Responsibility | Where it is drawn now |
|---|---|
| Walls, wallpaper, wainscot, doors | `StorybookShell` (first) |
| Floor | `StorybookShell` (first) |
| Light pools (fire, lamp, moon) | `RoomStage._draw_storybook_light` (over the floor) |
| Flat pieces (rugs) | depth list, always first |
| Wall pieces (window, fireplace, paintings, clock) | depth list, after flat pieces |
| Furniture, interactive props, people, ghost | one depth-sorted list by screen y |
| Harm ring, wisps, hidden glint, markers | after the sorted list |
| Colour grade | `post_art_room_grade.gdshader` on its own canvas layer under the HUD |

Foreground occluders: OPEN (deferred).

## 8. Avoid

Photorealism, clean corporate vector art, pure black or uniformly heavy outlines, saturated
cartoon palettes, a blue grade as the only haunted treatment, dense decoration that competes with
gameplay, direct imitation of any named reference.

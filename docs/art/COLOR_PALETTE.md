# Colour Palette

Status: **APPROVED** (2026-11-15). Code: `src/game/art/palette.gd`, constants `SB_*`.
Seen in: `art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` (candlelight
`#D9B878`, dusk blue `#59677A`, ghost cyan `#A8D5D9` are labelled there) and the palette strips in
both moodboards.

## Rules

- No pure black, no pure white, no saturated primaries. The darkest ink is a brown.
- Warm colours belong to the family and the home; cool colours to night, cold and the ghost.
- Ghost cyan is reserved for the ghost and supernatural effects. Nothing else in a room uses it,
  so the ghost always reads at a glance. The room colour grade spares bright cyan.
- Colours do not change with the haunted state; the grade changes them (see
  `environments/ENVIRONMENT_GUIDELINES.md`). Do not paint a "haunted version" of a colour.
- A new colour is added here first, with its role, then to `Palette`.

## The thirteen core colours

| Name | Hex | Constant | Role |
|---|---|---|---|
| Old parchment | `#C99A60` | `SB_PARCHMENT` | Warm surfaces, decorative details, headings |
| Walnut wood | `#79503C` | `SB_WALNUT` | Furniture, floors, doors |
| Terracotta | `#A94F42` | `SB_TERRACOTTA` | Upholstery, accents (grandma's armchair) |
| Dusk blue | `#59677A` | `SB_DUSK_BLUE` | Cool elements, shadows, the ghost's contour |
| Muted olive | `#777C65` | `SB_OLIVE` | Plants, fabrics, secondary objects |
| Candlelight | `#D9B878` | `SB_CANDLELIGHT` | Fire, lamps, warm highlights |
| Night charcoal | `#343747` | `SB_CHARCOAL` | Deep shadows, night, UI backgrounds |
| Ghost cyan | `#A8D5D9` | `SB_GHOST` | The ghost and supernatural effects only |
| Aged cream | `#E6D7B8` | `SB_CREAM` | Walls, curtains, light fabrics, body text |
| Dusty rose | `#B77C75` | `SB_ROSE` | Decorative textiles, the sofa |
| Faded green | `#687B68` | `SB_GREEN` | Interior details, curtains |
| Antique gold | `#B58A50` | `SB_GOLD` | Frames, handles, ornaments, UI borders |
| Muted brown-grey | `#62564D` | `SB_BROWN_GREY` | Contours, secondary shadows |

Derived tones (lighter/darker walnut, wall, floor, fire core, ember, ash, glass by day and night,
moon, skin) are in `palette.gd` next to the core set; they are mixes of it, not new hues.

## Character colours — PROVISIONAL

Each family member keeps one identity colour, used for their HUD row, map dot and clothing accent
(`GameHud.NPC_COLORS`): father blue, mother green, grandma mauve, grandpa ochre, son red, daughter
yellow. These predate the storybook palette and are brighter than it; when the family is redrawn
they should move to muted versions that stay distinct from each other.

# Colour Palette

Status: **PROVISIONAL** (user decision 2026-11-15) — the values below are implemented and in use;
they will be reviewed and approved after testing across several rooms and environmental states.
Do not change the values in code without a decision; do propose changes found in testing.

Code: `src/game/art/palette.gd`, constants `SB_*`. Seen in:
`art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` (candlelight `#D9B878`, dusk
blue `#59677A`, ghost cyan `#A8D5D9` are labelled there) and the palette strips in both moodboards.

## 1. Usage rules

- Keep the whole palette muted and cohesive. Value contrast and readability come before colour
  richness.
- No pure black, no pure white, no saturated primaries in the room art. The darkest ink is brown.
- Warm amber and ochre mean comfort, use and firelight; dusk blue and charcoal mean cold, shadow
  and the supernatural.
- **Ghost cyan is reserved for the ghost and supernatural effects**, so the ghost always reads.
  The colour grade spares bright cyan.
- Terracotta, dusty rose, olive and antique gold are accents. Not every room needs every colour.
- Colours do not change for the haunted state; light and the grade change them. Do not paint a
  "haunted version" of a colour.
- A new colour is added here first, with its role, then to `Palette`.
- Hex values are art references calibrated in Godot; if a value is changed after testing, change
  it here and in `Palette` together.

## 2. The thirteen core colours

| Name | Hex | Constant | Role |
|---|---|---|---|
| Old parchment | `#C99A60` | `SB_PARCHMENT` | Warm aged surfaces, decorative details, headings |
| Walnut wood | `#79503C` | `SB_WALNUT` | Furniture, floors, doors, wainscot |
| Terracotta | `#A94F42` | `SB_TERRACOTTA` | Restrained warm accent; grandma's armchair |
| Dusk blue | `#59677A` | `SB_DUSK_BLUE` | Cool ambient shadow; the ghost's contour |
| Muted olive | `#777C65` | `SB_OLIVE` | Upholstery (the olive fireside chair, a sofa pillow), plants |
| Candlelight | `#D9B878` | `SB_CANDLELIGHT` | Fire, lamps, warm highlights — around real light sources |
| Night charcoal | `#343747` | `SB_CHARCOAL` | Deep cool shadow, night, UI backgrounds |
| Ghost cyan | `#A8D5D9` | `SB_GHOST` | The ghost and supernatural effects only |
| Aged cream | `#E6D7B8` | `SB_CREAM` | Walls, curtains, paper, light fabric, body text |
| Dusty rose | `#B77C75` | `SB_ROSE` | The camelback sofa (Phase 1), mantel vase, wallpaper motif |
| Faded green | `#687B68` | `SB_GREEN` | The living-room window curtains (Phase 1), interior details |
| Antique gold | `#B58A50` | `SB_GOLD` | Brass, frames, handles, ornaments, UI borders |
| Muted brown-grey | `#62564D` | `SB_BROWN_GREY` | Soft and background contours, secondary shadows |

Contour colours: the main contour is `SB_CONTOUR #3B2C25` (dark muted brown); background and soft
contours use brown-grey (`SB_CONTOUR_SOFT`, from `#62564D`). The Gemini research proposes
`#62564D` as the primary contour; the built art test uses the darker brown for characters and
interactive objects so they stand out. PROVISIONAL with the palette.

Derived tones (lighter/darker walnut, wall, floor, fire core, ember, ash, glass by day and night,
moon, skin, shadow, and since Phase 1 fieldstone `SB_STONE #8A8379`, `SB_STONE_DARK #6A645C`,
`SB_STONE_LIGHT #A49D90`) live in `palette.gd` next to the core set; they are mixes of it, not new
hues. The rug uses darkened core colours so it stays below people and props in the hierarchy.

## 3. Cozy and haunted

**Cozy / normal:** warm amber and aged cream dominate the focal areas; walnut and olive give
structure; candlelight stays local to real light sources; shadows soft enough to read the room.

**Haunted / sabotaged:** ambient light shifts toward dusk blue and charcoal; warm contribution is
removed where a source is out; warm sources still burning in the game state keep their light;
cold local light (moon through the window), longer shadows and darker corners — never only a
uniform blue overlay. NPCs, props, routes and targets keep enough contrast.

## 4. Character colours — PROVISIONAL

One identity colour per family member for the HUD row, map dot and clothing accent
(`GameHud.NPC_COLORS`): father blue, mother green, grandma mauve, grandpa ochre, son red,
daughter yellow. They predate the storybook palette and are brighter than it; at the character
phase they should move to muted versions that stay distinct from each other.

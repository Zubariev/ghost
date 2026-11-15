# Art Direction — Whimsical Gothic Storybook

The main document for every visual decision. Read it before you build or change anything visual;
then read the guide for the area (below) and look at the concept images it points to.

- Direction approved: 2026-11-15 (user's art brief). Living room art test approved: 2026-11-15.
- Moved here from `design/art-direction.md` on 2026-11-15, with the concept images added under `art/`.
- Code that implements these rules: `src/game/art/` (`Palette`, `Ink`, `StorybookArt`,
  `StorybookShell`, `RoomMood`, `PropVisuals`), `assets/shaders/`, `assets/art/visual_style.json`.

## How to read the status labels

| Status | Meaning |
|---|---|
| **APPROVED** | Decided by the user. Follow it. |
| **PROVISIONAL** | Follow it unless there is a clear reason to revisit; say so before changing it. |
| **EXPERIMENTAL** | A direction being tried. Never let it become the standard without a decision. |
| **REJECTED** | Do not use. |

A concept image shows a direction; it is not a production asset. Never drop a whole concept
illustration in as a room background. Take its composition, shapes, materials, light and palette,
and build them with the game's own room, prop and character pieces.

## Intent — APPROVED

A hand-painted, illustrated fairy-tale look: warmth, domestic coziness, quirky humour, autumn
nostalgia, subtle gothic unease. The balance is about 40 % cozy, 30 % whimsical, 30 % mysterious.

**The defining contrast is a warm, familiar home slowly becoming an uncomfortable, haunted place.**

Inspiration: the *principles* of *Over the Garden Wall* — organic outlines, painterly textured
surfaces, expressive silhouettes, muted autumn colour, atmospheric light. Nothing is copied from it:
no characters, places, images or designs. All designs are original.

## Decisions

| Category | Decision | Status | Detail in |
|---|---|---|---|
| Art style | Whimsical Gothic Storybook, hand-painted illustration | APPROVED | this file |
| Camera and room view | Hamlet-style room box (back wall, two side walls, floor; one room on screen) — a gameplay decision, the art must fit it | APPROVED | Demo Spec §8.7, `ENVIRONMENT_GUIDELINES.md` |
| Palette | 13 storybook colours, no pure black, no saturated primaries | APPROVED | `COLOR_PALETTE.md` |
| Linework | Organic, wobbly, varying width, dark muted brown; strength by tier | APPROVED | `VISUAL_STYLE_GUIDE.md` |
| Surfaces | Soft shading, pigment variation, wood grain, woven fabric, faint paper grain | APPROVED | `VISUAL_STYLE_GUIDE.md` |
| Materials | Walnut wood, fieldstone, wool and velvet fabric, aged plaster, brass | PROVISIONAL | `VISUAL_STYLE_GUIDE.md` |
| Lighting | Two states per room, cozy and haunted, by colour grade and light pools | APPROVED | `ENVIRONMENT_GUIDELINES.md` |
| Shapes | Organic, slightly exaggerated, heavy bases, curved tops | PROVISIONAL | `VISUAL_STYLE_GUIDE.md` |
| Readability | Interactive objects and hiding spots stand out from decoration | APPROVED | `VISUAL_STYLE_GUIDE.md` |
| Depth layers | Background / furniture / interactive / characters / spectral, drawn in that order | PROVISIONAL | `ENVIRONMENT_GUIDELINES.md` |
| Foreground occluders | Large furniture in front of the camera, cut by the frame (as in the layer concepts) | EXPERIMENTAL | `ENVIRONMENT_GUIDELINES.md` |
| Living room | The art test, cozy and haunted | APPROVED | `environments/LIVING_ROOM.md` |
| Other ten rooms | Still placeholder look; roll the style out room by room | PROVISIONAL (planned) | `ENVIRONMENT_GUIDELINES.md` |
| Family character designs | Three concept sets disagree (see below) — no design chosen yet | EXPERIMENTAL | this file |
| Ghost design | Ghost cyan, faint glow, dusk-blue contour, simple and playful — APPROVED; its silhouette (round sheet vs. wispy tail) is EXPERIMENTAL | mixed | this file |
| UI style | Ornate dark-wood frames, parchment, brass (primary moodboard "UI Style") | EXPERIMENTAL | this file |
| Painted assets later | Every prop can be swapped for a PNG/WebP per state via `visual_style.json`; gameplay never depends on image size | APPROVED | `assets/art/props/sprite_guide.md` |

### Characters — EXPERIMENTAL

The six family members must stay readable at game size: distinct silhouettes, one colour
identity each (the HUD colours in `GameHud.NPC_COLORS`), and the traits from GDD §5.1/§5.4
(grandparents slow, daughter fastest on a tricycle, son with his computer, father the fixer).

The concepts do not agree yet:

- `art/moodboards/primary_moodboard.png` — father (moustache, waistcoat), mother (apron),
  grandma (glasses, wooden spoon), son, daughter with a doll and a small bicycle. No grandpa.
- `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` — a formal Victorian set;
  two elderly women, no grandpa.
- `art/concepts/characters/family_lineup_silhouettes.jpeg` — a rural, patched-clothes set with
  silhouette studies: a young father in a flat cap, mother with a basket, grandma with a cane and
  shawl, a stout grandpa with a pipe, son in a coat and hat, daughter in a pinafore.

**Decision needed before the family is redrawn** (roadmap: "redraw the six family members"):
which set, or which mix, becomes the family. Until then the game keeps its recoloured
placeholder figures.

### Ghost — mixed

Approved: ghost cyan `#A8D5D9`, faint glow, dusk-blue contour, simple and playful, never scary in
a horror sense. The colour grade spares the ghost (it stays cyan in a warm room).
Experimental: the silhouette. The game draws a round sheet ghost with a scalloped hem (as in the
primary moodboard); the other concepts show a wispy ghost with arms and a curling tail.

### UI — EXPERIMENTAL

The primary moodboard's "UI Style" panel: dark wooden frames with brass corners, a ghost portrait
beside the energy bar, slot buttons with drawn icons (candle, window, armchair, eye), a parchment
house map, a clock dial with the day and ×1/×2/×4. The game's HUD is still plain dark panels. Any
restyle keeps every element the HUD has today and its readability.

## Reference index

All images are original concept art made for this project. `art/` has a `.gdignore`, so Godot
does not import these files into the game.

| File | What it shows | Use it for | Status |
|---|---|---|---|
| `art/moodboards/primary_moodboard.png` | Whole-game board: house exterior, palette, key props, mood, kitchen day vs. night, family, ghost, props, UI, "be seen / hide" moments | Overall tone, props, UI direction | APPROVED as tone; parts EXPERIMENTAL as listed above |
| `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` | Exterior at dusk, living room cozy vs. haunted, palette strips, ghost, a family set, clock and oil lamp | The cozy/haunted contrast | APPROVED (contrast); characters EXPERIMENTAL |
| `art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` | Contours vs. form edges, wood / terracotta velvet / olive / parchment swatches, candlelight, dusk blue, ghost cyan, the same chairs cozy vs. haunted | Linework, materials, lighting states | APPROVED |
| `art/concepts/environments/living_room/living_room_base.jpeg` | The living room, empty: stone fireplace, arched window with green curtains, wainscot, sofa, armchairs, rug, bookcase | Living room furniture and materials | APPROVED (art test built from it) |
| `art/concepts/environments/living_room/living_room_cozy.jpeg` | The living room lived in: fire, lamps, portraits, father reading | Cozy state, wall decor | APPROVED |
| `art/concepts/environments/living_room/iterations/living_room_layers_v1.jpeg` | The room annotated with depth layers | Layer order | PROVISIONAL |
| `art/concepts/environments/living_room/iterations/living_room_layers_v2.jpeg` | Same, cleaner legend | Layer order | PROVISIONAL |
| `art/concepts/characters/family_lineup_silhouettes.jpeg` | A family set with silhouette studies, ghost | Silhouette readability | EXPERIMENTAL |

Missing: a haunted concept of the living room at full size (only the small panel in the
supplementary board), and concepts for the other ten rooms.

## Avoid — REJECTED

The recognisable character designs or identity of *Don't Starve* (the room *layout* idea from
*Hamlet* is a gameplay reference only). Anything copied from *Over the Garden Wall*. Generic mobile
cartoon looks, flat vector, thick uniform black outlines, photorealism, oversaturation, anime
styling, overly cute proportions, pure horror or gore.

## Guides

- `VISUAL_STYLE_GUIDE.md` — lines, shapes, surfaces, materials, proportions, readability.
- `COLOR_PALETTE.md` — the colours and where each is used.
- `environments/ENVIRONMENT_GUIDELINES.md` — how a room is built, its two states, layers.
- `environments/LIVING_ROOM.md` — the approved art test.

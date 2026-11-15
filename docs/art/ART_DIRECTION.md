# Art Direction — Whimsical Gothic Storybook

The main document for every visual decision in *Ghost vs. Humans*. Read it before building or
changing anything visual, then the guide for the area, then the concept images it points to.

- Direction approved 2026-11-15 (the user's art brief). Living room art test built and approved
  in-game 2026-11-15.
- Consolidated 2026-11-15 (Phase 0): the repository set (moved from `design/art-direction.md`)
  merged with the knowledge-base package the user supplied. The repository set is the source of
  truth for what is built and decided; the package added the OPEN status, the authority rules,
  the reference hierarchy, change control and the Gemini research report.
- Code that implements these rules: `src/game/art/` (`Palette`, `Ink`, `StorybookArt`,
  `StorybookShell`, `RoomMood`, `PropVisuals`, `FamilyArt`), `assets/shaders/`,
  `assets/art/visual_style.json`.

## 1. Status vocabulary

| Status | Meaning |
|---|---|
| **APPROVED** | Decided by the user. Mandatory. |
| **PROVISIONAL** | The current working choice. Follow it; it may be reviewed. Say so before changing it. |
| **EXPERIMENTAL** | A direction being tried. Must not silently become a production standard. |
| **OPEN** | Not decided. Surface it whenever it matters; never guess or settle it silently. |
| **REJECTED** | Do not use. |

## 2. Authority and conflicts

- **Gameplay, camera, room geometry, projection, navigation and demo scope** are governed by the
  GDD (`ghost_house_game_design_document_uk.md`) and the Demo Specification
  (`demo_specification_ghost_house_uk.md`). No art document overrides them.
- **Visual treatment** (style, palette, linework, materials, lighting, look of props and
  characters) is governed by this document and the guides it lists.
- If an art document appears to conflict with the GDD or the Demo Specification, **report the
  conflict before implementing**; do not silently choose one.
- An art task never changes gameplay, camera, room geometry, data coordinates, footprints,
  navigation or interaction as a side effect.

### Reference hierarchy (highest first)

1. Decisions the user approved explicitly (in conversation, recorded in these documents).
2. This document and its guides.
3. Approved concept art and moodboards (`art/`, see §7).
4. Experimental generated images.
5. External inspiration and research (`research/`).

A generated image does not become a standard because it is in `art/`.

## 3. Intent — APPROVED

A hand-painted, illustrated fairy-tale look: warmth, domestic coziness, quirky humour, autumn
nostalgia, subtle gothic unease. Target balance about 40 % cozy, 30 % whimsical, 30 % mysterious
(the balance itself is PROVISIONAL).

**The defining contrast is a warm, familiar home slowly becoming an uncomfortable, haunted place.**

Primary inspiration: the *principles* of *Over the Garden Wall* — organic outlines, painterly
textured surfaces, expressive silhouettes, muted autumn colour, atmospheric light. Nothing is
copied: no characters, places, compositions, frames, designs or assets. All designs are original.
Further research references (Gemini report: *The Secret of Kells*, *Song of the Sea*, Arthur
Rackham, Tove Jansson, Victorian/Edwardian and Arts and Crafts interiors, ink-and-watercolour
illustration) are inputs, not templates.

## 4. Style and spatial presentation — reconciliation

**APPROVED 2026-11-15 — applied to GDD §13.1 (v0.9) and Demo Specification §4.1 (v0.14).**

Earlier, GDD §13.1 and Demo Specification §4.1 named *Don't Starve* as the visual basis. They now
separate two things:

| Concern | Decision |
|---|---|
| Visual art direction (the look) | Whimsical Gothic Storybook |
| Spatial presentation (how a room is shown) | The *Don't Starve: Hamlet* interior framing, as a spatial and composition reference only |
| Camera, room geometry, projection, navigation, gameplay | Unchanged — as built and as the GDD/Spec define them |

The camera and room box are APPROVED (built and validated, spike 2026-11-12) and the storybook
look is APPROVED; anything that would need the recognisable *Don't Starve* identity is REJECTED
(§10). Still inconsistent wording, not yet changed: GDD §13.2's first sentence and the *Don't
Starve* block in §13.4 (proposed in `proposals/PHASE0_REVIEW.md` §2, not applied).

## 5. Decisions

| Category | Decision | Status | Detail in |
|---|---|---|---|
| Art style | Whimsical Gothic Storybook, hand-painted 2D illustration | APPROVED | §3 |
| *Over the Garden Wall* | Primary inspiration, principles only | APPROVED | §3 |
| Emotional balance | 40 / 30 / 30 | PROVISIONAL | §3 |
| Camera and room view | Hamlet-style room box (back wall, two slanted side walls, floor; one room on screen) | APPROVED (gameplay, GDD/Spec) | `environments/ENVIRONMENT_GUIDELINES.md` |
| GDD/Spec wording on *Don't Starve* | Storybook is the look; *Hamlet* a spatial reference only | APPROVED (GDD v0.9 §13.1, Spec v0.14 §4.1) | §4 |
| Palette | 13 storybook colours (values as in code) | **PROVISIONAL** — review after testing across rooms and states | `COLOR_PALETTE.md` |
| Linework | Organic, wobbly, varying width, dark muted brown, strength by tier | APPROVED (direction); exact values PROVISIONAL | `VISUAL_STYLE_GUIDE.md` |
| Surfaces and texture | Restrained paper grain, pigment variation, wood grain, woven fabric | APPROVED (direction) | `VISUAL_STYLE_GUIDE.md` |
| Materials | Wood, stone, fabric, plaster, brass, glass, paper | PROVISIONAL | `VISUAL_STYLE_GUIDE.md` |
| Shapes | Organic, slightly exaggerated | PROVISIONAL | `VISUAL_STYLE_GUIDE.md` |
| Readability hierarchy | Characters and ghost > interactive props > major furniture > architecture > decor | APPROVED | `VISUAL_STYLE_GUIDE.md` |
| Cozy and haunted states | Same room, same positions; light sources and a colour grade, never only a flat blue overlay | APPROVED | `environments/ENVIRONMENT_GUIDELINES.md` |
| Ghost draw order | Depth-sorted together with furniture and people (the ghost can be behind furniture) — important for stealth and hiding | **APPROVED** (2026-11-15) | `environments/ENVIRONMENT_GUIDELINES.md` |
| Foreground occluders | Large furniture in front of the camera, cut by the frame | OPEN — deferred to a later phase | `environments/ENVIRONMENT_GUIDELINES.md` |
| Living room — in-game art test | The built room, cozy and haunted, with the Phase 1 refinement | APPROVED | `environments/LIVING_ROOM.md` |
| Living room — concept image | **The visual target for Phase 1** (not its perspective or geometry) | APPROVED (as target) | `environments/LIVING_ROOM.md` |
| Living room — haunted concept | Full-size matching image | OPEN | `environments/LIVING_ROOM.md` |
| Other ten rooms | Placeholder look until restyled room by room | PROVISIONAL (planned) | `environments/ENVIRONMENT_GUIDELINES.md` |
| Family character designs | Three concept sets disagree | OPEN — deferred to the character phase | §6 |
| Ghost colour and glow | Ghost cyan, faint glow, dusk-blue contour, simple and playful | APPROVED | §6 |
| Ghost silhouette | Round sheet (built) vs. wispy tail (concepts) | OPEN — deferred | §6 |
| UI style | Dark wood, parchment, brass (primary moodboard) | EXPERIMENTAL | §6 |
| Painted assets | Props replaceable by images per state; gameplay never depends on image size | APPROVED (mechanism); spec PROVISIONAL | `SPRITE_SPEC.md` |
| Room-state visuals (dirt, polish, cold, embers) | GDD §13.3 visual language, every room | APPROVED — art Phase 2, approved 2026-11-15 | `environments/ENVIRONMENT_GUIDELINES.md` §4 |

## 6. Characters, ghost, UI

**Family — OPEN (deferred).** The six must stay readable at game size: distinct silhouettes, one
identity colour each (`GameHud.NPC_COLORS`), the traits of GDD §5.1/§5.4. Concepts disagree:

- `art/moodboards/primary_moodboard.png` — father (moustache, waistcoat), mother (apron), grandma
  (glasses, spoon), son, daughter with a doll and a small bicycle. No grandpa.
- `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` — a formal Victorian set;
  two elderly women, no grandpa.
- `art/concepts/characters/family_lineup_silhouettes.jpeg` — a rural set with silhouette studies:
  father in a flat cap (as the built placeholder), mother with a basket, grandma with a cane, a
  stout grandpa with a pipe, son in a coat and hat, daughter in a pinafore.

The game keeps its code-drawn placeholder figures until a set is chosen.

**Ghost.** APPROVED: ghost cyan `#A8D5D9`, faint glow, dusk-blue contour, simple and playful,
never horror. The colour grade spares the ghost. OPEN: the silhouette (built: round sheet with a
scalloped hem, as in the primary moodboard; other concepts: wispy with arms and a tail).

**UI — EXPERIMENTAL.** The primary moodboard's "UI Style": dark wooden frames with brass corners,
a ghost portrait beside the energy bar, icon slot buttons, a parchment map, a clock dial with the
day and ×1/×2/×4. The HUD is still plain dark panels; any restyle keeps every element and its
readability.

## 7. Reference index

All images are original concept art made for this project. `art/` has a `.gdignore`, so Godot
does not import them.

| File | What it shows | Use it for | Status |
|---|---|---|---|
| `art/moodboards/primary_moodboard.png` | Whole-game board: exterior, palette, key props, mood, kitchen day vs. night, family, ghost, props, UI, "be seen / hide" | Tone, props, UI direction | APPROVED as tone; parts EXPERIMENTAL/OPEN as above |
| `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` | Exterior at dusk, living room cozy vs. haunted, palette strips, ghost, a family set | Cozy/haunted contrast | APPROVED (contrast); characters OPEN |
| `art/moodboards/supplementary/materials_lines_lighting_sheet.jpeg` | Contours vs. form edges, wood / terracotta / olive / parchment swatches, candlelight, dusk blue, ghost cyan, chairs cozy vs. haunted | Linework, materials, lighting | APPROVED (direction) |
| `art/concepts/environments/living_room/living_room_cozy.jpeg` | The living room lived in: stone fireplace with fire, arched window, portraits, father reading. Same image as the package's `living_room_cozy_candidate.jpeg` | **Phase 1 visual target** | APPROVED (as target) |
| `art/concepts/environments/living_room/living_room_base.jpeg` | The same room, empty, candles in the fireplace | Furniture set and materials | APPROVED (supporting) |
| `art/concepts/environments/living_room/iterations/living_room_layers_v1.jpeg`, `_v2.jpeg` | The room annotated with depth layers | Layer thinking | PROVISIONAL (the ghost-on-top layer is not adopted: §5) |
| `art/concepts/characters/family_lineup_silhouettes.jpeg` | A family set with silhouette studies | Silhouette readability | OPEN |

Missing: a full-size haunted living room; concepts for the other ten rooms; a chosen family set.

## 8. Production constraints — APPROVED

- Visual presentation stays separate from gameplay logic; the room view reads the simulation and
  never changes it.
- **This project has no physics collision shapes.** Its equivalents are data: walking footprints
  (`assets/data/house/movement.json`), sight blockers, hiding spots and decor flags
  (`assets/data/house/furniture.json`), interaction and hiding range (`assets/data/ghost/`). None
  of them may be derived from, or changed for, an image.
- Painted images replace drawings only (`PropVisuals`); they never move or resize a piece.
- Do not use a whole concept illustration as a flattened room background.
- Decor must not compete with interactive sabotage targets.
- Character silhouettes and gameplay states stay readable at normal game scale.
- The architecture is one code-drawn room view (`RoomStage`) with depth sorting; art work fits
  into it rather than rewriting it into per-prop scenes, unless the user decides otherwise.

## 9. Change control

When a visual decision is accepted:

1. Update the relevant art document and the decision's status here.
2. Add or replace the supporting concept reference in `art/` and §7.
3. Record what it supersedes.
4. Never alter GDD/Spec gameplay or camera requirements as a side effect of an art task; propose
   such changes separately.

## 10. Avoid — REJECTED

The recognisable character designs or visual identity of *Don't Starve* (the *Hamlet* room
framing is a spatial reference only). Anything copied from *Over the Garden Wall* or any named
reference. Generic mobile cartoon looks, clean corporate vector art, thick uniform black
outlines, photorealism, photo-texture overlays and generic grunge filters, oversaturation, anime
styling, overly cute proportions, pure horror or gore, and a uniform blue filter as the only
haunted treatment.

## 11. Guides

- `VISUAL_STYLE_GUIDE.md` — shapes, lines, texture, materials, characters, readability, layering.
- `COLOR_PALETTE.md` — colours, roles, cozy and haunted use.
- `SPRITE_SPEC.md` — painted prop images (PROVISIONAL).
- `environments/ENVIRONMENT_GUIDELINES.md` — how a room is built, states, draw order, checklist.
- `environments/LIVING_ROOM.md` — the art test and the Phase 1 target.
- `research/GEMINI_ART_DIRECTION_REPORT.md` — research input, not decisions.
- `proposals/PHASE0_REVIEW.md` — Phase 0 changes and the proposed GDD/Spec wording.

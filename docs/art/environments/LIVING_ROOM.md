# Living Room — art test

| | Status |
|---|---|
| In-game art test (as built) | **APPROVED baseline** — built and approved 2026-11-15 (`6bfc25b`, `5f1a966`, evidence `d7e26aa`) |
| Concept `living_room_cozy.jpeg` | **APPROVED as the Phase 1 visual target** (user decision 2026-11-15) — its look, not its perspective or geometry |
| Full-size haunted concept | OPEN — none yet |

The first and so far only room in the storybook style.

## 1. Concepts

| Image | What to take from it |
|---|---|
| `art/concepts/environments/living_room/living_room_cozy.jpeg` (the package's `living_room_cozy_candidate.jpeg`, same image, 1375 × 768) | **Target.** Large fieldstone fireplace with a lit fire and a heavy wooden mantel with a clock, photos and a vase; tall arched window with heavy green curtains and tiebacks; walnut wainscot below cream plaster; several framed portraits; dusty-rose camelback sofa; terracotta wingback; olive and mismatched chairs; small side tables with lamps; blue-and-orange patterned rug; tall bookcase; father reading |
| `art/concepts/environments/living_room/living_room_base.jpeg` | The same room empty: furniture shapes and materials without people |
| `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` | Cozy beside haunted (small panel): desaturated dusk blue, cold fire |
| `.../iterations/living_room_layers_v1.jpeg`, `_v2.jpeg` | Layer thinking only (ghost-on-top not adopted) |

## 2. What is built (data, unchanged by art work)

From `assets/data/house/furniture.json` → `living_room` (u, v floor coordinates):

| Piece | Position | Gameplay role |
|---|---|---|
| Window | (0.45, back wall) | `window_living_room` — ghost can open it (cold) |
| Rug | (0.50, 0.55) | flat, walked over |
| Sofa | (0.38, 0.32) | hiding spot `hide_living_room_sofa_2` (searchable, large) |
| Armchair (terracotta wingback) | (0.78, 0.55) | `grandma_armchair` — seat and hiding spot |
| Side table | (0.62, 0.30) | furniture |
| Floor lamp | (0.12, 0.78) | `lamp_living_room` — ghost can snuff it (dark) |
| Fireplace | (0.18, back wall) | decor; burns unless the room is cold |
| Wall clock | (0.585, back wall) | decor |
| Painting, portrait | (0.69, back wall) | decor |
| Painting, landscape | (0.81, back wall) | decor |
| Bookshelf | (0.90, 0.06) | decor |
| Armchair, olive | (0.10, 0.15) | decor |
| Tea table | (0.06, 0.24) | decor |

Decor pieces are drawn only and stand off every family route (a test checks). Doors are where the
house plan puts them (side walls).

## 3. Built vs. target (what Phase 1 should close)

All visual; no position, footprint or size in data changes.

| Element | Target (concept) | Built now |
|---|---|---|
| Fireplace | Large fieldstone fireplace, chimney breast rising to the ceiling, heavy wooden mantel | Small grey plaster fireplace with a thin mantel |
| Window | Tall arched window, heavy **green** velvet curtains, tiebacks | Rectangular window, terracotta curtains, rose valance |
| Sofa | Dusty-rose camelback | **Faded green (olive-toned)** camelback with dusty-rose cushions |
| Rug | Rectangular, blue and orange pattern | Oval, dusty rose with a gold ring |
| Walls | Walnut wainscot panels below cream plaster on all walls | Panelled wainscot on the back wall; side walls have a plain walnut band without panels |
| Portraits | Several framed portraits and photos | Two paintings (portrait, landscape) |
| Mantel | Clock, framed photos, vase | Small items |
| Side lamps | Table lamps on small tables | One floor lamp (the interactive one) |
| Fire | Log fire (cozy concept) / candles (base concept) | Log fire, out when cold |
| Characters | Painted people | Code-drawn placeholders (deferred to the character phase) |

Perspective and room shape stay as built (the box); the concept's free perspective is not copied.

## 4. Open production questions (from the package), answered for the built room

| Question | Answer now |
|---|---|
| Does the perspective match the GDD room presentation? | No — the concept is free perspective; the game keeps the box (by decision). |
| Enough unobstructed floor for navigation? | Yes — layout comes from data and family routes are tested. |
| Do foreground chairs block the playable space? | Not built (occluders OPEN). |
| Are NPCs and the ghost readable around furniture? | To verify in the Phase 1 review (§6). |
| Which items are interactive? | Window, floor lamp, grandma's armchair, sofa (hiding/search). The rest is decor. |
| How is the room split into assets? | Code-drawn pieces per furniture entry; any piece can become a painted image per state (`../SPRITE_SPEC.md`). |

## 5. States

- **Cozy** — lamp lit, window shut, fire burning.
- **Haunted** — lamp out, window open, fire out.

Same layout, positions and camera. Capture: `bash tools/play.sh art-test` →
`production/qa/evidence/art-test-living-room/`.

## 6. Phase 1 art integration review (required before sign-off)

- [ ] NPC readability against furniture and backgrounds (each family member, cozy and haunted).
- [ ] Interactive prop readability (window, lamp, armchair, sofa) and their states.
- [ ] Ghost visibility and depth sorting (in front of / behind the sofa and armchair; hidden glint).
- [ ] Walkable floor readability (routes visible against the new rug and floor).
- [ ] Cozy and haunted consistency (same room, readable in both).
- [ ] Preservation of all gameplay: full test suite passes; `furniture.json`, `movement.json` and
      geometry unchanged; headless day run without errors.
- [ ] Side-by-side screenshots with the concept retained in `production/qa/evidence/`.

## 7. Open

- Full-size haunted concept.
- Family redraw (character phase).

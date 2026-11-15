# Living Room — art test

| | Status |
|---|---|
| In-game art test (as built) | **APPROVED baseline** — built and approved 2026-11-15 (`6bfc25b`, `5f1a966`, evidence `d7e26aa`); Phase 1 refinement **APPROVED** 2026-11-15 (user moved on to Phase 2) |
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

## 3. Built vs. target

Phase 1 (2026-11-15, evidence `production/qa/evidence/art-phase1-living-room/`) moved the room
toward the concept. All visual; no position, footprint or size in data changed.

| Element | Target (concept) | Before Phase 1 | After Phase 1 |
|---|---|---|---|
| Fireplace | Large fieldstone fireplace, chimney to the ceiling, heavy mantel | Small grey plaster fireplace | Fieldstone chimney breast to the ceiling, narrowing above a heavy walnut mantel on corbels; stone-arched firebox with andirons; stone hearth |
| Window | Tall arched, heavy **green** curtains, tiebacks | Rectangular, terracotta curtains, rose valance | Tall arched window with small panes and a fanlight; green curtains to the floor on a rod with gold finials; gold tiebacks with tassels |
| Sofa | Dusty-rose camelback | Faded green, rose cushions | **Dusty rose**, walnut base rail, olive and cream throw pillows |
| Rug | Rectangular, blue and orange pattern | Oval, rose with a gold ring | Rectangle laid in floor perspective (u ±0.20, v ±0.12): muted terracotta border, dusk-blue field, parchment medallion and corner motifs, cream fringe |
| Walls | Walnut wainscot panels on all walls | Panels on the back wall, plain band on the sides | Panel mouldings on the side walls too |
| Portraits | Several framed portraits and photos | Two paintings | Two paintings, three framed family photos on the mantel, and two side-wall portraits (a lady on the left wall, a child on the right, near the back; `visual_style.json` → `wall_portraits`) |
| Mantel | Clock, framed photos, vase | Small items | Candle, three framed photos, vase with a sprig (the pendulum clock stays on the wall) |
| Side lamps | Table lamps on small tables | One floor lamp | Unchanged — a decorative lit lamp would mislead when the ghost has put the real lamp out |
| Characters | Painted people | Code-drawn placeholders | Unchanged (character phase) |

Still different, by design: the room box instead of the concept's free perspective; the
fireplace is smaller than the concept's (its width is set by the back-wall space between the
room's left edge and the window, and its position by `furniture.json`); the side-wall portraits
are narrow because the side walls are steeply foreshortened, and sit near the back because the
side doors take the middle of each wall.

### Phase 1 review result (2026-11-15)

| Check | Result |
|---|---|
| Family readable against furniture and background (cozy, haunted) | Pass |
| Interactive props readable, states visible | Pass |
| Ghost visibility and depth sorting (behind / in front of the sofa, hidden glint) | Pass — glint in the rose sofa is faint (follow-up, gameplay feedback) |
| Walkable floor readable | Pass — rug muted after the first capture so it stays below people and props |
| Cozy and haunted consistent | Pass |
| Gameplay preserved | Pass — 240 tests; no change to `assets/data`, `src/sim`, room geometry, layout or paths |

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

# Living Room — art test

| | Status |
|---|---|
| In-game art test (as built) | **APPROVED baseline** — built and approved 2026-11-15 (`6bfc25b`, `5f1a966`, evidence `d7e26aa`); Phase 1 refinement **APPROVED** 2026-11-15 (user moved on to Phase 2) |
| Concept `living_room_cozy.jpeg` | **APPROVED as the Phase 1 visual target** (user decision 2026-11-15) — its look, not its perspective or geometry |
| Full-size haunted concept | OPEN — none yet |
| Painted fireplace (art Phase 3 trial) | **APPROVED** — built and approved 2026-11-15 (§8); shrunk to 76 % (scale 0.38) for the real-world scale, 2026-11-20 |
| Layout in metres (Phase B pilot) | **Built 2026-11-20, awaiting user review** (§10) |
| Painted props (art Phase 4) | **Built 2026-11-20, awaiting user review** — window (closed / open), sofa, both armchairs, side and tea tables, wall clock (painted hands: a stopped clock), both paintings, bookshelf; brass floor lamp (lit / out); rug 2.5 × 1.8 m and side-wall portraits ~60 % (still code-drawn); evidence `production/qa/evidence/art-phase4-props/` |

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

## 8. Phase 3 — painted fireplace trial (APPROVED, 2026-11-15)

The first painted prop, to test the sprite path (`../SPRITE_SPEC.md`) before any more are made.

**Source.** Generated images kept as references in `art/concepts/props/fireplace/`:
- First try: `fireplace_source_empty.jpeg` / `fireplace_source_burning.jpeg` (1200 × 896 JPEG, white
  background). Rejected after the first capture: seen at an angle (the user asked for straight-on;
  SPRITE_SPEC asks for a front view), tall and narrow (~171 px wide against the code's ~228), bare
  mantel; the burning one has its flames painted in.
- **Used:** `fireplace_source_front.png` (1402 × 1122 PNG, opaque white background): straight-on
  elevation, empty firebox with an iron grate, the mantel's candle, three framed family photos and
  rose vase painted in, even light.

**Sprite.** `assets/art/props/fireplace.png`, 410 × 387 RGBA, made with `tools/sprite_cutout.gd`
(`-- <source> <out> 170 0.4174`): white background removed by flood fill from the border plus
enclosed near-white pockets (the candlestick's handle loop, gaps in the sprig), edges un-blended
(no fringe on dark or magenta), the chimney cut at source row 170 so it meets the ceiling line,
scaled to 0.4174, 4 px transparent padding. Imported lossless, no mipmaps (Godot defaults; no
shimmer or blur seen at half size).

**Config** (`assets/art/visual_style.json` → `sprites.fireplace`): `anchor` [0.5, 0.888] (the
chimney breast's centre where it meets the hearth, i.e. the piece's back-wall point), `scale` 0.5
(2× art), `effects` offset [0, −2] and scale 1.0 (the painted firebox is as wide as the code one).
On screen: about 205 × 194 px — the breast ~171 px wide (code: 176) and exactly back-wall high
(170 px), the mantel at about the code mantel's height, the hearth ~19 px onto the floor.

**Fire stays code.** One image for both states. The fire, its glow, the smoke from a cold grate and
the fading embers are still drawn by code, on top of the image at the effects point
(`StorybookArt.draw_effects`, called by `RoomStage._draw_piece` after the sprite). No painted fire is
used: it would not go out when the room turns cold.

**Unchanged.** `furniture.json` (u 0.18, back wall, decor), geometry, camera, draw order (the
fireplace is a wall piece, drawn before the depth-sorted furniture, people and ghost), firelight
pools on the floor, gameplay. `--code-art` (`bash tools/play.sh art-test <dir> --code-art`)
draws every prop in code again, for comparison; a missing image falls back to code by itself.

**Painted flame layer (2026-11-15, after the trial's approval).** The flat code flames looked
pasted on in the painted firebox. Now `effects.states.burning` draws
`assets/art/props/fireplace_flames.png` (140 × 124, ~70 × 62 px on screen; source
`art/concepts/props/fireplace/fireplace_flames_source.png`, cut out with `-- <source> <out> 0 0.115`)
at the firebox floor while the fire burns, with a gentle flicker (`flicker` 0.06: a stretch and a
sway about the logs). The code glow and the floor firelight stay; out, the layer goes and the code
smoke and embers show. A missing file brings the code flames back. The logs are drawn in front of
the painted grate (it is low, so they read as piled on it).

**Differences from the code-drawn fireplace (to review).**
- The mantel candle is painted unlit; the code drawing lit it while the fire burned.
- The hearth is a raised stone step seen from the front, not a slab laid in the floor's perspective.

**Review checklist** (captures `production/qa/evidence/art-phase3-fireplace/`, code version in
`…-code/`): scale and alignment on the back wall; clean edges; readable at game scale; fits the
storybook look beside code-drawn pieces; the ghost in front of it (shots 09, 10); fire and smoke
inside the firebox; cozy and haunted.

### Painted walls and floor — feasibility (not built)

- The shell is drawn by `StorybookShell` as fixed screen-space polygons from `RoomGeometry`
  (floor trapezoid, back wall rectangle, two side-wall trapezoids), then doors, wear, light pools
  and the grade on top. The room box never moves, so painted surfaces can be added without
  touching geometry, projection or navigation.
- **Recommended:** images painted *already in the box's projection* (one per surface, sized to
  its screen polygon, transparent outside it), drawn instead of the code surface by the same
  kind of config as `sprites` (e.g. `shell` per room and surface). No distortion, no new
  rendering path. Doors, the wall fade (alpha when the ghost is in a wall), wear, light and the
  grade stay code and sit on top. Cost: one set of images per room look.
- **Alternative:** tileable textures mapped onto the polygons with `draw_polygon` UVs. Godot 2D
  maps each triangle affinely, so a trapezoid shows a skew along its diagonal; it needs the
  surface cut into many thin strips. Cheaper art, more code, plank/panel lines less controllable.
- Either way: painted wall art must leave the door openings to the code (doors differ per room),
  and must not bake in light or the wainscot's state.

## 10. Phase B — laid out in metres (user approval 2026-11-20)

The room is **7 × 5 m** (`rooms.json` size_m). Positions below are metres from the left wall (x)
and the back wall (depth); `furniture.json` stores them as fractions of the room (u = x / 7,
v = depth / 5). Walking footprints are the pieces' real sizes (`movement.json`).

```
      back wall
   +--------------------------------------------------------+
0.0|      FFFFFFFFFFFFFF                           BBBBBBB  |
0.2|                                               BBBBBBB  |
0.5|                                                        |
0.8|   oooooo                                               |
1.0|   oooooo                                       GGGGG   |
1.2|   ooo4oo tttt                                  GGGGG   |
1.5|          tttt                                          |
1.8|                SSSSSSSSSSSSSSSS ssss                   |
2.0D........        SSSSSSSSSSSSSSSS ssss           ........D
2.2D........        SSSS1SSSSSS2SSSS                ........D
2.5D........        SSSSSSSSSSSSSSSS~~~~ lllAAAAAAA ........D
2.8D........        ~~~~~~~~~~~~~~~~~~~~    AAAAAAA ........D
3.0|                ~~~~~~~~~~~~~~~~~~~~    AAA3AAA         |
3.2|                ~~~~~~~~~~~~~~~~~~~~                    |
3.5|                ~~~5~~~~~~~~6~~~~~~~                    |
3.8|                ~~~~~~~~~~~~~~~~~~~~                    |
4.0|  fffff                                          ppppp  |
4.2|  fffff                                          ppppp  |
4.5|  fffff                                          ppppp  |
4.8|                                                        |
   +--------------------------------------------------------+
    0 m                                              7 m   (front, open side: camera)
  L  landscape painting (wall, 1.3 m up)  at 0.40, 0.05 m  (0.6 x 0.1)
```

| Piece | x, depth (m) | Role |
|---|---|---|
| Landscape painting | 0.4 (wall, 1.3 m up) | decor |
| Fireplace | 1.6 (wall) | decor |
| Wall clock | 2.95 (wall, 1.15 m up) | decor |
| Window | 4.2 (wall) | `window_living_room` |
| Portrait | 5.45 (wall, 1.25 m up) | decor |
| Bookshelf | 6.35, 0.3 | decor |
| Gramophone on a cabinet **(new)** | 6.35, 1.25 | furniture (an obstacle: it stands in the way to the window) |
| Olive armchair | 0.75, 1.1 | furniture — grandpa's seat (was decor) |
| Tea table | 1.45, 1.45 | furniture (was decor: routes to grandpa crossed it) |
| Sofa | 3.0, 2.2 | hiding spot — father's and mother's seats |
| Side table | 4.35, 2.1 | furniture |
| Floor lamp | 4.8, 2.6 | `lamp_living_room` |
| Grandma's armchair | 5.45, 2.95 | `grandma_armchair`, hiding spot — grandma's seat |
| Rug 2.5 × 1.8 m | 3.2, 3.2 | walked over — son and daughter (her dolls) |
| Fern on a stand **(new)** | 0.55, 4.35 | decor |
| Potted palm **(new)** | 6.45, 4.35 | decor |

**Doors:** left (workshop) and right (hall) at depth 2.5 m; a 1 m clear zone in front of each
holds nothing. **Seats** (`furniture.json` "seats", metres): where each family member rests or
plays when the activity names no object — father 2.55, 2.35; mother 3.45, 2.35; grandma 5.45,
3.05; grandpa 0.75, 1.25; son 2.4, 3.7; daughter 3.6, 3.5. The decor test checks that no route
between the doors, the work spots and the seats crosses decor.

## 9. Open

- Full-size haunted concept.
- Family redraw (character phase).

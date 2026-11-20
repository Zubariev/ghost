# Dining Room

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/dining_room/`) |
| Layout in metres (Phase B) | **Built 2026-11-20, awaiting user review** (§ Phase B below) |
| Painted props | **Built 2026-11-20, awaiting user review** — window (closed / open, plum curtains), sideboard, dining table (meal `none` / `ready`), chairs; standard floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `dining_room` · in-game name «Їдальня» · ground floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

Where the whole family meets three times a day. A long table in the middle, a sideboard full of the good china, a tall window. It must read as the place of family ritual: when the meal is laid the room is full and warm; when the food is late or cold the empty table says so.

**Who uses it** (schedules): all six family members at 07:00, 12:00 and 19:00 (breakfast, lunch, dinner). The meal (`meal_food`) appears on the table when cooked.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.5, back wall) | `window_dining_room` (closed / open) — the ghost can change it (→ open) | — |
| sideboard | (0.82, 0.08) | hiding spot `hide_dining_room_sideboard_1` (large grid); blocks sight | ~118 px |
| rug | (0.5, 0.6) | furniture | — |
| dining_table | (0.5, 0.58) | `meal_food` (none / ready); hiding spot `hide_dining_room_table` (small grid) | ~228 px |
| chair | (0.24, 0.58) | furniture | ~44 px |
| chair | (0.76, 0.58) | furniture | ~44 px |
| floor_lamp | (0.1, 0.82) | `lamp_dining_room` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- left wall (v ≈ 0.5) → Хол (`hall`)
- right wall (v ≈ 0.5) → Кухня (`kitchen`)

The table is both the meal and a small hiding spot under the tablecloth. Only two chairs are pieces (u 0.24 and 0.76); people at the table are placed by the code.

## 3. Light and the two states

**Warm anchor:** the lamp (front left) and the window's daylight; at night the laid table should feel warm. No candles that stay lit when the lamp is out (they would mislead, as in LIVING_ROOM §3).

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: warm light over the table | Out: the table in shadow |
| Window | Closed, curtains tied back | Open: cold draught across the floor, frost (code) |
| Meal | Laid: plates, a tureen, bread | Not laid / missed: a bare cloth |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** deep bottle-green damask wallpaper above a walnut dado, a plate rail with blue-and-white plates
- **Floor:** dark polished boards, a large rectangular rug under the table
- **Details:** a still-life painting, a wall clock, the sideboard's candlesticks (unlit), a fruit bowl
- **Mood:** formal but loved; the room most changed by the family's routine

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of a family dining room in an old house: a long walnut dining table with a white cloth, set for supper with a soup tureen, bread and plates, simple wooden chairs, a tall carved sideboard with blue-and-white china and two brass candlesticks (unlit), bottle-green damask wallpaper above a walnut dado, a plate rail, a tall window with heavy curtains, a brass floor lamp giving a warm pool of light, a large patterned rug. Hand-inked dark-brown outlines, painted textures, warm amber light against cool shadows. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a tall sash window with heavy plum curtains tied back |
| sideboard | One image (closed doors). | ~100 px | a tall carved walnut sideboard with glazed upper doors, blue-and-white china, two brass candlesticks (unlit) |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a large rectangular rug, faded red and gold |
| dining_table | Two images or one plus a layer: the empty table, and the meal laid (`meal_food` none / ready) — preferred: the table once, the laid meal as an `effects.states.ready` layer. | ~75 px | a long walnut table with a white cloth, seen from the front; layer: a tureen, bread, plates and cups (the laid meal) |
| chair | One image (dining chair, seen from the front). | ~85 px | a plain wooden dining chair with a rush seat |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `chair`, `floor_lamp`, `rug`, `window` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"dining_room/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- Whether the meal is a painted layer on the table (`effects.states.ready`, recommended) or a second table image.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] Six people around the table stay readable against the cloth and chairs.
- [ ] Laid and empty table are clearly different.
- [ ] The hiding spot under the table reads as possible (tablecloth hangs low).

## Phase B — laid out in metres (built 2026-11-20, awaiting user review)

The room is **5.0 × 4.5 m** (`rooms.json` size_m); `furniture.json` stores x / 5.0 and depth / 4.5.
Footprints are real sizes (`movement.json`). Doors: left (hall), right (kitchen); the 1.2 m × 1 m zone inside each side,
back or front door (`.` below) holds nothing (test `test_nothing_stands_in_front_of_a_door`), and no
family route crosses decor (`test_no_family_route_in_any_room_crosses_decor`). Letters are pieces
that stand on the floor; digits are seats (furniture.json "seats").

```
   +----------------------------------------+  back wall
0.0|                            AAAAAAAAAA  |
0.2|  GGGG                      AAAAAAAAAA  |
0.5|  GGGG                                  |
0.8|                                        |
1.0|                                        |
1.2|                                        |
1.5|              BBBB    CCCC              |
1.8D........    DDDDDDDDDDDDDDDD    ........D
2.0D........ EEEDDDDDDDDDDDDDDDDFFF ........D
2.2D........ EEEDDDDDDDDDDDDDDDDFFF ........D
2.5D........    DDDDDDDDDDDDDDDD    ........D
2.8|                                        |
3.0|                                        |
3.2|                                        |
3.5|                                        |
3.8|                                  HHHH  |
4.0|                                  HHHH  |
4.2|                                        |
   +----------------------------------------+  front (camera)   5.0 x 4.5 m
```

| | Piece | x, depth (m) | Role |
|---|---|---|---|
| - | window | 2.50 (wall) | `window_dining_room` |
| A | sideboard | 4.10, 0.30 | hiding spot, blocks sight |
| B | chair | 2.00, 1.65 | furniture |
| C | chair | 3.00, 1.65 | furniture |
| - | rug | 2.50, 2.30 | walked over |
| D | dining table | 2.50, 2.30 | `meal_food`, hiding spot |
| E | chair | 1.30, 2.30 | furniture |
| F | chair | 3.70, 2.30 | furniture |
| G | floor lamp | 0.50, 0.50 | `lamp_dining_room` |
| H | plant (fern) | 4.50, 3.95 | decor |

**Places at the table** (furniture.json "object_seats" → `meal_food`, metres): father 2.0, 1.75 and mother 3.0, 1.75 behind it; grandma 1.3, 2.4 and grandpa 3.7, 2.4 at the ends; son 2.1, 2.95 and daughter 2.9, 2.95 in front.


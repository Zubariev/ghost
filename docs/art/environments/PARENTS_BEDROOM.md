# Parents' Bedroom

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/parents_bedroom/`) |
| Layout in metres (Phase B) | **Built 2026-11-20, awaiting user review** (§ Phase B below) |
| Painted props | **Built 2026-11-20, awaiting user review** — window (closed / open, rose curtains over lace), double bed, walnut wardrobe; standard floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `parents_bedroom` · in-game name «Спальня батьків» · upper floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The mother and father's room upstairs: a big double bed, a tall wardrobe, a rug, a lamp and a window. They sleep here from 22:00 to 06:00. It should feel private and settled — the one room that is theirs.

**Who uses it** (schedules): father and mother sleep 22:00–06:00.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.7, back wall) | `window_parents_bedroom` (closed / open) — the ghost can change it (→ open) | — |
| double_bed | (0.38, 0.3) | hiding spot `hide_parents_bedroom_bed` (large grid) | ~180 px |
| wardrobe | (0.88, 0.05) | hiding spot `hide_parents_bedroom_wardrobe_2` (large grid; unique find: lore_diary_3); blocks sight | ~90 px |
| rug | (0.45, 0.75) | furniture | — |
| floor_lamp | (0.12, 0.62) | `lamp_parents_bedroom` (lit / out) — the ghost can change it (→ out) | ~36 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- right wall (v ≈ 0.5) → Коридор (2 поверх) (`upper_corridor`)

The bed and the wardrobe are large hiding spots; the wardrobe blocks sight and hides diary page 3.

## 3. Light and the two states

**Warm anchor:** the bed and the lamp (front left).

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: warm bedside light | Out: dark, moonlight from the window |
| Window | Closed | Open: draught, frost; the sleepers get cold (breath is not shown while asleep) |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** dusty-rose striped wallpaper, a picture rail, a wedding photograph
- **Floor:** boards with a soft rug at the foot of the bed
- **Details:** a quilt, a bedside table with a clock and a book, a hat box on the wardrobe
- **Mood:** quiet, adult, a little worn

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of a married couple's bedroom in an old house: a carved wooden double bed with a patchwork quilt, a tall walnut wardrobe with a hat box on top, dusty-rose striped wallpaper, a framed wedding photograph, a soft rug, a sash window with lace and heavy curtains, a brass floor lamp. Hand-inked dark-brown outlines, painted textures, warm lamplight against moonlit blue. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a sash window with lace under heavy dusty-rose curtains |
| double_bed | One image, made bed; a sleeping person is drawn over it by the code. | ~95 px | a carved wooden double bed with a patchwork quilt and two pillows |
| wardrobe | One image (doors shut). Blocks sight. | ~185 px | a tall walnut wardrobe with two doors and a hat box on top |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a soft rectangular rug, muted blue |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `double_bed`, `floor_lamp`, `rug`, `wardrobe`, `window` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"parents_bedroom/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The grandparents' bed and wardrobe are the same kinds: each bedroom's own painting goes under `parents_bedroom/<kind>` and `grandparents_bedroom/<kind>`.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] Two sleepers read in the bed at night (cozy and haunted).
- [ ] The wardrobe hiding spot reads; the ghost behind it is hidden as before.

## Phase B — laid out in metres (built 2026-11-20, awaiting user review)

The room is **5.0 × 4.5 m** (`rooms.json` size_m); `furniture.json` stores x / 5.0 and depth / 4.5.
Footprints are real sizes (`movement.json`). Doors: right (upper corridor); the 1.2 m × 1 m zone inside each side,
back or front door (`.` below) holds nothing (test `test_nothing_stands_in_front_of_a_door`), and no
family route crosses decor (`test_no_family_route_in_any_room_crosses_decor`). Letters are pieces
that stand on the floor; digits are seats (furniture.json "seats").

```
   +----------------------------------------+  back wall
0.0|          AAAABBBBBBBBBBBBBB  CCCCCCCCC |
0.2|          AAAABBBBBBBBBBBBBB  CCCCCCCCC |
0.5|              BBBBBBBBBBBBBB  CCCCCCCCC |
0.8|  DDD         BBBBBBBBBBBBBB            |
1.0|  DDD         BBBBBBBBBBBBBB            |
1.2|              BBBBBBBBBBBBBB            |
1.5|              BBBBBBBBBBBBBB            |
1.8|              BBBBBBBBBBBBBB    ........D
2.0|              BBBBBBBBBBBBBB    ........D
2.2|                                ........D
2.5|                 2      1       ........D
2.8|                                        |
3.0|                                        |
3.2|                                        |
3.5|  EEEE                                  |
3.8|  EEEE                                  |
4.0|  EEEE                                  |
4.2|                                        |
   +----------------------------------------+  front (camera)   5.0 x 4.5 m
```

| | Piece | x, depth (m) | Role |
|---|---|---|---|
| - | window | 1.20 (wall) | `window_parents_bedroom` |
| A | nightstand | 1.45, 0.30 | furniture |
| B | double bed | 2.60, 1.10 | hiding spot |
| C | wardrobe | 4.35, 0.35 | hiding spot, blocks sight |
| D | floor lamp | 0.45, 1.00 | `lamp_parents_bedroom` |
| - | rug | 2.60, 3.00 | walked over |
| E | plant (fern) | 0.50, 3.90 | decor |

**Seats:** father 3.0, 2.6; mother 2.2, 2.6.


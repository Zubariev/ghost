# Children's Bedroom

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/children_bedroom/`) |
| Layout in metres (Phase B) | **Built 2026-11-20, awaiting user review** (§ Phase B below) |
| Painted props | **Built 2026-11-20, awaiting user review** — window (closed / open, starry yellow curtains), two different beds (patchwork; `starry` variant added to `furniture.json`), computer desk (`working` / `broken`, old beige computer — the proposed era), toy box, easel; star floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `children_bedroom` · in-game name «Дитяча спальня» · upper floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The son and daughter's shared room: two beds, the son's computer desk, a toy box, the daughter's easel, a lamp and a window. They play and draw here in the morning and sleep from 22:00. Bright and messy compared to the rest of the house — the one place with colour and toys.

**Who uses it** (schedules): the daughter (dolls 08:00, drawing 09:00) and the son (play 08:00 and 17:00); both sleep from 22:00.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.5, back wall) | `window_children_bedroom` (closed / open) — the ghost can change it (→ open) | — |
| bed | (0.18, 0.3) | furniture | ~98 px |
| bed | (0.42, 0.3) | hiding spot `hide_children_bedroom_bed` (small grid) | ~98 px |
| computer_desk | (0.8, 0.2) | `computer` (working / broken) — the ghost can change it (→ broken) | ~85 px |
| toy_box | (0.62, 0.72) | hiding spot `hide_children_bedroom_toy_box_4` (small grid; unique find: lore_toy_horse) | ~94 px |
| easel | (0.3, 0.78) | furniture | ~58 px |
| floor_lamp | (0.92, 0.82) | `lamp_children_bedroom` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- left wall (v ≈ 0.5) → Коридор (2 поверх) (`upper_corridor`)

The computer (`computer`, working / broken) is the ghost's target here. The second bed (u 0.42) and the toy box (toy horse) are small hiding spots; the first bed is not.

## 3. Light and the two states

**Warm anchor:** the lamp (front right) and the computer screen (a cool glow while working).

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: warm | Out: dark, the screen glow if working |
| Window | Closed | Open: draught, frost; the children feel cold |
| Computer | Working | Broken: cracked screen |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** pale blue paper with small stars, children's drawings pinned up, a height chart
- **Floor:** boards with a bright rag rug
- **Details:** toys on the floor (decor, off routes), a model plane hanging, a bookshelf of picture books
- **Mood:** warm, colourful, the most alive room — the haunted state should feel most wrong here

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of two children's shared bedroom in an old house: two small wooden beds with patchwork quilts, a desk with an old beige computer and a chair, a painted toy box, a child's easel with a painting, pale blue wallpaper with small stars, children's drawings pinned up, a model plane hanging, toys on a rag rug, a window, a brass floor lamp. Hand-inked dark-brown outlines, painted textures, warm lamplight. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a window with yellow curtains with small stars |
| bed | One image, child's bed; a sleeping child is drawn over it. | ~85 px | a small wooden child's bed with a patchwork quilt and a stuffed toy |
| computer_desk | Two images: `working` (screen on, neutral), `broken` (cracked screen). Screen glow, if any, is code. | ~95 px | a wooden desk with an old beige computer, keyboard and chair; second image: the screen cracked |
| toy_box | One image (lid shut). | ~50 px | a painted wooden toy box with the lid shut |
| easel | One image, a child's painting on it. | ~110 px | a child's easel with a bright painting of a house |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `floor_lamp`, `window` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"children_bedroom/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The computer's era: the brief proposes an old beige computer so it fits the storybook house — to confirm.
- Screen glow while working: code glow (`effects`), like the lamp.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] The computer and its two states read; the broken one without the code's effects.
- [ ] The hiding bed is distinguishable from the other bed.
- [ ] Two children asleep read at night.

## Phase B — laid out in metres (built 2026-11-20, awaiting user review)

The room is **5.0 × 4.5 m** (`rooms.json` size_m); `furniture.json` stores x / 5.0 and depth / 4.5.
Footprints are real sizes (`movement.json`). Doors: left (upper corridor); the 1.2 m × 1 m zone inside each side,
back or front door (`.` below) holds nothing (test `test_nothing_stands_in_front_of_a_door`), and no
family route crosses decor (`test_no_family_route_in_any_room_crosses_decor`). Letters are pieces
that stand on the floor; digits are seats (furniture.json "seats").

```
   +----------------------------------------+  back wall
0.0|        CCCCCCCC BBBBBB DDDDDDDD        |
0.2|        CCCCCCCC BBBBBB DDDDDDDD   AAA  |
0.5|        CCCCCCCC        DDDDDDDD        |
0.8|        CCCCCCCC        DDDDDDDD        |
1.0|        CCCCCCCC        DDDDDDDD        |
1.2|        CCCCCCCC        DDDDDDDD        |
1.5|        CCCCCCCC        DDDDDDDD        |
1.8D........CCCCCCCC        DDDDDDDD        |
2.0D........                                |
2.2D........                       EEEEEEEEE|
2.5D........            6          EEEEEEEEE|
2.8|                               EEEEEEEEE|
3.0|         FFFFF                     5    |
3.2|         FFFFF                          |
3.5|         FFFFF         GGGGGGG          |
3.8|                       GGGGGGG          |
4.0|                                        |
4.2|                                        |
   +----------------------------------------+  front (camera)   5.0 x 4.5 m
```

| | Piece | x, depth (m) | Role |
|---|---|---|---|
| - | window | 2.50 (wall) | `window_children_bedroom` |
| A | floor lamp | 4.55, 0.40 | `lamp_children_bedroom` |
| B | toy box | 2.50, 0.35 | hiding spot |
| C | bed | 1.55, 0.95 | furniture |
| D | bed (starry) | 3.45, 0.95 | hiding spot |
| - | rug | 2.50, 2.60 | walked over |
| E | computer desk | 4.40, 2.60 | `computer` |
| F | easel | 1.40, 3.40 | furniture |
| G | rocking horse | 3.30, 3.75 | decor |

**Seats:** son 4.4, 3.2; daughter 2.5, 2.7.


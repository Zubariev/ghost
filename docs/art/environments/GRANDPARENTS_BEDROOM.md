# Grandparents' Bedroom

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/grandparents_bedroom/`) |
| Layout in metres (Phase B) | **Built 2026-11-20, awaiting user review** (§ Phase B below) |
| Painted props | **Built 2026-11-20, awaiting user review** — window (closed / open, lace), iron-and-brass bed, mirrored wardrobe, rocking chair, dresser (monocle still code-drawn); rose floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `grandparents_bedroom` · in-game name «Спальня бабусі й дідуся» · upper floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

Grandma and grandpa's old-fashioned room: a high double bed, a heavy wardrobe, a rocking chair, a dresser with grandpa's monocle on it, a lamp and a window. Lace, faded florals and keepsakes of a long life.

**Who uses it** (schedules): grandpa wakes at 06:00; both sleep from 22:00. The monocle on the dresser is the ghost's first pickup (it lets the player see sight zones).

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.25, back wall) | `window_grandparents_bedroom` (closed / open) — the ghost can change it (→ open) | — |
| double_bed | (0.55, 0.3) | `grandparents_bed` (free / occupied); hiding spot `hide_grandparents_bedroom_bed` (large grid) | ~180 px |
| wardrobe | (0.9, 0.05) | hiding spot `hide_grandparents_bedroom_wardrobe_2` (large grid; unique find: lore_diary_1); blocks sight | ~90 px |
| rocking_chair | (0.2, 0.7) | furniture | ~56 px |
| floor_lamp | (0.82, 0.7) | `lamp_grandparents_bedroom` (lit / out) — the ghost can change it (→ out) | ~37 px |
| dresser | (0.1, 0.08) | pickup: monocle (lets the ghost see sight zones) | ~79 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- open front edge (u 0.5) → Коридор (2 поверх) (`upper_corridor`)

The bed (object `grandparents_bed`, free / occupied) and the wardrobe (diary page 1) are large hiding spots. The dresser's monocle must be visible until taken.

## 3. Light and the two states

**Warm anchor:** the lamp (front right) and the bed.

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit | Out: moonlight from the window (back left) |
| Window | Closed | Open: draught, frost; the old folk feel the cold most |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** faded cream paper with small roses, a lace-trimmed shelf, old portraits
- **Floor:** boards with a rag rug
- **Details:** a lace bedspread, knitting on the rocking chair, a jewellery box and a mirror on the dresser
- **Mood:** gentle, old, a little musty

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of an elderly couple's bedroom in an old house: a high iron-and-brass double bed with a lace bedspread, a heavy dark wardrobe, a wooden rocking chair with knitting on it, a dresser with a mirror, a jewellery box and a monocle, faded cream wallpaper with small roses, old framed portraits, a rag rug, a window with lace curtains, a brass floor lamp. Hand-inked dark-brown outlines, painted textures, warm lamplight against moonlit blue. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a small window with lace curtains |
| double_bed | One image, made bed; a sleeping person is drawn over it by the code. | ~95 px | a high iron-and-brass double bed with a lace bedspread (`grandparents_bedroom/double_bed`) |
| wardrobe | One image (doors shut). Blocks sight. | ~185 px | a heavy dark wardrobe with a mirror door |
| rocking_chair | One image; the rocking is not animated. | ~90 px | a wooden rocking chair with a knitted blanket and knitting |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |
| dresser | One image without the monocle; the monocle is drawn by the code until taken (pickup). | ~85 px | a dresser with a tilting mirror and a jewellery box — painted without the monocle |

## 7. Shared kinds and open points

- **Shared kinds:** `double_bed`, `floor_lamp`, `wardrobe`, `window` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"grandparents_bedroom/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The monocle stays code-drawn on the dresser so it can disappear when taken (pickup).

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] The monocle is easy to spot on the painted dresser until taken.
- [ ] The occupied bed reads (grandparents asleep).
- [ ] The rocking chair is not mistaken for a hiding spot.

## Phase B — laid out in metres (built 2026-11-20, awaiting user review)

The room is **4.5 × 4.0 m** (`rooms.json` size_m); `furniture.json` stores x / 4.5 and depth / 4.0.
Footprints are real sizes (`movement.json`). Doors: front (upper corridor); the 1.2 m × 1 m zone inside each side,
back or front door (`.` below) holds nothing (test `test_nothing_stands_in_front_of_a_door`), and no
family route crosses decor (`test_no_family_route_in_any_room_crosses_decor`). Letters are pieces
that stand on the floor; digits are seats (furniture.json "seats").

```
   +------------------------------------+  back wall
0.0| AAAAAAA     BBBBBBBBBBBBBBCCCCCCCCC|
0.2| AAAAAAA     BBBBBBBBBBBBBBCCCCCCCCC|
0.5|             BBBBBBBBBBBBBBCCCCCCCCC|
0.8|             BBBBBBBBBBBBBB         |
1.0|             BBBBBBBBBBBBBB         |
1.2|             BBBBBBBBBBBBBB         |
1.5|             BBBBBBBBBBBBBB         |
1.8|             BBBBBBBBBBBBBB         |
2.0|             BBBBBBBBBBBBBB         |
2.2|   DDDDD EEEE                 FFF   |
2.5|   DD4DD EEEE                       |
2.8|   DDDDD                            |
3.0|             ..........             |
3.2|             ..........             |
3.5|             ..........             |
3.8|             ..........             |
   +------------------------------------+  front (camera)   4.5 x 4.0 m
```

| | Piece | x, depth (m) | Role |
|---|---|---|---|
| - | window | 1.75 (wall) | `window_grandparents_bedroom` |
| A | dresser | 0.55, 0.30 | pickup: monocle |
| B | double bed | 2.50, 1.10 | `grandparents_bed`, hiding spot |
| C | wardrobe | 3.95, 0.35 | hiding spot, blocks sight |
| D | rocking chair | 0.70, 2.60 | furniture |
| E | side table | 1.35, 2.60 | furniture |
| F | floor lamp | 3.90, 2.40 | `lamp_grandparents_bedroom` |

**Seats:** grandpa 0.7, 2.7.


# Upper Bathroom

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/upper_bathroom/`) |
| Layout in metres (Phase B) | **Built 2026-11-20, awaiting user review** (§ Phase B below) |
| Painted props | **Built 2026-11-20, awaiting user review** — claw-foot bathtub, pedestal sink with mirror; tulip floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `upper_bathroom` · in-game name «Ванна (2 поверх)» · upper floor · no window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The upstairs bathroom: a claw-foot bathtub, a pedestal sink with a mirror, a bath mat and a lamp. The children wash here at 21:00 before bed. Small, tiled, echoing; at night with the lamp out it is one of the eeriest rooms.

**Who uses it** (schedules): the son and the daughter at 21:00 (bedtime).

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| bathtub | (0.35, 0.18) | hiding spot `hide_upper_bathroom_bathtub_0` (large grid) | ~182 px |
| sink | (0.78, 0.08) | hiding spot `hide_upper_bathroom_sink` (small grid) | ~39 px |
| rug | (0.55, 0.7) | furniture | — |
| floor_lamp | (0.88, 0.8) | `lamp_upper_bathroom` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- back wall (u 0.62) → Коридор (2 поверх) (`upper_corridor`)

No window. The bathtub is a large hiding spot, the sink a small one.

## 3. Light and the two states

**Warm anchor:** the lamp (front right) — the only light.

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: warm light on white tiles | Out: dark; the tub and the mirror as pale shapes |
| Cold | — | No window: cold only from the house |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** white metro tiles to shoulder height, sea-green paint above, a few cracked tiles
- **Floor:** small black-and-white hexagon tiles, a bath mat (the rug)
- **Details:** a towel rail, a mirror, a soap dish, a rubber duck
- **Mood:** cold and echoing; clean surfaces show dirt and polish clearly

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of an old house's upstairs bathroom: a white claw-foot bathtub with brass taps, a pedestal sink with a round mirror above, white metro tiles to shoulder height with sea-green walls above, small black-and-white hexagon floor tiles, a bath mat, a towel rail with towels, a rubber duck, a brass floor lamp giving warm light. Hand-inked dark-brown outlines, painted textures, warm lamplight against cool tiles. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| bathtub | One image (claw-foot tub). | ~75 px | a white claw-foot bathtub with brass taps and a towel over the rim |
| sink | One image (pedestal sink, mirror above as part of it or a separate wall piece). | ~85 px | a white pedestal sink with brass taps and a round mirror above it |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a small bath mat, faded green |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `floor_lamp`, `rug` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"upper_bathroom/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The mirror: part of the sink painting, or a separate wall piece (it would need a furniture entry, decor).

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] The children read against white tiles (contrast).
- [ ] The bathtub reads as a hiding place.

## Phase B — laid out in metres (built 2026-11-20, awaiting user review)

The room is **3.5 × 3.0 m** (`rooms.json` size_m); `furniture.json` stores x / 3.5 and depth / 3.0.
Footprints are real sizes (`movement.json`). Doors: back (upper corridor); the 1.2 m × 1 m zone inside each side,
back or front door (`.` below) holds nothing (test `test_nothing_stands_in_front_of_a_door`), and no
family route crosses decor (`test_no_family_route_in_any_room_crosses_decor`). Letters are pieces
that stand on the floor; digits are seats (furniture.json "seats").

```
   +----------------------------+  back wall
0.0|             .........AAAAA |
0.2|             .........AAAAA |
0.5|             .........      |
0.8|             .........  5   |
1.0|BBBBBBBBBBBBBB              |
1.2|BBBBBBBBBBBBBB              |
1.5|BBBBBBBBBBBBBB   6          |
1.8|                            |
2.0|                            |
2.2|                        CCC |
2.5| DDDD                   CCC |
2.8|                            |
   +----------------------------+  front (camera)   3.5 x 3.0 m
```

| | Piece | x, depth (m) | Role |
|---|---|---|---|
| A | sink | 3.10, 0.35 | hiding spot |
| B | bathtub | 0.90, 1.45 | hiding spot |
| - | rug | 1.90, 2.40 | walked over |
| C | floor lamp | 3.15, 2.50 | `lamp_upper_bathroom` |
| D | laundry basket | 0.40, 2.60 | decor |

**Seats:** son 3.0, 0.95; daughter 2.2, 1.5.


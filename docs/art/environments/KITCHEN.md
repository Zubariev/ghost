# Kitchen

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/kitchen/`) |
| Painted props | OPEN — none yet (§6) |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `kitchen` · in-game name «Кухня» · ground floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

Grandma's domain: she cooks breakfast, lunch and dinner here. A cast-iron range is the warm heart; the counter is cluttered with jars and pots, groceries sit in a basket, and a scrubbed table stands in the middle. Two of the ghost's best tricks live here: jamming the stove and hiding the groceries.

**Who uses it** (schedules): grandma at 06:00, 09:00 and 17:00 (meal preparation); the father comes to repair a broken stove.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.3, back wall) | `window_kitchen` (closed / open) — the ghost can change it (→ open) | — |
| counter | (0.62, 0.08) | hiding spot `hide_kitchen_counter_1` (small grid) | ~118 px |
| stove | (0.82, 0.32) | `stove` (working / broken) — the ghost can change it (→ broken) | ~107 px |
| basket | (0.3, 0.48) | `grocery_basket` (available / hidden) — the ghost can change it (→ hidden) | ~58 px |
| kitchen_table | (0.52, 0.72) | hiding spot `hide_kitchen_table` (small grid) | ~131 px |
| floor_lamp | (0.1, 0.82) | `lamp_kitchen` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- left wall (v ≈ 0.5) → Їдальня (`dining_room`)

The stove (interactive, critical repair) and the basket (interactive) must stand out from the clutter of decor. The counter and the table are small hiding spots.

## 3. Light and the two states

**Warm anchor:** the cast-iron range (`stove`) — warm glow from its fire door while working; plus the lamp front left.

| | Cozy | Haunted |
|---|---|---|
| Stove | Working: fire glow at the door, a kettle | Broken: cold, door hanging, smoke (code) |
| Groceries | Basket full | Hidden: basket empty |
| Lamp / window | Lit; closed | Out; open (cold, frost) |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** white glazed tiles to shoulder height (some cracked), pale yellow limewash above, a shelf of copper pans
- **Floor:** red quarry tiles, worn paths in front of the range and counter
- **Details:** strings of onions and dried herbs, a wall rack of spoons, a clock, a calendar
- **Mood:** busy, warm, smelling of bread — the coziest room by day

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of an old farmhouse kitchen: a black cast-iron cooking range with a glowing fire door and a kettle, a long wooden counter with jars, crocks and copper pots, a wicker basket of vegetables and bread, a scrubbed pine kitchen table, white glazed wall tiles below pale yellow walls, copper pans on a shelf, strings of onions and herbs, red quarry-tile floor, a window, a brass floor lamp. Hand-inked dark-brown outlines, painted textures, warm amber light. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a sash window with checked gingham curtains |
| counter | One image; pots and jars on it are part of the painting. | ~100 px | a long wooden counter with jars, crocks, a bread board and copper pots |
| stove | Two images: `working`, `broken` (door hanging, dented). Fire glow and smoke are code. | ~115 px | a black cast-iron cooking range with a fire door, a chimney pipe and a kettle on top; second image: broken — fire door hanging off, dented, cold |
| basket | Two images: `available` (full of groceries), `hidden` (empty basket). | ~45 px | a wicker basket full of vegetables and a loaf; second image: the same basket empty |
| kitchen_table | One image. | ~65 px | a scrubbed pine table with a bowl and a rolling pin |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `floor_lamp`, `window` also appear in other rooms. A painted image is looked up by kind (or `kind:variant`), not by room (`PropVisuals`), so one painting would show in every room. A look of its own for this room needs a room-scoped key or a `variant` — decision OPEN (`ENVIRONMENT_GUIDELINES.md` §8).
- The stove's fire glow while working: code glow (like the fireplace) or a painted flame layer through the fire door (`effects.states.working`).

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] Stove and basket read as interactive among the clutter; both states clear.
- [ ] Grandma at the range stays readable against the black iron.
- [ ] The broken stove reads as broken without the smoke.

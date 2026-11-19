# Kitchen

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/kitchen/`) |
| Painted props | **Built 2026-11-20, awaiting user review** — cast-iron range (`working` / `broken`), grocery basket (`available` / `hidden`), counter, table, window (closed / open, gingham); tulip floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
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

## 6. Props to paint — generation list (2026-11-16)

Order of work: the stove first (the most important piece, and it settles the glow question in §7), then
the list top to bottom. Every prompt is the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8) followed by
the prop text below.

**How to generate**
- Any size the generator gives; keep the shape (w : h). The image is cut out and scaled with
  `tools/sprite_cutout.gd` to the final size (2× the on-screen size at depth 1.0, `scale` 0.5;
  SPRITE_SPEC §2).
- A prop with two images: make the second by **editing the first**, so framing and outline match and
  the prop does not jump when its state changes.
- White background, PNG if possible. Keep the sources in `art/concepts/props/<kind>/`
  (e.g. `art/concepts/props/stove/`). Game files go to `assets/art/props/` (`<kind>_<state>.png`, SPRITE_SPEC §4).

| # | Kind | Images (game files) | Shape (w : h) | Final size (2×) | Prop text (after the preamble) |
|---|---|---|---|---|---|
| 1 | `stove` | `stove_working.png`, then `stove_broken.png` | ~1 : 1 | ~240 × 230 | *A black cast-iron kitchen cooking range with a small closed fire door with dark vent slots, a short chimney pipe rising from the back, a copper kettle on the hotplate, brass rail along the front.* Second, by editing: *the same range broken: fire door hanging off one hinge, the front dented, the kettle knocked askew, cold and dead.* |
| 2 | `basket` | `basket_available.png`, then `basket_hidden.png` | 1.4 : 1 | ~125 × 90 | *A round wicker basket full of groceries: carrots, onions, potatoes, a round loaf of bread.* Second: *the same wicker basket, empty.* |
| 3 | `counter` | `counter.png` | 1.5 : 1 | ~290 × 200 | *A long wooden kitchen counter with cupboard doors below; on top, glass jars, stoneware crocks, a bread board and two copper pots.* |
| 4 | `kitchen_table` | `kitchen_table.png` | 2 : 1 | ~255 × 130 | *A low scrubbed pine kitchen table with turned legs, a mixing bowl and a rolling pin on it.* |
| 5 | `window` | `window_kitchen_closed.png`, then `window_kitchen_open.png` (key `kitchen/window`) | 1.1 : 1 | ~340 × 300 | *A white-painted wooden sash window with small panes, checked red-and-cream gingham curtains on a rod, a sill with a small herb pot.* Second: *the same window, sash swung open inward, curtains pushed aside.* Frost, draught and curtain sway stay code. |
| 6 | `floor_lamp` | `floor_lamp.png` (house-wide key, proposed — §7) | ~1 : 2.4 | ~140 × 340 | *A brass floor lamp with a fringed fabric shade, unlit, on a round weighted base.* The lit glow is code (`effects`), so lit and out share the image. |

Final sizes come from the on-screen widths in §2 divided by each piece's depth (`0.78 + 0.34 × v`) and
the height guides at depth 1 (counter 100, stove 115, basket 45, table 65, lamp 170, window 150 px), ×2.
Keep the painted width close to the footprint (SPRITE_SPEC §2); the cutout fixes size, not shape.

## 7. Shared kinds and open points

- **Shared kinds:** `floor_lamp`, `window` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"kitchen/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- **OPEN — the stove's fire glow while working:** code glow (like the fireplace) or a painted flame layer through the fire door (`effects.states.working`). *Proposed:* the closed fire door is painted (§6 #1) and the code adds the glow through its vent slots, so nothing burning is painted in and the broken stove simply goes dark; a painted flame layer only if that looks flat in the capture.
- **OPEN — the floor lamp:** *proposed* one house-wide `floor_lamp` image for all eleven rooms (no `kitchen/floor_lamp` key) instead of one per room. The kitchen window keeps its own (`kitchen/window`, gingham curtains suit the room).

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] Stove and basket read as interactive among the clutter; both states clear.
- [ ] Grandma at the range stays readable against the black iron.
- [ ] The broken stove reads as broken without the smoke.

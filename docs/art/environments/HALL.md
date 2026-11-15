# Hall

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/hall/`) |
| Painted props | OPEN — none yet (§6) |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `hall` · in-game name «Хол» · ground floor · no window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The heart of the ground floor and the house's crossroads: the front door, the staircase up to the bedrooms, and doors to the living room, dining room and library. Nobody lingers here except the daughter on her tricycle, but everyone passes through many times a day, so it must read instantly as *the hall*: an entrance with a stair. Story to tell: the family's coming and going — coats on the stand, an old chest of things nobody unpacked.

**Who uses it** (schedules): everyone passes through (every meal, bedtime, morning); the daughter rides her tricycle here at 14:00. The ghost starts here (`ghost.json` start room) and is sent back here after full contact.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| stairs | (0.22, back wall) | hiding spot `hide_hall_stairs` (large grid); blocks sight | ~113 px |
| door_front | (0.5, 1.0) | furniture | — |
| coat_stand | (0.8, 0.25) | furniture | ~29 px |
| rug | (0.5, 0.6) | furniture | — |
| floor_lamp | (0.88, 0.8) | `lamp_hall` (lit / out) — the ghost can change it (→ out) | ~39 px |
| chest | (0.84, 0.08) | hiding spot `hide_hall_chest_5` (small grid; unique find: lore_letter) | ~85 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- Stairs (up) → Коридор (2 поверх) (`upper_corridor`)
- left wall (v ≈ 0.5) → Вітальня (`living_room`)
- right wall (v ≈ 0.5) → Їдальня (`dining_room`)
- back wall (u 0.62) → Бібліотека (`library`)

No window: the only daylight would come from the front door, which is at the open front edge. Keep the floor between the four exits clear — it is the busiest route in the house.

## 3. Light and the two states

**Warm anchor:** the hall lamp (`lamp_hall`, front right). There is no fire; a small glazed fanlight over the back door could carry a cool daylight note (decor, painted in the wall art, never a light source).

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: a warm pool front right, the stair half in shadow | Out: dark; only the cold fanlight and the code's dusk-blue corners |
| Cold | — | No window here: the hall turns cold only when the rooms around it do (breath, cold corners) |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** dark oak wainscot to two-thirds height, faded olive-and-gold wallpaper above, a picture rail
- **Floor:** worn encaustic tiles in a faded terracotta-and-cream checker, a long runner (the rug)
- **Details:** a barometer and a mirror on the back wall, framed silhouettes; brass hooks; the carved newel post of the stair
- **Mood:** welcoming but echoing; the first room the player sees — it sets the tone

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of the entrance hall of an old family house, seen from inside: a dark oak staircase with a carved newel post rising along the back-left wall to the floor above, dark oak wainscot and faded olive wallpaper with a gold motif, worn terracotta-and-cream checker tiles with a long patterned runner, a coat stand heavy with coats and a hat, an old travel chest with brass corners, a brass floor lamp with a fringed shade giving a warm pool of light, a small arched fanlight over a back door. Hand-inked dark-brown outlines, painted textures, warm amber lamplight against cool shadow. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| stairs | Back-wall piece rising to the ceiling; one image. It is the way between floors and a large hiding spot. | ~170 px | a dark oak staircase with a carved newel post and turned balusters, climbing from front-left up to the back wall's top edge |
| door_front | The front door at the room's open front edge (v 1.0): drawn by the code as a threshold; no image unless a front-edge treatment is decided (OPEN). | — | — |
| coat_stand | One image, coats and a hat on it. | ~160 px | a bentwood coat stand with two long coats, a scarf and a bowler hat |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a long runner, faded red with a cream border |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | a brass floor lamp with a fringed parchment shade (shared with every room) |
| chest | One image (lid shut). | ~55 px | an old wooden travel chest with brass corners and leather straps |

## 7. Shared kinds and open points

- **Shared kinds:** `chest`, `floor_lamp`, `rug`, `stairs` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"hall/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The front door sits at the open front edge (v 1.0), where the room has no wall: how to show it (a threshold mat, a door frame cut by the screen edge) is OPEN; foreground occluders are deferred.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] The four exits and the stair read at a glance.
- [ ] The ghost's start point (centre front) stays clear and readable.
- [ ] The daughter's tricycle route reads against the tiles and runner.

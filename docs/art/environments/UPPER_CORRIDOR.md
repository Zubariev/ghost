# Upper Corridor

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/upper_corridor/`) |
| Painted props | OPEN — none yet (§6) |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `upper_corridor` · in-game name «Коридор (2 поверх)» · upper floor · no window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The landing at the top of the stairs: the stair down to the hall, a runner, a chest, a lamp, and doors to all four upstairs rooms. A narrow, in-between place the family crosses at bedtime and in the morning.

**Who uses it** (schedules): everyone passing between the bedrooms, the bathroom and the stairs (mornings, bedtime).

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| stairs | (0.22, back wall) | hiding spot `hide_upper_corridor_stairs` (large grid); blocks sight | ~113 px |
| rug | (0.5, 0.55) | furniture | — |
| chest | (0.8, 0.2) | hiding spot `hide_upper_corridor_chest_2` (small grid) | ~92 px |
| floor_lamp | (0.88, 0.8) | `lamp_upper_corridor` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- left wall (v ≈ 0.5) → Спальня батьків (`parents_bedroom`)
- back wall (u 0.62) → Спальня бабусі й дідуся (`grandparents_bedroom`)
- right wall (v ≈ 0.5) → Дитяча спальня (`children_bedroom`)
- open front edge (u 0.5) → Ванна (2 поверх) (`upper_bathroom`)
- Stairs (down) → Хол (`hall`)

No window. Four doors (left, right, back, front) plus the stairs: keep every exit clear. The stairs block sight and are a large hiding spot; the chest is a small one.

## 3. Light and the two states

**Warm anchor:** the lamp (front right) — the only light.

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: a warm pool, the doors visible | Out: dark landing, doors as dark shapes |
| Cold | — | No window: cold only from the rooms around it |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** faded blue-grey paper above a painted dado, a few small framed prints
- **Floor:** boards with a long runner
- **Details:** a banister and newel at the stair head, a small table with a vase, a grandfather's portrait
- **Mood:** hushed, creaky, a little spooky at night — the corridor where a ghost is expected

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of the upstairs landing of an old house: the top of a dark oak staircase with a banister going down, a long patterned runner on worn boards, an old blanket chest, several closed panelled doors, faded blue-grey wallpaper above a painted dado, small framed prints, a brass floor lamp giving a warm pool of light in the dark. Hand-inked dark-brown outlines, painted textures, warm lamplight against deep blue shadow. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| stairs | Back-wall piece rising to the ceiling; one image. It is the way between floors and a large hiding spot. | ~170 px | the top of a dark oak staircase going down, with a banister and newel post (`upper_corridor/stairs`) |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a long runner, faded red with a cream border |
| chest | One image (lid shut). | ~55 px | an old painted blanket chest |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp |

## 7. Shared kinds and open points

- **Shared kinds:** `chest`, `floor_lamp`, `rug`, `stairs` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"upper_corridor/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The hall stairs (going up) and the corridor stairs (going down) are the same kind: paint each under `hall/stairs` and `upper_corridor/stairs`.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] All four doors and the stair read with the lamp out.
- [ ] People crossing at bedtime do not merge with the dark doors.

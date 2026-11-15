# Living Room — art test

Status: **APPROVED** (built and approved by the user 2026-11-15; commits `6bfc25b`, `5f1a966`,
evidence `d7e26aa`). The first and so far only room in the storybook style.

## Concepts

| Image | What to take from it |
|---|---|
| `art/concepts/environments/living_room/living_room_base.jpeg` | Furniture set and materials: fieldstone fireplace with a heavy wooden mantel, arched window with green velvet curtains and tie-backs, cream plaster above walnut wainscot, rose camelback sofa, terracotta armchair, olive fireside chair, round side table, patterned rug, bookcase |
| `art/concepts/environments/living_room/living_room_cozy.jpeg` | The cozy state: fire burning, lamp pools, family portraits on the walls, a mantel clock, someone reading |
| `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg` | Cozy beside haunted: the same room desaturated into dusk blue with a cold fire |
| `.../iterations/living_room_layers_v1.jpeg`, `_v2.jpeg` | Layer order (see `ENVIRONMENT_GUIDELINES.md`) |

## What is built

Fireplace (the warm anchor, on the back wall), grandma's terracotta wingback armchair (an
interactive seat and hiding spot), an olive fireside chair, a tea table, a side table with a
teacup, a camelback sofa (hiding spot, searchable), a patterned rug, a bookshelf, a fringed floor
lamp, the window with heavy curtains, two paintings (a moustached ancestor, a dusk landscape), a
pendulum clock, a wooden door to the hall, small things on the mantel.

Decor pieces (`"decor": true` in `furniture.json`): fireplace (u 0.18), wall clock, two paintings,
bookshelf (0.90, 0.06), olive armchair (0.10, 0.15), tea table (0.06, 0.24). They stand off every
family route (a test checks).

## States

- **Cozy** — lamp lit, window shut, fire burning.
- **Haunted** — lamp out, window open, fire out.

Same layout, same camera. Capture: `bash tools/play.sh art-test` →
`production/qa/evidence/art-test-living-room/`.

## Differences from the concepts

- Free-perspective painting → the room box (by design).
- The concept's fireplace holds candles (`living_room_base`) or a log fire (`living_room_cozy`);
  the game uses a log fire, which goes out when the room is cold.
- The concepts' arched window and fieldstone chimney are simplified in code drawing; a painted
  sprite can replace each prop later (`assets/art/props/sprite_guide.md`).
- Characters are still recoloured placeholders (`ART_DIRECTION.md`, Characters).

## Open

- No full-size haunted concept yet.
- Family redraw (after the character design decision).

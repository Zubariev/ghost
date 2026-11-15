# Environment Guidelines

How a room is built in the storybook style. Main document: `../ART_DIRECTION.md`.

## The room view — APPROVED (gameplay)

One room on screen at a time, seen as a box: back wall, two side walls slanting in, floor, a
front edge (Demo Spec §8.7, the *Hamlet*-style layout). The ghost passes through walls; doors and
stairs sit where the house plan says. Concept images are painted in free perspective; the game
does **not** copy that camera. Translate a concept into the box: keep its furniture, materials,
light and mood, place the pieces on the room's floor grid.

Code: `RoomStage` (draws a room), `StorybookShell` (walls, wainscot, floor), `StorybookArt`
(furniture), `RoomLayout` + `assets/data/house/furniture.json` (what stands where).

## Building a room — APPROVED

1. **Layout first, from gameplay.** Interactive objects, hiding spots (at least two per room) and
   sight blockers come from `furniture.json`. Family routes must stay clear (a test checks).
2. **Decor second.** Pieces that only dress the room get `"decor": true`: drawn only, never an
   obstacle, hiding spot or sight blocker, and placed off every family route.
3. **One warm anchor per room** — the thing the room's coziness centres on (living room:
   fireplace; kitchen: stove; bedrooms: bed and lamp).
4. **Walls tell the story** — paintings, clocks, shelves; but the back wall stays readable as a
   wall, and doors stay clear.
5. **Turn the room on** in `assets/art/visual_style.json` → `storybook_rooms`. Rooms not in the
   list keep the placeholder look.
6. **Capture both states** and compare with the concept (below). The user approves each room.

## Two states: cozy and haunted — APPROVED

References: `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg`, the lighting half
of `materials_lines_lighting_sheet.jpeg`, the kitchen day/night pair in `primary_moodboard.png`.

| | Cozy | Haunted |
|---|---|---|
| When | Lamp lit, window shut, comfortable | Lamp out (dark), window open (cold) |
| Colour | Amber highlights, warm mid-tones | Desaturated; dusk-blue and charcoal shadows; cold highlights |
| Light | Firelight and lamplight pools, gentle vignette | Moonlight through the window, darker corners, longer shadows |
| Fire | Burning | Out when the room is cold (an open window puts it out) |

- The state is the room's **warmth** (1 cozy … 0 haunted): dark −0.55, dim −0.25, cold −0.45,
  eased over about a second (`RoomMood`).
- It is a colour grade over the room (`post_art_room_grade.gdshader`, layer 1 under the HUD),
  never a flat blue overlay. Same layout, same positions, same camera in both states.

## Depth layers — PROVISIONAL

Reference: `art/concepts/environments/living_room/iterations/living_room_layers_v1.jpeg` and `_v2`.
Drawn back to front:

1. Background — walls, windows, wall decor.
2. Furniture and decor (midground).
3. Interactive props.
4. Characters (family), sorted by depth with the furniture they stand among.
5. Spectral — the ghost and its effects, always on top, never hidden by furniture.

**Foreground occluders — EXPERIMENTAL.** The layer concepts put large chairs in front of the
camera, cut by the frame. In the room box this would hide the floor where people walk and hide
spots; do not add any until it is decided, and if added they must fade when someone or the ghost
is behind them.

## Rolling out to the other rooms — PROVISIONAL (planned)

Ten rooms still use the placeholder look. Order to be decided with the user; each needs a concept
(none exist yet) or a written brief in a new `environments/<ROOM>.md`, then the steps above.

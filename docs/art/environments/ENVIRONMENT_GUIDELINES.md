# Environment Guidelines

How a room is built in the storybook style. Main document: `../ART_DIRECTION.md`.

## 1. Goals — PROVISIONAL

Rooms feel like parts of one old, inhabited house. Each has its own identity, and all share the
storybook illustration language, the contour and material treatment, one warm/cool lighting
logic, the same room view and a clear gameplay hierarchy.

## 2. The room view — APPROVED (gameplay; GDD §13.2, Demo Spec §8.7)

One room on screen at a time, seen as a box: back wall, two side walls slanting in, a floor that
narrows toward the back, no front wall (`RoomGeometry`: floor corners (330, 250), (950, 250),
(1170, 625), (110, 625) on the 1280 × 720 screen; back wall 170 px high, side walls 290 px at the
front; depth scale 0.78 at the back to 1.12 at the front). Positions are floor coordinates
(u left→right, v back→front, 0..1).

Concept images are painted in free perspective. The game does **not** copy that camera, geometry
or projection. Translate a concept into the box: keep its furniture, materials, light and mood;
the pieces stay where `furniture.json` puts them.

Before working on a room: look at the current camera, coordinates, sorting and navigation for it,
compare the concept with the box, list every mismatch, and change nothing in camera, geometry,
coordinates, navigation or gameplay to imitate the concept.

## 3. Building a room — APPROVED

1. **Layout comes from gameplay.** Interactive objects, hiding spots (at least two per room) and
   sight blockers are in `furniture.json`; walking footprints in `movement.json`. Family routes
   stay clear (a test checks).
2. **Decor second.** Pieces that only dress the room get `"decor": true`: drawn only, never an
   obstacle, hiding spot or sight blocker, placed off every family route.
3. **One warm anchor per room** — living room: fireplace; kitchen: stove; bedrooms: bed and lamp.
4. **Composition:** a clear floor and readable routes; furniture says what the room is for
   without filling every space; no decoration added only to fill a gap; doors, routes, people and
   targets stay legible; avoid tangencies between people and furniture or wall decor.
5. **Walls tell the story** (paintings, clocks, shelves) while the back wall still reads as a wall
   and doors stay clear. Back-wall pieces are furniture entries; **side-wall portraits** are art
   config in `assets/art/visual_style.json` → `wall_portraits` (wall, v range along it, h range up
   it, variant), drawn by `StorybookShell.draw_wall_portraits`. A test keeps them on the wall,
   above the wainscot and clear of the side doors (v 0.39–0.61).
6. **Turn the room on** in `assets/art/visual_style.json` → `storybook_rooms`. Rooms not listed
   keep the placeholder look.
7. **Capture both states** and review (checklist §7). The user approves each room.

## 4. Two states: cozy and haunted — APPROVED

References: `art/moodboards/supplementary/living_room_cozy_haunted_board.jpeg`, the lighting half
of `materials_lines_lighting_sheet.jpeg`, the kitchen day/night pair in `primary_moodboard.png`.

| | Cozy | Haunted |
|---|---|---|
| When | Lamp lit, window shut, comfortable | Lamp out (dark), window open (cold) |
| Sources | Fire, lamps and warm practical lights | Sources out where the game state says so; ones still burning keep their light |
| Colour | Amber highlights, warm mid-tones | Desaturated; dusk-blue and charcoal shadows; cold highlights |
| Light | Firelight and lamplight pools, gentle vignette | Moonlight through the window, darker corners, longer shadows |
| Fire | Burning | Out when the room is cold (an open window puts it out) |

- The state is the room's **warmth** (1 cozy … 0 haunted): dark −0.55, dim −0.25, cold −0.45,
  eased over about a second (`RoomMood`).
- Light pools are drawn by the room; the grade is a shader on its own layer
  (`post_art_room_grade.gdshader`). **Never only a flat blue overlay.** Same layout, positions and
  camera in both states, with enough contrast for people, routes and targets.
- Known gap: placeholder rooms (not yet storybook) still show cold as a flat blue overlay
  (`Palette.COLD_OVERLAY`); it goes away as each room is restyled.
- **Room-state visuals — APPROVED (art Phase 2, built and approved 2026-11-15).** GDD §13.3.
  Drawn by the room view in **every room** (`RoomWear`, `RoomStage`; numbers in
  `assets/art/visual_style.json` → `wear`), always under furniture and people:
  - **Dirty:** a brown-grey dulling wash over floor and walls; dust patches and stains on the
    floor (fixed per room, never in a doorway); cobwebs in the four top corners and on top of
    bookshelves and wardrobes; dust motes drifting in the window, lamp and fire light.
  - **Clean:** a faint sheen in bands across the floor. **Normal** shows neither.
  - **Cold:** breath puffs in front of each person's face (not while asleep); in storybook rooms
    frost on an open window and a pale draught creeping over the floor from it.
  - **Cold or dark:** dusk-blue shadow gathering in the floor and ceiling corners (with the
    room's warmth).
  - **Fire out:** embers glowing in the grate and fading over about 25 s, plus the smoke curl.
  - Broken objects keep their own state drawings (stove smoke, computer crack).
  Everything eases in and out (about a second) when the room changes.

## 5. Draw order — APPROVED (as built)

Back to front: floor and walls → light pools → flat pieces (rugs) → wall pieces (window,
fireplace, paintings, clock) → **one list sorted by screen depth: furniture, interactive props,
family and the ghost together** → harm ring, wisps, hidden glint, markers → colour grade → HUD.

**The ghost is depth-sorted with the furniture and people** (user decision 2026-11-15): it can be
behind a sofa or armchair, which matters for stealth and hiding readability. It is not drawn on a
permanent top layer, although the layer concepts
(`../../../art/concepts/environments/living_room/iterations/`) suggest one.

**Foreground occluders — OPEN (deferred).** Large furniture in front of the camera, cut by the
frame, would cover floor where people walk and hiding spots. Not added until decided; if added,
they must fade when someone or the ghost is behind them.

## 6. Rolling out to the other rooms — PROVISIONAL (planned)

Ten rooms use the placeholder look. Order to be decided with the user (likely kitchen, dining
room, hall first: the family spends most time there). Each needs a concept or a written brief in
a new `environments/<ROOM>.md`, then §3.

## 7. Review checklist (every room, every visual change)

- [ ] The room reads as a specific functional space.
- [ ] Floor and walking routes read clearly.
- [ ] Camera and room box unchanged; compatible with the GDD and the code.
- [ ] Family members do not merge with furniture or background (cozy and haunted, day and night).
- [ ] Interactive props and hiding spots are distinguishable from decor; their states read.
- [ ] The ghost is visible where it should be and hidden by furniture in front of it as before.
- [ ] Cozy and haunted are recognisably the same room; light changes keep readability.
- [ ] Foreground occlusion, if any, is intentional (none while OPEN).
- [ ] No gameplay, footprint, coordinate, navigation or interaction change: full test suite passes,
      including the decor-off-routes and layout tests.
- [ ] Screenshots of both states retained in `production/qa/evidence/`.

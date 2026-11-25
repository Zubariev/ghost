# Sprint 001 — House expansion, crafting, items, fixes

Written 2026-11-25. Source: the sprint brief (22 items, 7 phases) given with `/sprint-plan`.
Workflow is `minimal`: no story files and no `sprint-status.yaml`; this document is the plan.
Branch: `feat/godot-setup-room-spike`. Review mode: solo.

## Sprint goal
The ghost can explore a basement, an attic and two yards, craft elixirs at the back-yard tree,
trade flies for spider nests with the attic spider, and use a timed monocle — with the listed
fixes in and the 322-test baseline still green.

## Baseline (2026-11-25, before any change)
`gdUnit4`: 322 test cases, 41 suites, 0 failures. Working tree had uncommitted art evidence and
untracked concept art; none of it is touched or committed by this sprint.

## Goal prerequisites
| Needed | Status |
|---|---|
| Main scene (`run/main_scene`) and playable house | exists (`src/game/house_game.tscn`) |
| Test runner | exists (gdUnit4, `tests/README.md`) |
| Image generation for new art | exists: `tools/art/kichat.py` (user authorised its token, 2026-11-25) |
| Windowed capture for visual evidence | **missing in this session** (snap cannot open a Godot window); the user runs `tools/play.sh capture` |
| Drag-and-drop UI layer | **missing**; built in Phase C |

## What the audit found (drives the order)
- Rooms are data: `assets/data/house/rooms.json` (`floor`, `grid`, `size_m`) + `furniture.json`.
  `GhostNavigator` crosses walls to the neighbouring grid cell on the same floor and floors to
  the same cell one floor up/down. New locations are data plus small navigator/stage changes.
- Phase 7 cause: `GhostNavigator.U_MIN/U_MAX = -0.22/1.22`, `V_MIN/V_MAX = -0.42/1.08`.
- Inventory = `GhostLoot` (10 slots, one per material kind, stacking; items from hiding-spot
  grids in `assets/data/ghost/loot.json`). New items and the crafting inventory reuse it.
- Monocle is a world pickup on the dresser plus a permanent `_has_monocle` flag
  (`house_game.gd`, `room_stage.gd`) that gates the Q sight cones. It is saved in `save_state`.
- Toy box already exists (`hide_children_bedroom_toy_box_4`, hiding + loot): item 16 needs a test, not a build.
- Doors are drawn in code (`storybook_shell.gd`, `room_stage.gd::_draw_doors`); no door images exist.
- Tricycle flip rule: `character_animator.gd` `["tricycle", dir == "right"]`.
- Room cleanliness is `RoomState.Cleanliness` (DIRTY/NORMAL/CLEAN); nests set it back to DIRTY.
- Speed: `ghost.json` `speed`, scaled by `RoomCondition.ghost_factor`; energy: `GhostEnergy`.
- Family movement uses doors (`rooms.json` `doors`); new areas get no family doors, so no NPC enters them.

## Decisions taken
- Monocle respawn ("random slot valid for search") = a random hiding spot from `loot.json` (user, 2026-11-25).
- Art: generated with `tools/art/kichat.py` where it fits the pipeline, otherwise code-drawn
  placeholders, each listed under "Art still required" at the end.
- Items: crafting materials, flies, nests, elixirs and the monocle all become `loot.json` items
  (new `kind` values: `consumable`, `tool`); no second inventory.

## Phases
Order: A, B, C, D, E, F, G, H. A is independent and first; E and G depend on C's drop-on-ghost
target; D depends on B (the tree is in the back yard) and C (drag); F depends on B and C.

### A. Independent fixes (items 15, 16, 18, 22)
| Task | Files | Acceptance |
|---|---|---|
| A1 Tricycle direction | `character_animator.gd`, art check | rides facing the way it rolls; other clips unchanged; test on `choose()` |
| A2 Mother cleaning artifact | `assets/art/characters/mother/*` (pixel fix), `tools/art/` | no white between elbow and body; frames still aligned |
| A3 Toy box verification | `tests/unit/ghost/ghost_loot_test.gd` | toy box is a hiding spot and searchable |
| A4 Tighter boundary | `ghost_navigator.gd`, `ghost_navigator_test.gd` | margins about 0.07 u / 0.1 v; crossing and floor change still work |

### B. New locations (items 1, 2)
Basement `floor -1` under the hall; attic `floor 2` over the upper corridor; back yard on the
library's far side; front yard in front of the hall. Rooms in `rooms.json` (plus `furniture.json`
hiding spots, so every room has two), stairs/floor links, `HouseState` loading, stage drawing for
outdoor rooms (sky, grass, fence, no ceiling), mood/lighting, save compatibility.
Acceptance: each new room reachable by walking through a wall or W/S + Space; family routes and
schedules unchanged; `house_state`, `room_layout`, `ghost_navigator` tests extended.

### C. Items and drag layer (core of items 5, 12, 13, 19)
New items in `loot.json`; `GhostLoot` gains `remove(item, n)`, `add(item, n)` and a one-unit
transfer; a HUD drag controller (drag a slot's single unit; drop targets: crafting slot, ghost,
inventory slot).
Acceptance: dragging moves exactly one unit; counts never duplicate or vanish; dropping elsewhere returns the unit.

### D. Crafting (items 3, 4, 5, 6, 7, 19)
`assets/data/crafting/recipes.json` (recipes, tree upgrades, unlocks) and `CraftingBoard`
(5 typed slots, one kind per slot, quantity per slot, validation, consume, result slot, upgrades).
Tree object in the back yard to the right of centre; hold E opens the crafting screen;
screen layout: inverted pentagram of 5 slots + centre result slot, recipe list left, inventory bottom, Craft button above it.
Acceptance: every rule in the brief under "Ingredient placement" and "Crafting validation";
upgrade unlocks recipes with no UI code change; state survives close/reopen and save/load.

### E. Elixirs (items 20, 21)
Energy elixir restores `GhostEnergy`; speed elixir via a single timed-modifier list in the ghost's
speed calculation (multiplier and duration in data), consumed on drop-on-ghost.
Acceptance: restore clamps to max; speed returns to normal; overlapping doses refresh, never stack.

### F. Spider and flies (items 8 to 11)
Attic spider as a permanent object (`objects` data + furniture entry); flies as a renewable loot
item with kitchen weighting in `loot.json`; exchange 6 flies for nests; nest use sets the room's
cleanliness to DIRTY through the existing room state.
Acceptance: insufficient flies give feedback and consume nothing; repeated trades never duplicate or lose items.

### G. Monocle (items 12 to 14)
Dresser pickup becomes the first-find message plus an inventory item; drag onto the ghost starts
the effect (`monocle.json`: `duration_minutes`); expiry removes the effect and puts the monocle
into a random hiding spot; saved and loaded.
Acceptance: never two monocles; Q cones work only while active.

### H. Doors and integration (item 17 and the whole sprint)
Door art replaces drawn doors where a generated image fits; the drawn door stays as the fallback.
Full test suite; update this document; final report.

## Risks
| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Window cannot open in this session, so no captures | certain | visual items unverified | headless tests plus a scripted capture mode; user runs `tools/play.sh capture` |
| `house_game.gd` (1320 lines) grows | high | maintainability | new logic in separate classes; `house_game.gd` only wires |
| Monocle save format changes | medium | old saves | `load_state` defaults for missing keys |
| New rooms disturb simulation, morale, schedules | medium | regressions | rooms without doors or schedule entries; baseline suite after phase B |
| Generated art off-style | medium | rework | follow `docs/art/ART_DIRECTION.md`; keep `.prev` copies |
| Drag-and-drop in headless tests | medium | weak UI tests | logic in `CraftingBoard`/`GhostLoot`, UI kept thin |

## Art still required (end of sprint, 2026-11-26)
Painted with `tools/art/kichat.py` this sprint: 8 surfaces (basement, attic, yards), crafting tree,
shed, woodpile, hedge, interior door. Still code-drawn or needing another pass:
| Asset | Now | Needed |
|---|---|---|
| Attic spider | code-drawn | painted sprite (it is a permanent character) |
| Crafting screen (the hollow) | code-drawn bark rings and darkness | painted hollow rim; the pentagram and slots can stay drawn |
| Item icons: bone, feather, ectoplasm, ink, fly, nest, both elixirs, monocle | code-drawn (`ItemArt`), like every existing item icon | painted icons when the item icons are painted as a set |
| Lawn texture | painted | tiling seams show as dark lines; regenerate or fix the edges |
| Garden wall texture | painted | its ivy sprigs repeat visibly |
| Yard side walls | the back wall's texture (front yard: house front on both sides) | side textures (garden wall / hedge / fence) |
| Hedge | painted | reads as a round bush, not a 2 m hedge |
| Door | one painted door for every door | grass tufts painted inside the doorway; per-room doors optional |
| Mother's cleaning sprite | white blob removed | look at it animated in the game |

## Definition of done (state 2026-11-26)
- [x] Every brief item implemented and validated headless; visual items partly seen in captures
      (areas, crafting); doors, tricycle and the mother's sprite not yet seen in the game
- [x] Full gdUnit4 suite green: 419 test cases (baseline 322)
- [x] Captures reviewed: doors, crafting, areas and their fixes (2026-11-26)
- [x] Mother's cleaning seen in the game (2026-11-26)
- [x] Daughter's tricycle seen in the game and measured (2026-11-26)
- [x] No commits made, nothing pushed (none were requested)
- [x] Demo Specification updated for the scope change (v0.16, 2026-11-26)

## Progress log
- 2026-11-25: plan written; baseline 322 tests green.
- 2026-11-25: **Phase A done, 325 tests green.**
  - A1 tricycle: cause was a double mirror (`character_animator.gd` flipped when riding right, and
    `character_rig.gd` already un-mirrors `faces_left` views). Animator now flips on "left". Both
    tricycle tests were rewritten and watched failing on the old code (2 failures) before the fix.
    Not yet seen in a window.
  - A2 mother: 340 px opaque white blob (x 201–218, y 112–145) in `clean_body.png` between elbow and
    torso erased, plus its halo; canvas size unchanged (274×373). Checked in a before/after crop;
    not yet seen animated in the game. Only `clean_body.png` changed.
  - A3 toy box: already a hiding spot with loot; added a data test that searches it.
  - A4 boundary: `GhostNavigator` margins U ±0.22 → −0.07/1.07, V_MIN −0.42 → −0.15. New tests failed
    before the change; crossing into a neighbour room still lands inside it.
- 2026-11-26: **Phase B done in code and data, 336 tests green; not yet seen in a window.**
  - Rooms (`rooms.json`): basement (floor −1 under the hall, dark, cold, dirty), attic (floor 2 over
    the upper corridor, dim, cold, dirty), back yard (grid row −1 behind the library), front yard
    (row 2 in front of the hall). New room flags in `RoomState`: `outdoor`, `family_access` (data
    `family`).
  - Rules: outdoor light follows daylight (`HouseState`); no cleaning task where the family never
    goes (`TaskBoard`); no floating up or down into or out of open air (`GhostNavigator`).
  - Furniture and loot: 10 new hiding spots, all searchable (basement stairs/barrel/crate, attic
    chest/wardrobe, shed/woodpile/rain barrel, two hedges). New code-drawn kinds `shed`, `woodpile`,
    `hedge` (`FurnitureArt`, footprints in `movement.json`).
  - Look: 8 painted surfaces generated with `kichat.py` (3 regenerated after review), in
    `assets/art/surfaces/` and `visual_style.json`; sky backdrop and no indoor wear outdoors
    (`RoomStage`); HUD map stacks all four floors; sky tones in `COLOR_PALETTE.md`.
  - Tests: `tests/unit/house/house_areas_test.gd` (7, watched failing on the old code),
    `tests/integration/data/house_areas_data_test.gd` (4). Two existing rules scoped to family
    rooms, on purpose: "every room has a lamp" and "the family restores the house on day 1".
  - Headless smoke (scratch script): all 15 rooms by day and night, no errors or warnings.
  - Capture for the user: `bash tools/play.sh areas-test` → `production/qa/evidence/sprint-001-areas/`.
  - Known limits: the yards' side walls use the same texture as their back wall (garden wall;
    house front), the generated textures are not checked for tiling seams in the game yet, and the
    family never enters the new areas, so the ghost is always unseen there (a design question, below).

- 2026-11-26: **Phase C done, 355 tests green; the mouse drag itself not yet tried in a window.**
  - `GhostLoot` is now the one store everything moves units through: `add`, `remove` (all or
    nothing, never below zero), `can_add`, `uses_slot`, `use_of`, signal `inventory_changed`.
    Kinds `consumable` and `tool` take a slot like `material`; an emptied kind frees its slot.
  - `GhostItemUse` (new): an item's `use` data names an effect; owners register a handler per
    effect; one unit is used up only when the handler says it worked; `keep` items stay (monocle).
  - Items in `loot.json`: materials bone, feather, ectoplasm, ink, fly (placed in phase F);
    consumables spider_nest, elixir_energy (amount 40), elixir_speed (×1.5 for 60 game min);
    tool monocle. Effect values are data; minutes are game minutes (1 per real second at speed 1).
    New materials placed in fitting hiding spots (bones basement, feathers attic and shed, ink
    library, ectoplasm rare). Ukrainian names in `strings.csv`. Code-drawn icons in `ItemArt`.
  - HUD drag layer: each bar slot is a drag source for **one unit** (data
    `{"type": "inventory_unit", "item", "from_slot"}`, shared with crafting); a full-screen drop
    layer under the panels takes the mouse only while dragging and accepts a drop within 72 px of
    the ghost, showing a ring there. The bar never changes on its own: a refused or missed drop
    leaves the unit where it was, so nothing is lost or duplicated.
  - `house_game.gd` wiring only: creates `GhostItemUse`, gives the HUD the ghost's screen point,
    uses the item on drop and logs the result. No effects are registered yet (phases E to G), so
    every drop is refused for now.
  - Tests: `ghost_inventory_test.gd` (9), `ghost_item_use_test.gd` (6), `tests/unit/ui/hud_drag_test.gd`
    (4); all watched failing before the code. Headless end-to-end in the game scene: an elixir drop
    runs the effect with the data amount and uses one unit; a thread drop is refused and kept.

- 2026-11-26: **Phase D done in code and data, 379 tests green; the screen not yet seen in a window.**
  - Data `assets/data/crafting/recipes.json`: tree (kind, open_minutes 2), 5 slots, start tier 0,
    upgrades (tier 1: 3 bone + 2 feather; tier 2: 2 ectoplasm + 2 ink), 4 recipes: energy elixir
    and speed elixir from the start, distilled ectoplasm at tier 1, double energy elixir at tier 2.
    New recipes and upgrades are data only; the screen builds its list from the data.
  - `CraftingBoard` (logic, no UI): one unit per placement from `GhostLoot`; one kind per point;
    the same kind in two points counts together; ready = unlocked + ingredients + the middle empty
    or the same result; craft uses up exactly the ingredients; the result goes to the inventory
    whole or stays; units that no longer fit stay on the board; upgrades paid from the inventory;
    saved in the game save (`"crafting"`, older saves load without it).
  - `CraftingScreen` (UI, no state): the hollow's bark rim and darkness, an inverted pentagram with
    5 points and the result in the centre, recipe list on the left (locked as "??? — level N",
    ready ones lit), the selected recipe's needs (on the star / needed, in the bag), the bar at the
    bottom with Craft above it, tree level and upgrade top right. Drag a bar unit to a point; click
    a point or drag it to the bar to take one back; click or drag the centre to take the result.
    E or Esc closes and empties the board into the inventory as far as it fits. The clock pauses.
  - Tree: `crafting_tree` piece in the back yard at u 0.7 (right of centre), reach 1.8 m; hold E
    beside it for 2 game minutes (progress ring as for searching) to open the hollow.
  - Tests: `tests/unit/crafting/crafting_board_test.gd` (20), `tests/integration/data/crafting_data_test.gd`
    (4). Headless end-to-end in the game scene: hold opens at 2 min and pauses the clock; second kind
    on a point refused; Craft lights only when ready; craft and take result; closing returns a
    half-built recipe; reopening shows an empty board; the tree's level survives save and load.
  - Capture for the user: `bash tools/play.sh crafting-test` → `production/qa/evidence/sprint-001-crafting/`.

- 2026-11-26: **Phase E done, 392 tests green; not yet seen in a window.**
  - Energy elixir: `GhostEnergy.restore(amount)` (amount 40 from `loot.json`), clamped to the
    maximum; refused at full energy so the elixir is kept, not wasted.
  - Speed elixir: `GhostEffects` (new): timed effects in game minutes (they stop while the clock is
    paused: pause menu, crafting); a second dose restarts the time (the longer of the two) and
    never stacks the multiplier; `speed_multiplier()` is exactly 1 without the effect and never
    below 1. The game multiplies the ghost's movement by it (one place, `house_game.gd`), so speed
    returns to normal when it ends. Values from `loot.json`: ×1.5 for 60 game minutes.
  - HUD: running effects listed under the energy bar ("Еліксир швидкості — ще N хв"); a log line
    when one ends. Effects are saved and loaded (`"effects"`).
  - Tests: `ghost_effects_test.gd` (9), 4 new in `ghost_energy_test.gd`; both watched failing first.
    Headless end-to-end in the game scene: both elixirs crafted at the tree; energy elixir refused
    at full and kept, used at 30 → 70; speed measured 1.619 → 2.428 m/s (×1.50); no time passes
    while crafting; 40 min left after save and load; after expiry 1.619 m/s again, HUD line gone.

- 2026-11-26: **Phase F done, 404 tests green; not yet seen in a window.**
  - Spider: a permanent `spider` piece in the attic (u 0.86, v 0.12; no footprint, no sight
    blocking), code-drawn hanging on its thread. E within 1.6 m trades; the prompt shows the fly
    count, or how many are still missing. Data `assets/data/ghost/spider.json` (give 6 fly, get 1
    spider_nest; "six flies for spider nests" read as one nest per six, changeable in data).
  - `SpiderTrade` (new): all-or-nothing trade (paying with the last flies frees their slot for the
    nest; a nest with no room leaves the flies); `dirty_room(house, room)` sets the room's existing
    cleanliness to dirty, refused for a room already dirty or outdoors (the nest is kept).
  - Flies: a renewable loot item found by the normal search. A spot may override an item's respawn
    (`"respawn": {"fly": 45}`, new in `GhostLoot`); the kitchen counter and table bring flies back
    every 45 game minutes, five other spots (dining, living room, bathroom, attic, rain barrel) every
    240 — about 64 a day in the kitchen against 6 per other spot.
  - Nest: dropped on the ghost (`GhostItemUse` effect `dirty_room`); the family's usual cleaning tasks
    then take the room on again.
  - Tests: `tests/unit/spider/spider_trade_test.gd` (8), per-spot respawn in `ghost_loot_test.gd`,
    `tests/integration/data/spider_data_test.gd` (3); watched failing first. Headless end-to-end:
    kitchen counter search gave a fly; E at the spider with 1 fly refused ("wants 5 more"); with 7 it
    traded (1 fly, 1 nest left); nest refused and kept in a dirty kitchen; in a clean kitchen it made
    it dirty and the family's `clean:kitchen` task came back.
  - Capture: `areas-test` now also shoots the spider with its trade prompt.

- 2026-11-26: **areas-test reviewed** (`production/qa/evidence/sprint-001-areas/`, run by the user):
  all four areas render by day and night, the yards have sky, the ghost at an outer wall stays at
  the wall's edge. Fixed after it: the code-drawn tree's crown left the screen (drawing ×0.72), the
  spider's prompt sat off the top over the resolve bar (now just above the floor under it).
  Seen, not fixed (art): the lawn texture shows tiling seams; the garden wall's ivy repeats.
- 2026-11-26: **Phase D art done**: the crafting tree, shed, woodpile and hedge are painted
  (`kichat.py`; first tree request failed on the server and was retried), cut out into
  `assets/art/props/back_yard|front_yard/`, registered in `visual_style.json`; the tree's hollow was
  enlarged by an edit; the shed and woodpile were cropped above a title the model painted; the
  first woodpile (an upright log) was rejected. The hedge reads as a round bush, not a long hedge.
  Not yet seen in the game.
- 2026-11-26: **Phase E evidence**: `crafting-test` now also shoots both elixirs used
  (`c09-elixirs-used-speed-running`).
- 2026-11-26: **Phase G done, 416 tests green; not yet seen in a window.**
  - `Monocle` (new) owns the lifecycle; the effect is unchanged (Q shows sight zones), now only
    while the monocle works. Found once on the grandparents' dresser into the inventory (a full
    inventory leaves it there); the first find shows a card: "О! Це ж монокль дідуся. Він вічно
    його губив." and "Перетягніть на привида, щоб ~~надіти~~ активувати" (Ukrainian like the rest
    of the game; strikethrough with BBCode in a new HUD card). Dragged onto the ghost it works for
    90 game minutes (`loot.json`, = 90 s at normal speed) and shows its timer under the energy bar;
    sight zones switch on, Q toggles them. When the time is up the sight zones go off and it turns
    up in a random hiding spot (`GhostLoot.place_randomly`), first in that spot's grid, found by
    searching. Always exactly one monocle (dresser, inventory, active or one spot).
  - `GhostLoot`: single items placed into spots at run time (`place`, `placed_spot`, saved);
    refused when the item is held or already placed.
  - Save: monocle state and its random generator's state (a loaded game hides it in the same
    spot); saves from before sprint 001 (a permanent monocle) load with the monocle in the inventory.
  - Tests: `tests/unit/monocle/monocle_test.gd` (12, watched failing first); the frame-for-frame
    save test now runs with the monocle working. Headless end-to-end: dresser → inventory with the
    card; Q refused before activating; active 90 min with cones and timer; a second drop does
    nothing; at 89 min still active, at 90 in one random spot (different spots across runs), cones
    off; searched there (first in the grid), taken without the card, activated again; an old save
    loads with it in the inventory.
  - Capture: `areas-test` also shoots the dresser, the first-find card and the monocle working.

- 2026-11-26: **crafting-test and areas-test reviewed** (run by the user). Seen working: painted
  tree, shed, woodpile in the yard with the hold ring at the hollow; the hollow screen with the
  inverted pentagram, locked "???" recipes, needs list, Craft lit when ready, the elixir in the
  centre then in the bar; both elixirs used with the speed timer; the spider's prompt now in
  place; the monocle card; sight zones drawn while it works (faint on the terracotta floor).
  Fixed after it: disabled Craft / Upgrade buttons showed no text (the screen faded them on top of
  the plaque's own disabled look); the card's crossed-out word was not crossed out (BBCode `[s]`
  did not render) — the card is now plain labels with the line drawn, and an opaque panel.
  The capture's monocle timer stays at 90 because scripted captures skip the per-frame update.
- 2026-11-26: **Phase H (doors) done, 419 tests green; not yet seen in a window.**
  - Painted interior door (`kichat.py`, cut out to `assets/art/props/house/door_interior.png`,
    sprite `door` in `visual_style.json`; a `room/door` entry can give one room its own).
  - `DoorArt` (new) lays it onto the same frames the drawn doors used: side walls in perspective
    (8 strips, 0.39–0.61 along the wall, 0.64 of its height), back wall flat at `BACK_DOOR_U`.
    Both drawing paths (storybook living room, every other room) use it; the drawn doors stay as
    the fallback. Door positions, family routes, room connections and the ghost's movement are
    untouched (no gameplay data changed; the walking and door tests pass unchanged). The open front
    edge stays a gap. Doors are not opened or closed in this game: the image shows one ajar.
  - Tests: `tests/unit/art/door_art_test.gd` (3). Headless smoke through all 15 rooms by day and
    night (30 visits): no errors or warnings.
  - Capture for the user: `bash tools/play.sh props-test sprint-001-doors` (every room, day and
    night) → `production/qa/evidence/sprint-001-doors/` (a new folder, so the earlier art evidence
    is not overwritten).

- 2026-11-26: **Final captures reviewed** (run by the user): `sprint-001-doors` (all 15 rooms, day
  and night): the painted door on back walls (hall, upper corridor) and in perspective on side
  walls (living room both sides), frames and dark doorways where the drawn doors were. Crafting:
  disabled Craft / Upgrade now show their text. Monocle card: "надіти" crossed out, opaque panel.
  Back yard: painted tree with the large hollow, shed, woodpile. Not captured: the daughter's
  tricycle and the mother's cleaning (`character-test` without a name captures grandma; needs
  `character-test daughter` and `character-test mother`).

- 2026-11-26: **Character captures**: the mother (`character-mother`, 01:12) — the cleaning pose has
  no white patch between the elbow and the body (the kitchen floor shows through), frame aligned:
  item 18 verified in the game. The daughter's folder has no new files (still 2026-11-20); a
  headless start of the same capture shows no error, so it did not run or stopped before its first
  screenshot. The tricycle fix (item 15) is still unseen in the game.

- 2026-11-26: **Daughter captured** (`character-daughter`, 01:14): at the same game moment as the
  2026-11-20 shots the tricycle now faces the other way (d10, d11). Measured headless in the hall at
  14:30 over 600 frames: facing the way she rolls in 57 of 57 rolling frames; with the old
  animator, 0 of 56 (backwards every time). Item 15 verified. Seen while measuring, not looked
  into: her pose alternates between tricycle and standing during the activity.

## Conflicts and open questions (raised 2026-11-26)
- **Demo Spec §2.3** puts "the full crafting tree and resource economy" OUT OF SCOPE for the first
  demo ("recipes later"); **§4.2** adds rooms only when navigation or routines need them. This sprint
  (user brief, 2026-11-25) brings crafting and four new areas in. **Resolved 2026-11-26**: Demo
  Specification v0.16 (§2.3, §4.2, new §8.12, changelog), with the user's approval.
- **New areas are safe ground.** No family member goes to the basement, attic or yards, so the
  ghost can wait there unseen and refill energy (dark and cold). This is the same kind of escape
  item 22 removed outside the walls. **Decided 2026-11-26 (user): accepted for now**; revisit if it
  breaks the balance.

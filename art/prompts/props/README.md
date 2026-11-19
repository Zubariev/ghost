# Prop image prompts — every room except characters (2026-11-20)

One ready-to-paste prompt per image: open the file, copy all of it into ki-chat (image generation on),
and save the result under **Save as**. Built from the user's sprite-generator template, filled in from
the room briefs (`docs/art/environments/<ROOM>.md` §6) and `docs/art/SPRITE_SPEC.md`.

**Two-state props** (window, stove, basket, dining table, computer): generate the first state from its
prompt alone; then open the second state's prompt and **attach the first image** to the same message.
The model cannot repeat an object without seeing it.

**Changes from the template** (proposed, easy to revert):
- §6 asks for a **plain white background** instead of real transparency: image models fake
  transparency with a painted checkerboard, while white cuts out cleanly with `tools/sprite_cutout.gd`.
- §5 lists the sprite-spec rules directly, since the website model cannot read the project's documents.
- Lamps are **one unlit image** each (the game draws the glow), not a lit and an out image.

**Not in this list:** rugs (flat floor pieces, kept code-drawn — painting them projected is an open
point), the hall front door (OPEN), the fireplace (done), characters (later phase).

**Open decisions this list proposes an answer to:** the computer's era (old beige computer), one
house-wide brass floor lamp (the workshop keeps its own), the stove's glow drawn by code.

**Code work after the images:** the wall clock is painted without hands and pendulum, and the dining
table's meal becomes a second state — both need a small code change when they are added.

Save each image in `art/concepts/props/<room>/` (folders are made as you go). Living-room images
replace its approved code-drawn look only after a capture review.

## Order

### Every room (house-wide)

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 1 | [`01_house_floor_lamp.md`](01_house_floor_lamp.md) | `floor_lamp` | — | `art/concepts/props/house/floor_lamp.png` | — |

### Living room

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 2 | [`02_living_room_window_closed.md`](02_living_room_window_closed.md) | `window` | closed | `art/concepts/props/living_room/window_closed.png` | — |
| 3 | [`03_living_room_window_open.md`](03_living_room_window_open.md) | `window` | open | `art/concepts/props/living_room/window_open.png` | `window_closed.png` |
| 4 | [`04_living_room_sofa.md`](04_living_room_sofa.md) | `sofa` | — | `art/concepts/props/living_room/sofa.png` | — |
| 5 | [`05_living_room_armchair.md`](05_living_room_armchair.md) | `armchair` | — | `art/concepts/props/living_room/armchair.png` | — |
| 6 | [`06_living_room_armchair_olive.md`](06_living_room_armchair_olive.md) | `armchair` | — | `art/concepts/props/living_room/armchair_olive.png` | — |
| 7 | [`07_living_room_side_table.md`](07_living_room_side_table.md) | `side_table` | — | `art/concepts/props/living_room/side_table.png` | — |
| 8 | [`08_living_room_tea_table.md`](08_living_room_tea_table.md) | `tea_table` | — | `art/concepts/props/living_room/tea_table.png` | — |
| 9 | [`09_living_room_wall_clock.md`](09_living_room_wall_clock.md) | `wall_clock` | — | `art/concepts/props/living_room/wall_clock.png` | — |
| 10 | [`10_living_room_painting_portrait.md`](10_living_room_painting_portrait.md) | `painting` | — | `art/concepts/props/living_room/painting_portrait.png` | — |
| 11 | [`11_living_room_painting_landscape.md`](11_living_room_painting_landscape.md) | `painting` | — | `art/concepts/props/living_room/painting_landscape.png` | — |
| 12 | [`12_living_room_bookshelf.md`](12_living_room_bookshelf.md) | `bookshelf` | — | `art/concepts/props/living_room/bookshelf.png` | — |

### Kitchen

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 13 | [`13_kitchen_stove_working.md`](13_kitchen_stove_working.md) | `stove` | working | `art/concepts/props/kitchen/stove_working.png` | — |
| 14 | [`14_kitchen_stove_broken.md`](14_kitchen_stove_broken.md) | `stove` | broken | `art/concepts/props/kitchen/stove_broken.png` | `stove_working.png` |
| 15 | [`15_kitchen_basket_available.md`](15_kitchen_basket_available.md) | `basket` | available | `art/concepts/props/kitchen/basket_available.png` | — |
| 16 | [`16_kitchen_basket_hidden.md`](16_kitchen_basket_hidden.md) | `basket` | hidden | `art/concepts/props/kitchen/basket_hidden.png` | `basket_available.png` |
| 17 | [`17_kitchen_counter.md`](17_kitchen_counter.md) | `counter` | — | `art/concepts/props/kitchen/counter.png` | — |
| 18 | [`18_kitchen_kitchen_table.md`](18_kitchen_kitchen_table.md) | `kitchen_table` | — | `art/concepts/props/kitchen/kitchen_table.png` | — |
| 19 | [`19_kitchen_window_closed.md`](19_kitchen_window_closed.md) | `window` | closed | `art/concepts/props/kitchen/window_closed.png` | — |
| 20 | [`20_kitchen_window_open.md`](20_kitchen_window_open.md) | `window` | open | `art/concepts/props/kitchen/window_open.png` | `window_closed.png` |

### Dining room

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 21 | [`21_dining_room_window_closed.md`](21_dining_room_window_closed.md) | `window` | closed | `art/concepts/props/dining_room/window_closed.png` | — |
| 22 | [`22_dining_room_window_open.md`](22_dining_room_window_open.md) | `window` | open | `art/concepts/props/dining_room/window_open.png` | `window_closed.png` |
| 23 | [`23_dining_room_sideboard.md`](23_dining_room_sideboard.md) | `sideboard` | — | `art/concepts/props/dining_room/sideboard.png` | — |
| 24 | [`24_dining_room_dining_table_none.md`](24_dining_room_dining_table_none.md) | `dining_table` | none | `art/concepts/props/dining_room/dining_table_none.png` | — |
| 25 | [`25_dining_room_dining_table_ready.md`](25_dining_room_dining_table_ready.md) | `dining_table` | ready | `art/concepts/props/dining_room/dining_table_ready.png` | `dining_table_none.png` |
| 26 | [`26_dining_room_chair.md`](26_dining_room_chair.md) | `chair` | — | `art/concepts/props/dining_room/chair.png` | — |

### Hall

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 27 | [`27_hall_stairs.md`](27_hall_stairs.md) | `stairs` | — | `art/concepts/props/hall/stairs.png` | — |
| 28 | [`28_hall_coat_stand.md`](28_hall_coat_stand.md) | `coat_stand` | — | `art/concepts/props/hall/coat_stand.png` | — |
| 29 | [`29_hall_chest.md`](29_hall_chest.md) | `chest` | — | `art/concepts/props/hall/chest.png` | — |

### Library

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 30 | [`30_library_bookshelf.md`](30_library_bookshelf.md) | `bookshelf` | — | `art/concepts/props/library/bookshelf.png` | — |
| 31 | [`31_library_reading_chair.md`](31_library_reading_chair.md) | `reading_chair` | — | `art/concepts/props/library/reading_chair.png` | — |

### Workshop

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 32 | [`32_workshop_window_closed.md`](32_workshop_window_closed.md) | `window` | closed | `art/concepts/props/workshop/window_closed.png` | — |
| 33 | [`33_workshop_window_open.md`](33_workshop_window_open.md) | `window` | open | `art/concepts/props/workshop/window_open.png` | `window_closed.png` |
| 34 | [`34_workshop_tool_rack.md`](34_workshop_tool_rack.md) | `tool_rack` | — | `art/concepts/props/workshop/tool_rack.png` | — |
| 35 | [`35_workshop_workbench.md`](35_workshop_workbench.md) | `workbench` | — | `art/concepts/props/workshop/workbench.png` | — |
| 36 | [`36_workshop_crate.md`](36_workshop_crate.md) | `crate` | — | `art/concepts/props/workshop/crate.png` | — |
| 37 | [`37_workshop_floor_lamp.md`](37_workshop_floor_lamp.md) | `floor_lamp` | — | `art/concepts/props/workshop/floor_lamp.png` | — |

### Upper corridor

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 38 | [`38_upper_corridor_stairs.md`](38_upper_corridor_stairs.md) | `stairs` | — | `art/concepts/props/upper_corridor/stairs.png` | — |
| 39 | [`39_upper_corridor_chest.md`](39_upper_corridor_chest.md) | `chest` | — | `art/concepts/props/upper_corridor/chest.png` | — |

### Parents' bedroom

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 40 | [`40_parents_bedroom_window_closed.md`](40_parents_bedroom_window_closed.md) | `window` | closed | `art/concepts/props/parents_bedroom/window_closed.png` | — |
| 41 | [`41_parents_bedroom_window_open.md`](41_parents_bedroom_window_open.md) | `window` | open | `art/concepts/props/parents_bedroom/window_open.png` | `window_closed.png` |
| 42 | [`42_parents_bedroom_double_bed.md`](42_parents_bedroom_double_bed.md) | `double_bed` | — | `art/concepts/props/parents_bedroom/double_bed.png` | — |
| 43 | [`43_parents_bedroom_wardrobe.md`](43_parents_bedroom_wardrobe.md) | `wardrobe` | — | `art/concepts/props/parents_bedroom/wardrobe.png` | — |

### Grandparents' bedroom

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 44 | [`44_grandparents_bedroom_window_closed.md`](44_grandparents_bedroom_window_closed.md) | `window` | closed | `art/concepts/props/grandparents_bedroom/window_closed.png` | — |
| 45 | [`45_grandparents_bedroom_window_open.md`](45_grandparents_bedroom_window_open.md) | `window` | open | `art/concepts/props/grandparents_bedroom/window_open.png` | `window_closed.png` |
| 46 | [`46_grandparents_bedroom_double_bed.md`](46_grandparents_bedroom_double_bed.md) | `double_bed` | — | `art/concepts/props/grandparents_bedroom/double_bed.png` | — |
| 47 | [`47_grandparents_bedroom_wardrobe.md`](47_grandparents_bedroom_wardrobe.md) | `wardrobe` | — | `art/concepts/props/grandparents_bedroom/wardrobe.png` | — |
| 48 | [`48_grandparents_bedroom_rocking_chair.md`](48_grandparents_bedroom_rocking_chair.md) | `rocking_chair` | — | `art/concepts/props/grandparents_bedroom/rocking_chair.png` | — |
| 49 | [`49_grandparents_bedroom_dresser.md`](49_grandparents_bedroom_dresser.md) | `dresser` | — | `art/concepts/props/grandparents_bedroom/dresser.png` | — |

### Children's bedroom

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 50 | [`50_children_bedroom_window_closed.md`](50_children_bedroom_window_closed.md) | `window` | closed | `art/concepts/props/children_bedroom/window_closed.png` | — |
| 51 | [`51_children_bedroom_window_open.md`](51_children_bedroom_window_open.md) | `window` | open | `art/concepts/props/children_bedroom/window_open.png` | `window_closed.png` |
| 52 | [`52_children_bedroom_bed.md`](52_children_bedroom_bed.md) | `bed` | — | `art/concepts/props/children_bedroom/bed.png` | — |
| 53 | [`53_children_bedroom_computer_desk_working.md`](53_children_bedroom_computer_desk_working.md) | `computer_desk` | working | `art/concepts/props/children_bedroom/computer_desk_working.png` | — |
| 54 | [`54_children_bedroom_computer_desk_broken.md`](54_children_bedroom_computer_desk_broken.md) | `computer_desk` | broken | `art/concepts/props/children_bedroom/computer_desk_broken.png` | `computer_desk_working.png` |
| 55 | [`55_children_bedroom_toy_box.md`](55_children_bedroom_toy_box.md) | `toy_box` | — | `art/concepts/props/children_bedroom/toy_box.png` | — |
| 56 | [`56_children_bedroom_easel.md`](56_children_bedroom_easel.md) | `easel` | — | `art/concepts/props/children_bedroom/easel.png` | — |

### Upper bathroom

| # | Prompt file | Kind | State | Save as | Attach |
|---|---|---|---|---|---|
| 57 | [`57_upper_bathroom_bathtub.md`](57_upper_bathroom_bathtub.md) | `bathtub` | — | `art/concepts/props/upper_bathroom/bathtub.png` | — |
| 58 | [`58_upper_bathroom_sink.md`](58_upper_bathroom_sink.md) | `sink` | — | `art/concepts/props/upper_bathroom/sink.png` | — |

## How these were made (2026-11-20)

Generated through ki-chat's image API (`/api/v1/images/generations`, and `/api/v1/images/edit` for every
second state, from the first image) with a short form of each prompt: the DESIGN and notes plus the
style lines (white background, straight-on, no people, no text). Redone by edit after review: grandma
painted into her armchair, measurement labels on the side table, the broken stove still burning, drop
shadows behind the clock and paintings and around the living-room window, "BONE" on the toy box, the
kitchen table's floor shadow, a doll on the starry bed, the tablecloth (cream, outlined).

Added after the first review (user, 2026-11-20): every lamp a `lit` and an `out` image, five lamp
designs (`art/concepts/props/lamps/`), a second children's bed (`bed_starry`), two more library
bookshelves (`bookshelf_books`, `bookshelf_curios`).

## Sizes (real-world scale, `docs/art/SPRITE_SPEC.md` §2)

Each image is fitted into its real box (75 px per metre on screen at depth 1; art 2×). Wall pieces sit
*lift* above the floor.

| Sprite key | Width × height (m) | Lift (m) |
|---|---|---|
| `floor_lamp` | 0.5 × 1.6 | — |
| `dining_room/floor_lamp` | 0.5 × 1.6 | — |
| `library/floor_lamp` | 0.5 × 1.6 | — |
| `parents_bedroom/floor_lamp` | 0.5 × 1.6 | — |
| `kitchen/floor_lamp` | 0.5 × 1.6 | — |
| `upper_bathroom/floor_lamp` | 0.5 × 1.6 | — |
| `grandparents_bedroom/floor_lamp` | 0.5 × 1.6 | — |
| `children_bedroom/floor_lamp` | 0.5 × 1.5 | — |
| `workshop/floor_lamp` | 0.5 × 1.6 | — |
| `living_room/window` | 1.6 × 2.1 | 0.02 |
| `kitchen/window` | 1.3 × 1.2 | 0.85 |
| `dining_room/window` | 1.4 × 2.1 | 0.02 |
| `workshop/window` | 1.0 × 0.9 | 1.0 |
| `parents_bedroom/window` | 1.5 × 2.1 | 0.02 |
| `grandparents_bedroom/window` | 1.1 × 1.0 | 0.95 |
| `children_bedroom/window` | 1.3 × 1.4 | 0.7 |
| `living_room/wall_clock` | 0.35 × 0.85 | 1.15 |
| `living_room/painting:portrait` | 0.45 × 0.55 | 1.25 |
| `living_room/painting:landscape` | 0.6 × 0.48 | 1.3 |
| `living_room/sofa` | 2.0 × 0.95 | — |
| `living_room/armchair` | 0.85 × 1.1 | — |
| `living_room/armchair:olive` | 0.85 × 1.1 | — |
| `living_room/side_table` | 0.5 × 0.7 | — |
| `living_room/tea_table` | 0.5 × 0.7 | — |
| `living_room/bookshelf` | 0.9 × 1.9 | — |
| `kitchen/stove` | 0.9 × 1.7 | — |
| `kitchen/basket` | 0.45 × 0.5 | — |
| `kitchen/counter` | 1.8 × 1.15 | — |
| `kitchen/kitchen_table` | 1.3 × 0.9 | — |
| `dining_room/dining_table` | 2.0 × 1.0 | — |
| `dining_room/chair` | 0.45 × 1.05 | — |
| `dining_room/sideboard` | 1.2 × 2.0 | — |
| `hall/stairs` | 2.0 × 2.25 | — |
| `hall/coat_stand` | 0.6 × 1.85 | — |
| `hall/chest` | 0.95 × 0.65 | — |
| `library/bookshelf` | 1.4 × 2.0 | — |
| `library/bookshelf:books` | 1.4 × 2.0 | — |
| `library/bookshelf:curios` | 1.4 × 2.0 | — |
| `library/reading_chair` | 0.85 × 1.1 | — |
| `workshop/tool_rack` | 1.2 × 1.2 | — |
| `workshop/workbench` | 1.7 × 0.95 | — |
| `workshop/crate` | 0.65 × 0.55 | — |
| `upper_corridor/stairs` | 1.3 × 2.25 | — |
| `upper_corridor/chest` | 0.95 × 0.65 | — |
| `parents_bedroom/double_bed` | 1.7 × 1.2 | — |
| `parents_bedroom/wardrobe` | 1.1 × 2.1 | — |
| `grandparents_bedroom/double_bed` | 1.7 × 1.25 | — |
| `grandparents_bedroom/wardrobe` | 1.0 × 2.1 | — |
| `grandparents_bedroom/rocking_chair` | 0.75 × 1.1 | — |
| `grandparents_bedroom/dresser` | 0.95 × 1.65 | — |
| `children_bedroom/bed` | 1.0 × 0.9 | — |
| `children_bedroom/bed:starry` | 1.0 × 0.9 | — |
| `children_bedroom/computer_desk` | 1.1 × 1.25 | — |
| `children_bedroom/toy_box` | 0.8 × 0.5 | — |
| `children_bedroom/easel` | 0.6 × 1.4 | — |
| `upper_bathroom/bathtub` | 1.7 × 1.05 | — |
| `upper_bathroom/sink` | 0.6 × 1.75 | — |

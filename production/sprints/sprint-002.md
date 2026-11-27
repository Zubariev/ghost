# Sprint 002 — Yards and item art, spider ecology, root progression, family routines

Planned 2026-11-26 from the sprint brief given with `/sprint-plan`. Workflow `minimal`, review mode `solo`
(no director gates, no PR-SPRINT). No story files exist (`production/epics/` is absent) and none are invented:
this document is the plan, as in sprint 001. Branch `feat/godot-setup-room-spike`. Nothing is committed by planning.
Baseline to hold: **419 gdUnit4 test cases green** (sprint 001 end state). No milestone, no risk register.

## Sprint goal
The ghost walks through two painted yards and a painted item set, feeds an attic spider that can grow hostile and
spit webs, spends materials on a root-network progression screen under the old tree, and finds the family using the
bathroom at believable times; 419 baseline tests plus the new ones are green.

## Goal prerequisites
| Needed to show the goal | Status |
|---|---|
| Main scene and playable house (`src/game/house_game.tscn`) | exists |
| Test runner (gdUnit4) | exists |
| Image generation: `tools/art/kichat.py` needs `KI_CHAT_TOKEN` | **missing in this session**: the user must supply the token (never written to a file) |
| Windowed capture for visual evidence | **missing in this session** (snap cannot open a Godot window): the user runs `tools/play.sh <mode>` |
| Reference images | found, but **not in `my-ghost-game/`** (that folder is empty): see "Reference images" |
| Node catalog for the progression tree (names, costs, unlocks) | **missing**: no design source defines more than 2 upgrade tiers and 4 recipes (see D3) |

Per skill rules these gaps are reported, not solved here. Fixes: supply the token and run captures; decide D3 before Phase 4.

## Reference images (inspected 2026-11-26)
Both are untracked PNGs in the repo root (Ukrainian filenames); `my-ghost-game/` exists but is empty. Proposed: move them to
`art/references/sprint-002/` (`art/` is `.gdignore`d) at sprint start. They are guidance, never in-game images.
- **Reference A** (`Похмурий затишок…png`): front yard (clapboard two-storey house, porch with lit windows and lantern, white picket
  fence, mailbox, big oak with a swing, hydrangeas, stone path) and back yard (house rear with back door and steps, shed, clothesline,
  hollow oak at the right, sandbox, red tricycle, raised garden bed, birdhouse, plank fence), plus a props strip (fence, mailbox, tree,
  shed, clothesline, sandbox, tricycle, garden bed, birdhouse, flowerpot, watering can, gnome) and a six-colour palette
  (cream, grey-beige, sage, olive, russet, near-black). Dusk, warm window light, desaturated.
- **Reference B** (`Підземне дерево…png`): cross-section; sky and shed/fence/house strip above a grass line; the tree's hollow and trunk;
  a root network in soil; plain circular nodes (dark rim, flat colour fill, glow on the lit ones); five colour groups: amber
  (trunk hub, bottom and the long left root), slate-grey (upper left), mauve-pink (upper right), olive-green (lower right), orange (below
  the trunk); a coffin on the long left root's far end, gold light around it; a back arrow, title and a small counter at the top.
  Nodes are dark/dim when locked, lit and glowing when open or owned.

## Audit: what exists, what changes
| Area | Exists (preserve) | Changes |
|---|---|---|
| Yards | `back_yard` 10.5×7.5 m, `front_yard` 10×6 m in `rooms.json`; sky backdrop, 8 generated surfaces (lawn tiles with seams, ivy wall repeats), painted props: crafting tree, shed, woodpile, hedge (sprint 001); hiding spots: shed, woodpile, rain barrel, 2 hedges; family never enters (no doors, `family_access` false) | repaint to Reference A under the **Storybook style**; new decor; fix known seams; side walls get own textures; **no** change to sizes, footprints (`movement.json`), hiding data, tree position (u 0.7), door/stair links |
| Yard art docs | none (`environments/` has 10 room files, no yard) | `BACK_YARD.md`, `FRONT_YARD.md` + status rows in `ART_DIRECTION.md` |
| Items | 20 icon keys in `loot.json`, all **code-drawn** in `ItemArt.draw`; item data already holds an `icon` key, so definition and visual are already separate | painted icon per key under `assets/art/items/`, loaded by `ItemArt` with the code drawing kept as fallback; no item logic change |
| Spider | `spider` furniture piece in the attic (u 0.86, v 0.12, no footprint), **code-drawn** (`furniture_art.gd:268`); `SpiderTrade` (6 flies → 1 nest, all-or-nothing); `spider.json`; E within 1.6 m | painted multi-part sprite and rig; ecology; hostile state; web; the trade becomes the feeding |
| Ghost energy | `GhostEnergy` (`lost(amount, reason)` signal, `penalize`, `restore`, regen, hidden ×3); `GhostEffects`, `Stealth` hiding | add a public `drain(amount, reason)` (web damage); respects hiding |
| Crafting | `CraftingBoard`, `CraftingScreen` (hollow rim + pentagram), `recipes.json` (tiers 0–2, 2 upgrades paid in items, 4 recipes), saved under `"crafting"` | nodes/branches data, `CraftingProgression` logic, new `ProgressionScreen`, entry button; tiers become the trunk nodes, so old saves load |
| Routines | 6 schedules; **son and daughter already wash 21:00–22:00 in `upper_bathroom`**, both at once; adults never use it; nobody in the morning; **no `wash` clip exists in any rig** (kids stand idle); no runtime occupancy rule; 1 bathroom (3.5×3 m, 1st floor, off the corridor) | schedule data: staggered morning and evening slots for all six; occupancy data test; `wash` clip optional asset |
| Time | `GameClock`, 1 game min = 1 s at speed 1 (a day is 24 real minutes at ×1) | spider recovery counted in game days from the clock |
| Tests | 419 cases, 41+ suites; `tests/unit/{spider,crafting,npc,schedule,art,ghost,ui,…}` | new suites per track |

The user's brief says "no family member uses the bathroom"; the data shows the children do at bedtime. The plan treats that as
"adults never, and nobody in the morning".

## Decisions (defaults apply unless you say otherwise)
| # | Decision | Default | Status |
|---|---|---|---|
| D1 | Reference A is semi-realistic with no outlines; `ART_DIRECTION.md` makes Whimsical Gothic Storybook with organic dark-brown outlines **APPROVED** and the style is mandatory | Take layout, prop list, palette and mood from A; paint in the storybook style (prompts say so). A is not copied | APPROVED 2026-11-26 |
| D2 | Which branch is the long left one with the coffin (brief fixes the shape, not the branch) | **Room-Specific Anomalies**: the only branch that grows by room, so it earns the most nodes. Ghost Abilities: lower right (green). Children: upper right (mauve). Trunk hub: the existing tiers (amber) | APPROVED 2026-11-26 |
| D3 | Node catalog | `design/crafting-progression-catalog.md`: trunk T0–T2 (existing tiers), Room-Specific Anomalies 11 room bonds on the long left branch to the coffin, Ghost Abilities 8, Children 4 (option a); value changes and existing recipes only; coffin has no node, effect or glow | APPROVED 2026-11-26 |
| D4 | The existing trade is the feeding (flies → calories, nest as before) | yes; no second interaction | proposed |
| D5 | Hostile spider acts only in the attic; refuses trades while hostile; web ignores a hidden ghost | yes | proposed |
| D6 | Second bathroom | **No**: staggered 15-min slots fit one bathroom; revisit only if the headless day run shows queues | decided by audit, reopen on evidence |
| D7 | Coffin: visual landmark and branch end only (no quest, boss or reward) | yes | per brief |
| D8 | Node cost currency | keep item costs from the inventory (as today); Reference B's counter is not built | proposed |

## Capacity
Dates are an assumption: start 2026-11-27, target end 2026-12-29 (22 working days). Estimates are agent-assisted working days; image generation
(retries, cut-outs, style rejects) is the main variance.
- Must Have 18.5 d; Should Have 3 d; Nice to Have 1 d. Buffer 20% of Must: 3.7 d. Must plus buffer is 22.2 d, so the target end only holds if Should Have is dropped or run in parallel; say so when planning pace.

## Phases and order
Order is set by dependencies: **P0** prep; **P1** routines (small, data-only, independent); **P2** spider ecology logic (headless, no art needed);
**P3** progression logic and data; then art tracks in parallel with UI; **P4** spider art/rig and wiring; **P5** progression screen;
**P6** item art; **P7** yards; **P8** integration. Art generation can start in P1 (it is wait-time work) once the token exists.
Logic before UI before art keeps screens built against real data; yards come last because they are the riskiest to style and the
least coupled.

### P0 — Prep (0.5 d) — producer, art-director
Move references; record D1–D8; confirm token; run the 419-test baseline; write `BACK_YARD.md`/`FRONT_YARD.md` skeletons; create
`production/qa/evidence/sprint-002-*` plan; list the uncommitted evidence PNGs as untouched.

### P1 — Family routines (E) (1.5 d) — systems-designer, ai-programmer
| Task | Detail | Acceptance |
|---|---|---|
| E1 Slot design | One-person 15-min slots in `upper_bathroom`. Morning proposal: mother 06:00–06:15, father 06:15–06:30, grandpa 06:30–06:45 (each after waking, before the 07:00 shared breakfast); son 07:45–08:00 and daughter 08:00–08:15 (after breakfast, before play); grandma 08:15–08:30 (her 06:00 cooking start is kept). Evening (six slots, 20:30–22:00, each before that person's bedtime): father 20:30, mother 20:45, son 21:00, daughter 21:15, grandpa 21:30, grandma 21:45 (the children's current 21:00–22:00 blocks shrink to their slot, then sleep or play) | no two windows overlap in the room; every NPC visits morning and evening; times final after the first headless day run |
| E2 Data | edit the six `assets/data/schedules/*.json`; use existing `animation: "wash"`; target the sink/bathtub object | schedules load; `ScheduleLookup` tests updated |
| E3 Walk/animation | Without a `wash` clip the NPC stands idle at the sink (current kids' behaviour): documented, not hidden. Optional: a `wash` clip for six rigs via `rig_build.py` (asset list below) | no NPC leaves a window early; idle fallback verified |
| E4 Occupancy | Data guarantee first; add a runtime hold only if the day run shows a late finisher overlapping the next slot (`NpcRoutine` hold exists, `npc_hold_test`) | headless day: no deadlock, no stuck NPC, 15 rooms |
| E5 Bathroom count | audit result D6: one bathroom | recorded in the sprint log |
Tests: `tests/integration/data/bathroom_schedule_test.gd` (non-overlap, coverage, windows contiguous), extend `schedule_lookup_test`,
`scenario_test` regression (cleaning, meals, sleep, morale unchanged).
Risk: morale and cleaning windows move by minutes; the `mother_clean_*` and `son_help_mother` task windows are not shortened.

### P2 — Spider ecology (C) (2 d) — systems-designer (numbers), godot-gdscript-specialist (code)
New pure class `SpiderEcology` (RefCounted, like `SpiderTrade`), values in a new `ecology` block of `spider.json`
(one tuning file, nothing in scripts).
| State | Meaning |
|---|---|
| FRIENDLY | calories below `grown_at`; trades |
| GROWN | big but calm: warning stage, size visible |
| HOSTILE | calories reached `hostile_at` or max size; attacks; refuses trades |
| RECOVERING | after `hostile_days` game days: calories and size decay at `recover_per_day` back to FRIENDLY |
Tuning keys: `calories_per_fly`, `decay_per_day`, `size_min`, `size_max`, `size_curve`, `grown_at`, `hostile_at`, `hostile_days`,
`recover_per_day`, `attack_cooldown_minutes`, `telegraph_seconds`, `web_speed`, `web_damage_pct`, `web_hit_radius`, `max_hits_per_day`.
Rules: a trade of 6 flies adds `6 × calories_per_fly`; decay runs on `GameClock` minutes (paused with the clock); decay is slower than
intake; size is a pure function of calories; save/load state under `"spider"`.
`SpiderWeb`: one projectile = one hit (consumed on first contact), telegraph then flight, can miss a moving ghost, no damage while the ghost
is hidden or out of the room, `max_hits_per_day` plus cooldown cap the energy lost, damage as a percentage of max via
`GhostEnergy.drain`. Fairness test: a ghost that keeps moving and hides can always avoid loss.
Balance target to confirm by simulation, not guess: feeding every day gets hostile after about 4–5 days; one feed per 2 days never does.
Tests: `tests/unit/spider/spider_ecology_test.gd`, `spider_web_test.gd`, `ghost_energy_test.gd` (+drain), data test.

### P3 — Progression logic (D1–D3, D6) (2 d) — game-designer, systems-designer, godot-gdscript-specialist
`assets/data/crafting/progression.json` (new) next to `recipes.json`:
`branches[]` {id, name key, colour key, accent room (optional), root_anchor}; `nodes[]` {id, branch, parents[], cost{item:n}, requires[], unlocks{recipes[], effects[]}, layout{x,y hint, control points}}.
Existing tiers 1 and 2 become trunk nodes `trunk_1`, `trunk_2`; recipes gain `node` (keep `tier` as an alias until migrated);
`CraftingProgression` (logic: state per node LOCKED / AVAILABLE / OWNED, `can_unlock`, `unlock` paying from `GhostLoot`, branch visibility)
wraps `CraftingBoard` (kept); effects go through a registry like `GhostItemUse` (owners register handlers; unknown effect = refused loudly).
Room branch nodes carry a `room` id; adding a room adds data only. Save under `"crafting"` with a migration from `tier`.
Node content: `design/crafting-progression-catalog.md` (approved 2026-11-26). Needs a shared value-modifier list (key, add/multiply, optional room/npc_role) read by `GhostEnergy`, ghost speed, `GhostLoot`, `Monocle`, `StealthSystem`; unknown keys fail at load; HUD bar must lay out 12 slots (G6). Tests: `tests/unit/crafting/crafting_progression_test.gd` (state machine, dependency, cost all-or-nothing, migration, no
double unlock), data test for graph validity (no cycles, parents exist, every recipe reachable).

### P4 — Spider art, rig, wiring (B, wiring of C) (3 d) — art-director, technical-artist, gameplay-programmer
1. Spike (0.5 d): one generated spider tested against the style rules; choose the rig. Proposed: a node rig of `Sprite2D` parts
   (no skeleton, no AnimationPlayer): body/abdomen, head+mandibles, 8 legs as 4 mirrored pairs (front pair = feeding limbs), thread;
   tweens in a `SpiderRig` class; drawn through the existing sprite path so depth sorting is unchanged.
2. Animations: idle (breath, leg twitch), descend on ghost proximity (range in data, smooth ease to a lower point; returns to the ceiling
   after the ghost has been away `return_delay` seconds), feed (front legs bring to mouth, 2–3 s, input not blocked), attack telegraph (rear up, spin
   web), recover.
3. Size: rig scale from `SpiderEcology.size`, anchored to the thread so growth reads as hanging lower and bigger; interaction reach scales in data.
4. Wire: `house_game.gd` creates `SpiderEcology`, calls it from `_trade_with_spider`, ticks it, spawns webs; HUD hint when GROWN/HOSTILE.
Tests: rig builds all parts, scale follows size, state-to-animation mapping (pure), web hit/miss/once, trade refused when hostile.
Evidence: `bash tools/play.sh spider-test` capture mode (new, mirrors `areas-test`): idle, descended, feeding, grown, hostile + web, hit.

### P5 — Progression screen (D4, D5, D7) (3 d) — ux-designer, ui-programmer, technical-artist
Spec first with `/ux-design` (`design/ux/…`). Navigation: hollow screen → "Roots" button → `ProgressionScreen` → node → panel (cost, needs,
unlock) → back to the hollow (Esc closes one level). New scene logic only; `CraftingScreen` gets one button.
- Layout from data: node positions and control points from `progression.json`; roots drawn as tapering `Ink` curves with wobble and side rootlets (seeded, stable), branch colour on nodes only; painted soil, bark and a coffin sprite as assets; tree base and ground strip painted.
- Node language: LOCKED dim fill, dark rim; AVAILABLE full colour with soft glow and pulse; OWNED bright with gold ring; SELECTED thicker ring plus panel; INACCESSIBLE branch: root drawn thin and dull to its edge, nodes hidden until the parent is owned.
- Longest branch to the left, coffin sprite at its tip, dull gold light; other two shorter; asymmetric.
- Input: mouse (hover, click) and keyboard/gamepad focus (neighbour by data order); clock paused as in the hollow.
Tests: layout fits 1280×720 with bounds check on all nodes, selection and focus order, state colours via pure mapping, navigation open/close, no node overlap.
Evidence: screenshots of start state, mid-progress, all owned, locked-branch state.

### P6 — Item art (A3) (2 d) — art-director, technical-artist
Pipeline: generate each icon with `kichat.py` from one shared style prompt (soft dark-brown outline, flat paper-grain fill, 3/4 view, centred, plain
background); cut out with `tools/sprite_cutout.gd`; 256×256 PNG, transparent; saved as `assets/art/items/<icon_key>.png` (+`.import`, lossless,
mipmaps on); `ItemArt.draw` draws the texture fitted to the slot (40–64 px bar, larger in the hollow) and falls back to the existing code drawing.
Validation: contact sheet at 40 px and 64 px (`tools/art/montage.gd`) read by silhouette; consistent outline across the set; one batch regenerated
for outliers. Art is previewed, not silently swapped: placeholders stay code-drawn and are listed.
| Priority | Icon keys (20 in `loot.json`) |
|---|---|
| Must (14) | dust, cobweb, candle, nail, thread, bone, feather, ectoplasm, ink, fly, spider_nest, elixir_energy, elixir_speed, monocle |
| Should (6) | key, letter, photo, page, map, horse (lore; kept code-drawn if time runs out, but the bar then shows two styles) |
Tests: every `icon` in `loot.json` resolves to a texture or the fallback; no item logic test changes.

### P7 — Yards (A1, A2) (3 d) — art-director, technical-artist, level-designer (geometry guard)
1. Geometry guard first: a snapshot test of `rooms.json`/`furniture.json`/`movement.json` yard values (sizes, footprints, hiding ids, tree u/v, door and stair links);
   it must stay green through the whole phase.
2. Shared kit (both yards): picket/plank fence, hedge/hydrangea, oak foliage, stone path, lantern light, house clapboard, grass; shared palette from
   `COLOR_PALETTE.md` plus the sky tones already there.
3. Back yard: fix lawn seams, wall ivy, side walls; add decor layers: house rear with lit windows and back door as the back wall, clothesline, sandbox, tricycle
   (daughter's), garden bed, birdhouse, watering can; repaint shed, woodpile, rain barrel, tree.
4. Front yard: house front with porch and wreath, picket fence, mailbox, stone path, swing oak, hydrangeas; distinct from the back (tidy, welcoming, formal vs worn, lived-in).
5. New decor is **visual only**: on the backdrop/wall layer or ground-level without footprint, so walkable space and hiding spots do not change. Anything that
   would need a footprint is listed and decided separately.
6. Dusk/day/night variants follow `HouseState` daylight.
Asset sizes: backdrops generated at 2048×1152, props 512–1024 px cut out; see inventory.
Tests: geometry snapshot, sprite registry resolves, transparency check script (no opaque border), `areas-test` captures by day and night.

### P8 — Integration and QA (2 d) — qa-lead, qa-tester
Full gdUnit4 run; `/smoke-check sprint`; captures: `areas-test`, `crafting-test` (extended), `spider-test`, new `routines-test` (bathroom times);
headless day runs (all 15 rooms, 3 days, one hostile cycle); balance run for the spider; save/load across a hostile spider and a half-unlocked tree;
docs: Demo Spec update, `ART_DIRECTION.md` rows, sprint-002 log. Visual items are marked "seen" only after the user's windowed capture.

## Tasks (priority tables)
### Must Have
| ID | Task | Owner | Est. d | Depends on | Acceptance |
|---|---|---|---|---|---|
| S2-01 | P0 prep, decisions D1–D3 recorded | producer, art-director | 0.5 | – | refs moved, baseline 419 green, D1/D2 answered |
| S2-02 | Bathroom slots, six schedules, data test | systems-designer, ai-programmer | 1.5 | S2-01 | every NPC morning+evening, no overlap, day run clean |
| S2-03 | Spider ecology + web logic + tuning file | systems-designer, godot-gdscript-specialist | 2 | S2-01 | states, decay by game days, one hit per web, caps, tests |
| S2-04 | Progression data + `CraftingProgression` + migration | game-designer, godot-gdscript-specialist | 2 | S2-01, D3 | graph valid, unlock rules, old saves load |
| S2-05 | Spider art, rig, animations, wiring | art-director, technical-artist, gameplay-programmer | 3 | S2-03 | idle/descend/feed/attack/size seen in capture |
| S2-06 | Progression screen (spec, layout, states, input, entry) | ux-designer, ui-programmer | 3 | S2-04 | all states and navigation work; 1280×720 fits; screenshots |
| S2-07 | Item art, 14 Must icons, loader and fallback | art-director, technical-artist | 1.5 | token | set reads at 40 px; fallback test |
| S2-08 | Yard art both yards, geometry guard green | art-director, technical-artist, level-designer | 3 | token | style match, seams gone, geometry snapshot unchanged |
| S2-09 | Integration, regression, evidence, docs | qa-lead, qa-tester | 2 | all | suite green, smoke pass, QA report |
### Should Have
| ID | Task | Owner | Est. d | Depends on | Acceptance |
|---|---|---|---|---|---|
| S2-10 | 6 lore icons painted | art-director | 0.5 | S2-07 | whole catalog painted |
| S2-11 | `wash` clip for six rigs | technical-artist | 1.5 | S2-02 | clip plays in the bathroom, non-explicit |
| S2-12 | Painted soil/bark/coffin set for the root screen | art-director | 1 | S2-06 | integrated, replaces fallback drawing |
### Nice to Have
| ID | Task | Owner | Est. d | Acceptance |
|---|---|---|---|---|
| S2-13 | Per-room doors for the yards; extra yard props (gnome, flowerpot) | art-director | 0.5 | visual only, geometry guard green |
| S2-14 | Runtime bathroom hold if the day run needs it | ai-programmer | 0.5 | no overlap under late finishes |

## Carryover from sprint 001
None: its Definition of Done is fully checked. Its "Art still required" list is taken up here: spider (S2-05), crafting screen rim (S2-12, S2-06),
item icons (S2-07, S2-10), lawn seams, wall ivy, side walls, hedge reading as a bush (S2-08), door grass tufts (S2-13).

## Agents (assigned only where the domain is needed)
| Agent | Owns | Files |
|---|---|---|
| art-director | style rulings, D1, yard docs, review of every generated batch | `docs/art/**` |
| technical-artist | generation runs, cut-outs, import, rig parts, sprite registry | `assets/art/**`, `tools/art/**`, `visual_style.json` |
| systems-designer | spider numbers, node costs, bathroom slots | `assets/data/ghost/spider.json`, `progression.json` values, schedules |
| game-designer | node catalog (D3) | `design/` note |
| godot-gdscript-specialist | logic classes, saves, registries | `src/game/ghost/spider_*`, `src/game/crafting/*` |
| gameplay-programmer | spider rig behaviour, web, wiring | `src/game/art/spider_rig.gd`, `house_game.gd` wiring only |
| ai-programmer | schedules/occupancy | `assets/data/schedules`, `src/sim/npc` |
| ux-designer, ui-programmer | progression spec and screen | `design/ux/`, `src/game/crafting/progression_screen.gd` |
| level-designer | geometry guard for yards | `tests/integration/data` |
| qa-lead, qa-tester | test plan, captures, regression | `tests/**`, `production/qa/**` |
The orchestrator (this session) owns integration and every cross-file decision. Shared files with one writer at a time:
`house_game.gd` (wiring only, gameplay-programmer), `loot.json`, `visual_style.json`. Each agent reports its public interface before the next depends on it.
Parallelism: P1, P2 and P3 can run together (disjoint files); P4 follows P2; P5 follows P3; P6 and P7 run alongside once the token exists.

## Files and systems affected
New: `spider_ecology.gd`, `spider_web.gd`, `spider_rig.gd`, `crafting_progression.gd`, `progression_screen.gd`, `progression.json`,
`assets/art/items/*`, yard/spider/root art, `BACK_YARD.md`, `FRONT_YARD.md`, UX spec, new tests and capture modes.
Edited: `spider.json`, `recipes.json`, six schedules, `ghost_energy.gd` (+`drain`), `item_art.gd`, `furniture_art.gd`, `crafting_screen.gd` (+button),
`house_game.gd` (wiring), `room_stage.gd` (yard backdrops), `visual_style.json`, `strings.csv`, `ART_DIRECTION.md`, Demo Spec.
Untouched: `rooms.json` geometry, `movement.json`, hiding spots, navigation, camera, existing evidence PNGs.

## Asset inventory (AI-generated)
| Group | Count | Spec |
|---|---|---|
| Item icons | 14 + 6 | 256×256 PNG, transparent, centred, shared prompt; `assets/art/items/<key>.png`; legible at 40 px |
| Spider parts | ~12 (body, head, 4 leg pairs, mandibles, thread, web strand) | 512 px longest side, transparent, one consistent pose and light direction; `assets/art/props/attic/spider_<part>.png`; neutral pose so the rig can pivot |
| Back-yard backdrop(s) | 1 to 3 layers | 2048×1152, sky/house/fence/far trees, no foreground props baked in |
| Front-yard backdrop(s) | 1 to 3 layers | same |
| Yard props | ~14 (sandbox, tricycle, clothesline, garden bed, birdhouse, watering can, mailbox, swing tree, fence section, porch, hydrangea, stepping stones, oak foliage, lantern) | 512–1024 px, transparent; `assets/art/props/back_yard|front_yard/` |
| Surfaces | 4 to 6 | lawn (seamless), path, soil, bark, fence plank, garden wall; 1024 px tiles, tiling checked in a 3×3 montage |
| Root screen | soil tile, bark tile, coffin, tree base/ground strip | coffin 512 px transparent; others tile or strip |
| Optional | `wash` clip ×6 | rig parts via `rig_build.py` |
Naming: lowercase snake_case, room/area folder; `.import` kept with the PNG; originals in `art/concepts/` with `.prev` copies (as `kichat.py` does).
Rules: prompts never contain personal or project-private data; the reference images are **not** uploaded to the generation service (describe them in words)
unless you say so; no raw output is used without cut-out, defringe and a style check.

## Data architecture (summary)
`spider.json` ecology block (tuning only) · `progression.json` (branches, nodes, parents, costs, unlocks, layout) · `recipes.json` (+`node`) ·
`schedules/*.json` (bathroom windows) · item icons by key (no definition change) · one save key per system (`"spider"`, `"crafting"` migrated).
Effects registry for node unlocks (no per-node code in the UI). Adding a branch, node or room-branch is data only.

## UI requirements
Progression screen as above; HUD hint for the spider's mood; the hollow's new "Roots" button; Esc steps back one level; all text in `strings.csv`
(Ukrainian like the rest); 1280×720 minimum; mouse plus keyboard focus; clock paused; no icons or illustrations in nodes.

## Testing
Automated (new, each watched failing first): spider ecology/web, energy drain, progression logic and graph validity, node-state colour mapping, layout bounds,
bathroom schedule coverage and overlap, item icon resolution, yard geometry snapshot, sprite transparency. Headless: three-day runs, spider balance runs, save/load.
Visual (user runs `tools/play.sh`): yards day/night, spider states, progression screen, bathroom times; evidence kept in `production/qa/evidence/sprint-002-*`.
Headless results are never reported as visual verification. QA plan: `production/qa/qa-plan-sprint-002-2026-11-26.md` (written 2026-11-26; sprint tasks treated as stories).

## Risks
| Risk | P | Impact | Mitigation |
|---|---|---|---|
| Reference A is semi-realistic and clashes with the approved style (D1) | high | art rework, style drift | storybook prompts, art-director gate per batch, references stay out of the build |
| Generated art inconsistent across 20 icons / many props | high | patchy set | one shared prompt, contact-sheet review, regenerate outliers, keep code fallback |
| Spider parts generated separately will not line up | high | rig breaks | generate one full spider, split by cut-out (`cut_part.gd`, `split_limb.gd`), spike before committing |
| Node catalog undefined (D3) | high | long branch empty or invented | design pass and your approval before wiring; fixture-driven UI |
| Web fairness / energy loss loop | medium | frustrating | telegraph, cap per day, hidden immunity, simulation run, all numbers in data |
| Yard repaint shifts walkable space | medium | navigation regressions | geometry snapshot test; decor visual-only |
| Schedule changes disturb morale/cleaning/meal sharing | medium | regressions | scenario regression; no work window shortened |
| Token or window unavailable | certain this session | no new art or captures without you | token supplied by user; captures via `tools/play.sh`; plan marks visuals unverified |
| `house_game.gd` (1556 lines) keeps growing | high | maintainability | new logic in classes; wiring only |
| ~22 d scope is large | medium | slip | Should/Nice are cuttable; yards and lore icons are the first cuts |

## Dependencies on external factors
User supplies `KI_CHAT_TOKEN` and runs windowed captures; D1–D3 answers; availability of the external image service (first tree request failed once in sprint 001).

## Acceptance criteria by phase
- P1: all six use the bathroom morning and evening in non-overlapping 15-min slots; 3-day headless run has no stuck NPC; existing routines unchanged.
- P2: configurable ecology, growth, hostile, recovery by game days, one-hit webs, capped energy loss; tests green.
- P3: any branch/node/room added by data only; costs all-or-nothing; old saves load; graph validator green.
- P4: new painted spider animated by parts; idle, descend, feed, attack, size all seen in capture; trade/feeding unaffected.
- P5: every node state visible; navigation hollow ⇄ roots; long left branch ends at the coffin; layout within 1280×720; screenshots retained.
- P6: Must icons painted and readable at 40 px, fallback test green, no item logic changed.
- P7: both yards match the storybook set and share one kit, still distinct; geometry snapshot unchanged; seams fixed; captures day/night.
- P8: full suite green (≥ 419 + new), smoke pass, QA report, docs updated.

## Definition of Done
- [ ] All Must Have tasks complete and each acceptance criterion met
- [x] QA plan exists (`production/qa/qa-plan-sprint-002-2026-11-26.md`)
- [ ] Full gdUnit4 suite green with no skipped tests (419 baseline + new)
- [ ] Smoke check passed (`/smoke-check sprint`); QA sign-off APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] Windowed captures reviewed for yards, spider, progression screen, bathroom routine, retained in `production/qa/evidence/sprint-002-*`
- [ ] Geometry snapshot for the yards unchanged; no gameplay data edited by art work
- [ ] No S1/S2 bugs in delivered features
- [ ] `ART_DIRECTION.md`, yard docs, Demo Spec and this log updated; open art items listed
- [ ] Nothing committed or pushed without your instruction

## Recommended implementation order
P0 → (P1 ∥ P2 ∥ P3, art generation starts when the token exists) → P4 → P5 → (P6 ∥ P7) → P8.

## Progress log
- 2026-11-26: **P0 done.** Baseline 419 green (`production/qa/evidence/sprint-002-baseline.txt`); references moved to
  `art/references/sprint-002/` (`reference_a_yards.png`, `reference_b_root_progression.png`); D1–D3 approved; catalog in
  `design/crafting-progression-catalog.md`; QA plan written. Yard doc skeletons moved to P7 with the yard art.
- 2026-11-26: **P1 done in data, 423 tests green; screenshots not yet taken.**
  - Slots re-timed from the plan's 15-minute proposal: walks to the upstairs bathroom take 3 to 22 game minutes (worst
    case run-down house, grandparents), so windows are 15–30 minutes. User approved the table and grandma's visits
    (Demo Spec §5.6 note added; her test now expects 13 activities). Grandpa goes in the morning only; the other five twice.
  - Morning: mother 06:00, father 06:15 (then `father_dress`), grandpa 06:30–07:00, grandma 08:00–08:30, son 08:30
    (computer split round it), daughter 08:45. Evening: father 20:00–20:30, grandma 20:30–21:00, son 21:00, daughter 21:15
    (no longer at the same time as her brother), mother 21:30–22:00. Children then read / play dolls in their room until 22:00.
  - New `tests/integration/data/bathroom_schedule_test.gd` (4): everyone goes, no overlap, the children no longer share
    21:00, ≥ 5 min at the sink after the worst-case walk. Three watched failing on the old data; the fourth by a mutation
    (grandma's evening slot shortened: "−1 min at the sink after a 16 min walk"), then restored.
  - Headless 3-day run: never two in the bathroom, no visit under 5 min, nobody stuck (`sprint-002-routines/day-log.md`).
  - Found, not changed: morale ends day 1 up to 7 points higher (more completed activities, +1 each); day 1 the son's
    first computer half-hour is skipped while the computer is broken (no morale effect).
  - No `wash` clip exists: people stand idle in the bathroom (as the children did before). Clip is S2-11 (Should).
  - Capture mode `bash tools/play.sh routines-test` added (`house_game.gd` capture code only); needs a window.

- 2026-11-27: **P1 screenshots reviewed** (`bash tools/play.sh routines-test`, run by the user): each of the 11 visits
  shows the right person alone in the bathroom; father dressing; children in their room at 21:40. People stand mid-floor
  between bath and sink (no `wash` clip or target yet: S2-11). Awaiting the user's sign-off.
- 2026-11-27: **P2 done (logic and data), 454 tests green; not wired into the game yet (P4).**
  - `SpiderEcology` (`src/game/ghost/spider_ecology.gd`): moods FRIENDLY → GROWN (warning, still trades) → HOSTILE (refuses
    food, capped calories, `hostile_days`) → RECOVERING (shrinks, refuses food) → FRIENDLY at `calm_at`; burns calories by
    game minutes; size linear in calories; save/load, older saves start friendly.
  - `SpiderWeb` (`src/game/ghost/spider_web.gd`): cooldown → wind-up with the spot marked where the ghost was → web flies to
    that spot; hits only an exposed ghost within the radius when it lands; one hit per web; daily cap; hiding or the
    spider calming cancels the wind-up. Real seconds, so fair at every game speed.
  - `GhostEnergy.drain(amount, reason)`: the web's damage path (reason "web").
  - `spider.json` `ecology` and `web` blocks (all values provisional, notes in `_ecology`).
  - Tests: `spider_ecology_test.gd` (14), `spider_web_test.gd` (11), 2 in `ghost_energy_test.gd`, 4 in
    `spider_data_test.gd`; the first three watched failing before the code (missing classes and method), the data
    targets by a mutation. Balance run: `production/qa/evidence/sprint-002-spider/balance.md`.
  - Not done here (P4): feeding from `_trade_with_spider`, ticking, drawing the web and wind-up, HUD mood hint, save key
    `"spider"`. `GhostStats` will count web damage as "spent", not "lost to being seen"; decide in P4.
- 2026-11-27: **P3 done (logic, data, wiring), 488 tests green; the roots screen is P5.**
  - `progression.json`: 26 nodes from the approved catalog (T0–T2, R1–R11, G1–G8, K1–K4; the catalog summary said 25,
    a miscount: 3 trunk + 23). Costs: concrete provisional amounts by the catalog's S/M/L sizes.
  - `CraftingProgression`: trunk nodes *are* the tree's existing levels (owned = board tier reached; unlocking one is
    `CraftingBoard.upgrade()`), so the hollow screen's upgrade button and sprint 001 saves need no migration. Branch nodes:
    own costs, all or nothing, saved as `"progression": {"owned": [...]}`; `check()` rejects unknown branches/parents, cycles,
    nodes without cost or effect, invalid effects (run when the game loads, and by `progression_data_test.gd`).
  - `GhostModifiers`: one list of {key, add|mul, value, room?, npcs?, action?}; 13 known keys. Read by `GhostEnergy`
    (max, regen, multipliers, action cost/minutes; `room_id` set each frame), `GhostLoot` (`search_minutes()`, `slot_count()`),
    `StealthSystem` (glimpse energy and contact fright per family member), ghost speed and monocle minutes (`house_game.gd`).
    Detection energy is now charged with `drain(amount)` from the stealth signal's amount (same reasons, same stats).
  - Save/load: the tree and roots load before energy (a bigger maximum must exist before the saved value is clamped).
  - `CraftingBoard.upgrades()` added (read-only copy).
  - Tests: `ghost_modifiers_test.gd` (9), `crafting_progression_test.gd` (10), `ghost_modifiers_use_test.gd` (8),
    2 in `stealth_system_test.gd`, `progression_data_test.gd` (5); all watched failing first (missing classes / properties),
    the data test also by a mutation (a room bond moved to the attic). Headless end-to-end in the game scene: 29/29
    (`production/qa/evidence/sprint-002-progression/headless-e2e.md`).
  - Left for P5: node and branch names in `strings.csv` (`NODE_*`, `BRANCH_*`), layout data, the screen; the HUD bar is
    re-laid out only on the next inventory change after G6 (refresh it when a node is unlocked).
- 2026-11-27: **P5 UX spec approved**: `design/ux/roots-progression.md` (`/ux-design`, four review rounds). Choices: "Коріння"
  button + R in the hollow; Esc/E/right-click/← step back one level; bottom node panel; whole network drawn, locked dimmed;
  node positions in data with automatic fallback; single-press Unlock; spatial arrows + Tab; slide down into the soil.
  **Scope addition (user, 2026-11-27): a "Менше руху" (reduced motion) setting** in the settings menu, honoured by the roots screen.
- 2026-11-27: **P5 built, 516 tests green; screenshots not yet taken (`bash tools/play.sh roots-test`).**
  - `RootsScreen` (`src/game/crafting/roots_screen.gd`), child of the hollow (layer 5): sky/fence/shed strip, the tree and
    its hollow, soil, bark-brown roots (warm gold once owned, a light runs along on unlock), plain coloured node circles,
    the coffin (drawn; painted art is S2-12), parchment node panel (name, effect, cost have/need with ✗ in ember red,
    parents ✓/✗, "cannot be undone"), single-press "Розкрити". Arrows/Tab/Enter/Esc/E/right-click; slide down 0.35 s.
  - `RootsLayout` (positions from data or automatic along the branch, Tab order, arrow neighbours, 36 px hit circles, seeded
    root curves, coffin), `RootsStyle` (state → radius/ring/glow/pulse; branch colours = existing palette: candlelight,
    gold, olive, rose).
  - Hollow: "Коріння (R)" button (top left, beside the recipes heading) and R (physical key, works on Ukrainian layouts); its
    keys are ignored while the roots are open. `node_unlocked` → game log line and slot-bar refresh (G6).
  - "Менше руху": `GameSettings.reduced_motion` (saved under `game`), checkbox in the settings screen, passed to the hollow.
  - Data: hand-placed `layout` for all 26 nodes after reference B, branch `direction`, coffin place on the rooms branch;
    66 strings (`BRANCH_*`, `NODE_*`, `NODE_*_TEXT`, `ROOTS_*`, `SET_REDUCED_MOTION`).
  - Deviation from the spec, small: missing materials are marked in ember red (`SB_EMBER`) instead of rose, for contrast on
    parchment; still with ✗.
  - Tests: `roots_layout_test.gd` (8), `roots_style_test.gd` (6), `roots_screen_test.gd` (9), 2 in `game_settings_test.gd`,
    3 in `progression_data_test.gd` (layout in the soil, ≥ 30 px apart, coffin far left, every string present); all watched
    failing first. Found by the tests: an arrow test expectation (fixed in the test) and the R key compared by layout
    keycode (fixed: physical key). Headless end-to-end in the game: 10/10.
- 2026-11-27: **roots-test reviewed** (`production/qa/evidence/sprint-002-progression/r00–r10`, run by the user): navigation,
  first visit, short of materials, unlock, mid-progress, all owned and the coffin as specced. Fixed after it (user's pick):
  locked nodes keep ~45% of their branch colour (branches did not read on a first visit); owned = thick gold ring + small
  steady halo vs available = wide pulsing halo, no ring (too alike in a still). Spec's States table updated; 2 style tests
  (watched failing first); 518 tests green. Not changed: the faint olive green; the flat drawn ground strip (S2-12 art).
  Screenshots need a second run.
- 2026-11-27: **roots-test re-run reviewed**: branch tints read on the first visit (r03); owned vs available clear (r08).
- 2026-11-27: **P4 done in code (spider in the game), 532 → 539 tests; painted spider not generated (`KI_CHAT_TOKEN` not
  set in this session).**
  - `SpiderBehaviour` (drop toward the floor when the ghost is within `react_m`, back up after `return_delay_seconds`;
    feed / telegraph / hostile / idle), `SpiderPose` (the rig: thread, abdomen, head, mouth, 8 legs as hip/knee/foot, front
    pair eats; size and drop), `SpiderArt` (code-drawn from the pose; the web's wind-up mark and the web in flight).
    Values: `spider.json` `behaviour`.
  - Game: the trade feeds the spider (D4); hostile or recovering refuses with a prompt; mood changes logged; the web runs
    each frame while the clock runs, only at a ghost in the attic and not hidden; a hit drains `damage_pct` of the maximum
    ("web", counted as *lost* in the end summary); saved under `"spider"`. `RoomStage.spider_draw/spider_overlay`.
  - Tests: `spider_behaviour_test.gd` (6), `spider_pose_test.gd` (7), 1 in `spider_web_test.gd`; watched failing first.
    Headless end-to-end in the game: 14/14 (lowering, feeding = calories, refusal, one hit = 10, none hidden / elsewhere /
    paused, stats, save/load, recovery). Capture: `bash tools/play.sh spider-test`.
  - Rig choice (B2): pose points per part drawn in code; painted part images will follow the same points (no skeleton,
    no AnimationPlayer).
- 2026-11-27: **P6 loader done; icons not generated (no token).** `ItemArt` draws `assets/art/items/<icon>.png` when it
  exists, else the code drawing (all 20 icon keys have one); `item_art_test.gd` (4).
- 2026-11-27: **P7 guard and briefs done; art not generated (no token).** `yard_geometry_test.gd` + snapshot fixture
  (rooms, pieces, hiding spots, footprints; mutation checked); `docs/art/environments/BACK_YARD.md`, `FRONT_YARD.md`;
  `ART_DIRECTION.md` row. **OPEN:** Reference A shows the house rear behind the back yard, but the back yard lies north of the
  house and the camera looks north, so its back wall faces away from the house; default: garden fence/wall with trees.
- 2026-11-27: **P8 (so far)**: full suite 539 green; headless checks re-run (bathroom days, progression, roots, spider) clean;
  Demo Spec v0.17 (§5.6 note, §8.13 new).
- 2026-11-27: **Decisions (user):** back yard's back wall = garden fence and trees (not the house rear); art prompts are
  run without a review step. Job files written: `art/prompts/sprint-002/{spider,items,yards,roots}.json` (3 + 20 + 18 + 3
  images; storybook style in every prompt, no reference images uploaded). Waiting for `KI_CHAT_TOKEN` in the session.
- 2026-11-27: **Art generated (user supplied a fresh `KI_CHAT_TOKEN`, used only on the command line, never written to a
  file) and wired; 545 tests green; not yet seen in a window.**
  - Generation: 44 jobs + retries (`retry.json`, `retry2.json`, `retry3.json`). Service timeouts (`[ERROR: Request Timeout]`)
    on the long spider prompt and on the coffin (twice, also worded as "a wooden box"); the spider worked with a short
    prompt. `kichat.py` now prints the service's error text instead of `KeyError(0)`. Rejected and regenerated: dust (a house,
    then a door), spider nest (a bird's nest), monocle (a magnifying glass), photo (blank), crafting tree (no hollow),
    spider leg (a whole spider).
  - Items: all 20 icons painted, cut out to 256 px (`assets/art/items/`), checked at 40 px; `ItemArt` uses them.
  - Spider: painted body and head (`assets/art/props/attic/spider_body.png`, its painted legs masked away) placed on the rig's
    body point (`SpiderArt.body_rect`, 3 tests); legs drawn from the rig in the painting's charcoal and terracotta; red eye
    glow when hostile. The generated single leg was not used (it did not match the body's legs).
  - Yards: repainted crafting tree, shed, woodpile, rain barrel (room-scoped `back_yard/barrel`), long hedge; decor (clothesline,
    sandbox, tricycle, garden bed, watering can, birdhouse; swing oak, two hydrangeas, mailbox) as `decor` pieces — drawn only;
    the geometry guard now compares the gameplay pieces exactly and requires decor to carry no gameplay fields (mutation
    checked). Surfaces: back-yard fence (back wall), fence with hedge (side walls), seamless lawn; front-yard picket fence with
    hydrangeas (side walls). New `side_wall` texture key in `RoomSurfaces` (2 tests). Sizes by `tools/art/props.py`.
  - Roots screen (S2-12): painted soil under the roots and bark on the trunk; the coffin stays code-drawn (generation timed out).
  - Headless smoke: both yards, the attic and the roots screen drawn without errors.
- 2026-11-27 capture review (user's windowed run): areas, roots, items OK. The spider capture stopped after s07 —
  captures run with `_process` off, so `_update_spider` never ran (no lowering, no web). Fixed in the capture only
  (`_spider_frames` / `_spider_until` drive the spider each frame; feeds until hostile; time limits on the waits).
  545 tests green. Spider-test to re-run. Findings noted: the back-yard lawn's dark root patches repeat visibly; the
  front yard's back wall is still the plain weatherboard (porch and door from the brief not painted); a faint
  horizontal seam in the roots soil.
- 2026-11-27 spider-test re-run (windowed): all ten shots s01–s10. Lowering toward the ghost, eating, growth, hostile
  wind-up mark at the ghost's feet with front legs raised, web in flight, hit (−10 energy, log line) all seen.
  Notes for the art pass: the code legs read navy rather than charcoal; lowered, the spider hangs just behind the
  ghost's head. S2-05 awaits the user's sign-off.
- 2026-11-27 fixes from the capture review:
  - spider legs: the painting's own warm charcoal (`SpiderArt.LEG_PAINTED` #3a3330, sampled from the body image)
    with a thin highlight, instead of the navy `SB_CHARCOAL`;
  - roots soil: the "seam" was the five stepped darkening bands; now one smooth gradient;
  - back-yard lawn: the root "stars" came from big dark tufts at the texture's edges meeting under mirrored tiling.
    The image service timed out (4×), so the lawn was rebuilt from the same painting by `tools/art/calm_texture.gd`
    (soft patches from its calm parts); the previous lawn kept at
    `art/concepts/props/sprint002/yards/floor_back_yard_lawn_v1.png`;
  - front porch (house front with door and wreath): NOT DONE — generation timed out 2×. Prompts ready in
    `art/prompts/sprint-002/fixes_retry.json`; placement planned as decor `front_porch` (u 0.5, v 0.03, 2.8 × 2.9 m).
  545 tests green; to be seen in `areas-test`, `spider-test`, `roots-test`.
- 2026-11-27 re-captures: lawn without stars (accepted look: even, a little plain); roots soil band line gone.
  Two follow-ups: the legs still read blue — the attic's cool grade pushes flat darks toward blue (#3a3330 → #262d42
  on screen), so LEG_PAINTED is now #4a3e36 (lighter, warmer); a faint vertical soil seam where the texture repeats
  (x = 1024) — soil made wrap-seamless by `tools/art/make_seamless.gd` (original kept at
  `art/concepts/props/sprint002/roots_soil_v1.png`). 545 tests green; spider-test and roots-test to re-run.
- 2026-11-27 correction: the legs stayed blue because the first leg edit never applied (the scripted replace did
  not match, unchecked); `_draw_painted` still used SB_CHARCOAL. The "cool grade" explanation above was wrong. Now
  LEG_PAINTED / LEG_SHINE are actually used. Roots soil re-capture: no line, no seam — accepted.
- 2026-11-27 spider-test re-run: legs now warm charcoal with terracotta joints, matching the painted body. S2-05 ready for sign-off.
- 2026-11-27 USER SIGN-OFF: S2-02 (bathroom routines), S2-05 (spider art/rig/animation), S2-06 (roots screen).
- 2026-11-27 porch and coffin retry: both timed out again (`art/prompts/sprint-002/retry4.json`); a trivial probe
  prompt also timed out (545 s), so the ki-chat image service is down as a whole. Prepared: `RootsScreen` draws
  `res://assets/art/props/roots/coffin.png` (140 px wide) when it exists, else the code coffin. The porch's
  placement is in the earlier entry. Both wait for the service.
- 2026-11-27 exit leak fixed ("9 ObjectDB instances leaked / 4 resources still in use", seen after every capture):
  `CraftingProgression` connected the board's `changed` to a lambda; a lambda in a RefCounted holds its self, so
  board ↔ progression formed a cycle that kept both, the loot and the modifiers alive. Now `changed.emit` is
  connected directly. Not present in sprint 001 (checked on HEAD). Regression tests in
  `crafting_progression_test.gd` (freed when unreferenced, failing before the fix; board change still forwarded).
  547 tests green; `house_game.tscn` exits with no leak report (headless, --verbose).
- 2026-11-27 QA: smoke PASS (`production/qa/smoke-2026-11-27.md`); /team-qa sign-off APPROVED WITH CONDITIONS
  (`production/qa/qa-signoff-sprint-002-2026-11-27.md`). Conditions: S2-05 web timing and legs/body look (details
  to get), porch and coffin into sprint 003, `/code-review` before advancing; monocle icon repaint advisory.
  S2-11, S2-13 carried over; S2-14 closed as not needed; S2-12 closed partial. New: combined save/load integration
  test (548 tests), evening pass in areas-test, evidence docs for S2-05/06/07/08/12 and sprint-002-final.
- 2026-11-27 `/code-review`: CHANGES REQUIRED → fixed → **APPROVED WITH SUGGESTIONS** (S2-09's code-review condition
  met). Fixes: roots-screen keyboard focus (plaques FOCUS_NONE; focus released on open), hover cleared on leaving
  the soil, redraw only while animating with reduced motion, `RoomStage.elapsed()`, 12 doc comments; 3 new
  viewport-routed tests (551 green). Sprint 003 notes: split `RootsScreen._build`; keep `house_game.gd` from growing.

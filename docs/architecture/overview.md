# Architecture Overview

How the code fits together. Last updated 2026-11-13 (after stage 5b, commit `ea3cc4c`).
Workflow is *minimal*: no ADRs are required; this overview and the Demo Specification carry
the decisions. Engine: Godot 4.7.2, statically typed GDScript (`.claude/docs/technical-preferences.md`).

## Layers

```
src/core/      engine-level helpers (no gameplay)        GameClock
src/data/      reading data files                         JsonData
src/sim/       the house simulation — no nodes, no drawing, fully unit-tested
src/game/      the playable game — ghost, stealth, rooms on screen, HUD
src/debug/     debug tools, not shipped                   sim_view (plan view of the house)
assets/data/   every gameplay value (JSON)                assets/i18n/ all player text (CSV)
```

Dependencies point downward only: `game` → `sim` → `core`/`data`. The simulation never knows
about the ghost's position, the screen or the HUD.

## Simulation (`src/sim/`)

| Class | Job |
|---|---|
| `HouseSim` | Builds everything from data; steps routines and morale once per game minute; stops when the scenario ends. |
| `GameClock` (core) | Game minutes from real seconds, ×1/×2/×4, pause, day/night. |
| `HouseState`, `RoomState`, `ObjectState` | Rooms (grid cell, cleanliness, temperature, light, windows), doors with walking minutes, objects with discrete states; lamps and windows drive light and temperature; requirements and effects. |
| `Schedule`, `Activity` | A person's day: activity windows (work, span, task windows), requirements, effects, morale category, conditions that affect them, anxiety. |
| `NpcRoutine` | One person's state machine: walk, wait, perform, skip, finish late, task windows, self-search, Broken, hold/release. |
| `TaskBoard`, `HouseTask` | Repair and clean tasks read from the house, priorities, claims. |
| `MoraleSystem` | Penalties, bonuses, Broken and recovery, win check on every change, loss at the last day's end. |
| `GhostActions` | The ghost's one-way object actions. |

## Game (`src/game/`)

| Class | Job |
|---|---|
| `house_game` (main scene) | Wires the simulation, ghost, stealth, view and HUD; input; scripted capture. |
| `GhostNavigator` | The ghost's room and floor position; through walls on the floor grid and through floors. |
| `RoomLayout` | Furniture placement, where each person stands and faces, hiding spots, occluders, sight zones and line of sight. Pure logic, shared by view and stealth. |
| `StealthSystem` | Detection, inspection, search, contact, hiding, energy ledger. |
| `RoomStage` | Draws the current room, furniture, family, ghost, sight cones, markers. Reads only. |
| `RoomGeometry`, `FurnitureArt`, `FamilyArt`, `Palette` | The room frame and code-drawn original placeholder art. |
| `GameHud`, `Localization` | Ukrainian HUD (clock, morale, log, prompt, map, banners) via the CSV text table. |

## One game minute, in order

1. `GameClock.advance` passes a whole minute and emits `minute_advanced`.
2. `HouseSim`: `MoraleSystem.begin_minute` → every `NpcRoutine.step` → `MoraleSystem.end_minute`
   (conditions, half-hourly penalties, Broken recovery, loss check).
3. `house_game`: `StealthSystem.on_minute` (reactions, inspections, searches, frights).
4. Every frame: ghost movement, `StealthSystem.observe` (sight checks), view and HUD redraw.

Signals carry events outward (activity started/completed/skipped, task done, morale changed,
Broken, contact, energy penalty); the HUD and logs listen, nothing listens upward.

## Data

| File | Holds |
|---|---|
| `assets/data/time/clock.json` | Time rules |
| `assets/data/sim/rules.json`, `tasks.json`, `morale.json` | Work steps, task priorities and durations, morale values |
| `assets/data/house/rooms.json` | Rooms, grid, windows, doors, objects (with repair, ghost and self-fix data) |
| `assets/data/house/furniture.json` | View layout, hiding spots, occluders, the monocle |
| `assets/data/schedules/*.json` | Six schedules with anxiety |
| `assets/data/ghost/ghost.json`, `stealth.json` | Ghost movement and stealth numbers |
| `assets/i18n/strings.csv` | Player text (Ukrainian; a column per language) |

## Tests

`tests/unit/` per system, `tests/integration/data/` for the shipped data and whole-day runs;
fixtures in `tests/unit/fixtures/sim_fixtures.gd`. CI: `.github/workflows/tests.yml` runs
gdUnit4 on Godot 4.7.2 for every push and pull request to `main`. Details: `tests/README.md`.

## Known structural debts
- Family positions inside rooms are computed for the view and stealth (`RoomLayout`) but have
  no walking paths yet — roadmap step 1.
- Debug sim view (`src/debug/`) duplicates some HUD text; it is a tool, not shipped.
- Runtime text is read from the CSV source; an exported build will need Godot's imported
  translations instead (generated on import, ignored by git).

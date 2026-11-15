# Roadmap — Ghost vs. Humans: House Takeover

Planning document. Last updated 2026-11-15.
Sources of truth: `ghost_house_game_design_document_uk.md` (GDD v0.8),
`demo_specification_ghost_house_uk.md` (Demo Specification v0.11). Summary: `design/game-brief.md`.
Repository: https://github.com/Zubariev/ghost (branch `main`).

## Done

| Stage (Demo Spec §13) | What was built | Commits | Evidence |
|---|---|---|---|
| Setup | Godot 4.7.2, GDScript, gdUnit4 v6.2.2, GitHub Actions CI | `104d925`, `d070c78`, `45696b0`, `fd3f727` | CI green on every push |
| 1. Spatial prototype | Hamlet-style room spike — verdict YES | `104d925` | `prototypes/ghost-house-spike-2026-11-12/SPIKE-NOTE.md` |
| 2. Simulation prototype | Clock, house state, grandma's schedule, cooking rules | `ac29214`, `9ff0839` | Demo Spec §5.6; tests |
| 3. Family prototype | Six schedules, priority work windows, shared meals | `ef0c714`, `eaa5c48` | Demo Spec §5.7; tests |
| 4. Morale | Penalties, bonuses, Broken, win and loss | `1d6da0c`, `7831a71` | Demo Spec §7.6; tests |
| 5a. Ghost in play | Hamlet-style rooms, ghost through walls/floors, five actions, Ukrainian HUD | `6b15e00`, `d3265db` | Demo Spec §8.7; tests |
| 5b. Stealth | Sight zones, detection, hiding, search, contact, energy ledger, monocle + Q | `7494d1d`, `ea3cc4c` | Demo Spec §8.8; tests |
| 5c. Family movement | Walks round furniture, through matching doors and stairs; sight from walking position | `43a2718`, `2fe1ba3` | Demo Spec §8.9; `stage5c-movement` |
| 5d. Ghost energy | Refill (hidden/dark/cold), action costs, timed harm with ring, detection penalties, HUD bar | `35907b8`, `9f14c1e`, `66818a7` | Demo Spec §8.10; `stage5d-energy` |
| 5e. Floor keys | W/S + Space; pause on Esc | `a4a9c6c` | Demo Spec §8.7 |
| Art test | Whimsical Gothic Storybook living room (cozy / haunted), painted-sprite path | `6bfc25b`, `5f1a966`, `d7e26aa` | `docs/art/ART_DIRECTION.md`; `art-test-living-room` |

Automated tests: **189**. Run: see `tests/README.md`.

## Next steps (in order)

### 1. Family movement inside and between rooms — *done 2026-11-14*
Built (Demo Spec §8.9): `RoomPaths` (grid A* round furniture footprints), `FamilyMotion`
(routes through doors and stairs, catch-up, staggered departures, stealth incidents),
sight from walking positions, `assets/data/house/movement.json`. Tests: 142 (movement unit
18, integration 4). Left: the user plays `bash tools/play.sh`, captures
`bash tools/play.sh capture` (production/qa/evidence/stage5c-movement), then commit.

Original scope:
Today family members jump between spots inside a room and only half-walk to doors.
- Every family member walks continuously along a path **around furniture** inside a room:
  from the door they enter by to their activity spot, from spot to spot (task to task,
  cooking to the table), and out through the correct door.
- Between rooms: leave through the door that leads to the next room, enter through the
  matching door; take the stairs between floors.
- Sight follows the actual walking position and direction.
- **Decided 2026-11-13:** walking inside a room is shown only, within the minutes the schedule
  already allows; it costs no simulation time (the simulation and its tests stay as they are).
- **Done when:** nobody teleports in any room during a full day; tests cover paths around
  furniture, door choice, and that simulation timings are unchanged.

### 2. Ghost energy system — *done 2026-11-15*
Built (Demo Spec §8.10): `GhostEnergy` (refill: passive, ×3 hidden, ×1.5 dark, ×1.25 cold;
none while acting or 5 min after; costs; detection penalties; low warning), `GhostCasting`
(harm takes 2–5 game minutes by cost, clockwise ring, cancelled by moving/hiding/floor
change/contact at no cost), energy bar in the HUD, `assets/data/ghost/energy.json`.
Tests: 167. Left: the user plays, captures `bash tools/play.sh capture`
(production/qa/evidence/stage5d-energy; shots 20–22 are the energy ones), then commit.

Original scope:
- Decide: maximum, regeneration, cost per action, exhaustion and its consequence
  (GDD §12.1: dissipate and return to a point of power).
- **Done when:** actions and detection spend energy by the agreed rules; tests.

### 3. Replace R/C for changing floors — *done 2026-11-15*
Decided: W + Space up, S + Space down; pause moved from Space to Esc (Demo Spec §8.7).

Original note:
Recorded as open in Demo Spec §8.7. Options noted: stairs only, mouse wheel, Shift + W/S.

### 4. Tuning after play — *in progress*
Round 1 (2026-11-15, Demo Spec §8.11, done and played): slower walking with per-person pace,
room condition slows people and the ghost, slower ghost, run-down start, head turns, hold E,
search and loot (inventory, lore journal). Awaiting play: `bash tools/play.sh`, capture
`bash tools/play.sh capture` → `production/qa/evidence/playtest-2026-11-15/` (23–25 loot).

Round 2 (2026-11-15, Demo Spec v0.12): morale probe (3 days headless, scripted ghost) showed the
win was out of reach and the family healed to 100 by day 2. Win = family average ≤ 20; bonuses
halved; late food makes a poor meal; no natural decay. Re-probe: casual ghost takes the average
70 → 38 in 3 days, perfect ghost wins on day 2 morning.

Art: the living room style is approved (2026-11-15). Paused by choice for gameplay; later art
steps: redraw the six family members (still recoloured placeholder figures), then roll the style
out to the other ten rooms (`docs/art/ART_DIRECTION.md`).

Provisional values to revisit with playtests: morale penalties and bonuses (Demo Spec §7.6 —
an undisturbed day ends with everyone at 100), sight zone sizes, search time, anxiety values,
energy amounts (§8.8), cooking and repair durations, ghost speed.

### 5. Stage 6 — vertical slice — *built and captured 2026-11-15*
The full 3-day scenario as one integrated demo: start, the three days, the end summary and a
restart (Demo Spec §10, §10.4). Built: start screen (main scene), family-resolve bar, day card
at dawn, end summary with the ghost's stats (GhostStats), Play again / To title; full-scenario
integration test. Capture: `bash tools/play.sh capture` → `production/qa/evidence/stage6-slice/`
(00 title, 01–28 tour incl. 26 day card, 27 resolve bar, 28 win summary; 29a/29 loss run).
Open: a cook whose cooking overruns their own meal skips it without the missed-meal penalty.
Polish: the resolve bar's hover number is dark on the dark empty part of the bar (shot 27).

### Later (Demo Spec §13 stage 7 and §14 P2)
Polish and balance, sound, animation, wider object set, family adaptation, save/load, more
scenarios.

## Open decisions

| Item | Where | Status |
|---|---|---|
| In-room walking costs simulation time? | step 1 | decided: no (visual only) |
| Energy rules | GDD §12.2, Demo Spec P0 #7 | decided 2026-11-14 (§8.10); values provisional |
| Floor-change controls | Demo Spec §8.7 | decided 2026-11-15: W/S + Space; pause Esc |
| Natural decay (rooms getting dirty without the ghost) | GDD §9.5 | decided 2026-11-15: none (ghost-only) |
| Food cooked after its meal window | Demo Spec §7.6 | decided 2026-11-15: stays, eaten as a poor meal (`meal_cold`) |
| Win condition | Demo Spec §7.4 | decided 2026-11-15: family average morale ≤ 20 (all-six-at-once was out of reach) |
| Win/loss presentation beyond the banner | GDD §1.4 | open |

## How we work
- Each stage: questions → plan → approval → tests first → build → full test run → deliberate
  rule-breaks to prove the tests catch them → the user plays → commit → push → CI.
- Decisions are recorded in the Demo Specification (Ukrainian) with a version entry.
- gdUnit4 stops a test file after its first failure: deliberate-break checks run the guarding
  test on its own.
- Windowed runs and screenshots are made from the user's own terminal (`bash tools/play.sh`,
  `bash tools/play.sh capture`); this session cannot open a window.

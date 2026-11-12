<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Spike: Hamlet-style room (2026-11-12)

**Question:** Can Godot 4.7 2D present a room interior in the *Don't Starve: Hamlet*
manner so that walls, floor, doors, furniture, a ghost passing through walls, a
walking NPC and interactive-object highlighting all read clearly?
(Demo Specification §4.1 technical check; roadmap stage 1.)

**Status:** concluded 2026-11-12 — YES. See `SPIKE-NOTE.md` and `evidence/`.

## Run

From the repo root:

```bash
/home/ther0/Games/godot --path . --windowed --resolution 1280x720 res://prototypes/ghost-house-spike-2026-11-12/room_test.tscn
```

Scripted tour that saves five screenshots into `evidence/` and quits:

```bash
/home/ther0/Games/godot --path . --windowed --resolution 1280x720 res://prototypes/ghost-house-spike-2026-11-12/room_test.tscn -- --capture=$PWD/prototypes/ghost-house-spike-2026-11-12/evidence
```

Controls: WASD float · E interact · Q sight cones · Space pause · 1/2/3 = ×1/×2/×4.

## What is in it

| Thing | Built as | Source |
|---|---|---|
| Room | Back wall + two slanted side walls, no front wall, plank floor converging to the back, cut floor edge | GDD 13.1–13.2 [AGREED] |
| Doors | Open doorway in the back wall, one in the left wall drawn in its perspective | Demo spec 4.1 |
| Depth | `Node2D.y_sort_enabled`; every object's origin is its front foot on the floor | Demo spec 4.1 |
| Ghost | Free WASD float, no collision; the wall it is inside fades to 45 % | Demo spec 8.2 [AGREED AS DIRECTION] |
| Test NPC | Grandma walking an 8-point loop, pausing at bed, stove, table and door | Demo spec 4.1 |
| Highlighting | Nearest interactable within 85 px pulses; others within 230 px get a faint outline; prompt above it | Demo spec 9.3 |
| E action | Lamp only: snuff / relight; changes the room light. No morale or NPC reaction | User decision (spike scope) |
| Stove, window | Targetable, prompt says the action is not in this test | — |
| Q | Peripheral (120°) and deep (42°) zones drawn on the floor. **Visual only** | Demo spec 8.5 (zones only) |
| Time | Clock at 1 game min = 1 real s, ×1/×2/×4, pause, day/night label | Demo spec 6 [AGREED] |
| Text | Ukrainian, looked up by key in `strings_uk.gd` | User decision |
| Tuning | `config.gd` | — |

Not built: detection, morale, schedules, energy, room states, hiding (F), real art.

## Choices made in the spike that are not in the docs

- **Pause freezes the ghost too**, not only the simulation (the demo spec leaves pause open).
- **Time speed scales the clock and the NPC, not the ghost's float speed.**
- **The ghost can relight the lamp** — a test convenience; the agreed rule is that
  restoration needs an NPC activity (demo spec 4.3).
- **NPC walks hand-placed waypoints**, not a navigation mesh. Navigation for six NPCs
  is a separate question.

## Findings

**YES** — the Hamlet-style presentation works in Godot 4.7 2D (user verdict, second run).

- Room, walls, doors and furniture read clearly. Depth sorting by floor point works.
- Fading the wall the ghost is inside keeps the ghost readable.
- Targeting: a bright outline and prompt for the target, a softer outline for nearby
  interactables. Range counts the ghost's body or its floor position.
- Sight zones must be clipped to the floor, or they spill through the walls.
- The HUD must stay off the room's area. The log now sits top-right.
- Open: object prompts can overlap NPC name labels.
- Not assessed: hands-on feel of WASD, pause and speeds; several NPCs; navigation;
  moving between rooms.

Full note: `SPIKE-NOTE.md`.

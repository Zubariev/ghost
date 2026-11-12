<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Spike note: Hamlet-style room (2026-11-12)

## Question tested

Can Godot 4.7 2D present a room interior in the *Don't Starve: Hamlet* manner so that
walls, floor, doors, furniture, a ghost passing through walls, a walking NPC and
interactive-object highlighting all read clearly? (Demo Specification §4.1; roadmap stage 1.)

## Result: YES

Verdict given by the user after the second run (2026-11-12). Observed in
`evidence/01`–`06` (Godot 4.7.2, Forward+, GTX 1650, 1280×720):

- A back wall and two slanted side walls with no front wall, plus a plank floor narrowing
  toward the back, read as one tilted room. Both doorways read as doors.
- Depth sorting by each object's floor point (`Node2D.y_sort_enabled`) puts the NPC
  correctly behind the table and in front of the stove.
- A wall the ghost is inside fades to 45 %, so the ghost stays visible inside walls.
- The nearest interactable gets a bright pulsing outline and a Ukrainian prompt.
  Interactables merely nearby get a softer outline. Decor gets none.
- Snuffing the lamp (CanvasModulate + PointLight2D) darkens the whole room, and it stays readable.
- Sight zones drawn on the floor and clipped to it read clearly.
- Cyrillic renders correctly with Godot's default font.

Fixed during the spike (first run → second run):
- The sight cones crossed the walls; they are now clipped to the floor polygon.
- The log panel covered the room; it is now a three-line box in the top-right corner.
- Targeting needed the ghost over an object's body. It now also counts the ghost being
  near the object's base on the floor. The "nearby" outline was too faint (alpha 0.35 → 0.6).

## Not assessed

- **How WASD movement, pause and ×1/×2/×4 feel.** The capture moves the ghost
  directly, and no hands-on report was given.
- **Several NPCs in one room, and navigation.** The NPC walks hand-placed waypoints.
  Pathfinding for six NPCs is untested.
- **Moving between rooms.** Only one room exists. Doors are drawn, not used.
- **Real art.** All of it is code-drawn placeholder shapes.

## Known issue carried forward

- An object's prompt can overlap an NPC's name label (`evidence/05`). This needs a
  label-placement rule before rooms get crowded.

## Spike choices not in the docs (to confirm or overrule)

- Pause freezes the ghost too, not only the simulation (the demo spec leaves pause open).
- Time speed scales the clock and NPCs, not the ghost's float speed.
- The ghost can relight the lamp, as a test convenience. The agreed rule is that
  restoration needs an NPC activity (demo spec §4.3).

## What to do next

Carry the room presentation forward. Production code is rewritten from scratch, never
taken from this folder. Next on the Demo Specification roadmap is **stage 2, the
simulation prototype**: the game clock, one schedule, one or two activities, and discrete
room/object states. It needs P0 decisions first, at least one full day's schedule for one
NPC and the room/object list.

# Workshop

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/workshop/`) |
| Painted props | OPEN — none yet (§6) |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `workshop` · in-game name «Майстерня» · ground floor · has a window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

The father's workshop off the living room: a sturdy workbench, a rack of tools on the back wall, a crate of odds and ends, a window. He works here every morning. It is the rough, practical room of the house — and the old crate hides a small key.

**Who uses it** (schedules): the father at 08:00 (tools); he fetches tools here for repairs.

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| window | (0.35, back wall) | `window_workshop` (closed / open) — the ghost can change it (→ open) | — |
| tool_rack | (0.75, back wall) | blocks sight | ~88 px |
| workbench | (0.45, 0.3) | hiding spot `hide_workshop_workbench` (small grid) | ~135 px |
| crate | (0.82, 0.62) | hiding spot `hide_workshop_crate_3` (small grid; unique find: key_small) | ~71 px |
| floor_lamp | (0.12, 0.8) | `lamp_workshop` (lit / out) — the ghost can change it (→ out) | ~39 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- right wall (v ≈ 0.5) → Вітальня (`living_room`)

The tool rack blocks sight along the back wall. The workbench and the crate are small hiding spots.

## 3. Light and the two states

**Warm anchor:** the lamp (front left) — a bare work light; by day the window.

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: hard warm light on the bench | Out: grey daylight or darkness |
| Window | Closed | Open: draught, frost (code) |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** rough whitewashed planks, a pegboard of tool outlines, a calendar
- **Floor:** bare boards covered in sawdust and shavings, oil stains
- **Details:** a vice, clamps, tins of nails, a hanging saw, a lantern (unlit)
- **Mood:** practical, cluttered, smelling of oil and wood

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of an old house's home workshop: a heavy wooden workbench with a vice, planks and shavings, a back-wall rack of hanging hand tools (saws, hammers, chisels), a wooden crate of odds and ends, rough whitewashed plank walls, a bare-board floor with sawdust, a small window with grey daylight, a simple metal work lamp. Hand-inked dark-brown outlines, painted textures, warm work light against cool shadows. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| window | Wall piece. Two images: `closed`, `open` (sash swung in, curtains drawn aside). Frost, draught and curtain sway are code. | ~150 px | a small four-pane window with no curtains, a cracked pane |
| tool_rack | Back-wall piece; one image (tools hanging on pegs). Blocks sight. | ~120 px | a back-wall rack of hanging hand tools: saws, hammers, chisels, a coil of rope |
| workbench | One image (vice, planks, shavings). | ~90 px | a heavy wooden workbench with a vice, a plank, wood shavings and a tin of nails |
| crate | One image (lid on). | ~55 px | a battered wooden crate with a lid and stencilled letters |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared floor lamp, or a workshop variant (a metal work lamp) |

## 7. Shared kinds and open points

- **Shared kinds:** `floor_lamp`, `window` also appear in other rooms. A painted image is looked up by kind (or `kind:variant`), not by room (`PropVisuals`), so one painting would show in every room. A look of its own for this room needs a room-scoped key or a `variant` — decision OPEN (`ENVIRONMENT_GUIDELINES.md` §8).
- A workshop lamp different from the house's brass lamps needs a variant (shared `floor_lamp` kind).

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] The father at the bench reads against the clutter.
- [ ] The crate and the workbench read as hiding places.

# Library

| | Status |
|---|---|
| Room brief (this file) | **PROVISIONAL** — drafted 2026-11-15 (art Phase 4), awaiting review |
| Concept image | OPEN — none yet (to be generated from §5 and kept in `art/concepts/environments/library/`) |
| Painted props | **Built 2026-11-20, awaiting user review** — three different bookshelves (maps, `books`, `curios` — variants added to `furniture.json`), leather reading chair; standard floor lamp; real-world scale (`../SPRITE_SPEC.md` §2), evidence `production/qa/evidence/art-phase4-props/` |
| In game | Placeholder look (not in `visual_style.json` → `storybook_rooms`) |

Room id `library` · in-game name «Бібліотека» · ground floor · no window.
Main documents: `../ART_DIRECTION.md`, `ENVIRONMENT_GUIDELINES.md` (rules every room follows),
`../SPRITE_SPEC.md` (image format and sizes), `LIVING_ROOM.md` (the finished example).

## 1. What the room is

A small, quiet book room off the hall: three tall bookshelves along the back wall, a wingback reading chair on a rug, a reading lamp. Grandpa reads here three times a day and the son reads comics. It hides the house map in its right-hand bookshelf.

**Who uses it** (schedules): grandpa at 08:00, 14:00 and 18:00 (reading); the son at 13:00 and 20:00 (comics).

## 2. Gameplay layout (from the data — art never changes it)

Positions are floor coordinates (u left→right, v back→front). Source: `assets/data/house/furniture.json`;
walking footprints `movement.json`; finds `assets/data/ghost/loot.json`. Width on screen is the footprint
width at the piece's depth — a painting should match it (SPRITE_SPEC §2).

| Piece (kind) | Position | Gameplay role | Width on screen |
|---|---|---|---|
| bookshelf | (0.22, back wall) | blocks sight | ~88 px |
| bookshelf | (0.5, back wall) | blocks sight | ~88 px |
| bookshelf | (0.78, back wall) | hiding spot `hide_library_bookshelf` (small grid; unique find: house_map); blocks sight | ~88 px |
| reading_chair | (0.4, 0.55) | hiding spot `hide_library_reading_chair_3` (small grid; unique find: lore_diary_2) | ~95 px |
| rug | (0.5, 0.65) | furniture | — |
| floor_lamp | (0.62, 0.5) | `lamp_library` (lit / out) — the ghost can change it (→ out) | ~34 px |

**Doors** (drawn by the code; painted walls must leave them clear):

- open front edge (u 0.5) → Хол (`hall`)

No window — the reading lamp is the only light, so this room is the darkest when it goes out. The three bookshelves block sight; the right one and the reading chair are hiding spots.

## 3. Light and the two states

**Warm anchor:** the reading lamp (`lamp_library`, mid-floor beside the chair).

| | Cozy | Haunted |
|---|---|---|
| Lamp | Lit: a warm pool on the chair and rug | Out: near darkness, books barely visible |
| Cold | — | No window: cold only from the house |

Room wear (every room, `ENVIRONMENT_GUIDELINES.md` §4): dust, stains and cobwebs when dirty, a sheen when
clean, breath and cold corners when cold — drawn by the code over the painting, never painted in.

## 4. Look

- **Walls:** almost hidden by books; where visible, deep oxblood paper and dark wood
- **Floor:** dark parquet in a herringbone, a round or oval rug
- **Details:** a globe, a ladder against a shelf, a bust, rolled maps on the right shelf (a quiet hint at the house map), a magnifying glass
- **Mood:** hushed, scholarly, a little dusty — cobwebs suit it

Palette: `../COLOR_PALETTE.md` (PROVISIONAL). No ghost cyan in the room.

## 5. Concept image brief (to generate)

Like `living_room_cozy.jpeg`: a reference for look and materials, not for camera or layout. The game keeps
its room box (`ENVIRONMENT_GUIDELINES.md` §2).

> Whimsical gothic storybook illustration of a small private library in an old house: three tall dark-wood bookshelves crammed with books along the back wall, a ladder, a globe, rolled maps on one shelf, a worn leather wingback reading chair on a round faded rug, a brass reading lamp with a green shade throwing a warm pool of light, dark herringbone parquet, oxblood walls. Hand-inked dark-brown outlines, painted textures, warm lamplight against deep shadow. No people.

## 6. Props to paint

Every brief starts with the shared preamble (`ENVIRONMENT_GUIDELINES.md` §8). On-screen height is a guide at
the back wall (depth 1); paint at 2× (SPRITE_SPEC §2). Cut out with `tools/sprite_cutout.gd`.

| Kind | Images | Height guide | Subject (after the preamble) |
|---|---|---|---|
| bookshelf | One image; a room can have its own (`<room>/bookshelf`, see §7). | ~180 px | a tall dark-wood bookshelf crammed with books, a few ornaments; library's own (`library/bookshelf`): one shelf with rolled maps |
| reading_chair | One image (wingback reading chair). | ~115 px | a worn brown leather wingback reading chair with a cushion |
| rug | Flat piece laid in the floor's perspective — keep code-drawn (perspective rug) or paint already projected (like the shell surfaces, LIVING_ROOM §8). | — | a round rug, faded blue with a gold border |
| floor_lamp | One image, shade unlit and neutral; the lit glow is code (`effects`), so lit and out share it. | ~170 px | shared brass floor lamp (here as the reading lamp) |

## 7. Shared kinds and open points

- **Shared kinds:** `bookshelf`, `floor_lamp`, `rug` also appear in other rooms. Give this room its own painting with a room-scoped key in `visual_style.json` → `sprites`: `"library/<kind>"` (APPROVED 2026-11-15, `ENVIRONMENT_GUIDELINES.md` §8); without one, the house-wide `"<kind>"` image (if any) is used.
- The living room's bookshelf and the library's are the same kind: the library's own painting goes under `library/bookshelf`.

## 8. Review (when built)

The checklist in `ENVIRONMENT_GUIDELINES.md` §7, plus:

- [ ] With the lamp out, people and the ghost stay readable (the room is the darkest).
- [ ] The bookshelf hiding spot is distinguishable from the two that are not.
- [ ] Grandpa in the reading chair reads against the leather.

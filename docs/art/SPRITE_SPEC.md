# Sprite Specification — painted prop images

Status: **PROVISIONAL** (Phase 0, 2026-11-15). To be confirmed by the Phase 3 trial with one real
painted prop; values marked *verify* must be checked in Godot 4.7 before they become APPROVED.
How-to steps: `assets/art/props/sprite_guide.md`. Rules: `ART_DIRECTION.md`, `VISUAL_STYLE_GUIDE.md`.

## 1. What the mechanism does (as built — APPROVED)

- `PropVisuals` (`src/game/art/prop_visuals.gd`) reads `assets/art/visual_style.json` →
  `sprites`. A key is a furniture `kind` (`"fireplace"`) or `kind:variant` (`"armchair:olive"`),
  optionally scoped to one room (`"kitchen/window"`, `"library/bookshelf"`; 2026-11-15). The most
  specific key wins: `room/kind:variant`, `room/kind`, `kind:variant`, `kind`.
- Per entry: `sprite` (default image), `states` (one image per visual state), `anchor` (the point
  of the image, 0..1 of its size, that sits on the piece's floor position; default bottom centre
  `[0.5, 1.0]`), `scale` (image scale at depth 1.0).
- Drawn size on screen = image pixels × `scale` × depth, where depth runs 0.78 at the back wall to
  1.12 at the front edge (`RoomGeometry`). Wall pieces (window, fireplace, paintings, clock) use
  depth 1.0 at the back wall's base.
- `effects` (art Phase 3, 2026-11-15): the code-drawn animation of the piece — fire and its glow,
  smoke, embers, a lamp's glow — still runs on top of the image, at `offset` [x, y] (screen px at
  depth 1, from the anchor point) with `scale`. So state changes that animate stay in code and
  the image shows only what never changes.
- `effects.states` (flame layer, 2026-11-15): per visual state, a painted layer drawn at the effects
  point *instead of* the code shapes (the code glow stays): `sprite`, `anchor`, `scale`, `flicker`
  (strength of a stretch and sway about the anchor). Used for the fireplace's burning logs and flames.
  Paint such a layer isolated, hard-edged, no glow (the game adds it).
- `glass` (2026-11-20): per state, a mask image the size of a painted window's image, opaque
  where its panes are. The code fills it with the sky behind the painting — day glass, night
  sky, or, when open, the darker outside with a cold sheen — so the panes follow the time of day.
  Masks are made from the cut-out window's enclosed see-through pockets (at least 6 px; the
  closed state's pane area limits the open one's), saved as `<image>_glass.png`.
- `effects.points` (2026-11-20): named points where the code draws a painted prop's moving
  parts on top: the working stove's flickering glow and the broken one's smoke (`fire`), the
  working computer's screen glow (`screen`); a clock could take `dial` and `pendulum`. Screen px
  at depth 1 from the floor point; a test checks each point lies on the image.
- Lamps (2026-11-20, user review): **two images**, `lit` (the shade glowing) and `out`; the
  code's glow is added on top only while lit, at the shade (`effects.offset` with
  `effects.scale` sized to the lamp, so the glow shrinks with a smaller lamp).
- A missing file falls back to the code drawing with a warning. The ghost's target highlight is
  added by the code around the image.
- **Gameplay never reads the image**: position, footprint, sight blocking, hiding spot and
  interaction range stay in data. A bigger image does not make a bigger obstacle.
- Only props have this path. **Walls, floor and doors cannot use images yet** (OPEN, Phase 3).

## 2. Authoring size

The game renders at 1280 × 720.

**Perspective (user review 2026-11-20).** Scale 1 is 75 px per metre; the room camera draws a
prop at FOCAL / z / 75 of that at its depth z (`RoomGeometry.scale_at`), wall pieces at the back
wall's — so sizes in metres are all a prop needs. A piece may be mirrored (`"flip": true` in
furniture.json: a chair turned the other way). Tools (`tools/art/`): `props.py` (the size table,
cut-out and merge), `kichat.py` (image generation; token per run, never stored),
`glass_masks.gd`, `defringe.gd` (removes a light halo from a cut-out), `texture_prep.gd`,
`montage.gd`, `crop.gd`.

**Real-world scale — PROVISIONAL (user review 2026-11-20).** Every painted prop is sized from its
real width × height in metres at the family's own scale: people are drawn about 120–140 px tall at
depth 1, so **75 px per metre**; the back wall (170 px) is about 2.3 m. Art is painted at 2×
(150 px per metre) with `"scale": 0.5`, and fitted into its real box (e.g. a sofa 2.0 × 0.95 m, a
double bed 1.7 × 1.2 m, a wardrobe 1.1 × 2.1 m, a floor lamp 0.5 × 1.6 m). Wall pieces also sit at
their real height: a window on its sill (≈0.7–1.0 m; floor-length curtains from the floor), a
clock or painting at eye level. The table of every prop's size is in the cut-out script's
record (`art/prompts/props/README.md` → Sizes). This replaced fitting the image to the walking
footprint (below), which made windows huge beside small furniture.

*Superseded (kept for history):*

- Paint at **2× the on-screen size at depth 1.0** and set `"scale": 0.5`. This keeps images sharp
  if the window is scaled up and leaves room to re-time scale. (*verify* the look of downscaled
  images, see §6.)
- Current on-screen sizes of the code-drawn living-room pieces (approximate, measured from the
  art-test capture `01-cozy-evening-family.png`, at their own depth), so a painting can match
  them:

| Piece | On screen (w × h px) | Paint at (2×) |
|---|---|---|
| Fireplace (wall) | ~228 × 183 (breast 170 high + hearth) | ~456 × 366 (the painted trial is ~205 × 194: breast 171 wide, see LIVING_ROOM §8) |
| Window with curtains (wall) | ~170 × 150 | ~340 × 300 |
| Sofa | ~235 × 100 | ~470 × 200 (at its depth, scale ≈ 0.9) |
| Armchair (wingback) | ~100 × 115 | ~200 × 230 |
| Floor lamp | ~70 × 170 | ~140 × 340 |
| Bookshelf | ~100 × 180 | ~200 × 360 |
| Side / tea table | ~55 × 55 | ~110 × 110 |

  For floor pieces, divide by the piece's depth (`0.78 + 0.34 × v`) to get the depth-1.0 size.
- ~~Keep the visual width close to the walking footprint~~ — at real-world scale most furniture
  is **narrower than its footprint** (the sofa ~130 px on screen against ~240 px of blocked
  floor). Whether the footprints shrink to match is **OPEN**, a gameplay decision
  (`environments/ENVIRONMENT_GUIDELINES.md` §9); the data is unchanged until it is made.

## 3. Image format

| Item | Rule |
|---|---|
| Format | PNG, RGBA, 8-bit, sRGB. Lossless WebP allowed. No JPEG for props. |
| Background | Transparent; straight (not premultiplied) alpha. A painting delivered on a plain white background (generated images) is cut out with `tools/sprite_cutout.gd` (flood fill from the border, edge un-blend, crop, scale, padding); keep the source in `art/concepts/props/<room>/`. Options (2026-11-20): `[box]` — one crop box for all of a prop's state images, so they line up and the prop does not jump when its state changes; `[islands] 0` with `[bg_min] 0.9` — for **white objects** (tablecloth, bathtub, sink), whose light areas would otherwise be cleared as background. Ask the generator for a white background, not transparency: models fake transparency with a painted checkerboard. Painted drop shadows do not cut out — have them removed with an edit of the image. |
| Padding | 4 px of transparent margin at 2× on every side (filter bleed). |
| View | Front view as the piece stands in the room box, slightly from above (matching the box's floor slope); no free perspective. |
| Floor contact | The `anchor` point is where the piece meets the floor: bottom centre for floor props; the base line for wall props. |
| Lighting | Paint neutral, even light. The game adds warm and haunted light, pools and the grade. No strong baked highlights, cast light or coloured rim light. Contact shadow minimal (*verify* against the code-drawn shadows in Phase 3). |
| Contours | Painted in, by tier (`VISUAL_STYLE_GUIDE.md` §2), at 2× width: interactive 4.8 px, furniture 3.4 px, background 2.2 px; dark muted brown, never black. |
| Palette | `COLOR_PALETTE.md`. No ghost cyan in props. |
| Highlights | Do not paint selection outlines; the game draws them. |
| Animated or state effects | Do not paint what the code animates: flames that flicker, smoke, glow around the object. A state image may show the state on the object itself (a lamp's shade glowing, a stove's fire behind its door); the code adds the moving glow on top (`effects`). |
| Height | A wall piece must fit the back wall (170 px on screen from its base); a test checks it. |

## 4. Naming and location

- Folder: `assets/art/props/` (inside the Godot project; `art/` at the root is reference only and
  is not imported); a room's own paintings in `assets/art/props/<room>/`, lamp designs shared by
  several rooms in `assets/art/props/lamps/`, window glass masks beside their image
  (`window_closed_glass.png`).
- File: `<kind>[_<variant>]_<state>.png`, lower case, underscores: `fireplace_burning.png`,
  `fireplace_out.png`, `armchair_olive.png`, `lamp_lit.png` → the `kind` is the one in
  `furniture.json` (`floor_lamp`, so `floor_lamp_lit.png`).
- One image per state the piece shows; a piece with no states has one image without a suffix.

## 5. States to paint (from the game data)

| Kind (furniture.json) | States | Note |
|---|---|---|
| `floor_lamp` (and other lamps) | `lit`, `out` | interactive; two images (2026-11-20) — five designs: brass (house-wide), standard, tulip, rose, stars, plus the workshop's work lamp |
| `window` | `closed`, `open` | interactive; open shows a swung sash and billowing curtains |
| `fireplace` | `burning`, `out` | decor; state follows room cold |
| `stove` | `working`, `broken` | interactive (kitchen) |
| `computer` | `working`, `broken` | interactive (children's bedroom) |
| `grocery_basket` | `available`, `hidden` | interactive (kitchen) |
| `armchair` (grandma's) | `free`, `occupied` | hiding spot; occupied may equal free if a person is drawn over it |
| Others (sofa, tables, bookshelf, paintings, clock, beds…) | one image | — |

## 6. Open points for the Phase 3 trial (*verify*)

- Texture filtering and mipmaps for images drawn at 0.39–0.56 of their size (2× art at
  scale 0.5 × depth): check for shimmer or blur; decide import settings and whether a project
  setting change is needed (that change needs approval).
- Downscaling (*verify*): checked across all rooms in the 2026-11-20 captures (art at 0.1–0.6 of
  its size): no shimmer or blur seen with Godot's default import.
- Animated parts: **resolved in the fireplace trial** — code overlays on top of the image
  (`effects`, §1). Frame sequences not needed so far. Curtain sway (window) not yet tried.
- Walls, floor and doors: feasibility written up in `environments/LIVING_ROOM.md` §8
  (recommended: per-surface images painted in the box's projection; not built).
- Character sprites (frames per pose and walk cycle) — character phase.

# Sprite Specification — painted prop images

Status: **PROVISIONAL** (Phase 0, 2026-11-15). To be confirmed by the Phase 3 trial with one real
painted prop; values marked *verify* must be checked in Godot 4.7 before they become APPROVED.
How-to steps: `assets/art/props/sprite_guide.md`. Rules: `ART_DIRECTION.md`, `VISUAL_STYLE_GUIDE.md`.

## 1. What the mechanism does (as built — APPROVED)

- `PropVisuals` (`src/game/art/prop_visuals.gd`) reads `assets/art/visual_style.json` →
  `sprites`. A key is a furniture `kind` (`"fireplace"`) or `kind:variant` (`"armchair:olive"`).
- Per entry: `sprite` (default image), `states` (one image per visual state), `anchor` (the point
  of the image, 0..1 of its size, that sits on the piece's floor position; default bottom centre
  `[0.5, 1.0]`), `scale` (image scale at depth 1.0).
- Drawn size on screen = image pixels × `scale` × depth, where depth runs 0.78 at the back wall to
  1.12 at the front edge (`RoomGeometry`). Wall pieces (window, fireplace, paintings, clock) use
  depth 1.0 at the back wall's base.
- A missing file falls back to the code drawing with a warning. The ghost's target highlight is
  added by the code around the image.
- **Gameplay never reads the image**: position, footprint, sight blocking, hiding spot and
  interaction range stay in data. A bigger image does not make a bigger obstacle.
- Only props have this path. **Walls, floor and doors cannot use images yet** (OPEN, Phase 3).

## 2. Authoring size

The game renders at 1280 × 720.

- Paint at **2× the on-screen size at depth 1.0** and set `"scale": 0.5`. This keeps images sharp
  if the window is scaled up and leaves room to re-time scale. (*verify* the look of downscaled
  images, see §6.)
- Current on-screen sizes of the code-drawn living-room pieces (approximate, measured from the
  art-test capture `01-cozy-evening-family.png`, at their own depth), so a painting can match
  them:

| Piece | On screen (w × h px) | Paint at (2×) |
|---|---|---|
| Fireplace (wall) | ~190 × 150 | ~380 × 300 |
| Window with curtains (wall) | ~170 × 150 | ~340 × 300 |
| Sofa | ~235 × 100 | ~470 × 200 (at its depth, scale ≈ 0.9) |
| Armchair (wingback) | ~100 × 115 | ~200 × 230 |
| Floor lamp | ~70 × 170 | ~140 × 340 |
| Bookshelf | ~100 × 180 | ~200 × 360 |
| Side / tea table | ~55 × 55 | ~110 × 110 |

  For floor pieces, divide by the piece's depth (`0.78 + 0.34 × v`) to get the depth-1.0 size.
- Keep the visual width close to the walking footprint (`movement.json` → `footprints`) so what
  the player sees matches where people can walk. A painting much wider than its footprint
  misleads the player; if it is needed, the footprint change is a gameplay decision, not art.

## 3. Image format

| Item | Rule |
|---|---|
| Format | PNG, RGBA, 8-bit, sRGB. Lossless WebP allowed. No JPEG for props. |
| Background | Transparent; straight (not premultiplied) alpha. |
| Padding | 4 px of transparent margin at 2× on every side (filter bleed). |
| View | Front view as the piece stands in the room box, slightly from above (matching the box's floor slope); no free perspective. |
| Floor contact | The `anchor` point is where the piece meets the floor: bottom centre for floor props; the base line for wall props. |
| Lighting | Paint neutral, even light. The game adds warm and haunted light, pools and the grade. No strong baked highlights, cast light or coloured rim light. Contact shadow minimal (*verify* against the code-drawn shadows in Phase 3). |
| Contours | Painted in, by tier (`VISUAL_STYLE_GUIDE.md` §2), at 2× width: interactive 4.8 px, furniture 3.4 px, background 2.2 px; dark muted brown, never black. |
| Palette | `COLOR_PALETTE.md`. No ghost cyan in props. |
| Highlights | Do not paint selection outlines; the game draws them. |

## 4. Naming and location

- Folder: `assets/art/props/` (inside the Godot project; `art/` at the root is reference only and
  is not imported).
- File: `<kind>[_<variant>]_<state>.png`, lower case, underscores: `fireplace_burning.png`,
  `fireplace_out.png`, `armchair_olive.png`, `lamp_lit.png` → the `kind` is the one in
  `furniture.json` (`floor_lamp`, so `floor_lamp_lit.png`).
- One image per state the piece shows; a piece with no states has one image without a suffix.

## 5. States to paint (from the game data)

| Kind (furniture.json) | States | Note |
|---|---|---|
| `floor_lamp` (and other lamps) | `lit`, `out` | interactive |
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
- Animated parts (fire flicker, smoke, curtain sway) are drawn in code today; a painted image
  replaces the whole code drawing, so animation would be lost. Decide: code overlays on top of
  images, or frame sequences.
- Whether walls, floor and doors get an image path (`StorybookShell`), and its spec.
- Character sprites (frames per pose and walk cycle) — character phase.

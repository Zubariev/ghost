# Ghost — the player character

Status: **design APPROVED (2026-11-20, `b_float_boots.png`); front / side / back references
APPROVED as the production basis (user, 2026-11-21). Production rig, animation and game
integration built 2026-11-21 (§7–§8) — awaiting the user's in-game review.** Main documents:
`../ART_DIRECTION.md` §6, `CHARACTER_PIPELINE.md`.

**Decisions (user, 2026-11-21):** the house and his clothes are c. 1895–1910 (a working art
direction, not a verified date); the canonical waistcoat colour is kept — colour and opacity are
adjustable settings, not repaints; he ALWAYS floats (legs hanging loose, knees soft, boots limp,
heels up, toes down, feet uneven) — in the rest pose and every clip.

## 1. Identity

| Field | Value |
|---|---|
| Id | `ghost` |
| Who | A former resident of the house from the time it was built — a modest household man, not an aristocrat, not a monster |
| Period | c. 1895–1910 (**assumption**: the house's era is not recorded in the GDD or Demo Spec; the research report points to late-Victorian / Edwardian country houses). OPEN until the user confirms |
| Age (as he died) | about 45 |
| Personality | Curious, clever, mischievous, slightly eccentric, sometimes melancholic; gentle-looking but able to make the house very uncomfortable |
| Face | Long gentle face, narrow slightly tired eyes, a faint wistful look; distinctive curved moustache |
| Hair | Medium-length, slightly wavy, side-parted, muted brown-grey, a little messy |
| Clothing | Off-white shirt with a high collar and long sleeves; small dark cravat, loosely knotted; brown-grey (taupe) waistcoat with a row of buttons and a thin watch chain; dark-grey trousers; old worn lace-up boots |
| Ghost look | Human-shaped, whole body including legs and boots; white with a very pale icy-blue tint; semi-transparent; a restrained soft blue-white edge glow; always floating: legs hang loose, knees slightly soft, boots limp with heels up and toes pointing down, never standing on the floor |
| Never changes | The moustache shape, the hair silhouette, the high collar + dark cravat, the taupe waistcoat with buttons, full legs with boots (no vanishing legs, no mist tail), head-to-body ratio, shoulder width, the tired-gentle face |
| Never add | Hat, cane, chains, sheet / veil / shroud, jewellery, weapons, coat |

The living version (`human_b.png`) is kept for future use (portraits, lore photos, flashbacks).

## 2. Images (`art/concepts/characters/ghost/`)

| File | Use | Status |
|---|---|---|
| `b_float_boots.png` | **Approved design** — the original reference | APPROVED |
| `ghost_front_reference.png` | **Canonical front view**; the identity source for every later edit | EXPERIMENTAL (awaiting approval) |
| `ghost_side_reference.png` | Side view, profile facing right (left = mirrored) | EXPERIMENTAL |
| `ghost_back_reference.png` | Back view | EXPERIMENTAL |
| `ghost_expression_sheet.png` | 8 expressions: neutral, curious, mischievous, surprise / frightened, anxious, annoyed, sad (row by row) | EXPERIMENTAL |
| `ghost_face_crop.png` | Enlarged head crop of the front view, used as the source for the expression sheet | tool input |
| `human_b.png` | Living version of the same man | kept for later |
| `canonical_*3.png`, `sheet_*`, `readable_*`, `transparency_*`, `compare_*.png`, `scale_test_game_size.png`, `human_[acd].png` | Phase 1 candidate exploration (A–D) | history |
| `b_legs_*`, `b_float_stockings.png`, `canonical_candidate.png` | Phase 1 leg / fix-up iterations | superseded |
| `rejected/` | Failed takes (sheet ghosts, identity drift) | REJECTED — do not reuse |

Evidence montages: `production/qa/evidence/character-ghost/`.

## 3. How the references were made

`tools/art/kichat.py` (one attached reference per edit — the API has no second reference slot, so
side, back and expressions were each edited from the front view only).

- **Text-only generation of "a ghost" fails**: the model adds sheets, veils and shrouds, and negating
  them ("no sheet") makes it worse. Working method: paint the man as a solid living person first,
  then edit him into a spirit.
- **Front**: a long "create a canonical front view" prompt redesigned him (curlier hair, camouflage
  waistcoat). A minimal edit of `b_float_boots.png` ("keep everything, change only the legs") kept
  the identity. Prompt used:

  > Keep this exact image almost unchanged: the same man, the same face and expression, the same hair,
  > moustache, shirt, cravat, waistcoat with its buttons and watch chain, trousers, boots, the same
  > colours, the same pale translucency and the same soft blue-white edge glow, the same size and
  > position on the canvas, the same painting style. Change only his legs: both legs hang straight
  > down side by side, symmetric, in a balanced neutral front pose … floating with empty space below.

- **Side / back**: "Turn this exact man to show him in a true 90-degree SIDE VIEW … / from BEHIND …"
  + keep block (face, moustache, hair, collar, cravat, waistcoat, trousers, boots, translucency,
  glow, proportions). Two takes each; chosen by head comparison (`heads_compare_takes.png`).
- **Expressions**: from the enlarged face crop, "eight separate head-and-shoulders portraits … the
  moustache must stay on every face". One panel lost the moustache and was fixed with a single-panel
  edit.

**Removing the painted glow by an edit turns him back into a living man** (warm skin, opaque
clothes): the model uses the glow as its cue for "ghost". This is one more reason for the glow to be
a separate engine layer (§5).

## 4. Known deviations in the references

- Line quality is cleaner and more digital than Grandma's gouache; paper grain is weak. Judge in a
  game screenshot before repainting.
- Side view: the face reads slightly younger and less tired than the front.
- Back view: the hair mass is a little fuller than the front.
- Expression sheet: the hair is curlier and fuller than the front view; the annoyed panel's
  moustache is a curlier handlebar than the others; style is the most cartoon-like of the set.
- Floating (user correction, 2026-11-21: the first front/side/back looked like standing on the
  floor): each view was re-edited from its own standing version ("change only his legs and feet so
  that he is clearly FLOATING … the boots hang limp with the heels raised and the toes pointing
  down, one foot a little lower"). Heads checked unchanged. Standing versions:
  `rejected/standing_*_reference.png`. The expression sheet (heads only) is unaffected.
- The painted glow is cyan-leaning (close to ghost cyan `#A8D5D9`) and thick at full size.

## 5. Production considerations (written before Phase 3; how each was done: §7)

Current code (2026-11-20): the ghost is a code-drawn round sheet (`FamilyArt.draw_ghost`), drawn in
`RoomStage`'s single depth-sorted pass by its floor point; when off the floor (inside a wall) it is
drawn last. A hidden ghost is not drawn at all — only a faint pair of glinting eyes
(`_draw_hidden_glint`). The room grade (`post_art_room_grade.gdshader`) spares bright cyan pixels so
the ghost keeps its colour.

1. **Body and glow as separate layers.** The sprite parts carry the body only (no painted halo); the
   glow is drawn by the engine as its own layer (user decision, 2026-11-20: "glow in Godot"). The
   references keep their painted glow only as identity guides. A glow-free sprite needs an extra
   edit step that keeps him pale (see §3: naive glow removal fails).
2. **Translucency.** One opaque painted sprite drawn with a modulate alpha (≈ 0.75–0.85, tuning
   knob) rather than a painted see-through image, so the same art works on dark wood, warm walls and
   light plaster. The face and the dark cravat keep the read on light walls; the edge glow keeps it
   on dark ones. Phase 1 transparency tests: pale ghosts nearly vanish on light cream walls.
3. **Depth sorting.** Body and glow are drawn inside the ghost's own entry in the sorted list, so a
   sofa in front covers both. The glow must not be a screen-space post effect over the whole frame,
   or it would show through furniture.
4. **Behind furniture.** Occlusion stays exactly as now (floor point sort). Rendering never changes
   what the family can see: sight, detection and hiding stay in `StealthSystem` and the data.
5. **Hiding.** Keep the current rule: hidden = body and glow not drawn, eyes-only glint.
6. **Dark rooms.** The glow's strength may rise as room light falls, purely visual; the body alpha
   stays fixed so readability does not depend on the room.
7. **Colour grade.** The grade spares only bright cyan; the waistcoat (taupe) and cravat (dark)
   would be warmed and darkened by it. Either draw the ghost after the grade or extend the grade's
   ghost mask — a decision for the implementation step.
8. **Sprite export.** Same as `SPRITE_SPEC.md`: straight alpha PNG, cut from a plain background. The
   pale figure is near the grey background in value — cut with `tools/sprite_cutout.gd` on the grey
   (not white) background, or regenerate parts on a darker flat background; check edges with
   `defringe.gd`.
9. **Lower body while moving.** Full legs (approved). While floating, the legs trail slightly behind
   the motion and the feet dangle (no walk cycle, no foot contact); bob as now. No fade on the legs
   unless the user asks for it later.
10. **Floor shadow.** The code ghost has a small floor shadow when over the floor; the painted ghost
    keeps that code shadow (not painted).

## 6. Next steps (written before Phase 3)

Rig poses (front, side), bases and parts per `CHARACTER_PIPELINE.md` §4 — a ghost rig likely needs
fewer leg moves (dangling, trailing) and more arm/face acting; glow-free part edits; then the
engine glow and alpha. Before that: update `ART_DIRECTION.md` §6 (ghost silhouette OPEN → the human
ghost; glow colour vs. "ghost cyan") — with the user's approval.

## 7. Production rig (Phase 3, 2026-11-21)

**Sources** (`art/concepts/characters/ghost/prod/`, not imported):

| File | Made by | Use |
|---|---|---|
| `noglow_<view>_x/y.png` → `ref_front/side/back.png` | Edit of each approved reference: "remove the light-blue glowing halo … leaving a clean, continuous, dark contour" | Glow-free bases (the game draws the glow). The edit made the contour thicker and darker |
| `rig_front_x.png`, `rig_back_y.png` | Edit: arms angled ~25° out, clear of the torso | Front / back: every part cut by polygon |
| `base_side_x.png` | Edit: near arm removed (its legs are cut off by the polygon) | Side body and head |
| `part_side_arm_x.png`, `part_side_legs_x.png` | Edit: "keep ONLY …" | Side arm; side legs (one part) |
| `rig_src.json` | Hand-written | Cuts, pivots, foot points, look, clips |

Build: `python3 tools/art/rig_build.py ghost` → `assets/art/characters/ghost/` (16 part PNGs +
`rig.json`). The builder finds the ghost's sources in `art/concepts/characters/ghost/prod/` and
cuts them from the flat grey (`bg_min` 0.6, `white_parts`: the shirt and face are near-white and
must not be cleared as holes — the first build did, see §9).

**Parts.** Front and back: `body` (hips to collar), `head` (child of body), `arm_l`, `arm_r`
(children of body, pivot at the shoulder), `leg_l`, `leg_r` (whole leg, hip to boot, pivot at the
hip, behind the body). Side (facing right; left mirrored): `body`, `head`, `arm` (near), `legs`
(both legs as one piece — the near/far split edits returned the whole figure four times). Knees and
elbows are not split: the legs hang and swing from the hip. Scale: 510 px per metre in the 1024
canvas (923 px from hair to the lowest toe ≈ 1.80 m hanging), built at 0.4.

**Foot point.** Each view's `foot` is the floor point under his lowest toe; `look.hover_m` (0.28 m)
lifts the whole figure above it, so he never touches the floor. A test checks every part's painted
bottom is above the foot point and that no idle bob dips down.

**Rendering** (`GhostVisual`, drawn by `RoomStage`):

- The posed rig is drawn opaque into an offscreen `SubViewport` (480 × 500); a second one holds
  his halo — the silhouette in `glow_color`, spread in rings of `glow_px`. `RoomStage` draws the
  floor shadow, then the halo, then the body texture **inside its depth-sorted pass**, at his floor
  point's depth (`RoomStage.ghost_sort_y`): furniture in front covers him and his halo; inside a
  wall he is drawn over the room, as before.
- Opacity is applied once to the composited figure (`look.opacity` 0.84), so overlapping parts never
  show darker seams. `look.tint` multiplies the painting (canonical colours kept); `glow_alpha`
  grows by `glow_dark_boost` in dim (×0.4) and dark (×1) rooms.
- Hidden: his body fades and shrinks into the spot (`presence`), then only the existing eye glint
  shows; coming out reverses it. Hiding rules are untouched.
- The room grade still applies to him (he is part of the room picture); the tint is the knob if the
  waistcoat reads too warm.

All settings: `rig_src.json` → `look` (copied into `rig.json`).

## 8. Animation (Phase 3, 2026-11-21)

`GhostAnimator` (visual only; never read by gameplay) is fed each frame by `RoomStage` with how far
the navigator actually moved him (m/s), whether he is hidden, and the harm being cast (from
`GhostCasting`, toward its object). `HouseGame` passes stealth's `contact` (caught) and `noticed`
signals as a startle.

| State (first match) | Clip |
|---|---|
| caught (1.6 s) / noticed (0.7 s) | `fright` (front): jolt up, arms flung out, legs kick apart, settle |
| casting a harm | `reach_side` (mirrored for left) / `reach_front` / `reach_back` toward the object: one arm raised, trembling with effort |
| drifting > 0.18 m/s (smoothed) | `glide_side` / `glide_front` / `glide_back` by the drift |
| hovering | `float_<last view>`; after 2.2 s still he turns to face the room (`float_front`) |

**Secondary motion** (added on top of every clip from his real drift): the body leans into
sideways drift (4.5° per m/s, ≤ 9°); legs and arms trail on a softer, slightly under-damped spring
(7° per m/s, ≤ 20°), so starts lag and stops swing on and settle — he never freezes. Moving toward
or away from the camera the legs foreshorten a little (trailing into depth). A jump of more than
0.6 m in one frame (respawn, floor change) is not motion. Clip changes blend over 0.4 s; a change of
view narrows and widens the figure over 0.22 s and keeps the bob's phase.

**Not animated** (the game has no state for it): picking up the monocle or loot (instant), searching
a spot (he is hidden), changing floor (instant), the respawn walk.

**Tests:** `tests/unit/art/ghost_animator_test.gd` (rig completeness, always floating, state table,
lean and trail, settle, turn and blend, hide/emerge, fright, teleport, depth sort, offscreen
compositing). Mutation checks (each caught): over-damped legs, mirror sign ignored, ghost always on
top.

**Captures:** `bash tools/play.sh character-test ghost` → `production/qa/evidence/character-ghost-game/`
(g00–g16: idle front / side / back, gliding, stop and settle, turning, reaching for the lamp,
behind and in front of the sofa, hiding and emerging, fright, far back, dark room).

## 9. Production QA log (2026-11-21)

- Glow removal in code (a flood fill to the ink contour, tool since removed) failed: the
  painted glow broke the contour and the fill ate the face and sleeves. Replaced by the edit above.
- Rig poses: front x and back y chosen (arms clear); front y kept the arms too close.
- Side base: both takes left the legs (cut off by polygon instead); take y left a white blob at the
  shoulder (rejected).
- Side near/far legs: 4 edits all returned the whole figure — the side legs are one part.
- First build cleared the white shirt and face as "holes" (the cutout's island rule) — rebuilt with
  `white_parts`.
- First reach and fright poses spread the arms to a T-pose (painted 25° out + 50°) — softened to
  one raised arm (−36°) and a fling of ±30°.
- First glide trailed the legs ~25° (read as swimming) — reduced to ~17°.
- First side foot point was 50 px above the painted toes (the test caught it).

**Known limitations:** the glow-free edit made the contour thick and near-black (the art direction
asks for dark brown); the side legs move as one piece; the side body has a painted white
sleeve-hole under the arm (covered at rest and in the glide, visible only in `reach_side` as a
shirt side); paper texture is weaker than on the family.

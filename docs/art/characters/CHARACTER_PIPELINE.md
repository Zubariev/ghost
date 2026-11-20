# Family Character Pipeline

Status: **EXPERIMENTAL — pilot (grandma) built 2026-11-20, awaiting user review.** Do not start the
other five family members before the pilot is approved.

Painted family members replace the code-drawn placeholders (`FamilyArt`) one by one. The pipeline
turns a text identity into a canonical painting, a turnaround, an animation-ready set of cutout parts,
keyframed clips and a game rig. It never changes gameplay: the rig only reads the states the game
already has (`FamilyMotion`, the schedule, `StealthSystem`, morale's Broken).

## 1. What exists (audit, 2026-11-20)

- **Drawing.** People are drawn immediately on the room canvas (`RoomStage._draw`), depth-sorted by
  their floor point together with furniture and the ghost. Each person is a callable in one sorted
  list; there are no character scene nodes. Placeholder figures: `FamilyArt.draw_person`
  (pose, walk phase, facing left/right only).
- **State the game provides per person per frame** (`FamilyMotion.person` + the routine):
  floor position (u, v), pose (`stand`, `walk`, `sit`, `sleep`, `broken`, `tricycle`), facing (a
  direction on the floor), marker (`?` while REACTING / INSPECTING / SEARCH_*, `!` in FRIGHT), and
  the schedule activity's animation (`cook`, `rest`, `eat`, `read`, `computer`, `draw`, `dolls`,
  `tools`, `wash`, `wake`, `sleep`, `tricycle`) or a task (repair, clean).
- **Camera.** One pinhole camera looks at the room from the front and above
  (`RoomGeometry`): people walk in every direction on the floor; the screen shows them from the
  front, the back or the side. Facing is a floor direction, so three views (front, side, back;
  left = mirrored side) cover all movement. No diagonal views are needed at this scale.
- **Scale.** 75 px per metre at scale 1; `scale_at(depth)` grows toward the camera.
- **References.** `art/concepts/characters/family_lineup_silhouettes.jpeg` and the moodboards show a
  rural, period-dressed family. **Conflict:** the user brief (2026-11-20) sets the family in the late
  1990s / early 2000s — the brief wins (family designs were OPEN in `ART_DIRECTION.md` §6); the
  period concepts are kept for silhouette and readability ideas only.
- **Image generation.** ki-chat's image API (`tools/art/kichat.py`): text → image, and edit of one
  attached image. One reference image per request; no style-reference slot.

## 2. Rig choice

| Option | Verdict |
|---|---|
| A — minimal cutout (head, torso, upper/lower arms, upper/lower legs) | Close, but upper/lower splits are invisible at game size (the figure is 120–200 px tall) and the skirt or trousers hide thighs. |
| B — detailed cutout (hair layers, hands, feet, cloth parts) | Over-engineered for this camera and scale; puppet-like seams. |
| **C — hybrid (chosen)** | A small cutout rig per view for walking, idles, activities and reactions, plus separately **painted full poses** where a rig would look wrong (sitting; later sleeping, the tricycle). |

**Per view: body, head, two arms (shoulder to hand), two lower legs (with shoes).** The body is the
figure with arms and lower legs removed (an image *edit*, which also paints in what the limbs
covered); the head, arms and legs are cut from the rig pose, or generated as their own image
(edit "keep only the arm") when they overlap the body. Elbows and knees are not split: at this size
a rotation at the shoulder or hip reads correctly, and fewer seams look less like a puppet.

**Godot architecture — immediate-mode cutout, no scene nodes.** `Skeleton2D`/`Bone2D` and
`AnimationPlayer` would need nodes outside the room's single depth-sorted draw, breaking furniture
occlusion. Instead a data rig (`CharacterRig`, `assets/art/characters/<id>/rig.json`) is drawn in
the same sorted pass: each part's transform is its parent's times its own rotation/stretch about
its pivot; clips are keyframes per part, eased. A per-person `CharacterAnimator` (visual only, never
saved) is the state machine. No third-party dependency.

Bone hierarchy (each view):

```
root (whole figure: bob, sway, jolt)
├── leg_l / leg_far     (behind the body)
├── leg_r / leg_near    (behind the body)
└── body (pivot at the hips)
    ├── arm_l / arm     (pivot at the shoulder; in front of the body)
    ├── arm_r
    └── head            (pivot at the neck; in front)
```

## 3. Files

```
art/concepts/characters/family/<id>/      sources (not imported): canonical, turnaround, rig poses,
                                          bases, parts, poses; rig_src.json (cuts, pivots, clips)
assets/art/characters/<id>/                game: <view>_<part>.png and rig.json (built, do not edit)
docs/art/characters/<ID>.md                identity spec, prompts used, asset list and status
```

Tools (`tools/art/`): `kichat.py` (generate / edit), `rig_build.py` (cut parts, write rig.json),
`cut_part.gd` (polygon or connected-piece cut), `grey_to.gd` (fix a colour that drifted in a pose),
`grid.gd` (read pixel positions), `montage.gd` / `crop.gd` (review), `defringe.gd`.

## 4. Steps for one character

1. **Identity.** Fill `IDENTITY_TEMPLATE.md` → `docs/art/characters/<ID>.md`. It is the only text
   source for every later prompt; never-change features are listed.
2. **Canonical.** Prompt 1, two candidates; choose one → `canonical.png`. Everything after edits it
   (or edits an edit of it).
3. **Turnaround.** Prompt 2 with the canonical attached: `turn_side.png` (profile facing right),
   `turn_back.png`. Check head size, hair, clothes and colours against the canonical.
4. **Rig poses.** Prompt 3: `rig_front.png` (arms angled out, feet apart), `rig_side.png` (near arm
   swung a little forward, legs in a small step). Re-run if a limb points or crosses the body.
5. **Bases.** Prompt 4a: edit each rig pose (or the back view) to remove arms and lower legs →
   `base_<view>.png` (armholes painted, skirt hem kept).
6. **Parts.** Cut with polygons where a limb is clear of the body (front and back); where it overlaps
   (side arm, legs), Prompt 4b ("keep ONLY the near arm …") paints the whole limb in place. Edits keep
   the canvas layout — verify with the outline boxes (`sprite_cutout.gd` prints them): every image of
   a view must share the top line and scale.
7. **Pivots and cuts.** Read joints with `grid.gd`; write them in `rig_src.json` (canvas px).
   Shoulder pivot at the top of the sleeve; hip pivots where the leg enters the skirt; neck at the
   chin line. Legs and arms are cut generously into the body: the body (drawn over legs, under arms)
   hides the overlap, so rotations never open gaps.
8. **Hybrid poses.** Prompt 5 for poses a rig cannot do (sitting): a full painted pose as its own
   view with its own `px_per_m` (a seated figure is shorter).
9. **Clips.** Keyframes in `rig_src.json` → `clips`: `[t, rot°, dx, dy, sy]` per part, eased. Walk
   clips last one stride and advance by metres walked (`stride_m`), so feet keep pace.
10. **Build and test.** `python3 tools/art/rig_build.py <id>`; the rig loads automatically
    (`CharacterRig.load_for`). Tests: `tests/unit/art/character_rig_test.gd`. Captures:
    `bash tools/play.sh character-test`.

## 5. Prompt templates

All prompts end with the **style block**:

> Whimsical gothic storybook illustration: hand-painted 2D, organic dark-brown ink contours of varying
> thickness (never black), gouache and watercolour textures with subtle paper grain, muted autumn
> colours, slightly exaggerated but believable proportions (head about one fifth of the height),
> expressive face, natural asymmetry. Not photorealistic, not 3D, not anime, not flat vector, not
> Victorian or fantasy clothing.

and, for edits, the **keep block**:

> Keep her/him exactly the same person: identical face, hair, glasses, clothing, colours, the same
> proportions, height and painting style. Plain flat pure white background, no floor, no shadow, no text.

| # | Use | Template |
|---|---|---|
| 1 | Canonical | `<IDENTITY>` Full-body character design, the whole figure from the top of the hair to the shoes, centred, standing straight-on facing the viewer in a neutral pose, neutral calm expression, arms hanging slightly away from the body so a gap shows, hands open and visible, feet a little apart and both visible, nothing in the hands. Even neutral light, no cast shadows. Plain flat pure white background, no floor, no scene, no furniture, no text, no character sheet. `<STYLE>` |
| 2 | Turnaround (attach canonical) | Turn this exact person to show them from `<their left side: a full-body side view in profile facing to the right | behind: a full-body back view>`, standing straight in a neutral pose, arms hanging naturally. `<KEEP>` |
| 3 | Rig pose (attach canonical / side view) | The same person in an animation rig pose `<front: arms held straight down but angled about twenty-five degrees out … feet a little further apart | side, facing right: the near arm hangs relaxed but swung about twenty degrees forward, clear of the torso, not pointing; legs slightly apart in a small step>`. Keep everything else identical: the same position on the canvas … `<KEEP>` |
| 4a | Body base (attach rig pose) | Remove both of their arms and hands completely, and remove the legs and shoes below the hem of the `<skirt / jacket>`. The shoulders end in neat rounded armholes. Keep everything else identical: the same position on the canvas … |
| 4b | Part (attach rig pose) | Keep ONLY `<the near arm in its sleeve, from the top of the shoulder to the relaxed hand | the two lower legs with the shoes, from just above the hem>`, complete; remove everything else entirely. Keep it in exactly the same position, size and painting style on the canvas. White background … |
| 5 | Pose reference / hybrid pose (attach canonical) | The same person `<sitting down facing the viewer as if on an invisible seat at knee height, hands folded on the lap | …>`. Do NOT draw any chair. `<KEEP>` |
| 6 | Direction | Not needed: front / side (mirrored for left) / back cover every floor direction at this camera. |
| 7 | State variation | Only when the game needs a look the rig cannot pose (e.g. sleeping in bed). Same keep block. |

**Identity across generations.** One reference per edit: always attach the canonical, or an image
already derived from it, never generate a view from text alone. Re-run rather than accept drift; fix
small colour drift in a part with `grey_to.gd` (grandma's front tights).

**Validating an image.** Whole figure, no crop; same face, hair silhouette, clothes and colours as
the canonical; white background (no checkerboard, no floor line, no shadow); limbs clear of the
body in rig poses; the outline box shares the top line and scale with its view.

## 6. Animation and states

`CharacterAnimator` state table (in code and here):

| Game state | Clip (view) |
|---|---|
| marker `!` (FRIGHT) | `fright` (front): jolt up, arms flung out, tremble; holds |
| marker `?` (noticing, inspecting, searching) | `anxious` (front): hunched, hands drawn together in front (wringing), looking left and right |
| pose `broken` | `slump` (front) |
| pose `sit` (rest, eat, read, computer, draw, dolls) | `sit` — the painted seated pose, breathing |
| pose `sleep` | not rigged yet: the code draws the sleeper in bed |
| pose `walk` | `walk_side` (mirrored for left) / `walk_front` / `walk_back` by the facing in metres |
| standing in an activity with a clip of that name | e.g. `cook` (back view at the stove) |
| anything else | `idle_front` / `idle_side` / `idle_back` |

Principles used: eased keys (ease in and out); breathing and weight shift in idles; walk with body
bob twice per stride, opposing arm swing, a lean, head counter-bob; anticipation and settle in
`fright`; blends of 0.25 s between clips; a narrowing "turn" between views instead of a snap. Clips
never interrupt gameplay: the animator only follows the states, which keep their own rules (tasks
run to completion, Broken and recovery as in the morale system).

## 7. Adding the next family member

Copy the grandma flow: identity → canonical (2 candidates) → turnaround → rig poses → bases → parts →
`rig_src.json` (cuts, pivots, clips; start from grandma's and retime for the character's movement
personality) → build → captures. Their activities decide extra clips (father: `tools`/repair, mother:
cleaning, grandpa: `read`, son: `computer`, daughter: `dolls`, `draw`, the tricycle as a painted pose
set). Stop for review per character.

## 7b. The ghost (2026-11-21)

The player's ghost uses the same rig format and builder (sources in
`art/concepts/characters/ghost/prod/`), with differences recorded in `GHOST.md` §7–§9: generated on
flat mid-grey (`bg_min`, `white_parts`), his painted glow removed by an edit and drawn by the game,
the figure composited offscreen (`GhostVisual`) so opacity applies once, and his own animator
(`GhostAnimator`: float, glide, reach, fright; lean and trailing from his real drift).

## 8. Status

| Item | Status |
|---|---|
| Pipeline, tools, rig format, animator | EXPERIMENTAL (pilot) |
| Grandma 1990s clothing direction | APPROVED (user, 2026-11-20); final visual sign-off pending the screenshots |
| Beige tights recolour (no regeneration) | APPROVED (user, 2026-11-20) |
| Hybrid cutout rig drawn by CharacterRig in the depth-sorted room pass | APPROVED (user, 2026-11-20) — keep this architecture |
| Rollout | APPROVED sequentially, one character at a time, each after review |
| Grandma rig (front, side, back, sit) and clips | Verified in game (evidence `production/qa/evidence/character-pilot-grandma/`); awaiting final visual sign-off |
| Period-dressed concept family | REJECTED for clothing (late-1990s brief); kept for silhouettes |
| Sleeping, tricycle, per-activity clips for others | OPEN |
| Seated people on sofas/chairs other than the painted pose | OPEN (one seated pose per character) |

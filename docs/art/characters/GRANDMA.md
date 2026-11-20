# Grandma — pilot character

Status: **EXPERIMENTAL — pilot built 2026-11-20, awaiting user review.**

**Why the pilot.** Of the six, grandma uses the most of what a character must do, all already in the
game: a clear work activity (cooking at the stove, three times a day), sitting at an exact spot (her
armchair, `grandma_armchair`), sleeping, a slow characterful walk between kitchen, dining room and
living room, and the stealth reactions (she is the one who glimpses, inspects and searches in the
kitchen). Her silhouette (short, round, a cloud of curls) is the most distinctive to test
readability.

## Identity

| Field | Value |
|---|---|
| Id | `grandma` |
| Family role | Cooking (GDD §5.1) |
| Age | about 72 |
| Personality | Low mobility, medium-low courage, cooking specialist (GDD §5.4); warm, busy, a worrier |
| Height | 1.58 m — the shortest adult (father ≈ 1.85, mother ≈ 1.68, grandpa ≈ 1.75) |
| Body | Short, soft and round, slightly stooped |
| Head-to-body | about 1 : 5 (storybook) |
| Face | Round and kind, rosy cheeks, laugh lines, small nose, warm hazel eyes; fair warm skin |
| Hair | Short silver-grey permed curls in a round cloud |
| Clothing | Buttoned dusty-rose knitted cardigan over a lilac floral blouse with a round collar; mustard-and-cream checked cotton apron; mid-calf dark plum pleated skirt; light beige tights |
| Shoes | Comfortable brown lace-up shoes |
| Accessories | Large gold-rimmed 1990s glasses on a thin beaded chain; thin leather wristwatch; small gold earrings |
| Palette | Dusty rose, lilac, mustard, cream, plum, beige, brown |
| Posture | Slight stoop, hands often close to the body |
| Movement | Short steps (0.9 m stride), unhurried, a little rocking; quick small reactions |
| Expressions | Calm, content (sitting), worried (searching), startled (contact) |
| Props | (wooden spoon — not drawn; the stir reads at game size) |
| Activities | cook (stove), rest (armchair), eat (dining table), sleep (bed); searching after a glimpse |
| Never changes | The curl cloud, the glasses on a chain, the rose cardigan, the mustard checked apron, the plum skirt, beige tights, brown shoes, 1.58 m |

**Identity prompt** (as used):

> A grandmother of about 72 from the late 1990s: short (1.58 m) and soft and round, slightly stooped,
> a round kind face with rosy cheeks, laugh lines, a small nose and warm hazel eyes; short silver-grey
> permed curls in a round cloud; large gold-rimmed 1990s glasses on a thin beaded chain; a buttoned
> dusty-rose knitted cardigan over a lilac floral blouse with a soft round collar; a mustard-and-cream
> checked cotton apron tied at the waist; a mid-calf dark plum pleated skirt; light beige tights;
> comfortable brown lace-up shoes; a thin leather wristwatch; small gold earrings.

## Images (art/concepts/characters/family/grandma/)

| File | Made by | Use |
|---|---|---|
| `canonical_a.png` → `canonical.png`, `canonical_b.png` | Prompt 1 (two candidates; A chosen: shows the glasses chain) | master reference |
| `turn_side.png`, `turn_back.png` | Prompt 2, canonical attached | turnaround |
| `rig_front.png` | Prompt 3, canonical attached | front cuts (head, arms, legs). Drift: tights turned dark grey → front legs recoloured (`grey_to`) |
| `rig_side.png` | Prompt 3, side view attached (second try: the first pointed the arm straight out) | side base and parts |
| `base_front.png`, `base_back.png`, `base_side.png` | Prompt 4a | bodies without arms and lower legs |
| `part_side_arm.png`, `part_side_legs.png` | Prompt 4b | side arm; side legs (split at x = 513) |
| `pose_sit.png` | Prompt 5, canonical attached | the seated pose (hybrid), 1.2 m tall |

Game parts: `assets/art/characters/grandma/{front,back,side,sit}_*.png`, `rig.json` (built from
`rig_src.json` by `tools/art/rig_build.py grandma`).

## Rig

Front and back: body (pivot hips), head (neck), arm_l / arm_r (shoulders), leg_l / leg_r (hips,
behind the skirt). Side (facing right; left mirrored): body, head, arm (near), leg_near, leg_far.
Sit: one painted body. Canvas scale 0.4 (227 px per metre; seated 299). Stride 0.9 m.

## Clips

`idle_front`, `idle_side`, `idle_back` (breathing, weight shift, head turns); `walk_side`,
`walk_front`, `walk_back` (one stride each, advanced by metres walked); `cook` (back view: stirring
arm, sway, nod); `anxious` (front: hands wringing in front of the apron, looking around); `fright` (front: jolt, arms out,
tremble, held); `slump` (Broken); `sit` (breathing).

## Verification (2026-11-20)

`bash tools/play.sh character-test` → `production/qa/evidence/character-pilot-grandma/`:
c01–c03 cooking at the stove (back view, stirring); c04–c09 walking from the stove to breakfast
(side view facing left, stepping); c10 the kitchen before; c11–c12 the ghost beside her at the
stove — she does not glimpse it (cooking, she faces the wall: correct game behaviour); c13–c13b the
fright of contact (front, arms flung out, "!"); c14–c15 resting in her armchair (the seated pose,
on the seat); c16a resting alone (08:20); c16–c17 a glance catches the ghost 1.8 m to her side,
"?", she rises into `anxious`. All by the game's own rules; no sight, detection or anxiety change.

**Finding (not changed):** a resting person faces the object they use, so in her armchair grandma
"looks" back toward the chair and sees the room only in her side glances, while her painting faces
the room. A design decision for later.

## Known limits (pilot)

- Sleeping is still the code drawing in bed; the tricycle is not grandma's.
- One seated pose: on the dining chairs she sits the same way as in the armchair.
- No separate hands, elbows or knees; no blink; no spoon in the stirring hand.
- Turning between views is a quick narrowing, not a painted three-quarter view.

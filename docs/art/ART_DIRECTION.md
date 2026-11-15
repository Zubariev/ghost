# Art direction: Whimsical Gothic Storybook

Status: approved direction 2026-11-15. The living room art test is built and awaiting review.
Other rooms keep the placeholder look until the art test is approved.
Source: the user's art direction brief (2026-11-15). This file records the rules the code follows.

## Intent

A hand-painted, illustrated fairy-tale look: warmth, domestic coziness, quirky humour, autumn
nostalgia, subtle gothic unease. The balance is about 40% cozy, 30% whimsical, 30% mysterious.
The look takes inspiration from the principles of *Over the Garden Wall*: organic outlines,
painterly textured surfaces, expressive silhouettes, muted autumn colour, atmospheric light. It
copies none of its characters, places or images. All designs are original.

**The defining contrast is a warm, familiar home slowly becoming an uncomfortable, haunted place.**

## Rules the code follows

| Area | Rule | Where |
|---|---|---|
| Palette | Old parchment #C99A60, walnut #79503C, terracotta #A94F42, dusk blue #59677A, muted olive #777C65, candlelight #D9B878, night charcoal #343747, ghost cyan #A8D5D9, aged cream #E6D7B8, dusty rose #B77C75, faded green #687B68, antique gold #B58A50, brown-grey #62564D. No pure black, no saturated primaries | `Palette.SB_*` |
| Contours | Dark muted brown, hand-drawn wobble, varying width. Strength by tier: characters and ghost > interactive objects > furniture > background (softest, lighter) | `Ink`, `Ink.Tier` |
| Surfaces | Soft vertical shading, pigment variation, wood grain, woven fabric. Paper grain, pigment pools and brush streaks are subtle (a few % of tone) | `Ink.fill/wood_grain/weave`, `canvas_art_storybook_paper.gdshader` |
| Light | Cozy: amber highlights, firelight and lamplight pools, gentle vignette. Haunted: desaturated, dusk-blue and charcoal shadows, cold highlights, darker corners, moonlight through the window, longer shadows. A colour grade, never a flat blue overlay | `RoomMood`, `post_art_room_grade.gdshader`, `RoomStage._draw_storybook_light` |
| Mood rule | Warmth 1 when lit and comfortable. Dark −0.55, dim −0.25, cold −0.45. The fireplace burns unless the room is cold (an open window puts it out). Eased over about a second | `RoomMood` |
| Ghost | Ghost cyan with a faint glow, dusk-blue contour, simple and playful | `FamilyArt.draw_ghost` |
| Readability | Interactive pieces (objects, hiding spots) get stronger contours and the highlight. Decoration is softer | `StorybookArt.draw` |
| Painted assets later | Every prop can be replaced by a PNG/WebP per state through `assets/art/visual_style.json`. Gameplay data never depends on image size | `PropVisuals`, `assets/art/props/sprite_guide.md` |

## Living room art test

Fireplace (central warm anchor on the back wall), two armchairs (grandma's terracotta wingback and
an olive fireside chair), a tea table, a side table with a teacup, a camelback sofa, a patterned
rug, a bookshelf, a fringed floor lamp, the window with heavy curtains, two paintings (a
moustached ancestor, a dusk landscape), a pendulum clock, a wooden door to the hall, and small
things on the mantel.

The new pieces are decor (`"decor": true` in `furniture.json`). They are drawn only, never an
obstacle, hiding spot or sight blocker. They stand where no family route ever passes, which a
test checks.

States: **cozy** (lamp lit, window shut, fire burning) and **haunted** (lamp out, window open,
fire out). Same layout, same positions, same camera. Captures: `bash tools/play.sh art-test`.

## Avoid

The recognisable character designs or identity of *Don't Starve*. Generic mobile cartoon looks,
flat vector, thick uniform black outlines, photorealism, oversaturation, anime styling, overly
cute proportions, pure horror or gore.

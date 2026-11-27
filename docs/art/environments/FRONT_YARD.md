# Front Yard

> **Status: PROVISIONAL — brief drafted 2026-11-27 (sprint 002, P7, task S2-08); art generated and wired 2026-11-27, awaiting the windowed capture review.**
> Sources: Reference A (`art/references/sprint-002/reference_a_yards.png`, front-yard panel and props strip),
> decision D1 (2026-11-26: layout ideas, props, palette and mood from A; painted in the approved storybook
> style). Geometry is guarded by `tests/integration/data/yard_geometry_test.gd`.

## 1. What the place is
The house's face to the street: tidy, welcoming, a little too quiet. The family never comes out here (Demo Spec
§8.12); for the ghost it is an open, exposed place with two hedges to hide in.

## 2. Gameplay layout (from the data — art never changes it)
Room 10.0 × 6.0 m, grid row 2 in front of the hall, open sky, light from daylight only.
| Piece | u, v | Gameplay |
|---|---|---|
| hedge (left) | 0.15, 0.50 | hiding spot `hide_front_yard_hedge_left` |
| hedge (right) | 0.85, 0.50 | hiding spot `hide_front_yard_hedge_right` |

## 3. Camera and the reference
The front yard lies **south** of the hall, so its back wall faces the house: Reference A's front-yard panel fits
(house front as the backdrop). The back wall is today the painted weatherboard house front.

## 4. Look
- Back wall: the house front — weatherboard, porch with white posts and railing, front door with a wreath,
  lit windows with dark shutters, a lantern by the door (lit at dusk/night, cool by day).
- Side walls: their own texture (now the house front on both sides): white picket fence with hydrangea bushes.
- Ground: lawn and a stone path to the porch (cobbles exist; keep or repaint, seamless).
- Hedges (repaint): a clipped hedge about 2 m wide and 1.1 m high (today it reads as a round bush).
- Shares the kit with the back yard (fence wood, foliage, palette, light) but stays tidy and formal.

## 5. Props to paint (visual only unless listed in §2)
| Prop | Placement idea | Notes |
|---|---|---|
| hedges (repaint) | their pieces | long and clipped, readable as hiding spots |
| mailbox on a post | near the front edge, no footprint | from reference A |
| picket fence sections and gate posts | side walls / front edge, no footprint | white, slightly worn |
| big oak with a rope swing | side-wall layer, backdrop only | must not cover the hedges |
| hydrangea bushes, potted plants on the porch | backdrop / porch | small decor |

## 6. Asset specs
As the back yard (`BACK_YARD.md` §6).

## 7. Review (when built)
`bash tools/play.sh areas-test` by day and night; geometry test green; side by side with the back yard.

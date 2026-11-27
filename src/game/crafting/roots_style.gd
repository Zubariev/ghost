## How a node looks on the roots screen (sprint 002, P5; design/ux/roots-progression.md, States &
## Variants). States differ by size, ring and glow as well as colour, so they read in greyscale.
## Branch colours are existing palette colours (no new colour standard).
class_name RootsStyle
extends RefCounted

const LOCKED_RADIUS: float = 9.0
const OPEN_RADIUS: float = 13.0
## Extra ring round the selected node (px).
const SELECTED_RING: float = 6.0
## How much of its branch colour a locked node keeps (review 2026-11-27: branches must read on a
## first visit, when almost everything is locked).
const LOCKED_TINT: float = 0.45

## Branch colour keys in progression.json → palette colours.
const BRANCH_COLOURS: Dictionary = {
	"amber": Palette.SB_CANDLELIGHT,
	"gold": Palette.SB_GOLD,
	"green": Palette.SB_OLIVE,
	"mauve": Palette.SB_ROSE,
}


## The palette colour for branch colour key [param key] (cream for an unknown key).
static func branch_colour(key: String) -> Color:
	return BRANCH_COLOURS.get(key, Palette.SB_CREAM)


## {radius, fill, rim, ring (gold ring: owned), ring_width, glow (0..1 steady glow), halo (glow
## size as a multiple of the radius), pulse (slow pulse), selected} for a node in [param state].
## Owned: thick gold ring and a small steady halo; available and affordable: a wide pulsing halo
## and no ring (review 2026-11-27: the two must differ in a still or greyscale screenshot).
static func node_look(state: CraftingProgression.NodeState, affordable: bool, selected: bool, colour: Color) -> Dictionary:
	var look: Dictionary = {"radius": OPEN_RADIUS, "fill": colour, "rim": Palette.SB_CONTOUR, "ring": false,
		"ring_width": 0.0, "glow": 0.0, "halo": 2.4, "pulse": false, "selected": selected}
	match state:
		CraftingProgression.NodeState.LOCKED:
			look["radius"] = LOCKED_RADIUS
			look["fill"] = Palette.SB_CHARCOAL.lerp(colour, LOCKED_TINT)
			look["rim"] = colour.darkened(0.45)
		CraftingProgression.NodeState.AVAILABLE:
			look["pulse"] = affordable
		CraftingProgression.NodeState.OWNED:
			look["fill"] = colour.lightened(0.25)
			look["ring"] = true
			look["ring_width"] = 4.0
			look["glow"] = 0.45
			look["halo"] = 1.5
	return look

## Code-drawn furniture in the Whimsical Gothic Storybook style (art direction 2026-11-15):
## organic shapes, brown hand-drawn contours by readability tier, soft shading, wood grain
## and woven fabric, the storybook palette. These are placeholders: any prop can be replaced
## by a painted sprite through [PropVisuals] without touching gameplay.
##
## The living room art-test props have their own designs: fieldstone fireplace (burning / out),
## wingback armchairs, dusty-rose camelback sofa, tea tables, fringed floor lamp, arched window
## with green curtains, rectangular patterned rug laid in floor perspective, bookshelf,
## paintings, pendulum clock. Art Phase 1 (2026-11-15) moved them toward the approved concept
## `art/concepts/environments/living_room/living_room_cozy.jpeg`
## (docs/art/environments/LIVING_ROOM.md); positions and sizes in data did not change. Other kinds reuse [FurnitureArt]'s shapes,
## re-rendered with storybook ink, shading and texture.
##
## A piece is drawn with its foot at the floor position (wall pieces at the back wall's base)
## and scaled for depth. Each part is [polygon (local px), colour, surface, tier]; surface is
## "wood", "fabric", "plain" (shaded, outlined) or "bare" (flat fill, no contour).
class_name StorybookArt
extends RefCounted

const HIGHLIGHT_WIDTH: float = 9.0
## The rug's half size in floor units (u, v): drawing only, rugs block nothing.
const RUG_HALF := Vector2(0.2, 0.12)

## Kinds drawn on the back wall (sorted behind everything on the floor).
const WALL_KINDS: Array[String] = ["window", "fireplace", "painting", "wall_clock"]


static func is_wall(kind: String) -> bool:
	return WALL_KINDS.has(kind)


## Draws one piece. [param piece] is its furniture.json entry; [param state] its visual
## state (sim object state, or "burning"/"out" for a fireplace); [param interactive]
## strengthens contours for gameplay-relevant pieces.
static func draw(canvas: CanvasItem, piece: Dictionary, uv: Vector2, state: StringName, highlighted: bool,
		is_day: bool, interactive: bool, time: float) -> void:
	var kind: String = String(piece["kind"])
	var variant: String = String(piece.get("variant", ""))
	var wall: bool = is_wall(kind)
	var foot: Vector2 = RoomGeometry.to_screen(uv)
	var s: float = 1.0 if wall else RoomGeometry.scale_at(uv.y)
	var seed: float = Ink.seed_at(foot) + float(kind.length())
	var tier: Ink.Tier = Ink.Tier.INTERACTIVE if interactive else (Ink.Tier.BACKGROUND if wall and kind != "window" else Ink.Tier.FURNITURE)
	var parts: Array = _parts(kind, variant, state, is_day, time, tier, uv)
	if parts.is_empty():
		return
	if highlighted:
		for part: Array in parts:
			if String(part[2]) != "bare":
				var poly: PackedVector2Array = _place(part[0], foot, s)
				var closed: PackedVector2Array = poly.duplicate()
				closed.append(poly[0])
				canvas.draw_polyline(closed, Palette.SB_HIGHLIGHT, HIGHLIGHT_WIDTH, true)
	for i: int in parts.size():
		var part: Array = parts[i]
		var poly: PackedVector2Array = _place(part[0], foot, s)
		var color: Color = part[1]
		var surface: String = String(part[2])
		var part_tier: Ink.Tier = part[3] if part.size() > 3 else tier
		var part_seed: float = seed + float(i) * 1.37
		if surface == "bare":
			if poly.size() >= 3 and not Geometry2D.triangulate_polygon(poly).is_empty():
				canvas.draw_colored_polygon(poly, color)
			continue
		Ink.fill(canvas, poly, color, part_seed)
		if surface == "wood":
			Ink.wood_grain(canvas, poly, color, part_seed, 3)
		elif surface == "fabric":
			Ink.weave(canvas, poly, color, part_seed, 8.0 * s)
		Ink.outline(canvas, poly, part_tier, part_seed)
	draw_effects(canvas, kind, state, foot, s, time)


## The animated, state-driven part of a piece (fire and its glow, smoke from a cold grate, a lit
## lamp's glow), drawn over the piece at [param foot] with scale [param s]. Separate from the
## shapes so it also runs on top of a painted sprite (art Phase 3, 2026-11-15).
## [param code_shapes] false: a painted layer replaces the code flames (the glow stays).
static func draw_effects(canvas: CanvasItem, kind: String, state: StringName, foot: Vector2, s: float, time: float,
		code_shapes: bool = true) -> void:
	if kind == "fireplace" and state == &"burning":
		_draw_fire(canvas, foot, s, time, code_shapes)
	elif kind == "fireplace":
		_draw_smoke(canvas, foot, s, time)
	if kind == "floor_lamp" and state != &"out":
		Ink.glow(canvas, foot + Vector2(0, -128) * s, Vector2(40, 30) * s, Color(Palette.SB_CANDLELIGHT, 0.55), 5)


static func _place(poly: PackedVector2Array, foot: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in poly:
		out.append(foot + p * s)
	return out


## The drawing of one piece as parts. [param uv] is its floor position (the rug is laid in
## the floor's perspective from it).
static func _parts(kind: String, variant: String, state: StringName, is_day: bool, time: float, tier: Ink.Tier,
		uv: Vector2 = Vector2(0.5, 0.5)) -> Array:
	match kind:
		"fireplace":
			return _fireplace(state)
		"armchair", "reading_chair":
			return _armchair(variant)
		"sofa":
			return _sofa()
		"side_table", "tea_table":
			return _tea_table(kind == "tea_table")
		"floor_lamp":
			return _floor_lamp(state)
		"window":
			return _window(state, is_day, time)
		"rug":
			return _rug(uv)
		"bookshelf":
			return _bookshelf()
		"painting":
			return _painting(variant)
		"wall_clock":
			return _clock(time)
	# Not yet given a storybook design: the original shapes, re-rendered in storybook ink.
	var parts: Array = []
	for part: Array in FurnitureArt._parts(kind, Vector2.ZERO, state, is_day):
		parts.append([part[0], _restyle(part[1]), "plain", tier])
	return parts


# Maps an original placeholder colour to its storybook counterpart.
static func _restyle(c: Color) -> Color:
	var options: Array[Color] = [Palette.SB_WALNUT, Palette.SB_WALNUT_DARK, Palette.SB_WALNUT_LIGHT, Palette.SB_TERRACOTTA,
		Palette.SB_OLIVE, Palette.SB_DUSK_BLUE, Palette.SB_CREAM, Palette.SB_GOLD, Palette.SB_CHARCOAL, Palette.SB_BROWN_GREY, Palette.SB_ROSE]
	var best: Color = options[0]
	var best_d: float = INF
	for o: Color in options:
		var d: float = Vector3(c.r - o.r, c.g - o.g, c.b - o.b).length_squared()
		if d < best_d:
			best_d = d
			best = o
	return Color(best, c.a)


# --- Shape helpers -----------------------------------------------------------------

static func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


## A slightly irregular quadrilateral: corners nudged by up to [param skew] px.
static func _rough(x0: float, y0: float, x1: float, y1: float, skew: float = 2.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0 + skew * 0.5, y0), Vector2(x1, y0 + skew * 0.4), Vector2(x1 - skew * 0.3, y1), Vector2(x0, y1 - skew * 0.2)])


## A rounded-top shape (arch / wingback): straight sides from [param y_bottom] up to
## [param y_shoulder], then a half-ellipse up to [param y_top].
static func _arch(x0: float, x1: float, y_bottom: float, y_shoulder: float, y_top: float, n: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(x0, y_bottom)])
	var cx: float = (x0 + x1) * 0.5
	var rx: float = (x1 - x0) * 0.5
	var ry: float = y_shoulder - y_top
	for i: int in n + 1:
		var a: float = PI + PI * float(i) / float(n)
		pts.append(Vector2(cx + cos(a) * rx, y_shoulder + sin(a) * ry))
	pts.append(Vector2(x1, y_bottom))
	return pts


# --- Living room art-test props ----------------------------------------------------

## Fieldstone fireplace on the back wall (concept: a stone chimney breast rising to the
## ceiling): irregular stones narrowing upward, a stone-arched firebox with andirons, a heavy
## walnut mantel on corbels carrying a candle, framed family photos and a vase; stone hearth.
static func _fireplace(state: StringName) -> Array:
	var burning: bool = state == &"burning"
	var breast := PackedVector2Array([Vector2(-88, 0), Vector2(88, 0), Vector2(84, -124), Vector2(66, -140),
		Vector2(62, -170), Vector2(-62, -170), Vector2(-66, -140), Vector2(-84, -124)])
	var parts: Array = [[breast, Palette.SB_STONE_DARK, "plain", Ink.Tier.BACKGROUND]]
	parts.append_array(_stones())
	parts.append_array([
		# Stone arch round the firebox, the dark opening, andirons and logs
		[_arch(-56, 56, 0, -62, -88, 14), Palette.SB_STONE_LIGHT, "plain", Ink.Tier.FURNITURE],
		[_arch(-44, 44, 0, -54, -74, 12), Palette.SB_CHARCOAL if burning else Palette.SB_CHARCOAL.darkened(0.25), "plain", Ink.Tier.FURNITURE],
		[_rect(-38, -24, -33, 0), Palette.SB_CHARCOAL.darkened(0.2), "bare"],
		[_rect(33, -24, 38, 0), Palette.SB_CHARCOAL.darkened(0.2), "bare"],
		[Ink.ellipse(Vector2(-35.5, -26), 4, 4, 10), Palette.SB_GOLD.darkened(0.25), "bare"],
		[Ink.ellipse(Vector2(35.5, -26), 4, 4, 10), Palette.SB_GOLD.darkened(0.25), "bare"],
		[Ink.ellipse(Vector2(-12, -9), 26, 6, 14), Palette.SB_WALNUT_DARK, "wood", Ink.Tier.FURNITURE],
		[Ink.ellipse(Vector2(14, -13), 22, 5, 14), Palette.SB_WALNUT, "wood", Ink.Tier.FURNITURE],
		# Hearth slab on the floor
		[PackedVector2Array([Vector2(-102, 0), Vector2(102, 0), Vector2(112, 12), Vector2(-114, 13)]), Palette.SB_STONE_LIGHT, "plain", Ink.Tier.FURNITURE],
		# Heavy walnut mantel on two corbels
		[PackedVector2Array([Vector2(-80, -110), Vector2(-64, -110), Vector2(-64, -104), Vector2(-72, -92), Vector2(-78, -94)]), Palette.SB_WALNUT_DARK, "wood", Ink.Tier.FURNITURE],
		[PackedVector2Array([Vector2(80, -110), Vector2(64, -110), Vector2(64, -104), Vector2(72, -92), Vector2(78, -94)]), Palette.SB_WALNUT_DARK, "wood", Ink.Tier.FURNITURE],
		[_rough(-100, -128, 100, -110, 2.0), Palette.SB_WALNUT, "wood", Ink.Tier.FURNITURE],
		[_rect(-98, -112, 98, -109), Palette.SB_WALNUT_DARK, "bare"],
		# On the mantel: a candlestick, three framed family photos, a vase with a sprig
		[_rect(-88, -136, -78, -128), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE],
		[_rect(-86, -154, -80, -136), Palette.SB_CREAM, "plain", Ink.Tier.FURNITURE],
		[_rough(-62, -150, -40, -128, 1.0), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE],
		[_rect(-58, -146, -44, -131), Palette.SB_PARCHMENT.lightened(0.2), "bare"],
		[Ink.ellipse(Vector2(-54, -141), 2.6, 3.2, 10), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
		[Ink.ellipse(Vector2(-48, -140), 2.4, 3.0, 10), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
		[_rough(-32, -144, -14, -128, 1.0), Palette.SB_WALNUT_LIGHT, "plain", Ink.Tier.FURNITURE],
		[_rect(-29, -141, -17, -131), Palette.SB_PARCHMENT.lightened(0.15), "bare"],
		[Ink.ellipse(Vector2(-23, -137), 2.6, 3.2, 10), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
		[_rough(16, -158, 38, -128, 1.0), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE],
		[_rect(20, -154, 34, -132), Palette.SB_PARCHMENT.lightened(0.2), "bare"],
		[Ink.ellipse(Vector2(27, -147), 3.4, 4.2, 10), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
		[PackedVector2Array([Vector2(27, -143), Vector2(33, -134), Vector2(21, -134)]), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
		[PackedVector2Array([Vector2(56, -128), Vector2(70, -128), Vector2(73, -142), Vector2(67, -154), Vector2(61, -154), Vector2(55, -142)]), Palette.SB_ROSE, "plain", Ink.Tier.FURNITURE],
		[PackedVector2Array([Vector2(64, -154), Vector2(58, -166), Vector2(61, -167), Vector2(65, -156), Vector2(71, -167), Vector2(74, -165), Vector2(66, -154)]), Palette.SB_OLIVE, "bare"],
	])
	if burning:
		parts.append([Ink.ellipse(Vector2(-83, -158), 2.5, 4.5, 8), Palette.SB_CANDLELIGHT, "bare"])
	else:
		# Cold ash on the hearth floor
		parts.append([Ink.ellipse(Vector2(0, -5), 36, 4, 14), Palette.SB_ASH, "bare"])
	return parts


## Half-width of the chimney breast at height [param y] (it narrows above the mantel).
static func _breast_half(y: float) -> float:
	if y > -124.0:
		return 86.0
	if y > -140.0:
		return lerpf(84.0, 66.0, (-124.0 - y) / 16.0)
	return lerpf(66.0, 62.0, (-140.0 - y) / 30.0)


## Irregular fieldstones in staggered rows over the chimney breast, mortar gaps between them;
## deterministic, so they never shimmer.
static func _stones() -> Array:
	var tones: Array[Color] = [Palette.SB_STONE, Palette.SB_STONE_LIGHT, Palette.SB_STONE.darkened(0.1), Palette.SB_BROWN_GREY.lightened(0.12)]
	var stones: Array = []
	var y: float = 0.0
	var row: int = 0
	while y > -168.0:
		var h: float = 14.0 + 6.0 * Ink.noise1(float(row) * 3.1 + 0.5)
		var top: float = maxf(y - h, -170.0)
		var half: float = _breast_half((y + top) * 0.5) - 1.5
		var x: float = -half
		var k: int = 0
		while x < half - 6.0:
			var w: float = 18.0 + 14.0 * Ink.noise1(float(row) * 7.3 + float(k) * 1.9)
			if row % 2 == 1 and k == 0:
				w *= 0.55
			var x1: float = minf(x + w, half)
			if half - x1 < 9.0:
				x1 = half
			var gap: float = 1.6
			var c: float = minf(3.5, (x1 - x) * 0.25)
			stones.append([PackedVector2Array([
				Vector2(x + gap + c, top + gap), Vector2(x1 - gap - c, top + gap), Vector2(x1 - gap, top + gap + c),
				Vector2(x1 - gap, y - gap - c), Vector2(x1 - gap - c, y - gap), Vector2(x + gap + c, y - gap),
				Vector2(x + gap, y - gap - c), Vector2(x + gap, top + gap + c)]),
				tones[(row * 3 + k) % tones.size()], "plain", Ink.Tier.BACKGROUND])
			x = x1
			k += 1
		y = top
		row += 1
	return stones


## Wingback armchair; variant "olive" for the second chair, otherwise terracotta.
static func _armchair(variant: String) -> Array:
	var cloth: Color = Palette.SB_OLIVE if variant == "olive" else Palette.SB_TERRACOTTA
	var cushion: Color = Palette.SB_CREAM.darkened(0.08) if variant == "olive" else Palette.SB_ROSE
	return [
		[_rect(-38, -10, -32, 0), Palette.SB_WALNUT_DARK, "wood"],
		[_rect(32, -10, 38, 0), Palette.SB_WALNUT_DARK, "wood"],
		[_arch(-40, 40, -48, -92, -116, 14), cloth.darkened(0.08), "fabric"],
		[PackedVector2Array([Vector2(-46, -46), Vector2(-40, -96), Vector2(-30, -100), Vector2(-28, -46)]), cloth.darkened(0.18), "fabric"],
		[PackedVector2Array([Vector2(46, -46), Vector2(40, -96), Vector2(30, -100), Vector2(28, -46)]), cloth.darkened(0.18), "fabric"],
		[_rough(-44, -50, 44, -10, 3.0), cloth, "fabric"],
		[Ink.ellipse(Vector2(0, -54), 30, 8, 16), cushion, "fabric"],
		[Ink.ellipse(Vector2(-44, -50), 9, 11, 12), cloth.darkened(0.05), "fabric"],
		[Ink.ellipse(Vector2(44, -50), 9, 11, 12), cloth.darkened(0.05), "fabric"],
	]


## Camelback sofa in dusty rose (concept target) with a walnut base rail, rolled arms, three
## seat cushions, an olive and a cream throw pillow, and turned legs.
static func _sofa() -> Array:
	var cloth: Color = Palette.SB_ROSE
	var back := PackedVector2Array([Vector2(-112, -50), Vector2(-112, -84), Vector2(-70, -92), Vector2(-30, -104), Vector2(0, -108),
		Vector2(30, -104), Vector2(70, -92), Vector2(112, -84), Vector2(112, -50)])
	return [
		[_rect(-108, -10, -100, 0), Palette.SB_WALNUT_DARK, "wood"],
		[_rect(100, -10, 108, 0), Palette.SB_WALNUT_DARK, "wood"],
		[back, cloth.darkened(0.14), "fabric"],
		[_rough(-118, -56, 118, -14, 3.0), cloth, "fabric"],
		[_rough(-114, -16, 114, -9, 1.5), Palette.SB_WALNUT, "wood"],
		[_rough(-104, -66, -38, -50, 2.0), cloth.lightened(0.07), "fabric"],
		[_rough(-34, -68, 34, -50, 2.0), cloth.lightened(0.09), "fabric"],
		[_rough(38, -66, 104, -50, 2.0), cloth.lightened(0.07), "fabric"],
		[Ink.ellipse(Vector2(-118, -56), 12, 16, 12), cloth.darkened(0.08), "fabric"],
		[Ink.ellipse(Vector2(118, -56), 12, 16, 12), cloth.darkened(0.08), "fabric"],
		[_rough(-84, -86, -56, -64, 2.0), Palette.SB_OLIVE, "fabric"],
		[_rough(52, -84, 80, -63, 2.0), Palette.SB_CREAM.darkened(0.12), "fabric"],
	]


## Round tea table on a pedestal; the side table carries a teacup on a doily, the tea table
## a small stack of books and a candle.
static func _tea_table(with_books: bool) -> Array:
	var parts: Array = [
		[PackedVector2Array([Vector2(-22, 0), Vector2(-4, -8), Vector2(4, -8), Vector2(22, 0)]), Palette.SB_WALNUT_DARK, "wood"],
		[_rect(-4, -46, 4, -6), Palette.SB_WALNUT, "wood"],
		[Ink.ellipse(Vector2(0, -50), 30, 8, 20), Palette.SB_WALNUT_LIGHT, "wood"],
		[Ink.ellipse(Vector2(0, -52), 18, 4, 16), Palette.SB_CREAM, "bare"],
	]
	if with_books:
		parts.append([_rough(-16, -62, 10, -54, 1.0), Palette.SB_TERRACOTTA, "plain"])
		parts.append([_rough(-13, -68, 8, -62, 1.0), Palette.SB_DUSK_BLUE, "plain"])
		parts.append([_rect(14, -66, 19, -54), Palette.SB_CREAM, "plain"])
	else:
		parts.append([PackedVector2Array([Vector2(-7, -60), Vector2(7, -60), Vector2(5, -52), Vector2(-5, -52)]), Palette.SB_CREAM, "plain"])
		parts.append([Ink.ellipse(Vector2(0, -52), 10, 2.5, 12), Palette.SB_ROSE.lightened(0.2), "bare"])
	return parts


## Brass floor lamp with a fringed parchment shade; out = cool shade.
static func _floor_lamp(state: StringName) -> Array:
	var lit: bool = state != &"out"
	var shade: Color = Palette.SB_CANDLELIGHT if lit else Palette.SB_DUSK_BLUE.lightened(0.1)
	var parts: Array = [
		[Ink.ellipse(Vector2(0, -3), 18, 5, 14), Palette.SB_GOLD, "plain"],
		[_rect(-2.5, -116, 2.5, -4), Palette.SB_GOLD.darkened(0.15), "plain"],
		[PackedVector2Array([Vector2(-14, -150), Vector2(14, -150), Vector2(26, -118), Vector2(-26, -118)]), shade, "fabric"],
	]
	for i: int in 9:
		var x: float = -24.0 + 6.0 * float(i)
		parts.append([_rect(x, -118, x + 2.0, -111), shade.darkened(0.2), "bare"])
	return parts


## One feathery frost sprig at [param from], growing along [param angle] for [param length] px:
## a fine stem with short side branches that shrink toward the tip.
static func _frost_sprig(from: Vector2, angle: float, length: float, color: Color) -> Array:
	var dir := Vector2(cos(angle), sin(angle))
	var parts: Array = [[_stroke(from, from + dir * length, 0.6), color, "bare"]]
	for i: int in 3:
		var at: Vector2 = from + dir * length * (0.3 + 0.22 * float(i))
		var twig: float = length * (0.4 - 0.1 * float(i))
		for side: float in [-1.0, 1.0]:
			var d: Vector2 = dir.rotated(side * 0.8)
			parts.append([_stroke(at, at + d * twig, 0.45), color, "bare"])
	return parts


## A thin quad from [param a] to [param b], [param half] px either side.
static func _stroke(a: Vector2, b: Vector2, half: float) -> PackedVector2Array:
	var n: Vector2 = (b - a).normalized().orthogonal() * half
	return PackedVector2Array([a + n, b + n, b - n, a - n])


## The tall arched window (concept target): walnut frame, small panes with a fanlight, heavy
## green velvet curtains on a rod, gathered by gold tiebacks and falling to the floor; panes
## show day sky or a moonlit night; open swings the lower sash and lets the curtains billow.
static func _window(state: StringName, is_day: bool, time: float) -> Array:
	var open: bool = state == &"open"
	var glass: Color = Palette.SB_GLASS_DAY if is_day else Palette.SB_GLASS_NIGHT
	var w: float = 48.0
	var top: float = -152.0
	var shoulder: float = -118.0
	var bottom: float = -46.0
	var sway: float = sin(time * 2.3) * 5.0 if open else 0.0
	var parts: Array = [
		[_arch(-w - 6, w + 6, bottom + 6, shoulder, top - 6, 16), Palette.SB_WALNUT, "wood", Ink.Tier.INTERACTIVE],
		[_arch(-w, w, bottom, shoulder, top, 16), Palette.SB_CHARCOAL if open else glass, "plain", Ink.Tier.INTERACTIVE],
	]
	if open:
		# The fanlight stays; the lower sash swings into the room.
		parts.append([_arch(-w, w, shoulder, shoulder, top, 16), glass, "plain", Ink.Tier.INTERACTIVE])
		parts.append([PackedVector2Array([Vector2(-w, shoulder), Vector2(-6, shoulder + 12), Vector2(-6, bottom - 12), Vector2(-w, bottom)]), glass.darkened(0.2), "plain", Ink.Tier.INTERACTIVE])
		# Frost (art Phase 2): a thin translucent rime hugging the glass edges, thicker in the
		# corners, with feathery fern sprigs growing in from the corners — no blobs or even
		# spikes (reviews 2026-11-15).
		var rime := Color(Palette.SB_MOON, 0.22)
		parts.append([PackedVector2Array([Vector2(-w, shoulder), Vector2(w, shoulder), Vector2(w, shoulder - 3), Vector2(w * 0.4, shoulder - 2), Vector2(-w * 0.3, shoulder - 3.5), Vector2(-w, shoulder - 2.5)]), rime, "bare"])
		parts.append([PackedVector2Array([Vector2(-w, shoulder), Vector2(-w + 4, shoulder + 20), Vector2(-w + 3, bottom - 20), Vector2(-w + 5, bottom), Vector2(-w, bottom)]), rime, "bare"])
		parts.append([PackedVector2Array([Vector2(-w, bottom), Vector2(-6, bottom - 12), Vector2(-8, bottom - 15), Vector2(-w * 0.5, bottom - 9.5), Vector2(-w, bottom - 4)]), rime, "bare"])
		var fern := Color(Palette.SB_MOON, 0.55)
		for sprig: Vector4 in [
			Vector4(-w + 1, shoulder - 1, -0.6, 11), Vector4(w - 1, shoulder - 1, -2.5, 10),
			Vector4(-w + 2, shoulder + 2, 0.7, 12), Vector4(-w + 2, bottom - 3, -0.6, 13),
			Vector4(-10, bottom - 13, -2.3, 8),
		]:
			parts.append_array(_frost_sprig(Vector2(sprig.x, sprig.y), sprig.z, sprig.w, fern))
	else:
		if not is_day:
			parts.append([Ink.ellipse(Vector2(w * 0.42, shoulder + 16), 8, 8, 14), Palette.SB_MOON, "bare"])
		# Glazing bars: a centre bar to the top, two side bars, three cross bars
		parts.append([_rect(-1.5, top, 1.5, bottom), Palette.SB_WALNUT, "bare"])
		for x: float in [-w * 0.5, w * 0.5]:
			parts.append([_rect(x - 1.2, shoulder, x + 1.2, bottom), Palette.SB_WALNUT, "bare"])
		for y: float in [shoulder, lerpf(shoulder, bottom, 0.38), lerpf(shoulder, bottom, 0.7)]:
			parts.append([_rect(-w, y - 1.2, w, y + 1.2), Palette.SB_WALNUT, "bare"])
		# Fanlight bars
		for a: float in [PI * 0.25, PI * 0.75]:
			var tip := Vector2(cos(a) * w, shoulder - sin(a) * (shoulder - top))
			var n := Vector2(-(tip.y - shoulder), tip.x).normalized() * 1.2
			parts.append([PackedVector2Array([Vector2(0, shoulder) + n, tip + n, tip - n, Vector2(0, shoulder) - n]), Palette.SB_WALNUT, "bare"])
	parts.append([_rough(-w - 12, bottom + 4, w + 12, bottom + 11, 1.0), Palette.SB_WALNUT_LIGHT, "wood", Ink.Tier.INTERACTIVE])
	# Curtain rod with finials
	parts.append([_rect(-w - 30, top - 17, w + 30, top - 12), Palette.SB_WALNUT_DARK, "plain", Ink.Tier.FURNITURE])
	for side: float in [-1.0, 1.0]:
		parts.append([Ink.ellipse(Vector2(side * (w + 33), top - 14.5), 4.5, 4.5, 10), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE])
	# Heavy green curtains to the floor, gathered by gold tiebacks; billowing when open
	for side: float in [-1.0, 1.0]:
		var inner: float = side * (w - 8.0)
		var outer: float = side * (w + 26.0)
		var curtain := PackedVector2Array([Vector2(outer, top - 12), Vector2(inner, top - 12), Vector2(inner + side * 16.0 + sway * side, -80),
			Vector2(inner + side * 8.0 + sway * side * 1.5, -3), Vector2(outer + sway * side * 0.5, -2)])
		parts.append([curtain, Palette.SB_GREEN.darkened(0.04), "fabric", Ink.Tier.FURNITURE])
		var tie := Vector2((inner + outer) * 0.5 + side * 10.0, -80)
		parts.append([Ink.ellipse(tie, 6, 3, 10), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE])
		parts.append([PackedVector2Array([tie + Vector2(-2, 2), tie + Vector2(2, 2), tie + Vector2(3, 14), tie + Vector2(-3, 14)]), Palette.SB_GOLD.darkened(0.1), "bare"])
	return parts


## Rectangular patterned rug laid flat in the floor's perspective (concept target), kept muted
## so it stays below people and interactive props (readability review, 2026-11-15): terracotta
## border with gold beads, dusk-blue field, a parchment medallion and corner motifs, cream
## fringe at the two short ends. [param uv] is its centre; it covers u ±RUG_HALF.x, v ±RUG_HALF.y
## of floor (drawing only: rugs are walked over and block nothing).
static func _rug(uv: Vector2) -> Array:
	var s: float = RoomGeometry.scale_at(uv.y)
	var hu: float = RUG_HALF.x
	var hv: float = RUG_HALF.y
	var q := func(du: float, dv: float) -> Vector2:
		return _floor_point(uv, s, du, dv)
	var quad := func(u0: float, v0: float, u1: float, v1: float) -> PackedVector2Array:
		return PackedVector2Array([q.call(u0, v0), q.call(u1, v0), q.call(u1, v1), q.call(u0, v1)])
	var diamond := func(cu: float, cv: float, ru: float, rv: float) -> PackedVector2Array:
		return PackedVector2Array([q.call(cu, cv - rv), q.call(cu + ru, cv), q.call(cu, cv + rv), q.call(cu - ru, cv)])
	var parts: Array = [
		[quad.call(-hu, -hv, hu, hv), Palette.SB_TERRACOTTA.darkened(0.3), "plain", Ink.Tier.BACKGROUND],
		[quad.call(-hu + 0.024, -hv + 0.032, hu - 0.024, hv - 0.032), Palette.SB_DUSK_BLUE.darkened(0.22), "fabric", Ink.Tier.BACKGROUND],
		[diamond.call(0.0, 0.0, 0.07, 0.056), Palette.SB_PARCHMENT.darkened(0.28), "plain", Ink.Tier.BACKGROUND],
		[diamond.call(0.0, 0.0, 0.04, 0.032), Palette.SB_TERRACOTTA.darkened(0.28), "bare"],
		[diamond.call(0.0, 0.0, 0.015, 0.012), Palette.SB_CREAM.darkened(0.3), "bare"],
	]
	for cu: float in [-1.0, 1.0]:
		for cv: float in [-1.0, 1.0]:
			parts.append([diamond.call(cu * (hu - 0.07), cv * (hv - 0.065), 0.022, 0.018), Palette.SB_PARCHMENT.darkened(0.32), "bare"])
	for i: int in 11:
		var bu: float = lerpf(-hu + 0.03, hu - 0.03, float(i) / 10.0)
		for cv: float in [-1.0, 1.0]:
			parts.append([diamond.call(bu, cv * (hv - 0.016), 0.006, 0.006), Palette.SB_GOLD.darkened(0.25), "bare"])
	for i: int in 9:
		var fv: float = lerpf(-hv + 0.012, hv - 0.012, float(i) / 8.0)
		for side: float in [-1.0, 1.0]:
			var u0: float = side * hu
			parts.append([quad.call(minf(u0, u0 + side * 0.013), fv - 0.0035, maxf(u0, u0 + side * 0.013), fv + 0.0035), Palette.SB_CREAM.darkened(0.2), "bare"])
	return parts


## A floor point [param du], [param dv] away from [param uv], in the local, unscaled
## coordinates parts use (screen offset from the piece's foot divided by its depth scale).
static func _floor_point(uv: Vector2, s: float, du: float, dv: float) -> Vector2:
	return (RoomGeometry.to_screen(uv + Vector2(du, dv)) - RoomGeometry.to_screen(uv)) / s


## Tall walnut bookshelf, slightly leaning, books of uneven heights, a plant on top.
static func _bookshelf() -> Array:
	var parts: Array = [
		[PackedVector2Array([Vector2(-58, 0), Vector2(58, 0), Vector2(60, -206), Vector2(-54, -210)]), Palette.SB_WALNUT_DARK, "wood"],
		[_rough(-64, -218, 66, -206, 2.0), Palette.SB_WALNUT, "wood"],
	]
	var book: int = 0
	for row: int in 4:
		var floor_y: float = -14.0 - 48.0 * float(row)
		parts.append([_rect(-52, floor_y, 54, floor_y + 5), Palette.SB_WALNUT_LIGHT, "bare"])
		var x: float = -50.0
		while x < 44.0:
			var bw: float = 7.0 + 5.0 * Ink.noise1(float(book) * 0.9)
			var bh: float = 26.0 + 12.0 * Ink.noise1(float(book) * 1.7 + 3.0)
			var lean: float = 5.0 if book % 7 == 3 else 0.0
			parts.append([PackedVector2Array([Vector2(x, floor_y), Vector2(x + bw, floor_y), Vector2(x + bw + lean, floor_y - bh), Vector2(x + lean, floor_y - bh)]),
				Palette.SB_BOOKS[book % Palette.SB_BOOKS.size()], "plain", Ink.Tier.BACKGROUND])
			x += bw + 1.5 + lean
			book += 1
	parts.append([PackedVector2Array([Vector2(-40, -218), Vector2(-20, -218), Vector2(-23, -234), Vector2(-37, -234)]), Palette.SB_TERRACOTTA, "plain"])
	parts.append([Ink.ellipse(Vector2(-30, -244), 14, 10, 14), Palette.SB_OLIVE, "plain"])
	return parts


## Framed painting on the back wall: "portrait" (a stern ancestor with a magnificent
## moustache) or "landscape" (a dusky hill with a lone crooked tree).
static func _painting(variant: String) -> Array:
	if variant == "portrait":
		return [
			[Ink.ellipse(Vector2(0, -116), 30, 38, 20), Palette.SB_GOLD, "plain"],
			[Ink.ellipse(Vector2(0, -116), 23, 31, 20), Palette.SB_GREEN.darkened(0.25), "bare"],
			[PackedVector2Array([Vector2(-16, -86), Vector2(16, -86), Vector2(12, -104), Vector2(-12, -104)]), Palette.SB_CHARCOAL, "bare"],
			[Ink.ellipse(Vector2(0, -122), 10, 12, 14), Palette.SB_SKIN.darkened(0.15), "bare"],
			[PackedVector2Array([Vector2(-14, -116), Vector2(-2, -119), Vector2(0, -117), Vector2(2, -119), Vector2(14, -116), Vector2(2, -114), Vector2(-2, -114)]), Palette.SB_BROWN_GREY.darkened(0.2), "bare"],
			[_rect(-9, -138, 9, -131), Palette.SB_CHARCOAL, "bare"],
		]
	return [
		[_rough(-36, -146, 36, -92, 2.0), Palette.SB_GOLD, "plain"],
		[_rect(-29, -139, 29, -99), Palette.SB_PARCHMENT.lightened(0.15), "bare"],
		[PackedVector2Array([Vector2(-29, -99), Vector2(-29, -112), Vector2(-8, -122), Vector2(14, -114), Vector2(29, -118), Vector2(29, -99)]), Palette.SB_OLIVE, "bare"],
		[PackedVector2Array([Vector2(8, -114), Vector2(10, -132), Vector2(6, -136), Vector2(12, -134), Vector2(13, -114)]), Palette.SB_CHARCOAL, "bare"],
		[Ink.ellipse(Vector2(-16, -130), 4, 4, 10), Palette.SB_CANDLELIGHT, "bare"],
	]


## Pendulum wall clock; the pendulum swings with time.
static func _clock(time: float) -> Array:
	var swing: float = sin(time * PI) * 7.0
	return [
		[_arch(-16, 16, -64, -132, -146, 10), Palette.SB_WALNUT, "wood"],
		[Ink.ellipse(Vector2(0, -126), 12, 12, 18), Palette.SB_CREAM, "plain"],
		[PackedVector2Array([Vector2(-0.8, -126), Vector2(0.8, -126), Vector2(0.8, -134), Vector2(-0.8, -134)]), Palette.SB_CHARCOAL, "bare"],
		[PackedVector2Array([Vector2(0, -127), Vector2(6, -124), Vector2(6, -122.5), Vector2(0, -125.5)]), Palette.SB_CHARCOAL, "bare"],
		[_rect(-10, -108, 10, -70), Palette.SB_CHARCOAL.lightened(0.1), "bare"],
		[PackedVector2Array([Vector2(-0.8, -108), Vector2(0.8, -108), Vector2(swing + 0.8, -80), Vector2(swing - 0.8, -80)]), Palette.SB_GOLD, "bare"],
		[Ink.ellipse(Vector2(swing, -78), 4, 4, 10), Palette.SB_GOLD, "plain"],
	]


static func _draw_fire(canvas: CanvasItem, foot: Vector2, s: float, time: float, flames: bool = true) -> void:
	Ink.glow(canvas, foot + Vector2(0, -26) * s, Vector2(60, 34) * s, Color(Palette.SB_CANDLELIGHT, 0.6), 6)
	if not flames:
		return
	for k: int in 3:
		var x: float = (-16.0 + 16.0 * float(k)) * s
		var h: float = (34.0 + 10.0 * sin(time * (7.0 + float(k)) + float(k) * 2.0)) * s
		var lean: float = sin(time * 3.0 + float(k)) * 4.0 * s
		var flame := PackedVector2Array([foot + Vector2(x - 10.0 * s, -12.0 * s), foot + Vector2(x + 10.0 * s, -12.0 * s),
			foot + Vector2(x + 5.0 * s + lean, -12.0 * s - h * 0.6), foot + Vector2(x + lean * 1.6, -12.0 * s - h), foot + Vector2(x - 5.0 * s + lean, -12.0 * s - h * 0.6)])
		canvas.draw_colored_polygon(flame, Palette.SB_TERRACOTTA.lightened(0.15))
		var core: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in flame:
			core.append(foot + Vector2(x + lean * 0.5, -16.0 * s) + (p - foot - Vector2(x + lean * 0.5, -16.0 * s)) * 0.55)
		canvas.draw_colored_polygon(core, Palette.SB_FIRE_CORE)


static func _draw_smoke(canvas: CanvasItem, foot: Vector2, s: float, time: float) -> void:
	var points := PackedVector2Array()
	for i: int in 12:
		var t: float = float(i) / 11.0
		points.append(foot + Vector2(sin(t * 6.0 + time * 1.5) * 6.0, -14.0 - 50.0 * t) * s)
	canvas.draw_polyline(points, Color(Palette.SB_ASH, 0.35), 3.0 * s, true)
	canvas.draw_colored_polygon(Ink.ellipse(foot + Vector2(-6, -12) * s, 3 * s, 1.5 * s, 8), Color(Palette.SB_EMBER, 0.6 + 0.3 * sin(time * 2.0)))

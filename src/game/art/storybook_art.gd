## Code-drawn furniture in the Whimsical Gothic Storybook style (art direction 2026-11-15):
## organic shapes, brown hand-drawn contours by readability tier, soft shading, wood grain
## and woven fabric, the storybook palette. These are placeholders: any prop can be replaced
## by a painted sprite through [PropVisuals] without touching gameplay.
##
## The living room art-test props have their own designs: fireplace (burning / out), wingback
## armchairs, camelback sofa, tea tables, fringed floor lamp, curtained window, patterned
## rug, bookshelf, paintings, pendulum clock. Other kinds reuse [FurnitureArt]'s shapes,
## re-rendered with storybook ink, shading and texture.
##
## A piece is drawn with its foot at the floor position (wall pieces at the back wall's base)
## and scaled for depth. Each part is [polygon (local px), colour, surface, tier]; surface is
## "wood", "fabric", "plain" (shaded, outlined) or "bare" (flat fill, no contour).
class_name StorybookArt
extends RefCounted

const HIGHLIGHT_WIDTH: float = 9.0

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
	var parts: Array = _parts(kind, variant, state, is_day, time, tier)
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
	if kind == "fireplace" and state == &"burning":
		_draw_fire(canvas, foot, s, time)
	elif kind == "fireplace":
		_draw_smoke(canvas, foot, s, time)
	if kind == "floor_lamp" and state != &"out":
		Ink.glow(canvas, foot + Vector2(0, -128) * s, Vector2(40, 30) * s, Color(Palette.SB_CANDLELIGHT, 0.55), 5)


static func _place(poly: PackedVector2Array, foot: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in poly:
		out.append(foot + p * s)
	return out


static func _parts(kind: String, variant: String, state: StringName, is_day: bool, time: float, tier: Ink.Tier) -> Array:
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
			return _rug()
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

## Stone fireplace on the back wall: chimney breast, surround, arched firebox, mantel with a
## candle, a vase and a small framed photo; hearth slab on the floor.
static func _fireplace(state: StringName) -> Array:
	var burning: bool = state == &"burning"
	var parts: Array = [
		[_rect(-88, -168, 88, 0), Palette.SB_WALL.darkened(0.08), "plain", Ink.Tier.BACKGROUND],
		[_arch(-74, 74, 0, -96, -112, 14), Palette.SB_BROWN_GREY.lightened(0.18), "plain", Ink.Tier.FURNITURE],
		[_rough(-96, -124, 96, -110, 2.0), Palette.SB_WALNUT, "wood", Ink.Tier.FURNITURE],
		[_rect(-90, -110, 90, -104), Palette.SB_WALNUT_DARK, "bare"],
		[_arch(-46, 46, 0, -54, -72, 12), Palette.SB_CHARCOAL if burning else Palette.SB_CHARCOAL.darkened(0.25), "plain", Ink.Tier.FURNITURE],
		[PackedVector2Array([Vector2(-100, 0), Vector2(100, 0), Vector2(110, 12), Vector2(-112, 13)]), Palette.SB_BROWN_GREY, "plain", Ink.Tier.FURNITURE],
		# Logs
		[Ink.ellipse(Vector2(-12, -9), 26, 6, 14), Palette.SB_WALNUT_DARK, "wood", Ink.Tier.FURNITURE],
		[Ink.ellipse(Vector2(14, -13), 22, 5, 14), Palette.SB_WALNUT, "wood", Ink.Tier.FURNITURE],
		# Mantel things: candlestick + candle, a vase with a sprig, a small framed photo
		[_rect(-74, -134, -66, -124), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE],
		[_rect(-73, -152, -67, -134), Palette.SB_CREAM, "plain", Ink.Tier.FURNITURE],
		[PackedVector2Array([Vector2(52, -124), Vector2(64, -124), Vector2(67, -138), Vector2(61, -150), Vector2(55, -150), Vector2(49, -138)]), Palette.SB_ROSE, "plain", Ink.Tier.FURNITURE],
		[PackedVector2Array([Vector2(58, -150), Vector2(52, -164), Vector2(56, -165), Vector2(60, -152), Vector2(66, -166), Vector2(69, -164), Vector2(61, -150)]), Palette.SB_OLIVE, "bare"],
		[_rough(-20, -146, 2, -124, 1.0), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE],
		[_rect(-16, -142, -2, -128), Palette.SB_DUSK_BLUE.lightened(0.15), "bare"],
	]
	if burning:
		parts.append([Ink.ellipse(Vector2(-70, -156), 2.5, 4.5, 8), Palette.SB_CANDLELIGHT, "bare"])
	else:
		# Cold ash on the hearth floor
		parts.append([Ink.ellipse(Vector2(0, -5), 36, 4, 14), Palette.SB_ASH, "bare"])
	return parts


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


## Camelback sofa in faded green with three cushions and turned legs.
static func _sofa() -> Array:
	var cloth: Color = Palette.SB_GREEN
	var back := PackedVector2Array([Vector2(-112, -50), Vector2(-112, -84), Vector2(-70, -92), Vector2(-30, -104), Vector2(0, -108),
		Vector2(30, -104), Vector2(70, -92), Vector2(112, -84), Vector2(112, -50)])
	return [
		[_rect(-108, -10, -100, 0), Palette.SB_WALNUT_DARK, "wood"],
		[_rect(100, -10, 108, 0), Palette.SB_WALNUT_DARK, "wood"],
		[back, cloth.darkened(0.12), "fabric"],
		[_rough(-118, -56, 118, -10, 3.0), cloth, "fabric"],
		[_rough(-104, -66, -38, -50, 2.0), cloth.lightened(0.08), "fabric"],
		[_rough(-34, -68, 34, -50, 2.0), cloth.lightened(0.1), "fabric"],
		[_rough(38, -66, 104, -50, 2.0), cloth.lightened(0.08), "fabric"],
		[Ink.ellipse(Vector2(-118, -56), 12, 16, 12), cloth.darkened(0.06), "fabric"],
		[Ink.ellipse(Vector2(118, -56), 12, 16, 12), cloth.darkened(0.06), "fabric"],
		[_rough(-80, -86, -52, -64, 2.0), Palette.SB_ROSE, "fabric"],
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


## The window with heavy curtains, tiebacks and a valance; panes show day sky or a moonlit
## night; open swings the sash and lets the curtains billow.
static func _window(state: StringName, is_day: bool, time: float) -> Array:
	var open: bool = state == &"open"
	var glass: Color = Palette.SB_GLASS_DAY if is_day else Palette.SB_GLASS_NIGHT
	var w: float = 52.0
	var top: float = -150.0
	var bottom: float = -50.0
	var sway: float = sin(time * 2.3) * 5.0 if open else 0.0
	var parts: Array = [
		[_rect(-w - 6, top - 6, w + 6, bottom + 6), Palette.SB_WALNUT, "wood", Ink.Tier.INTERACTIVE],
		[_rect(-w, top, w, bottom), Palette.SB_CHARCOAL if open else glass, "plain", Ink.Tier.INTERACTIVE],
	]
	if not is_day and not open:
		parts.append([Ink.ellipse(Vector2(w * 0.45, top + 22), 9, 9, 14), Palette.SB_MOON, "bare"])
	if open:
		parts.append([PackedVector2Array([Vector2(-w, top), Vector2(-6, top + 12), Vector2(-6, bottom - 12), Vector2(-w, bottom)]), glass.darkened(0.2), "plain", Ink.Tier.INTERACTIVE])
	else:
		parts.append([_rect(-2, top, 2, bottom), Palette.SB_WALNUT, "bare"])
		parts.append([_rect(-w, (top + bottom) * 0.5 - 2, w, (top + bottom) * 0.5 + 2), Palette.SB_WALNUT, "bare"])
	parts.append([_rough(-w - 12, bottom + 4, w + 12, bottom + 11, 1.0), Palette.SB_WALNUT_LIGHT, "wood", Ink.Tier.INTERACTIVE])
	# Heavy curtains, gathered by gold tiebacks; billowing when the window is open
	for side: float in [-1.0, 1.0]:
		var inner: float = side * (w - 10.0)
		var outer: float = side * (w + 26.0)
		var curtain := PackedVector2Array([Vector2(outer, top - 12), Vector2(inner, top - 12), Vector2(inner + side * 14.0 + sway * side, -96),
			Vector2(inner + side * 6.0 + sway * side * 1.5, bottom + 18), Vector2(outer + sway * side * 0.5, bottom + 22)])
		parts.append([curtain, Palette.SB_TERRACOTTA.darkened(0.06), "fabric", Ink.Tier.FURNITURE])
		parts.append([Ink.ellipse(Vector2((inner + outer) * 0.5 + side * 8.0, -94), 6, 3, 10), Palette.SB_GOLD, "plain", Ink.Tier.FURNITURE])
	parts.append([_rough(-w - 32, top - 22, w + 32, top - 8, 2.0), Palette.SB_ROSE.darkened(0.1), "fabric", Ink.Tier.FURNITURE])
	return parts


## Patterned oval rug: rose border, terracotta field, gold medallion and diamond motifs.
static func _rug() -> Array:
	var parts: Array = [
		[Ink.ellipse(Vector2.ZERO, 196, 56, 40), Palette.SB_ROSE.darkened(0.12), "plain", Ink.Tier.BACKGROUND],
		[Ink.ellipse(Vector2.ZERO, 176, 47, 40), Palette.SB_TERRACOTTA.darkened(0.1), "fabric", Ink.Tier.BACKGROUND],
		[Ink.ellipse(Vector2.ZERO, 70, 19, 28), Palette.SB_GOLD.darkened(0.08), "plain", Ink.Tier.BACKGROUND],
		[Ink.ellipse(Vector2.ZERO, 46, 12, 24), Palette.SB_DUSK_BLUE.darkened(0.1), "bare"],
		[Ink.ellipse(Vector2.ZERO, 18, 5, 16), Palette.SB_CREAM.darkened(0.1), "bare"],
	]
	for i: int in 10:
		var a: float = TAU * float(i) / 10.0
		var at := Vector2(cos(a) * 128.0, sin(a) * 33.0)
		parts.append([PackedVector2Array([at + Vector2(0, -5), at + Vector2(7, 0), at + Vector2(0, 5), at + Vector2(-7, 0)]), Palette.SB_GOLD, "bare"])
	return parts


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


static func _draw_fire(canvas: CanvasItem, foot: Vector2, s: float, time: float) -> void:
	Ink.glow(canvas, foot + Vector2(0, -26) * s, Vector2(60, 34) * s, Color(Palette.SB_CANDLELIGHT, 0.6), 6)
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

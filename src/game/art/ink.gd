## Hand-drawn rendering helpers for the Whimsical Gothic Storybook style (art direction
## 2026-11-15): organic, slightly irregular contours of varying width in muted brown, fills
## with soft tonal shading and pigment variation, and light surface marks (wood grain,
## fabric weave). Everything is deterministic: the same [param seed] gives the same wobble
## every frame, so shapes never shimmer.
##
## Contour weight follows the readability hierarchy: characters and the ghost strongest,
## then interactive objects, then furniture, then background decoration (softest, lighter).
##
## [codeblock]
## Ink.shape(canvas, poly, Palette.SB_TERRACOTTA, Ink.Tier.INTERACTIVE, seed)
## Ink.wood_grain(canvas, poly, Palette.SB_WALNUT, seed)
## [/codeblock]
class_name Ink
extends RefCounted

enum Tier { CHARACTER, INTERACTIVE, FURNITURE, BACKGROUND }

## Contour width (px at scale 1) and opacity per tier.
const WIDTH: Dictionary = {Tier.CHARACTER: 2.8, Tier.INTERACTIVE: 2.4, Tier.FURNITURE: 1.7, Tier.BACKGROUND: 1.1}
const ALPHA: Dictionary = {Tier.CHARACTER: 1.0, Tier.INTERACTIVE: 0.95, Tier.FURNITURE: 0.8, Tier.BACKGROUND: 0.55}
## How far contours wander from the true shape, px.
const WOBBLE: float = 1.3
## Spacing of the points a contour is redrawn through, px.
const STEP: float = 9.0


## Fill plus contour.
static func shape(canvas: CanvasItem, poly: PackedVector2Array, color: Color, tier: Tier, seed: float, shade: float = 0.14) -> void:
	fill(canvas, poly, color, seed, shade)
	outline(canvas, poly, tier, seed)


## Fills [param poly] with soft vertical shading (lighter above, darker below) and slight
## per-point pigment variation. Falls back to a plain fill if the shape cannot be shaded.
static func fill(canvas: CanvasItem, poly: PackedVector2Array, color: Color, seed: float, shade: float = 0.14) -> void:
	if poly.size() < 3:
		return
	var points: PackedVector2Array = wobble(poly, seed, WOBBLE * 0.5)
	if Geometry2D.triangulate_polygon(points).is_empty():
		points = poly
		if Geometry2D.triangulate_polygon(points).is_empty():
			return
	var top: float = INF
	var bottom: float = -INF
	for p: Vector2 in points:
		top = minf(top, p.y)
		bottom = maxf(bottom, p.y)
	var height: float = maxf(1.0, bottom - top)
	var colors := PackedColorArray()
	for i: int in points.size():
		var t: float = (points[i].y - top) / height
		var tone: float = lerpf(shade * 0.6, -shade, t) + (noise1(seed * 3.1 + float(i) * 0.71) - 0.5) * 0.06
		colors.append(_tone(color, tone))
	canvas.draw_polygon(points, colors)


## A closed hand-drawn contour around [param poly], width varying along its length.
static func outline(canvas: CanvasItem, poly: PackedVector2Array, tier: Tier, seed: float, color: Color = Palette.SB_CONTOUR) -> void:
	if poly.size() < 2:
		return
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	line(canvas, closed, tier, seed, color)


## An open hand-drawn stroke through [param points].
static func line(canvas: CanvasItem, points: PackedVector2Array, tier: Tier, seed: float, color: Color = Palette.SB_CONTOUR, width_scale: float = 1.0) -> void:
	var path: PackedVector2Array = wobble_open(points, seed, WOBBLE)
	var base: float = float(WIDTH[tier]) * width_scale
	var ink: Color = Color(color, color.a * float(ALPHA[tier]))
	if tier == Tier.BACKGROUND:
		ink = Color(Palette.SB_CONTOUR_SOFT, Palette.SB_CONTOUR_SOFT.a * float(ALPHA[tier]))
	# Draw in short runs so the pressure (width) can change along the stroke.
	var run: int = 4
	var i: int = 0
	while i < path.size() - 1:
		var j: int = mini(i + run, path.size() - 1)
		var pressure: float = 0.65 + 0.7 * noise1(seed * 1.7 + float(i) * 0.37)
		canvas.draw_polyline(path.slice(i, j + 1), ink, maxf(0.6, base * pressure), true)
		i = j


## Faint, slightly wavy wood grain across a surface.
static func wood_grain(canvas: CanvasItem, poly: PackedVector2Array, color: Color, seed: float, lines: int = 4) -> void:
	var box: Rect2 = _bounds(poly)
	if box.size.y < 6.0 or box.size.x < 6.0:
		return
	var grain: Color = Color(color.darkened(0.35), 0.35)
	for k: int in lines:
		var y: float = box.position.y + box.size.y * (float(k) + 0.5 + (noise1(seed + float(k)) - 0.5) * 0.6) / float(lines)
		var points := PackedVector2Array()
		for step: int in 9:
			var x: float = box.position.x + box.size.x * (0.06 + 0.88 * float(step) / 8.0)
			points.append(Vector2(x, y + sin(float(step) * 0.9 + seed * 5.0 + float(k)) * 1.2))
		var inside: PackedVector2Array = _clip_inside(points, poly)
		if inside.size() >= 2:
			canvas.draw_polyline(inside, grain, 1.0, true)


## Faint woven texture (short diagonal strokes) for upholstery and curtains.
static func weave(canvas: CanvasItem, poly: PackedVector2Array, color: Color, seed: float, spacing: float = 9.0) -> void:
	var box: Rect2 = _bounds(poly)
	var mark: Color = Color(color.darkened(0.25), 0.28)
	var y: float = box.position.y + spacing * 0.5
	var row: int = 0
	while y < box.end.y:
		var x: float = box.position.x + spacing * (0.5 if row % 2 == 0 else 1.0)
		while x < box.end.x:
			var at := Vector2(x, y) + Vector2(noise1(seed + x * 0.13) - 0.5, noise1(seed + y * 0.17) - 0.5) * 2.0
			if Geometry2D.is_point_in_polygon(at, poly):
				canvas.draw_line(at, at + Vector2(2.5, -2.0), mark, 1.0, true)
			x += spacing
		y += spacing * 0.8
		row += 1


## A soft radial glow made of stacked translucent ellipses.
static func glow(canvas: CanvasItem, centre: Vector2, radius: Vector2, color: Color, rings: int = 6) -> void:
	for ring: int in rings:
		var t: float = 1.0 - float(ring) / float(rings)
		canvas.draw_colored_polygon(ellipse(centre, radius.x * t, radius.y * t, 28), Color(color, color.a / float(rings)))


## [param poly] redrawn through evenly spaced points, each nudged along the outline's normal.
static func wobble(poly: PackedVector2Array, seed: float, amount: float = WOBBLE) -> PackedVector2Array:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	var out: PackedVector2Array = wobble_open(closed, seed, amount)
	out.remove_at(out.size() - 1)
	return out


static func wobble_open(points: PackedVector2Array, seed: float, amount: float = WOBBLE) -> PackedVector2Array:
	var out := PackedVector2Array()
	var travelled: float = 0.0
	for i: int in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length: float = a.distance_to(b)
		var pieces: int = maxi(1, int(length / STEP))
		var normal: Vector2 = (b - a).orthogonal().normalized() if length > 0.001 else Vector2.ZERO
		for k: int in pieces:
			var t: float = float(k) / float(pieces)
			var offset: float = (noise1(seed * 2.3 + (travelled + length * t) * 0.045) - 0.5) * 2.0 * amount
			out.append(a.lerp(b, t) + normal * offset)
		travelled += length
	out.append(points[points.size() - 1])
	return out


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Smooth 1-D value noise in 0..1.
static func noise1(x: float) -> float:
	var i: float = floorf(x)
	var f: float = x - i
	var u: float = f * f * (3.0 - 2.0 * f)
	return lerpf(_hash(i), _hash(i + 1.0), u)


## A stable seed for something drawn at [param at] (screen or floor position).
static func seed_at(at: Vector2) -> float:
	return fposmod(at.x * 0.0173 + at.y * 0.0311, 97.0)


static func _hash(x: float) -> float:
	return fposmod(sin(x * 127.1 + 311.7) * 43758.5453, 1.0)


static func _tone(color: Color, amount: float) -> Color:
	return color.lightened(amount) if amount >= 0.0 else color.darkened(-amount)


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for p: Vector2 in poly:
		box = box.expand(p)
	return box


static func _clip_inside(points: PackedVector2Array, poly: PackedVector2Array) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for p: Vector2 in points:
		if Geometry2D.is_point_in_polygon(p, poly):
			kept.append(p)
	return kept

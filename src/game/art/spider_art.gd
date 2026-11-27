## Draws the attic spider from its [SpiderPose] (sprint 002, P4, task S2-05), and the hostile
## spider's web: the marked spot on the floor during the wind-up and the web in flight.
## The rig (user brief B2): the painted body and head ([constant BODY_PATH], generated 2026-11-27,
## its painted legs masked away) placed on the pose's body point; the eight legs drawn in code from
## the pose's hip / knee / foot points in the painting's charcoal and terracotta, so they bend
## freely. Without the image the whole spider is drawn in code.
class_name SpiderArt
extends RefCounted

const LEG_WIDTH: float = 4.5
const INK_EXTRA: float = 2.5
const BODY_PATH: String = "res://assets/art/props/attic/spider_body.png"
## In the body image (px): the abdomen's centre, the head's centre, the eyes.
const BODY_ABDOMEN := Vector2(88, 170)
const BODY_HEAD := Vector2(87.5, 47.5)
const BODY_EYES: Array[Vector2] = [Vector2(66, 16), Vector2(105, 16)]
## The painted body's own warm charcoal (sampled from [constant BODY_PATH] 2026-11-27: dark #29221e,
## mid #4f4b46), so the code legs match it; the palette's night charcoal (#343747) read navy beside
## it. A little lighter than the body's darks: the attic's light darkens it on screen.
const LEG_PAINTED := Color("4a3e36")
const LEG_SHINE := Color("6a5c52")

static var _body: Texture2D
static var _body_loaded: bool = false


## The painted body image, or null when there is none.
static func body_texture() -> Texture2D:
	if not _body_loaded:
		_body_loaded = true
		_body = load(BODY_PATH) as Texture2D if ResourceLoader.exists(BODY_PATH) else null
	return _body


## Where the body image goes: its abdomen on the pose's body point, scaled so its head lands on the
## pose's head (the rig's head offset × [param size]) at [param depth].
static func body_rect(pose: Dictionary, size: float, depth: float, foot: Vector2, tex_size: Vector2) -> Rect2:
	var k: float = absf(SpiderPose.HEAD_OFFSET) * size * depth / BODY_ABDOMEN.distance_to(BODY_HEAD)
	var abdomen: Vector2 = foot + Vector2(pose["body"]) * depth
	return Rect2(abdomen - BODY_ABDOMEN * k, tex_size * k)


## The spider at floor point [param foot] and [param depth], in [param pose], scaled by [param size].
## [param hostile] lights its eyes red; [param highlighted] adds the ghost's target outline.
static func draw(canvas: CanvasItem, foot: Vector2, depth: float, pose: Dictionary, size: float, hostile: bool, highlighted: bool) -> void:
	var at := func(p: Vector2) -> Vector2: return foot + p * depth
	var head: Vector2 = at.call(pose["head"])
	var body: Vector2 = at.call(pose["body"])
	var painted: Texture2D = body_texture()
	if painted != null:
		_draw_painted(canvas, foot, depth, pose, size, hostile, highlighted, painted)
		return
	canvas.draw_line(at.call(pose["thread_top"]), head + Vector2(0, -14.0 * size * depth), Color(Palette.SB_CREAM, 0.7), 1.5, true)
	for leg: Dictionary in pose["legs"]:
		var points := PackedVector2Array([at.call(leg["hip"]), at.call(leg["knee"]), at.call(leg["foot"])])
		canvas.draw_polyline(points, Palette.INK, (LEG_WIDTH + INK_EXTRA) * depth, true)
		canvas.draw_polyline(points, Palette.SB_CHARCOAL, LEG_WIDTH * depth, true)
	var abdomen: PackedVector2Array = Ink.ellipse(body, 30.0 * size * depth, 36.0 * size * depth, 22)
	var head_shape: PackedVector2Array = Ink.ellipse(head, 16.0 * size * depth, 14.0 * size * depth, 16)
	if highlighted:
		for shape: PackedVector2Array in [abdomen, head_shape]:
			canvas.draw_polyline(shape + PackedVector2Array([shape[0]]), Palette.HIGHLIGHT, 9.0, true)
	for shape: Array in [[abdomen, Palette.SB_CHARCOAL.lightened(0.08)], [head_shape, Palette.SB_CHARCOAL]]:
		var poly: PackedVector2Array = shape[0]
		canvas.draw_colored_polygon(poly, shape[1])
		canvas.draw_polyline(poly + PackedVector2Array([poly[0]]), Palette.INK, 2.5, true)
	canvas.draw_colored_polygon(Ink.ellipse(body, 9.0 * size * depth, 13.0 * size * depth, 12), Palette.SB_TERRACOTTA.darkened(0.25))
	var eye: Color = Palette.SB_EMBER.lightened(0.3) if hostile else Palette.SB_CANDLELIGHT
	for side: float in [-6.0, 6.0]:
		canvas.draw_colored_polygon(Ink.ellipse(head + Vector2(side, 4.0) * size * depth, 3.5 * depth, 3.5 * depth, 8), eye)


static func _draw_painted(canvas: CanvasItem, foot: Vector2, depth: float, pose: Dictionary, size: float, hostile: bool,
		highlighted: bool, texture: Texture2D) -> void:
	var rect: Rect2 = body_rect(pose, size, depth, foot, texture.get_size())
	var k: float = rect.size.x / texture.get_size().x
	# the wind-up rears the head: lift the painted body by half the head's extra rise
	var rest_head: Vector2 = Vector2(pose["body"]) + Vector2(0, SpiderPose.HEAD_OFFSET * size)
	rect.position.y += (Vector2(pose["head"]).y - rest_head.y) * depth * 0.5
	canvas.draw_line(foot + Vector2(pose["thread_top"]) * depth, rect.position + Vector2(rect.size.x * 0.5, 4.0 * k),
		Color(Palette.SB_CREAM, 0.7), 1.5, true)
	var width: float = LEG_WIDTH * 1.3 * size * depth
	for leg: Dictionary in pose["legs"]:
		var hip: Vector2 = foot + Vector2(leg["hip"]) * depth
		var knee: Vector2 = foot + Vector2(leg["knee"]) * depth
		var tip: Vector2 = foot + Vector2(leg["foot"]) * depth
		var points := PackedVector2Array([hip, knee, tip])
		canvas.draw_polyline(points, Palette.INK, width + INK_EXTRA, true)
		canvas.draw_polyline(points, LEG_PAINTED, width, true)
		canvas.draw_polyline(points, LEG_SHINE, width * 0.3, true)   # a thin highlight along the leg
		for band: Vector2 in [hip.lerp(knee, 0.85), knee.lerp(tip, 0.45)]:   # the painting's terracotta joint bands
			canvas.draw_circle(band, width * 0.55, Palette.SB_TERRACOTTA.darkened(0.1))
	if highlighted:
		var abdomen: Vector2 = rect.position + BODY_ABDOMEN * k
		var outline: PackedVector2Array = Ink.ellipse(abdomen, 92.0 * k, 92.0 * k, 24)
		canvas.draw_polyline(outline + PackedVector2Array([outline[0]]), Palette.HIGHLIGHT, 9.0, true)
	canvas.draw_texture_rect(texture, rect, false)
	if hostile:
		for eye: Vector2 in BODY_EYES:
			canvas.draw_circle(rect.position + eye * k, 9.0 * k, Color(Palette.SB_EMBER.lightened(0.2), 0.75))


## The hostile spider's attack: during the wind-up a pale web mark on the floor at [param target]
## (screen point, depth [param depth]); in flight a web ball from [param mouth] toward it,
## [param progress] 0..1 of the way.
static func draw_web(canvas: CanvasItem, phase: SpiderWeb.Phase, mouth: Vector2, target: Vector2, depth: float, progress: float, t: float) -> void:
	if phase == SpiderWeb.Phase.TELEGRAPH:
		var grow: float = 0.85 + 0.15 * sin(t * 9.0)
		var r: float = 34.0 * depth * grow
		canvas.draw_colored_polygon(Ink.ellipse(target, r, r * 0.45, 20), Color(Palette.SB_CREAM, 0.18))
		for k: int in 8:
			var a: float = TAU * float(k) / 8.0
			canvas.draw_line(target, target + Vector2(cos(a) * r, sin(a) * r * 0.45), Color(Palette.SB_CREAM, 0.55), 1.2, true)
		canvas.draw_arc(target, r * 0.6, 0.0, TAU, 20, Color(Palette.SB_CREAM, 0.45), 1.2, true)
	elif phase == SpiderWeb.Phase.FLIGHT:
		var ball: Vector2 = mouth.lerp(target, progress)
		canvas.draw_line(mouth, ball, Color(Palette.SB_CREAM, 0.6), 1.5, true)
		canvas.draw_circle(ball, 9.0 * depth, Color(Palette.SB_CREAM, 0.85))
		canvas.draw_arc(ball, 9.0 * depth, 0.0, TAU, 14, Palette.INK, 1.5, true)

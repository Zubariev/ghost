## The six family members and the ghost, drawn in code as original placeholder figures.
## Each person has a distinct silhouette: father tall with a flat cap and overalls; mother
## with a headscarf and rolled sleeves; grandma short with a grey bun and shawl; grandpa
## thin and bald with glasses and a cane; the son in a striped jumper with messy hair; the
## daughter small with two pigtails (on a tricycle when riding).
class_name FamilyArt
extends RefCounted

const SKIN := Color("ecd2b4")
const OUTLINE: float = 2.5

## npc id -> look: body colour, height, build, hair colour
const LOOKS: Dictionary = {
	"father": {"body": Color("3f5573"), "height": 1.18, "width": 1.15, "hair": Color("3a2a1e")},
	"mother": {"body": Color("4f6a46"), "height": 1.05, "width": 0.95, "hair": Color("5a3a22")},
	"grandma": {"body": Color("5c3049"), "height": 0.92, "width": 1.12, "hair": Color("b9b5b0")},
	"grandpa": {"body": Color("6b5a40"), "height": 1.08, "width": 0.85, "hair": Color("d8d4cc")},
	"son": {"body": Color("a0453a"), "height": 0.82, "width": 0.88, "hair": Color("4a3020")},
	"daughter": {"body": Color("d8b04a"), "height": 0.68, "width": 0.80, "hair": Color("8a5a2a")},
}


## Draws one family member standing (or posed) at [param foot].
## [param pose]: "stand", "walk", "sit", "sleep", "broken", "tricycle".
static func draw_person(canvas: CanvasItem, npc_id: String, foot: Vector2, s: float, pose: String, phase: float, facing_left: bool) -> void:
	var look: Dictionary = LOOKS.get(npc_id, LOOKS["mother"])
	var h: float = float(look["height"]) * s
	var w: float = float(look["width"]) * s
	if pose != "sleep":
		canvas.draw_colored_polygon(_ellipse(foot, 20 * w, 6 * s), Palette.SHADOW)
	if pose == "sleep":
		_draw_sleeping(canvas, foot, s, look)
		return
	var sit: bool = pose in ["sit", "broken"]
	var bob: float = absf(sin(phase)) * -2.0 * s if pose == "walk" else 0.0
	var swing: float = sin(phase) * 7.0 * s if pose == "walk" else 0.0
	var hip := foot + Vector2(0, (-20.0 if sit else -34.0) * h + bob)
	if pose == "tricycle":
		_draw_tricycle(canvas, foot, s, phase)
		hip = foot + Vector2(0, -40 * s)
	# Legs
	if sit:
		canvas.draw_line(hip + Vector2(-6 * w, 0), foot + Vector2(-16 * w, -2), Palette.INK, 4.0 * s, true)
		canvas.draw_line(hip + Vector2(6 * w, 0), foot + Vector2(16 * w, -2), Palette.INK, 4.0 * s, true)
	elif pose != "tricycle":
		canvas.draw_line(hip + Vector2(-6 * w, 0), foot + Vector2(-6 * w + swing, 0), Palette.INK, 4.0 * s, true)
		canvas.draw_line(hip + Vector2(6 * w, 0), foot + Vector2(6 * w - swing, 0), Palette.INK, 4.0 * s, true)
	# Body
	var shoulder := hip + Vector2(0, -46 * h)
	var body := PackedVector2Array([hip + Vector2(-20 * w, 4), hip + Vector2(20 * w, 4), shoulder + Vector2(13 * w, 0), shoulder + Vector2(-13 * w, 0)])
	canvas.draw_colored_polygon(body, look["body"])
	_details_body(canvas, npc_id, hip, shoulder, w, h, s)
	_outline(canvas, body)
	# Arms
	if pose == "broken":
		canvas.draw_line(shoulder + Vector2(-12 * w, 4), shoulder + Vector2(-8 * w, -26 * h), Palette.INK, 4.0 * s, true)
		canvas.draw_line(shoulder + Vector2(12 * w, 4), shoulder + Vector2(8 * w, -26 * h), Palette.INK, 4.0 * s, true)
	else:
		canvas.draw_line(shoulder + Vector2(-13 * w, 4), hip + Vector2(-21 * w - swing * 0.5, -10), Palette.INK, 4.0 * s, true)
		canvas.draw_line(shoulder + Vector2(13 * w, 4), hip + Vector2(21 * w + swing * 0.5, -10), Palette.INK, 4.0 * s, true)
	if npc_id == "grandpa" and not sit:
		canvas.draw_line(hip + Vector2(24 * w, -10), foot + Vector2(26 * w, 0), Palette.WOOD_DARK, 3.0 * s, true)
	# Head
	var head_center := shoulder + Vector2(0, -15 * s)
	if pose == "broken":
		head_center += Vector2(0, 8 * s)
	var head := _ellipse(head_center, 13 * s, 15 * s)
	canvas.draw_colored_polygon(head, SKIN)
	_outline(canvas, head)
	_details_head(canvas, npc_id, head_center, s, look, facing_left, pose == "broken")


static func _details_body(canvas: CanvasItem, npc_id: String, hip: Vector2, shoulder: Vector2, w: float, h: float, s: float) -> void:
	match npc_id:
		"father":  # overall bib and straps
			canvas.draw_colored_polygon(PackedVector2Array([hip + Vector2(-12 * w, 2), hip + Vector2(12 * w, 2), shoulder + Vector2(8 * w, 18 * h), shoulder + Vector2(-8 * w, 18 * h)]), Color("2c3d55"))
			canvas.draw_line(shoulder + Vector2(-8 * w, 18 * h), shoulder + Vector2(-10 * w, 0), Color("2c3d55"), 3.0 * s)
			canvas.draw_line(shoulder + Vector2(8 * w, 18 * h), shoulder + Vector2(10 * w, 0), Color("2c3d55"), 3.0 * s)
		"grandma":  # shawl over the shoulders
			canvas.draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-16 * w, 0), shoulder + Vector2(16 * w, 0), shoulder + Vector2(0, 22 * h)]), Color("8a7a9a"))
		"grandpa":  # waistcoat
			canvas.draw_colored_polygon(PackedVector2Array([hip + Vector2(-10 * w, 0), hip + Vector2(10 * w, 0), shoulder + Vector2(6 * w, 4), shoulder + Vector2(-6 * w, 4)]), Color("4a3e2c"))
		"son":  # jumper stripes
			for i: int in 3:
				var y: float = lerpf(hip.y, shoulder.y, 0.25 + i * 0.22)
				canvas.draw_line(Vector2(hip.x - 15 * w, y), Vector2(hip.x + 15 * w, y), Color("e8d8b0"), 3.0 * s)
		"mother":  # rolled sleeves: light cuffs
			canvas.draw_line(shoulder + Vector2(-14 * w, 14 * h), shoulder + Vector2(-16 * w, 20 * h), Palette.LINEN, 4.0 * s)
			canvas.draw_line(shoulder + Vector2(14 * w, 14 * h), shoulder + Vector2(16 * w, 20 * h), Palette.LINEN, 4.0 * s)


static func _details_head(canvas: CanvasItem, npc_id: String, c: Vector2, s: float, look: Dictionary, facing_left: bool, broken: bool) -> void:
	var hair: Color = look["hair"]
	match npc_id:
		"father":  # flat cap with a peak
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -6) * s, c + Vector2(15, -6) * s, c + Vector2(12, -17) * s, c + Vector2(-12, -17) * s]), Color("4b4038"))
			var peak: float = -1.0 if facing_left else 1.0
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(4 * peak, -7) * s, c + Vector2(22 * peak, -5) * s, c + Vector2(4 * peak, -2) * s]), Color("3a3028"))
			canvas.draw_line(c + Vector2(-6, 7) * s, c + Vector2(6, 7) * s, hair, 3.0 * s)
		"mother":  # headscarf
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -2) * s, c + Vector2(-13, -14) * s, c + Vector2(0, -19) * s, c + Vector2(13, -14) * s, c + Vector2(15, -2) * s]), Color("b4503c"))
			canvas.draw_colored_polygon(_ellipse(c + Vector2(15, 0) * s, 4 * s, 3 * s), Color("b4503c"))
		"grandma":  # bun
			canvas.draw_colored_polygon(_ellipse(c + Vector2(0, -9) * s, 14 * s, 9 * s), hair)
			canvas.draw_colored_polygon(_ellipse(c + Vector2(0, -21) * s, 7 * s, 6 * s), hair)
		"grandpa":  # white side hair, glasses
			canvas.draw_colored_polygon(_ellipse(c + Vector2(-12, -2) * s, 4 * s, 6 * s), hair)
			canvas.draw_colored_polygon(_ellipse(c + Vector2(12, -2) * s, 4 * s, 6 * s), hair)
			canvas.draw_arc(c + Vector2(-5, 1) * s, 4.5 * s, 0, TAU, 12, Palette.INK, 1.5 * s)
			canvas.draw_arc(c + Vector2(5, 1) * s, 4.5 * s, 0, TAU, 12, Palette.INK, 1.5 * s)
		"son":  # messy hair spikes
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -4) * s, c + Vector2(-10, -18) * s, c + Vector2(-4, -12) * s, c + Vector2(1, -20) * s, c + Vector2(6, -12) * s, c + Vector2(12, -17) * s, c + Vector2(13, -4) * s]), hair)
		"daughter":  # two pigtails
			canvas.draw_colored_polygon(_ellipse(c + Vector2(0, -8) * s, 13 * s, 8 * s), hair)
			canvas.draw_colored_polygon(_ellipse(c + Vector2(-17, 2) * s, 5 * s, 8 * s), hair)
			canvas.draw_colored_polygon(_ellipse(c + Vector2(17, 2) * s, 5 * s, 8 * s), hair)
	if broken:
		canvas.draw_line(c + Vector2(-7, 2) * s, c + Vector2(-3, 4) * s, Palette.INK, 2.0 * s)
		canvas.draw_line(c + Vector2(3, 4) * s, c + Vector2(7, 2) * s, Palette.INK, 2.0 * s)
	else:
		var look_x: float = -2.0 if facing_left else 2.0
		canvas.draw_colored_polygon(_ellipse(c + Vector2(-5 + look_x, 2) * s, 1.8 * s, 2.4 * s), Palette.INK)
		canvas.draw_colored_polygon(_ellipse(c + Vector2(5 + look_x, 2) * s, 1.8 * s, 2.4 * s), Palette.INK)


## Lying in bed: [param foot] is the bed's foot point; the head rests on the pillow and the
## body is a bump under the blanket (matches FurnitureArt's bed shapes).
static func _draw_sleeping(canvas: CanvasItem, foot: Vector2, s: float, look: Dictionary) -> void:
	var bump := _ellipse(foot + Vector2(0, -78) * s, 30 * s, 22 * s)
	canvas.draw_colored_polygon(bump, Color(look["body"]).darkened(0.25))
	_outline(canvas, bump)
	var head := _ellipse(foot + Vector2(0, -116) * s, 12 * s, 10 * s)
	canvas.draw_colored_polygon(head, SKIN)
	_outline(canvas, head)
	canvas.draw_colored_polygon(_ellipse(foot + Vector2(0, -123) * s, 12 * s, 6 * s), look["hair"])
	canvas.draw_string(ThemeDB.fallback_font, foot + Vector2(14, -132) * s, "z z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * s), Color(1, 1, 1, 0.8))


static func _draw_tricycle(canvas: CanvasItem, foot: Vector2, s: float, phase: float) -> void:
	for wheel: Vector2 in [Vector2(-22, -10), Vector2(24, -14)]:
		var r: float = (10.0 if wheel.x < 0 else 14.0) * s
		canvas.draw_arc(foot + wheel * s, r, 0, TAU, 16, Palette.INK, 3.0 * s)
		canvas.draw_line(foot + wheel * s, foot + wheel * s + Vector2(cos(phase), sin(phase)) * r, Palette.INK, 1.5 * s)
	canvas.draw_line(foot + Vector2(-22, -10) * s, foot + Vector2(24, -14) * s, Color("c0392b"), 4.0 * s)
	canvas.draw_line(foot + Vector2(18, -14) * s, foot + Vector2(20, -46) * s, Color("c0392b"), 3.0 * s)


## The ghost: a floating sheet with dark eyes. Its node position is the floor point below it.
static func draw_ghost(canvas: CanvasItem, foot: Vector2, s: float, time: float, over_floor: bool) -> void:
	var bob: float = sin(time * 3.0) * 5.0
	if over_floor:
		canvas.draw_colored_polygon(_ellipse(foot, (24.0 - bob) * s, 7 * s), Palette.SHADOW)
	var head := foot + Vector2(0, -72 + bob) * s
	var body := PackedVector2Array()
	for i: int in 13:
		var a: float = PI + PI * float(i) / 12.0
		body.append(head + Vector2(cos(a), sin(a)) * 26.0 * s)
	body.append(foot + Vector2(30, -26 + bob) * s)
	for i: int in 9:
		var x: float = 30.0 - 60.0 * float(i) / 8.0
		var y: float = -18.0 + bob + (6.0 if i % 2 == 0 else -4.0) + sin(time * 4.0 + float(i)) * 2.0
		body.append(foot + Vector2(x, y) * s)
	body.append(foot + Vector2(-30, -26 + bob) * s)
	canvas.draw_colored_polygon(body, Color(0.93, 0.96, 1.0, 0.84))
	var closed: PackedVector2Array = body.duplicate()
	closed.append(body[0])
	canvas.draw_polyline(closed, Color(0.16, 0.18, 0.32, 0.9), 2.5, true)
	canvas.draw_colored_polygon(_ellipse(head + Vector2(-9, 2) * s, 4.5 * s, 6.5 * s), Color(0.16, 0.18, 0.32))
	canvas.draw_colored_polygon(_ellipse(head + Vector2(9, 2) * s, 4.5 * s, 6.5 * s), Color(0.16, 0.18, 0.32))
	canvas.draw_colored_polygon(_ellipse(head + Vector2(0, 17) * s, 3.5 * s, 4.5 * s), Color(0.16, 0.18, 0.32))


static func _ellipse(c: Vector2, rx: float, ry: float, n: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _outline(canvas: CanvasItem, poly: PackedVector2Array) -> void:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	canvas.draw_polyline(closed, Palette.INK, OUTLINE, true)

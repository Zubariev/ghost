## Draws the house's furniture as flat, ink-outlined shapes (original placeholder art).
## Every piece is drawn at its foot point on the floor, scaled for depth. Wall pieces
## (windows) are drawn on the back wall at their u.
class_name FurnitureArt
extends RefCounted

const OUTLINE: float = 2.5
const HIGHLIGHT_WIDTH: float = 9.0


## Draws one piece. [param state] is its sim object's state ("" for plain furniture);
## [param highlighted] draws the ghost's target outline under it.
static func draw(canvas: CanvasItem, kind: String, uv: Vector2, state: StringName, highlighted: bool, is_day: bool) -> void:
	var foot: Vector2 = RoomGeometry.to_screen(uv)
	var s: float = RoomGeometry.scale_at(uv.y)
	var parts: Array = _parts(kind, uv, state, is_day)
	if highlighted:
		for part: Array in parts:
			canvas.draw_polyline(_closed(_place(part[0], foot, s, kind == "window")), Palette.HIGHLIGHT, HIGHLIGHT_WIDTH, true)
	for part: Array in parts:
		var poly: PackedVector2Array = _place(part[0], foot, s, kind == "window")
		canvas.draw_colored_polygon(poly, part[1])
		canvas.draw_polyline(_closed(poly), Palette.INK, OUTLINE, true)


## Rugs lie flat under everything else.
static func is_flat(kind: String) -> bool:
	return kind == "rug"


## Pieces hung on or standing against the back wall, drawn before anything on the floor.
static func is_wall(kind: String) -> bool:
	return kind == "window"


static func _place(poly: PackedVector2Array, foot: Vector2, s: float, on_wall: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in poly:
		out.append(p if on_wall else foot + p * s)
	return out


static func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var c: PackedVector2Array = poly.duplicate()
	c.append(poly[0])
	return c


static func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c, d])


static func _ellipse(c: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## A box seen from the front and a little above: [front face, top face].
static func _box(w: float, h: float, depth: float, front: Color, top: Color) -> Array:
	var hw: float = w * 0.5
	var inset: float = depth * 0.25
	return [
		[_quad(Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw - inset, -h - depth), Vector2(-hw + inset, -h - depth)), top],
		[_rect(-hw, -h, hw, 0), front],
	]


static func _parts(kind: String, uv: Vector2, state: StringName, is_day: bool) -> Array:
	match kind:
		"window":
			return _window(uv, state, is_day)
		"floor_lamp":
			var shade: Color = Palette.SHADE_LIT if state != &"out" else Palette.SHADE_OUT
			return [
				[_ellipse(Vector2(0, -4), 20, 6), Palette.BRASS],
				[_rect(-3, -124, 3, -6), Palette.BRASS_DARK],
				[_quad(Vector2(-34, -116), Vector2(34, -116), Vector2(20, -164), Vector2(-20, -164)), shade],
			]
		"stove":
			var door: Color = Color("5a3422") if state != &"broken" else Color("1a1a1e")
			var parts: Array = [[_rect(-9, -290, 9, -116), Palette.IRON]]
			parts += _box(124, 80, 30, Palette.IRON, Palette.IRON_TOP)
			parts += [
				[_ellipse(Vector2(-24, -95), 15, 5), Palette.IRON_DARK],
				[_ellipse(Vector2(24, -95), 15, 5), Palette.IRON_DARK],
				[_rect(-40, -66, 40, -18), Palette.IRON_TOP],
				[_rect(-26, -56, 26, -32), door],
			]
			if state == &"broken":
				parts.append([PackedVector2Array([Vector2(-30, -78), Vector2(-6, -60), Vector2(-16, -50), Vector2(10, -28), Vector2(-24, -46), Vector2(-14, -58)]), Color("e0735f")])
			return parts
		"basket":
			if state == &"hidden":
				return [[_ellipse(Vector2(0, -2), 26, 6), Color(0, 0, 0, 0.25)]]
			return [
				[_quad(Vector2(-30, -36), Vector2(30, -36), Vector2(24, 0), Vector2(-24, 0)), Palette.WOOD_LIGHT],
				[_ellipse(Vector2(-10, -40), 10, 8), Color("c0603a")],
				[_ellipse(Vector2(10, -42), 9, 9), Color("d8b04a")],
				[_rect(-30, -38, 30, -32), Palette.WOOD],
			]
		"counter":
			return _box(160, 74, 26, Palette.WOOD, Palette.LINEN)
		"kitchen_table", "side_table":
			var w: float = 120.0 if kind == "kitchen_table" else 56.0
			return _table(w, 60.0, Palette.WOOD_LIGHT)
		"dining_table":
			var parts: Array = _table(210.0, 62.0, Palette.WOOD_LIGHT)
			if state == &"ready":
				parts += [
					[_ellipse(Vector2(-50, -84), 18, 6), Palette.PORCELAIN],
					[_ellipse(Vector2(0, -88), 20, 7), Color("c98b4a")],
					[_ellipse(Vector2(50, -84), 18, 6), Palette.PORCELAIN],
				]
			return parts
		"chair":
			return [
				[_rect(-18, -104, 18, -58), Palette.WOOD_DARK],
				[_quad(Vector2(-22, -42), Vector2(22, -42), Vector2(18, -58), Vector2(-18, -58)), Palette.WOOD],
				[_rect(-20, -42, -15, 0), Palette.WOOD_DARK],
				[_rect(15, -42, 20, 0), Palette.WOOD_DARK],
			]
		"sideboard", "chest", "toy_box", "crate":
			var colors: Dictionary = {"sideboard": Palette.WOOD_DARK, "chest": Palette.WOOD, "toy_box": Palette.FABRIC_BLUE, "crate": Palette.WOOD_LIGHT}
			var size: Dictionary = {"sideboard": Vector2(150, 80), "chest": Vector2(110, 52), "toy_box": Vector2(80, 50), "crate": Vector2(70, 56)}
			return _box(size[kind].x, size[kind].y, 22, colors[kind], Palette.WOOD_LIGHT)
		"rug":
			return [
				[_ellipse(Vector2.ZERO, 190, 52, 36), Palette.RUG_BORDER],
				[_ellipse(Vector2.ZERO, 170, 44, 36), Palette.RUG],
			]
		"sofa":
			return [
				[_rect(-110, -96, 110, -50), Palette.FABRIC_GREEN],
				[_rect(-120, -60, 120, 0), Palette.FABRIC_GREEN.darkened(0.15)],
				[_rect(-128, -76, -104, 0), Palette.FABRIC_GREEN.darkened(0.3)],
				[_rect(104, -76, 128, 0), Palette.FABRIC_GREEN.darkened(0.3)],
			]
		"armchair", "reading_chair":
			var fabric: Color = Palette.FABRIC_RED if kind == "armchair" else Palette.FABRIC_BLUE
			return [
				[_rect(-36, -100, 36, -46), fabric],
				[_rect(-44, -54, 44, 0), fabric.darkened(0.15)],
				[_rect(-50, -70, -36, 0), fabric.darkened(0.3)],
				[_rect(36, -70, 50, 0), fabric.darkened(0.3)],
			]
		"rocking_chair":
			return [
				[_rect(-22, -110, 22, -56), Palette.WOOD],
				[_quad(Vector2(-26, -44), Vector2(26, -44), Vector2(22, -58), Vector2(-22, -58)), Palette.WOOD_LIGHT],
				[PackedVector2Array([Vector2(-34, -2), Vector2(34, -2), Vector2(26, 4), Vector2(-26, 4)]), Palette.WOOD_DARK],
				[_rect(-22, -44, -17, -2), Palette.WOOD_DARK],
				[_rect(17, -44, 22, -2), Palette.WOOD_DARK],
			]
		"workbench":
			var parts: Array = _table(190.0, 70.0, Palette.WOOD)
			parts += [[_rect(-60, -100, -20, -84), Palette.IRON], [_rect(20, -96, 70, -88), Palette.BRASS_DARK]]
			return parts
		"tool_rack", "bookshelf":
			var parts: Array = [[_rect(-60, -200, 60, 0), Palette.WOOD_DARK]]
			for row: int in 4:
				var y: float = -190.0 + row * 48.0
				if kind == "bookshelf":
					for b: int in 7:
						parts.append([_rect(-52 + b * 15, y, -40 + b * 15, y + 38), Palette.BOOK_COLORS[(b + row) % Palette.BOOK_COLORS.size()]])
				else:
					parts.append([_rect(-48 + row * 10, y + 8, -30 + row * 10, y + 40), Palette.IRON_TOP])
					parts.append([_rect(10, y + 14, 46, y + 22), Palette.BRASS_DARK])
				parts.append([_rect(-60, y + 38, 60, y + 44), Palette.WOOD])
			return parts
		"stairs":
			var parts: Array = []
			for step: int in 6:
				var y: float = -float(step) * 30.0
				parts.append([_rect(-70 + step * 4, y - 30, 70 - step * 4, y), Palette.WOOD if step % 2 == 0 else Palette.WOOD_LIGHT])
			parts.append([_rect(-78, -190, -70, 0), Palette.WOOD_DARK])
			return parts
		"coat_stand":
			return [
				[_ellipse(Vector2(0, -2), 18, 5), Palette.WOOD_DARK],
				[_rect(-3, -150, 3, -2), Palette.WOOD_DARK],
				[_quad(Vector2(-24, -150), Vector2(4, -150), Vector2(10, -96), Vector2(-28, -96)), Palette.FABRIC_BLUE],
			]
		"double_bed", "bed":
			var w: float = 200.0 if kind == "double_bed" else 110.0
			var hw: float = w * 0.5
			var blanket: Color = Palette.FABRIC_RED if kind == "double_bed" else Palette.FABRIC_BLUE
			return [
				[_rect(-hw + 6, -180, hw - 6, -120), Palette.WOOD_DARK],
				[_quad(Vector2(-hw, -40), Vector2(hw, -40), Vector2(hw - 10, -128), Vector2(-hw + 10, -128)), blanket],
				[_quad(Vector2(-hw + 22, -108), Vector2(hw - 22, -108), Vector2(hw - 28, -130), Vector2(-hw + 28, -130)), Palette.LINEN],
				[_rect(-hw - 4, -40, hw + 4, 0), Palette.WOOD],
			]
		"wardrobe":
			var parts: Array = _box(116, 210, 14, Palette.WOOD_DARK, Palette.WOOD)
			parts += [[_rect(-1.5, -200, 1.5, -12), Palette.INK], [_rect(-10, -112, -4, -104), Palette.BRASS], [_rect(4, -112, 10, -104), Palette.BRASS]]
			return parts
		"computer_desk":
			var screen: Color = Color("7fb4d6") if state != &"broken" else Color("1a1a1e")
			var parts: Array = _table(130.0, 66.0, Palette.WOOD)
			parts += [
				[_rect(-36, -150, 36, -94), Palette.IRON],
				[_rect(-30, -144, 30, -100), screen],
				[_rect(-6, -94, 6, -84), Palette.IRON],
				[_rect(-30, -86, 30, -80), Palette.IRON_TOP],
			]
			if state == &"broken":
				parts.append([PackedVector2Array([Vector2(-20, -140), Vector2(4, -120), Vector2(-6, -112), Vector2(18, -102), Vector2(-12, -118), Vector2(-2, -126)]), Color("e0735f")])
			return parts
		"easel":
			return [
				[_quad(Vector2(-26, 0), Vector2(-20, 0), Vector2(2, -130), Vector2(-4, -130)), Palette.WOOD],
				[_quad(Vector2(20, 0), Vector2(26, 0), Vector2(4, -130), Vector2(-2, -130)), Palette.WOOD],
				[_rect(-30, -120, 30, -70), Palette.LINEN],
				[_ellipse(Vector2(-6, -98), 10, 8), Color("e0a050")],
			]
		"bathtub":
			return [
				[_quad(Vector2(-110, -60), Vector2(110, -60), Vector2(100, -86), Vector2(-100, -86)), Palette.PORCELAIN.darkened(0.15)],
				[_rect(-110, -60, 110, -8), Palette.PORCELAIN],
				[_rect(-100, -8, -86, 0), Palette.BRASS_DARK],
				[_rect(86, -8, 100, 0), Palette.BRASS_DARK],
			]
		"sink":
			return [
				[_rect(-8, -80, 8, 0), Palette.PORCELAIN.darkened(0.1)],
				[_quad(Vector2(-36, -80), Vector2(36, -80), Vector2(30, -100), Vector2(-30, -100)), Palette.PORCELAIN],
				[_rect(-24, -170, 24, -110), Color("aab8c0")],
			]
		"dresser":
			var parts: Array = _box(96, 92, 16, Palette.WOOD, Palette.WOOD_LIGHT)
			for drawer: int in 3:
				var y: float = -84.0 + drawer * 28.0
				parts.append([_rect(-40, y, 40, y + 22), Palette.WOOD_DARK])
				parts.append([_rect(-5, y + 9, 5, y + 13), Palette.BRASS])
			if state == &"taken":
				parts.append([_rect(-42, -60, 42, -50), Palette.DOORWAY])
			return parts
		"door_front":
			return []
	push_warning("FurnitureArt: no art for '%s'" % kind)
	return [[_rect(-30, -60, 30, 0), Color("ff00ff")]]


static func _table(w: float, h: float, top_color: Color) -> Array:
	var hw: float = w * 0.5
	return [
		[_rect(-hw + 10, -h, -hw + 18, -h * 0.4), Palette.WOOD_DARK],
		[_rect(hw - 18, -h, hw - 10, -h * 0.4), Palette.WOOD_DARK],
		[_quad(Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw - 14, -h - 44), Vector2(-hw + 14, -h - 44)), top_color],
		[_rect(-hw, -h, hw, -h + 12), Palette.WOOD],
		[_rect(-hw + 4, -h + 12, -hw + 12, 0), Palette.WOOD],
		[_rect(hw - 12, -h + 12, hw - 4, 0), Palette.WOOD],
	]


## A window on the back wall at u; open shows the dark gap and a swung sash.
static func _window(uv: Vector2, state: StringName, is_day: bool) -> Array:
	var bl: Vector2 = RoomGeometry.back_wall_point(uv.x - 0.08, 0.30)
	var tr: Vector2 = RoomGeometry.back_wall_point(uv.x + 0.08, 0.88)
	var glass: Color = Palette.GLASS_DAY if is_day else Palette.GLASS_NIGHT
	var frame := _rect(bl.x, tr.y, tr.x, bl.y)
	var inner := _rect(bl.x + 8, tr.y + 8, tr.x - 8, bl.y - 8)
	var mid_x: float = (bl.x + tr.x) * 0.5
	var mid_y: float = (bl.y + tr.y) * 0.5
	if state == &"open":
		return [
			[frame, Palette.WOOD],
			[inner, Palette.DOORWAY],
			[_quad(Vector2(bl.x + 8, tr.y + 8), Vector2(mid_x, tr.y + 20), Vector2(mid_x, bl.y - 20), Vector2(bl.x + 8, bl.y - 8)), glass.darkened(0.2)],
			[_rect(bl.x - 6, bl.y - 2, tr.x + 6, bl.y + 6), Palette.WOOD_LIGHT],
		]
	return [
		[frame, Palette.WOOD],
		[inner, glass],
		[_rect(mid_x - 2, tr.y + 8, mid_x + 2, bl.y - 8), Palette.WOOD],
		[_rect(bl.x + 8, mid_y - 2, tr.x - 8, mid_y + 2), Palette.WOOD],
		[_rect(bl.x - 6, bl.y - 2, tr.x + 6, bl.y + 6), Palette.WOOD_LIGHT],
	]

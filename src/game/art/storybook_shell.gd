## The room itself — floor, walls, doors — in the Whimsical Gothic Storybook style (art test,
## 2026-11-15): aged-cream wallpaper with a faded damask motif, walnut wainscot with panel
## mouldings, a plank floor with slightly varied boards, soft painted contours, and wooden
## doors standing ajar. Same geometry as the placeholder shell ([RoomGeometry]); only the
## look differs. [param alpha] fades a wall the ghost is inside.
class_name StorybookShell
extends RefCounted

const PLANKS: int = 14
const WAINSCOT_HEIGHT: float = 0.36
## Damask motif spacing on the back wall, px.
const MOTIF_STEP := Vector2(34, 30)


static func draw_floor(canvas: CanvasItem) -> void:
	var edge := Vector2(0, RoomGeometry.FLOOR_EDGE)
	canvas.draw_colored_polygon(PackedVector2Array([RoomGeometry.FRONT_LEFT, RoomGeometry.FRONT_RIGHT,
		RoomGeometry.FRONT_RIGHT + edge, RoomGeometry.FRONT_LEFT + edge]), Palette.SB_WALNUT_DARK)
	for i: int in PLANKS:
		var u0: float = float(i) / float(PLANKS)
		var u1: float = float(i + 1) / float(PLANKS)
		var plank := PackedVector2Array([RoomGeometry.to_screen(Vector2(u0, 0)), RoomGeometry.to_screen(Vector2(u1, 0)),
			RoomGeometry.to_screen(Vector2(u1, 1)), RoomGeometry.to_screen(Vector2(u0, 1))])
		var tone: float = (Ink.noise1(float(i) * 1.9 + 0.3) - 0.5) * 0.16
		var color: Color = Palette.SB_FLOOR.lightened(tone) if tone >= 0.0 else Palette.SB_FLOOR.darkened(-tone)
		# Darker toward the back wall (further from the room's light).
		canvas.draw_polygon(plank, PackedColorArray([color.darkened(0.22), color.darkened(0.22), color, color]))
		Ink.wood_grain(canvas, plank, color, float(i) * 3.7, 5)
		# Staggered board ends
		var joint_v: float = 0.18 + 0.6 * Ink.noise1(float(i) * 2.3 + 5.0)
		Ink.line(canvas, PackedVector2Array([RoomGeometry.to_screen(Vector2(u0, joint_v)), RoomGeometry.to_screen(Vector2(u1, joint_v))]),
			Ink.Tier.BACKGROUND, float(i) + 11.0)
		Ink.line(canvas, PackedVector2Array([RoomGeometry.to_screen(Vector2(u0, 0)), RoomGeometry.to_screen(Vector2(u0, 1))]),
			Ink.Tier.BACKGROUND, float(i) * 1.3)
	Ink.outline(canvas, RoomGeometry.floor_polygon(), Ink.Tier.FURNITURE, 3.0)


static func draw_back_wall(canvas: CanvasItem, alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.back_wall_polygon()
	var top: Color = _a(Palette.SB_WALL.darkened(0.18), alpha)
	var bottom: Color = _a(Palette.SB_WALL, alpha)
	canvas.draw_polygon(poly, PackedColorArray([top, top, bottom, bottom]))
	# Faded damask: small diamond-and-dot motifs in staggered rows above the wainscot.
	var rail_y: float = RoomGeometry.BACK_LEFT.y - RoomGeometry.BACK_WALL_HEIGHT * WAINSCOT_HEIGHT
	var motif: Color = _a(Palette.SB_WALLPAPER_MOTIF, alpha)
	var y: float = poly[0].y + MOTIF_STEP.y * 0.6
	var row: int = 0
	while y < rail_y - 8.0:
		var x: float = RoomGeometry.BACK_LEFT.x + MOTIF_STEP.x * (0.5 if row % 2 == 0 else 1.0)
		while x < RoomGeometry.BACK_RIGHT.x - 6.0:
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 7), Vector2(x + 5, y), Vector2(x, y + 7), Vector2(x - 5, y)]), motif)
			canvas.draw_colored_polygon(Ink.ellipse(Vector2(x, y - 11), 1.6, 1.6, 8), motif)
			x += MOTIF_STEP.x
		y += MOTIF_STEP.y
		row += 1
	_wainscot(canvas, RoomGeometry.BACK_LEFT.x, RoomGeometry.BACK_RIGHT.x, rail_y, RoomGeometry.BACK_LEFT.y, alpha)
	Ink.outline(canvas, poly, Ink.Tier.FURNITURE, 1.0, _a(Palette.SB_CONTOUR, alpha))
	Ink.line(canvas, PackedVector2Array([poly[0], poly[1]]), Ink.Tier.FURNITURE, 2.0, _a(Palette.SB_WALNUT_DARK, alpha), 3.0)


static func draw_side_wall(canvas: CanvasItem, left: bool, alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.left_wall_polygon() if left else RoomGeometry.right_wall_polygon()
	# Shade darker toward the top and the front corner.
	var dark: Color = _a(Palette.SB_WALL_SIDE.darkened(0.3), alpha)
	var mid: Color = _a(Palette.SB_WALL_SIDE.darkened(0.1), alpha)
	var light: Color = _a(Palette.SB_WALL_SIDE, alpha)
	var colors := PackedColorArray([dark, mid, light, light.darkened(0.12)]) if left else PackedColorArray([mid, dark, light.darkened(0.12), light])
	canvas.draw_polygon(poly, colors)
	var band := PackedVector2Array([
		RoomGeometry.side_wall_point(left, 1.0, WAINSCOT_HEIGHT), RoomGeometry.side_wall_point(left, 0.0, WAINSCOT_HEIGHT),
		RoomGeometry.side_wall_point(left, 0.0, 0.0), RoomGeometry.side_wall_point(left, 1.0, 0.0)])
	canvas.draw_colored_polygon(band, _a(Palette.SB_WALNUT.darkened(0.12), alpha))
	Ink.wood_grain(canvas, band, Palette.SB_WALNUT, 21.0 if left else 23.0, 3)
	Ink.line(canvas, PackedVector2Array([band[0], band[1]]), Ink.Tier.FURNITURE, 5.0, _a(Palette.SB_GOLD.darkened(0.2), alpha), 1.4)
	Ink.outline(canvas, poly, Ink.Tier.FURNITURE, 4.0 if left else 6.0, _a(Palette.SB_CONTOUR, alpha))
	Ink.line(canvas, PackedVector2Array([poly[0], poly[1]]), Ink.Tier.FURNITURE, 7.0, _a(Palette.SB_WALNUT_DARK, alpha), 3.0)


## Doors where the family's doors are: wooden doors ajar on the side walls, an arched door
## on the back wall, an open gap at the front.
static func draw_doors(canvas: CanvasItem, house: HouseState, room_id: String, wall_alpha: Dictionary) -> void:
	for other: String in house.rooms:
		if house.walk_minutes(room_id, other) <= 0:
			continue
		var here: RoomState = house.rooms[room_id]
		var there: RoomState = house.rooms[other]
		if here.floor_level != there.floor_level:
			continue   # stairs are furniture
		var step: Vector2i = there.grid - here.grid
		if step.x != 0:
			var left: bool = step.x < 0
			_side_door(canvas, left, float(wall_alpha["left" if left else "right"]))
		elif step.y < 0:
			_back_door(canvas, float(wall_alpha["back"]))
		else:
			var a: Vector2 = RoomGeometry.to_screen(Vector2(0.44, 1.0))
			var b: Vector2 = RoomGeometry.to_screen(Vector2(0.56, 1.0))
			canvas.draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, RoomGeometry.FLOOR_EDGE), a + Vector2(0, RoomGeometry.FLOOR_EDGE)]), Palette.SB_CHARCOAL)


static func _side_door(canvas: CanvasItem, left: bool, alpha: float) -> void:
	var frame := PackedVector2Array([
		RoomGeometry.side_wall_point(left, 0.39, 0.64), RoomGeometry.side_wall_point(left, 0.61, 0.64),
		RoomGeometry.side_wall_point(left, 0.61, 0.0), RoomGeometry.side_wall_point(left, 0.39, 0.0)])
	var gap := PackedVector2Array([
		RoomGeometry.side_wall_point(left, 0.42, 0.59), RoomGeometry.side_wall_point(left, 0.58, 0.59),
		RoomGeometry.side_wall_point(left, 0.58, 0.0), RoomGeometry.side_wall_point(left, 0.42, 0.0)])
	Ink.fill(canvas, frame, _a(Palette.SB_WALNUT_DARK, alpha), 31.0)
	canvas.draw_colored_polygon(gap, _a(Palette.SB_CHARCOAL.darkened(0.2), alpha))
	# The door leaf, swung into the room a little, hinged at the back edge of the frame.
	var hinge_top: Vector2 = gap[0]
	var hinge_bottom: Vector2 = gap[3]
	var swing := Vector2(34, 8) if left else Vector2(-34, 8)
	var leaf := PackedVector2Array([hinge_top, hinge_top + swing + Vector2(0, -6), hinge_bottom + swing + Vector2(0, 4), hinge_bottom])
	Ink.fill(canvas, leaf, _a(Palette.SB_WALNUT, alpha), 37.0)
	Ink.wood_grain(canvas, leaf, Palette.SB_WALNUT, 41.0, 3)
	var inset: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in leaf:
		inset.append(p.lerp(_centre(leaf), 0.28))
	Ink.outline(canvas, inset, Ink.Tier.BACKGROUND, 43.0, _a(Palette.SB_CONTOUR, alpha))
	Ink.outline(canvas, leaf, Ink.Tier.FURNITURE, 47.0, _a(Palette.SB_CONTOUR, alpha))
	canvas.draw_colored_polygon(Ink.ellipse(hinge_top.lerp(hinge_bottom, 0.55) + swing * 0.85, 3.0, 3.0, 10), _a(Palette.SB_GOLD, alpha))
	Ink.outline(canvas, frame, Ink.Tier.FURNITURE, 53.0, _a(Palette.SB_CONTOUR, alpha))


static func _back_door(canvas: CanvasItem, alpha: float) -> void:
	var left_x: float = RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U - 0.07, 0.0).x
	var right_x: float = RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U + 0.07, 0.0).x
	var base_y: float = RoomGeometry.BACK_LEFT.y
	var frame: PackedVector2Array = StorybookArt._arch(left_x, right_x, base_y, base_y - 118.0, base_y - 140.0, 14)
	var gap: PackedVector2Array = StorybookArt._arch(left_x + 9, right_x - 9, base_y, base_y - 112.0, base_y - 130.0, 14)
	Ink.fill(canvas, frame, _a(Palette.SB_WALNUT_DARK, alpha), 61.0)
	canvas.draw_colored_polygon(gap, _a(Palette.SB_CHARCOAL.darkened(0.2), alpha))
	Ink.outline(canvas, frame, Ink.Tier.FURNITURE, 67.0, _a(Palette.SB_CONTOUR, alpha))


static func _wainscot(canvas: CanvasItem, x0: float, x1: float, top: float, bottom: float, alpha: float) -> void:
	var panel := StorybookArt._rect(x0, top, x1, bottom)
	Ink.fill(canvas, panel, _a(Palette.SB_WALNUT, alpha), 71.0, 0.1)
	Ink.wood_grain(canvas, panel, Palette.SB_WALNUT, 73.0, 4)
	var count: int = 8
	var width: float = (x1 - x0) / float(count)
	for i: int in count:
		var inset := StorybookArt._rect(x0 + width * float(i) + 7.0, top + 9.0, x0 + width * float(i + 1) - 7.0, bottom - 8.0)
		Ink.outline(canvas, inset, Ink.Tier.BACKGROUND, 75.0 + float(i), _a(Palette.SB_CONTOUR, alpha))
	Ink.line(canvas, PackedVector2Array([Vector2(x0, top), Vector2(x1, top)]), Ink.Tier.FURNITURE, 79.0, _a(Palette.SB_GOLD.darkened(0.15), alpha), 1.6)


static func _centre(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p: Vector2 in poly:
		sum += p
	return sum / float(poly.size())


static func _a(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)

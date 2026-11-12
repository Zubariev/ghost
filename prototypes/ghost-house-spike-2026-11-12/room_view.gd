# PROTOTYPE - NOT FOR PRODUCTION
#
## Draws the static room: darkness around it, back wall, two slanted side walls,
## the floor with planks, doors, a rug and a painting. Hamlet-style: there is no
## front wall, and a wall the ghost is inside fades so the ghost stays readable.
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const Shapes := preload("res://prototypes/ghost-house-spike-2026-11-12/shapes.gd")

enum Wall { BACK, LEFT, RIGHT }

var _alpha: Array[float] = [1.0, 1.0, 1.0]
var _target_alpha: Array[float] = [1.0, 1.0, 1.0]


static func floor_polygon() -> PackedVector2Array:
	return PackedVector2Array([Config.FLOOR_BACK_LEFT, Config.FLOOR_BACK_RIGHT, Config.FLOOR_FRONT_RIGHT, Config.FLOOR_FRONT_LEFT])


static func wall_polygon(wall: Wall) -> PackedVector2Array:
	var up_back := Vector2(0, -Config.BACK_WALL_HEIGHT)
	var up_front := Vector2(0, -Config.SIDE_WALL_FRONT_HEIGHT)
	match wall:
		Wall.BACK:
			return PackedVector2Array([Config.FLOOR_BACK_LEFT + up_back, Config.FLOOR_BACK_RIGHT + up_back, Config.FLOOR_BACK_RIGHT, Config.FLOOR_BACK_LEFT])
		Wall.LEFT:
			return PackedVector2Array([Config.FLOOR_FRONT_LEFT + up_front, Config.FLOOR_BACK_LEFT + up_back, Config.FLOOR_BACK_LEFT, Config.FLOOR_FRONT_LEFT])
		_:
			return PackedVector2Array([Config.FLOOR_BACK_RIGHT + up_back, Config.FLOOR_FRONT_RIGHT + up_front, Config.FLOOR_FRONT_RIGHT, Config.FLOOR_BACK_RIGHT])


## True when [param point] is on the floor (used for the ghost's shadow).
static func is_on_floor(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, floor_polygon())


## Fades whichever wall the ghost's body is inside.
func update_ghost(body_point: Vector2) -> void:
	for wall: int in [Wall.BACK, Wall.LEFT, Wall.RIGHT]:
		var inside: bool = Geometry2D.is_point_in_polygon(body_point, wall_polygon(wall))
		_target_alpha[wall] = Config.WALL_FADE_ALPHA if inside else 1.0


func _process(delta: float) -> void:
	var changed := false
	for i: int in _alpha.size():
		if not is_equal_approx(_alpha[i], _target_alpha[i]):
			_alpha[i] = move_toward(_alpha[i], _target_alpha[i], Config.WALL_FADE_SPEED * delta)
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-200, -200), Vector2(Config.VIEW_SIZE) + Vector2(400, 400)), Config.BACKGROUND)
	_draw_floor()
	_draw_back_wall(_alpha[Wall.BACK])
	_draw_side_wall(Wall.LEFT, _alpha[Wall.LEFT])
	_draw_side_wall(Wall.RIGHT, _alpha[Wall.RIGHT])


func _draw_floor() -> void:
	var floor_poly := floor_polygon()
	# Front edge thickness, so the floor reads as a cut-away slab.
	var edge := Vector2(0, Config.FLOOR_EDGE_THICKNESS)
	draw_colored_polygon(PackedVector2Array([Config.FLOOR_FRONT_LEFT, Config.FLOOR_FRONT_RIGHT, Config.FLOOR_FRONT_RIGHT + edge, Config.FLOOR_FRONT_LEFT + edge]), Config.FLOOR_EDGE)
	draw_colored_polygon(floor_poly, Config.FLOOR)
	# Planks converge toward the back, selling the tilt.
	for i: int in range(1, Config.FLOOR_PLANKS):
		var t: float = float(i) / float(Config.FLOOR_PLANKS)
		draw_line(Config.FLOOR_BACK_LEFT.lerp(Config.FLOOR_BACK_RIGHT, t), Config.FLOOR_FRONT_LEFT.lerp(Config.FLOOR_FRONT_RIGHT, t), Config.FLOOR_LINE, 2.0, true)
	for s: float in [0.1, 0.23, 0.38, 0.56, 0.77]:
		draw_line(Config.FLOOR_BACK_LEFT.lerp(Config.FLOOR_FRONT_LEFT, s), Config.FLOOR_BACK_RIGHT.lerp(Config.FLOOR_FRONT_RIGHT, s), Config.FLOOR_LINE, 1.5, true)
	# Rug under the table.
	draw_colored_polygon(Shapes.ellipse(Vector2(640, 488), 178, 50, 40), Config.RUG_BORDER)
	draw_colored_polygon(Shapes.ellipse(Vector2(640, 488), 160, 42, 40), Config.RUG)
	draw_polyline(_closed(floor_poly), Config.INK, 3.0, true)


func _draw_back_wall(alpha: float) -> void:
	var poly := wall_polygon(Wall.BACK)
	draw_colored_polygon(poly, _a(Config.WALL_BACK, alpha))
	var bl: Vector2 = Config.FLOOR_BACK_LEFT
	var br: Vector2 = Config.FLOOR_BACK_RIGHT
	var wainscot_y: float = bl.y - Config.BACK_WALL_HEIGHT * Config.WAINSCOT_FRACTION
	var top_y: float = bl.y - Config.BACK_WALL_HEIGHT
	var x: float = bl.x + 14.0
	while x < br.x:
		draw_line(Vector2(x, top_y), Vector2(x, wainscot_y), _a(Config.WALL_STRIPE, alpha), 6.0)
		x += 28.0
	draw_colored_polygon(Shapes.rect(bl.x, wainscot_y, br.x, bl.y), _a(Config.WAINSCOT, alpha))
	draw_line(Vector2(bl.x, wainscot_y), Vector2(br.x, wainscot_y), _a(Config.WALL_CAP, alpha), 4.0)
	# Open doorway to the next room.
	draw_colored_polygon(Shapes.rect(712, 118, 808, bl.y), _a(Config.WOOD_DARK, alpha))
	draw_colored_polygon(Shapes.rect(722, 128, 798, bl.y), _a(Config.DOORWAY, alpha))
	draw_polyline(_closed(Shapes.rect(712, 118, 808, bl.y)), _a(Config.INK, alpha), 2.5, true)
	draw_polyline(_closed(poly), _a(Config.INK, alpha), 3.0, true)
	draw_line(poly[0], poly[1], _a(Config.WALL_CAP, alpha), 7.0)


func _draw_side_wall(wall: Wall, alpha: float) -> void:
	var poly := wall_polygon(wall)
	draw_colored_polygon(poly, _a(Config.WALL_SIDE, alpha))
	# Wainscot band follows the floor edge.
	var front_floor: Vector2 = Config.FLOOR_FRONT_LEFT if wall == Wall.LEFT else Config.FLOOR_FRONT_RIGHT
	var back_floor: Vector2 = Config.FLOOR_BACK_LEFT if wall == Wall.LEFT else Config.FLOOR_BACK_RIGHT
	var front_w := front_floor - Vector2(0, Config.SIDE_WALL_FRONT_HEIGHT * Config.WAINSCOT_FRACTION)
	var back_w := back_floor - Vector2(0, Config.BACK_WALL_HEIGHT * Config.WAINSCOT_FRACTION)
	draw_colored_polygon(PackedVector2Array([front_w, back_w, back_floor, front_floor]), _a(Config.WAINSCOT_SIDE, alpha))
	draw_line(front_w, back_w, _a(Config.WALL_CAP, alpha), 4.0)
	if wall == Wall.LEFT:
		# Side door, its frame following the wall's perspective.
		var frame := PackedVector2Array([Vector2(270, 226), Vector2(200, 325), Vector2(200, 490), Vector2(270, 366)])
		var inner := PackedVector2Array([Vector2(262, 247), Vector2(208, 324), Vector2(208, 476), Vector2(262, 380)])
		draw_colored_polygon(frame, _a(Config.WOOD_DARK, alpha))
		draw_colored_polygon(inner, _a(Config.DOORWAY, alpha))
		draw_polyline(_closed(frame), _a(Config.INK, alpha), 2.5, true)
	else:
		var painting := PackedVector2Array([Vector2(1010, 209), Vector2(1090, 317), Vector2(1090, 419), Vector2(1010, 293)])
		var canvas := PackedVector2Array([Vector2(1018, 225), Vector2(1082, 313), Vector2(1082, 404), Vector2(1018, 289)])
		draw_colored_polygon(painting, _a(Config.BRASS_DARK, alpha))
		draw_colored_polygon(canvas, _a(Config.PAINTING, alpha))
		draw_polyline(_closed(painting), _a(Config.INK, alpha), 2.5, true)
	draw_polyline(_closed(poly), _a(Config.INK, alpha), 3.0, true)
	draw_line(poly[0], poly[1], _a(Config.WALL_CAP, alpha), 7.0)


static func _a(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)


static func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	return closed

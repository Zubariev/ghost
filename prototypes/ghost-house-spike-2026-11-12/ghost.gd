# PROTOTYPE - NOT FOR PRODUCTION
#
## The player's ghost: floats with WASD, ignores walls and furniture, bobs in place.
## Its node position is the point on the floor below it (used for depth sorting).
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const Shapes := preload("res://prototypes/ghost-house-spike-2026-11-12/shapes.gd")

## Whether the ghost is above the floor (draws a shadow) or inside a wall / outside.
var over_floor: bool = true

var _time: float = 0.0


func move(delta: float) -> void:
	var direction: Vector2 = Input.get_vector(&"ghost_left", &"ghost_right", &"ghost_up", &"ghost_down")
	position += direction * Config.GHOST_SPEED * delta
	position = position.clamp(Config.GHOST_BOUNDS.position, Config.GHOST_BOUNDS.end)


func get_body_point() -> Vector2:
	return global_position + Config.GHOST_BODY_OFFSET


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob: float = sin(_time * Config.GHOST_BOB_SPEED) * Config.GHOST_BOB_HEIGHT
	if over_floor:
		draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 24.0 - bob, 7.0), Color(0, 0, 0, 0.22))
	var head := Vector2(0, -72 + bob)
	var body := PackedVector2Array()
	for i: int in 13:
		var angle: float = PI + PI * float(i) / 12.0
		body.append(head + Vector2(cos(angle), sin(angle)) * 26.0)
	body.append(Vector2(30, -26 + bob))
	var waves := 4
	for i: int in waves * 2 + 1:
		var x: float = 30.0 - 60.0 * float(i) / float(waves * 2)
		var y: float = -18.0 + bob + (6.0 if i % 2 == 0 else -4.0) + sin(_time * 4.0 + float(i)) * 2.0
		body.append(Vector2(x, y))
	body.append(Vector2(-30, -26 + bob))
	draw_colored_polygon(body, Config.GHOST_FILL)
	var outline: PackedVector2Array = body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, Config.GHOST_INK, 2.5, true)
	draw_colored_polygon(Shapes.ellipse(head + Vector2(-9, 2), 4.5, 6.5, 12), Config.GHOST_INK)
	draw_colored_polygon(Shapes.ellipse(head + Vector2(9, 2), 4.5, 6.5, 12), Config.GHOST_INK)
	draw_colored_polygon(Shapes.ellipse(head + Vector2(0, 17), 3.5, 4.5, 10), Config.GHOST_INK)

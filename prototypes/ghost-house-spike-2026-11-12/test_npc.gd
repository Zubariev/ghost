# PROTOTYPE - NOT FOR PRODUCTION
#
## One family member walking a fixed loop of points, pausing at each activity spot.
## No schedule, no states, no reactions: this only tests movement and readability.
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const Shapes := preload("res://prototypes/ghost-house-spike-2026-11-12/shapes.gd")

var display_name: String = ""
var waypoints: Array[Vector2] = []
## Game seconds to stand at each waypoint.
var waits: Array[float] = []
## Direction to face while standing (Vector2.ZERO keeps the walking direction).
var look_dirs: Array[Vector2] = []
var facing: Vector2 = Vector2.DOWN

var _index: int = 0
var _wait_left: float = 0.0
var _walk_phase: float = 0.0
var _moving: bool = false


## Moves the NPC by one simulation step of [param sim_delta] game seconds.
func advance(sim_delta: float) -> void:
	if waypoints.is_empty():
		return
	if _wait_left > 0.0:
		_moving = false
		_wait_left -= sim_delta
		if _wait_left <= 0.0:
			_index = (_index + 1) % waypoints.size()
		queue_redraw()
		return
	var to_target: Vector2 = waypoints[_index] - position
	var step: float = Config.NPC_SPEED * sim_delta
	if to_target.length() <= step:
		position = waypoints[_index]
		_wait_left = waits[_index]
		if look_dirs[_index] != Vector2.ZERO:
			facing = look_dirs[_index]
		if _wait_left <= 0.0:
			_index = (_index + 1) % waypoints.size()
	else:
		facing = to_target.normalized()
		position += facing * step
		_moving = true
		_walk_phase += sim_delta * Config.NPC_STEP_RATE
	queue_redraw()


func _draw() -> void:
	var swing: float = sin(_walk_phase) * 7.0 if _moving else 0.0
	var bounce: float = absf(sin(_walk_phase)) * -2.0 if _moving else 0.0
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 20, 6), Color(0, 0, 0, 0.25))
	# Legs.
	draw_line(Vector2(-6, -32 + bounce), Vector2(-6 + swing, 0), Config.INK, 4.0, true)
	draw_line(Vector2(6, -32 + bounce), Vector2(6 - swing, 0), Config.INK, 4.0, true)
	var up := Vector2(0, bounce)
	# Dress and apron.
	var dress := PackedVector2Array([Vector2(-21, -28) + up, Vector2(21, -28) + up, Vector2(13, -80) + up, Vector2(-13, -80) + up])
	draw_colored_polygon(dress, Config.NPC_DRESS)
	var facing_away: bool = facing.y < -0.6
	if not facing_away:
		draw_colored_polygon(PackedVector2Array([Vector2(-12, -32) + up, Vector2(12, -32) + up, Vector2(9, -68) + up, Vector2(-9, -68) + up]), Config.NPC_APRON)
	_outline(dress)
	# Arms.
	draw_line(Vector2(-13, -76) + up, Vector2(-20 - swing * 0.5, -46) + up, Config.INK, 4.0, true)
	draw_line(Vector2(13, -76) + up, Vector2(20 + swing * 0.5, -46) + up, Config.INK, 4.0, true)
	# Head, hair, bun.
	var head_center := Vector2(0, -98) + up
	var head := Shapes.ellipse(head_center, 14, 17, 20)
	draw_colored_polygon(head, Config.NPC_SKIN)
	_outline(head)
	var hair := Shapes.ellipse(head_center + Vector2(0, -9 if not facing_away else -2), 15, 11 if not facing_away else 16, 20)
	draw_colored_polygon(hair, Config.NPC_HAIR)
	_outline(hair)
	var bun := Shapes.ellipse(head_center + Vector2(0, -22), 8, 7, 14)
	draw_colored_polygon(bun, Config.NPC_HAIR)
	_outline(bun)
	if not facing_away:
		var look: float = clampf(facing.x, -1.0, 1.0) * 4.0
		draw_colored_polygon(Shapes.ellipse(head_center + Vector2(-5 + look, 2), 2.0, 2.6, 8), Config.INK)
		draw_colored_polygon(Shapes.ellipse(head_center + Vector2(5 + look, 2), 2.0, 2.6, 8), Config.INK)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-50, -132) + up, display_name, HORIZONTAL_ALIGNMENT_CENTER, 100, 15, Config.NPC_LABEL)


func _outline(poly: PackedVector2Array) -> void:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, Config.INK, 2.5, true)

# PROTOTYPE - NOT FOR PRODUCTION
#
## Draws an NPC's peripheral and deep sight zones on the floor (toggled with Q).
## Visual only: no detection is computed in this spike.
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const RoomView := preload("res://prototypes/ghost-house-spike-2026-11-12/room_view.gd")

var npc: Node2D


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if npc == null:
		return
	var facing: Vector2 = npc.get("facing")
	var origin: Vector2 = npc.position
	_fan(origin, facing.angle(), Config.SIGHT_PERIPHERAL_ANGLE_DEG, Config.SIGHT_PERIPHERAL_LENGTH, Config.SIGHT_PERIPHERAL_COLOR)
	_fan(origin, facing.angle(), Config.SIGHT_DEEP_ANGLE_DEG, Config.SIGHT_DEEP_LENGTH, Config.SIGHT_DEEP_COLOR)


func _fan(origin: Vector2, direction: float, angle_deg: float, length: float, color: Color) -> void:
	var points := PackedVector2Array([origin])
	var half: float = deg_to_rad(angle_deg) * 0.5
	var steps := 18
	for i: int in steps + 1:
		var angle: float = direction - half + 2.0 * half * float(i) / float(steps)
		var ray := Vector2.from_angle(angle) * length
		points.append(origin + Vector2(ray.x, ray.y * Config.FLOOR_Y_SQUASH))
	# Clip to the floor so a cone never crosses a wall or leaves the room.
	var edge := Color(color, minf(color.a * 2.5, 0.8))
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(points, RoomView.floor_polygon()):
		draw_colored_polygon(piece, color)
		var outline: PackedVector2Array = piece.duplicate()
		outline.append(piece[0])
		draw_polyline(outline, edge, 2.0, true)

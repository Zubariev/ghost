## Where the ghost is: a room and a position on its floor (u: left→right 0..1, v: back
## wall 0 → front edge 1), allowed a little into the walls. It drifts through a wall into
## the neighbouring room on the floor's grid, and through the ceiling or floor into the room
## at the same grid cell above or below (stage 5a). The family's doors do not limit it.
##
## [codeblock]
## var nav := GhostNavigator.new(house)
## nav.place("hall", Vector2(0.5, 0.6))
## nav.move(input_direction * speed * delta)   # may change nav.room_id
## nav.change_floor(1)                          # R: up through the ceiling
## [/codeblock]
class_name GhostNavigator
extends RefCounted

signal room_changed(room_id: String)

## How far into the side walls, the back wall and past the front edge the ghost may go.
const U_MIN: float = -0.22
const U_MAX: float = 1.22
const V_MIN: float = -0.42
const V_MAX: float = 1.08

var room_id: String = ""
var uv: Vector2 = Vector2(0.5, 0.5)

var _house: HouseState


func _init(house: HouseState) -> void:
	_house = house


func place(target_room: String, at: Vector2) -> void:
	room_id = target_room
	uv = at


## Moves by [param delta] in floor units; crossing a wall's outer edge enters the room
## beyond it, if there is one.
func move(delta: Vector2) -> void:
	var next: Vector2 = uv + delta
	if next.x < U_MIN:
		next = _cross(Vector2i(-1, 0), next, Vector2(U_MAX - (U_MIN - next.x), next.y))
	elif next.x > U_MAX:
		next = _cross(Vector2i(1, 0), next, Vector2(U_MIN + (next.x - U_MAX), next.y))
	if next.y < V_MIN:
		next = _cross(Vector2i(0, -1), next, Vector2(next.x, V_MAX - (V_MIN - next.y)))
	elif next.y > V_MAX:
		next = _cross(Vector2i(0, 1), next, Vector2(next.x, V_MIN + (next.y - V_MAX)))
	uv = Vector2(clampf(next.x, U_MIN, U_MAX), clampf(next.y, V_MIN, V_MAX))


## Floats one floor up (+1) or down (−1) into the room at the same grid cell.
func change_floor(direction: int) -> bool:
	var here: RoomState = _house.rooms[room_id]
	var target: String = room_at(here.floor_level + direction, here.grid)
	if target.is_empty():
		return false
	room_id = target
	room_changed.emit(room_id)
	return true


## The wall the ghost is inside: "left", "right", "back", or "" when over the floor or
## in front of it.
func wall() -> String:
	if uv.x < 0.0:
		return "left"
	if uv.x > 1.0:
		return "right"
	if uv.y < 0.0:
		return "back"
	return ""


func room_at(floor_level: int, cell: Vector2i) -> String:
	for room: RoomState in _house.rooms.values():
		if room.floor_level == floor_level and room.grid == cell:
			return room.id
	return ""


func _cross(step: Vector2i, blocked: Vector2, entered: Vector2) -> Vector2:
	var here: RoomState = _house.rooms[room_id]
	var target: String = room_at(here.floor_level, here.grid + step)
	if target.is_empty():
		return blocked
	room_id = target
	room_changed.emit(room_id)
	return entered

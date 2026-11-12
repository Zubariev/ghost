## Where things are inside a room, in floor units (u: left→right 0..1, v: back wall 0 →
## front edge 1): furniture from `assets/data/house/furniture.json`, where each family
## member stands and which way they face, hiding spots, doors, and sight (Demo
## Specification §8.5, §8.8). Pure logic: the room view draws from it and the stealth
## system tests against it.
##
## [codeblock]
## var layout := RoomLayout.new(JsonData.read(RoomLayout.FURNITURE_PATH)["rooms"], house)
## var where: Dictionary = layout.person(routine, 2, "kitchen", sim.routines)
## var zone := RoomLayout.sight_zone(where["uv"], where["facing"], ghost_uv, cfg, layout.occluders("kitchen"))
## [/codeblock]
class_name RoomLayout
extends RefCounted

const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
const BACK_DOOR_U: float = 0.62

enum Zone { NONE, PERIPHERAL, DEEP }

## room id -> Array of furniture dictionaries {kind, u, v, object?, hide_id?, blocks_sight?, pickup?}
var furniture: Dictionary = {}

var _house: HouseState


func _init(furniture_by_room: Dictionary, house: HouseState) -> void:
	furniture = furniture_by_room
	_house = house


func pieces(room_id: String) -> Array:
	return furniture.get(room_id, [])


## Floor position of a sim object in a room, or (-1, -1) when it is not placed there.
func object_uv(room_id: String, object_id: String) -> Vector2:
	for piece: Dictionary in pieces(room_id):
		if String(piece.get("object", "")) == object_id:
			return _uv(piece)
	return Vector2(-1, -1)


func kind_uv(room_id: String, kind: String) -> Vector2:
	for piece: Dictionary in pieces(room_id):
		if String(piece["kind"]) == kind:
			return _uv(piece)
	return Vector2(-1, -1)


## Where the door toward [param other] is on this room's floor (stairs between floors).
func door_uv(room_id: String, other: String) -> Vector2:
	var here: RoomState = _house.rooms[room_id]
	var there: RoomState = _house.rooms[other]
	if here.floor_level != there.floor_level:
		var stairs: Vector2 = kind_uv(room_id, "stairs")
		return stairs if stairs.x >= 0.0 else Vector2(0.5, 0.1)
	var step: Vector2i = there.grid - here.grid
	if step.x < 0:
		return Vector2(0.0, 0.5)
	if step.x > 0:
		return Vector2(1.0, 0.5)
	if step.y < 0:
		return Vector2(BACK_DOOR_U, 0.0)
	return Vector2(0.5, 1.0)


## Hiding spots in a room: Array of {id, uv}.
func hiding_spots(room_id: String) -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	for piece: Dictionary in pieces(room_id):
		if piece.has("hide_id"):
			spots.append({"id": String(piece["hide_id"]), "uv": _uv(piece)})
	return spots


## Tall furniture that blocks sight, as floor rectangles.
func occluders(room_id: String) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for piece: Dictionary in pieces(room_id):
		if piece.has("blocks_sight"):
			var half := Vector2(float(piece["blocks_sight"][0]), float(piece["blocks_sight"][1]))
			rects.append(Rect2(_uv(piece) - half, half * 2.0))
	return rects


## Where (and how) a family member appears in [param room_id]: {uv, pose, facing}, or {}
## when they are not there. [param time] only animates the tricycle.
func person(routine: NpcRoutine, index: int, room_id: String, routines: Array[NpcRoutine], time: float = 0.0) -> Dictionary:
	var walk: Dictionary = routine.get_walk_progress()
	if not walk.is_empty():
		var t: float = float(walk["t"])
		var from_room: String = String(walk["from"])
		var to_room: String = String(walk["to"])
		if from_room == room_id and t < 0.5:
			var door: Vector2 = door_uv(room_id, to_room)
			var start: Vector2 = spot(routine, index, room_id)
			var at: Vector2 = start.lerp(door, t * 2.0)
			return {"uv": at, "pose": "walk", "facing": _toward(at, door, Vector2(0, 1))}
		if to_room == room_id and t >= 0.5:
			var door_in: Vector2 = door_uv(room_id, from_room)
			var middle := Vector2(0.5, 0.6)
			var at_in: Vector2 = door_in.lerp(middle, (t - 0.5) * 2.0)
			return {"uv": at_in, "pose": "walk", "facing": _toward(at_in, middle, Vector2(0, 1))}
		return {}
	if routine.room_id != room_id:
		return {}
	var pose: String = "stand"
	var activity: Activity = routine.current
	if routine.is_broken():
		pose = "broken"
	elif routine.state == NpcRoutine.State.PERFORMING and activity != null and routine.current_task == null:
		match activity.animation:
			"sleep":
				pose = "sleep"
			"eat", "rest", "read", "computer", "draw", "dolls":
				pose = "sit"
			"tricycle":
				pose = "tricycle"
	if pose == "sleep":
		var bed: Vector2 = bed_spot(routine, room_id, routines)
		if bed.x >= 0.0:
			return {"uv": bed, "pose": "sleep", "facing": Vector2(0, 1)}
	var at_spot: Vector2 = spot(routine, index, room_id)
	if pose == "tricycle":
		at_spot.x = 0.5 + 0.3 * sin(time * 0.6)
	return {"uv": at_spot, "pose": pose, "facing": facing(routine, room_id, at_spot)}


## The spot for this person: their repair's object, their activity's object, else a slot.
func spot(routine: NpcRoutine, index: int, room_id: String) -> Vector2:
	var at: Vector2 = _focus_object_uv(routine, room_id)
	if at.x >= 0.0:
		var spread: float = (float(index) - 2.5) * 0.06
		return Vector2(clampf(at.x + spread, 0.08, 0.92), clampf(at.y + 0.12, 0.1, 0.95))
	return Vector2(0.18 + 0.13 * float(index), 0.62 + 0.08 * float(index % 2))


## Which way the person looks: at the object they use, otherwise toward the front.
func facing(routine: NpcRoutine, room_id: String, at: Vector2) -> Vector2:
	var focus: Vector2 = _focus_object_uv(routine, room_id)
	if focus.x >= 0.0:
		return _toward(at, focus, Vector2(0, 1))
	return Vector2(0, 1)


## A place in one of the room's beds for this sleeper, two to a double bed, in data order.
func bed_spot(routine: NpcRoutine, room_id: String, routines: Array[NpcRoutine]) -> Vector2:
	var sleepers: Array[NpcRoutine] = []
	for other: NpcRoutine in routines:
		if other.room_id == room_id and other.state == NpcRoutine.State.PERFORMING and other.current != null \
				and other.current.animation == "sleep" and other.get_walk_progress().is_empty():
			sleepers.append(other)
	var place: int = sleepers.find(routine)
	for piece: Dictionary in pieces(room_id):
		var kind: String = String(piece["kind"])
		if kind != "bed" and kind != "double_bed":
			continue
		var capacity: int = 2 if kind == "double_bed" else 1
		if place < capacity:
			var offset: float = 0.0 if capacity == 1 else (-0.045 if place == 0 else 0.045)
			return Vector2(float(piece["u"]) + offset, float(piece["v"]) + 0.001)
		place -= capacity
	return Vector2(-1, -1)


## Which sight zone the ghost is in for someone at [param from_uv] looking along
## [param look]. Walls and [param blockers] (tall furniture) block sight.
static func sight_zone(from_uv: Vector2, look: Vector2, ghost_uv: Vector2, cfg: Dictionary, blockers: Array[Rect2]) -> Zone:
	if not line_of_sight(from_uv, ghost_uv, blockers):
		return Zone.NONE
	var to_ghost: Vector2 = ghost_uv - from_uv
	var distance: float = to_ghost.length()
	if distance < 0.0001:
		return Zone.DEEP
	var angle: float = rad_to_deg(absf(look.normalized().angle_to(to_ghost)))
	if angle <= float(cfg.get("deep_angle_deg", 40)) * 0.5 and distance <= float(cfg.get("deep_range", 0.33)):
		return Zone.DEEP
	if angle <= float(cfg.get("peripheral_angle_deg", 120)) * 0.5 and distance <= float(cfg.get("peripheral_range", 0.5)):
		return Zone.PERIPHERAL
	return Zone.NONE


## True when nothing blocks the line between two floor points: both must be on the floor
## (a point inside a wall is behind it) and the line must not cross tall furniture.
static func line_of_sight(from_uv: Vector2, to_uv: Vector2, blockers: Array[Rect2]) -> bool:
	if not _on_floor(from_uv) or not _on_floor(to_uv):
		return false
	for rect: Rect2 in blockers:
		if rect.has_point(to_uv) or _segment_hits_rect(from_uv, to_uv, rect):
			return false
	return true


static func _on_floor(uv: Vector2) -> bool:
	return uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0


static func _segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i: int in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false


static func _toward(from_uv: Vector2, to_uv: Vector2, fallback: Vector2) -> Vector2:
	var direction: Vector2 = to_uv - from_uv
	return direction.normalized() if direction.length() > 0.0001 else fallback


func _focus_object_uv(routine: NpcRoutine, room_id: String) -> Vector2:
	var object_id: String = ""
	if routine.current_task != null and routine.current_task.type == HouseTask.Type.REPAIR:
		object_id = routine.current_task.target_id
	elif routine.current != null:
		object_id = routine.current.target_object_id
	return object_uv(room_id, object_id) if not object_id.is_empty() else Vector2(-1, -1)


static func _uv(piece: Dictionary) -> Vector2:
	return Vector2(float(piece["u"]), float(piece["v"]))

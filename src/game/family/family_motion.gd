## Where each family member is on screen and which way they look while they walk (stage 5c,
## roadmap step 1). Decided 2026-11-13: walking is shown only and costs no simulation time.
##
## [br]- Each person walks along a [RoomPaths] route around furniture toward where the
##   simulation says they should be: their activity spot, or, while the simulation walks
##   them between rooms, just inside the next room's door.
## [br]- Between rooms the route leaves by the door that leads to the next room and enters by
##   the matching door (the stairs between floors). The room someone is shown in changes only
##   there.
## [br]- The view may trail the simulation. When the route left is longer than
##   [code]walk_speed × catch_up_minutes[/code], they walk faster to catch up in that time.
## [br]- People who set off on the same room-to-room route in the same frame leave one after
##   another, [code]stagger_minutes[/code] apart, instead of walking stacked on one spot.
## [br]- Stealth incidents: a searcher walks to the spot being searched; someone inspecting or
##   frightened stops and turns toward the sighting ("?" / "!").
##
## Pure logic over the simulation, which it never changes. Call [method update] every frame
## with the game minutes that passed. The room view draws from [method person] and the
## stealth system looks from it.
class_name FamilyMotion
extends RefCounted

## Person [param index] walked out of [param from_room] at [param exit_uv] and into
## [param to_room] at [param entry_uv] (the door pair, or the stairs).
signal door_crossed(index: int, from_room: String, to_room: String, exit_uv: Vector2, entry_uv: Vector2)

## Stealth incidents (search walks, turning to look); may be null.
var stealth: StealthSystem

var _routines: Array[NpcRoutine]
var _house: HouseState
var _layout: RoomLayout
var _paths: RoomPaths
var _speed: float
var _catch_up: float
var _door_inset: float
var _stagger: float
## One per routine: {room, uv, facing, pose, marker, route, goal_room, goal_uv}.
## route: Array of {room, start, targets: PackedVector2Array}.
var _walkers: Array[Dictionary] = []
var _time: float = 0.0


func _init(routines: Array[NpcRoutine], house: HouseState, layout: RoomLayout, paths: RoomPaths, config: Dictionary) -> void:
	_routines = routines
	_house = house
	_layout = layout
	_paths = paths
	_speed = float(config.get("walk_speed", 0.45))
	_catch_up = maxf(0.01, float(config.get("catch_up_minutes", 1.0)))
	_door_inset = float(config.get("door_inset", 0.12))
	_stagger = maxf(0.0, float(config.get("stagger_minutes", 0.15)))
	for i: int in routines.size():
		_walkers.append({"room": routines[i].room_id, "uv": Vector2(0.5, 0.6), "facing": Vector2(0, 1),
			"pose": "stand", "marker": "", "route": [], "goal_room": "", "goal_uv": Vector2(-1, -1), "wait": 0.0})
	settle()


## Puts everyone straight at where they should be, with no walking (game start, captures).
func settle() -> void:
	for i: int in _walkers.size():
		var goal: Dictionary = _goal(i)
		var walker: Dictionary = _walkers[i]
		walker["room"] = goal["room"]
		walker["uv"] = goal["uv"]
		walker["route"] = []
		walker["wait"] = 0.0
		walker["goal_room"] = goal["room"]
		walker["goal_uv"] = goal["uv"]
		_rest(walker, goal)


## Walks everyone on by [param minutes] game minutes.
func update(minutes: float) -> void:
	if minutes <= 0.0:
		return
	_time += minutes
	var leaving: Dictionary[String, int] = {}   # "from>to" -> people who set off this frame
	for i: int in _walkers.size():
		var walker: Dictionary = _walkers[i]
		var goal: Dictionary = _goal(i)
		if bool(goal.get("hold", false)):
			walker["route"] = []
			walker["goal_room"] = walker["room"]
			walker["goal_uv"] = walker["uv"]
			_rest(walker, goal)
			continue
		var from_room: String = String(walker["room"])
		if _retarget(walker, goal):
			var key: String = from_room + ">" + String(goal["room"])
			walker["wait"] = float(leaving.get(key, 0)) * _stagger
			leaving[key] = int(leaving.get(key, 0)) + 1
		if float(walker["wait"]) > 0.0 and not (walker["route"] as Array).is_empty():
			walker["wait"] = float(walker["wait"]) - minutes
			continue   # about to set off; keeps the pose it had
		var left: float = remaining(i)
		_advance(i, walker, maxf(_speed, left / _catch_up) * minutes)
		if (walker["route"] as Array).is_empty():
			_rest(walker, goal)
		else:
			walker["pose"] = "walk"
			walker["marker"] = String(goal.get("marker", ""))


## Where person [param index] is shown and looks in [param room_id]: {uv, pose, facing,
## marker?}, or {} when they are not shown there.
func person(index: int, room_id: String) -> Dictionary:
	var walker: Dictionary = _walkers[index]
	if String(walker["room"]) != room_id:
		return {}
	var placed: Dictionary = {"uv": walker["uv"], "pose": walker["pose"], "facing": walker["facing"]}
	if not String(walker["marker"]).is_empty():
		placed["marker"] = walker["marker"]
	return placed


## The room person [param index] is shown in.
func room_of(index: int) -> String:
	return String(_walkers[index]["room"])


## True while person [param index] is walking a route.
func is_walking(index: int) -> bool:
	return not (_walkers[index]["route"] as Array).is_empty()


## Length of the route person [param index] still has to walk, in floor units.
func remaining(index: int) -> float:
	var walker: Dictionary = _walkers[index]
	var total: float = 0.0
	var first: bool = true
	for segment: Dictionary in walker["route"]:
		# The segment being walked starts where the walker is; later ones at their door.
		var at: Vector2 = walker["uv"] if first and String(segment["room"]) == String(walker["room"]) else segment["start"]
		first = false
		for point: Vector2 in segment["targets"]:
			total += at.distance_to(point)
			at = point
	return total


# Where the simulation (and stealth) say person [param index] should be:
# {room, uv, pose, facing, marker?, hold?}.
func _goal(index: int) -> Dictionary:
	var routine: NpcRoutine = _routines[index]
	var walker: Dictionary = _walkers[index] if index < _walkers.size() else {}
	if stealth != null:
		var npc_id: String = routine.schedule.npc_id
		var phase: StealthSystem.Phase = stealth.phase_of(npc_id)
		if phase != StealthSystem.Phase.NONE and not walker.is_empty():
			var focus: Vector2 = stealth.incident_focus(npc_id)
			var marker: String = "!" if phase == StealthSystem.Phase.FRIGHT else "?"
			if phase == StealthSystem.Phase.SEARCH_WALK or phase == StealthSystem.Phase.SEARCH_CHECK:
				var spot := Vector2(clampf(focus.x, 0.05, 0.95), clampf(focus.y + 0.10, 0.05, 0.95))
				return {"room": walker["room"], "uv": spot, "pose": "stand", "facing": _toward(spot, focus), "marker": marker}
			return {"room": walker["room"], "uv": walker["uv"], "pose": "stand", "hold": true,
				"facing": _toward(Vector2(walker["uv"]), focus), "marker": marker}
	var walk: Dictionary = routine.get_walk_progress()
	if not walk.is_empty():
		var to_room: String = String(walk["to"])
		var entry: Vector2 = entry_uv(to_room, String(walk["from"]))
		return {"room": to_room, "uv": entry, "pose": "stand", "facing": Vector2(0, 1)}
	var placed: Dictionary = _layout.person(routine, index, routine.room_id, _routines, _time)
	if placed.is_empty():
		return {"room": routine.room_id, "uv": Vector2(0.5, 0.6), "pose": "stand", "facing": Vector2(0, 1)}
	return {"room": routine.room_id, "uv": placed["uv"], "pose": placed["pose"], "facing": placed["facing"]}


## Where someone coming from [param from_room] stops just inside [param room_id]'s door.
func entry_uv(room_id: String, from_room: String) -> Vector2:
	var door: Vector2 = _layout.door_uv(room_id, from_room)
	var inward: Vector2 = Vector2(0.5, 0.5) - door
	var entry: Vector2 = door + (inward.normalized() * _door_inset if inward.length() > 0.0001 else Vector2.ZERO)
	return entry if _paths.is_free(room_id, entry) else _paths.nearest_free(room_id, entry)


# Plans a new route when the goal moved (returns true); a goal that only slid a little (the
# tricycle) moves the route's end instead.
func _retarget(walker: Dictionary, goal: Dictionary) -> bool:
	var goal_room: String = String(goal["room"])
	var goal_uv: Vector2 = goal["uv"]
	if goal_room == String(walker["goal_room"]) and goal_uv.distance_to(walker["goal_uv"]) < 0.0001:
		return false
	var route: Array = walker["route"]
	var same_room: bool = goal_room == String(walker["goal_room"])
	if same_room and goal_uv.distance_to(walker["goal_uv"]) < 0.03:
		if not route.is_empty():
			var last: Dictionary = route[route.size() - 1]
			var targets: PackedVector2Array = last["targets"]
			if not targets.is_empty():
				targets[targets.size() - 1] = goal_uv
				last["targets"] = targets
		elif String(walker["room"]) == goal_room and _paths.is_free(goal_room, goal_uv):
			walker["uv"] = goal_uv   # tiny slide while resting (the tricycle's sway)
		walker["goal_uv"] = goal_uv
		return false
	walker["goal_room"] = goal_room
	walker["goal_uv"] = goal_uv
	walker["route"] = _plan(String(walker["room"]), walker["uv"], goal_room, goal_uv)
	return true


# Route from a room and point to another: through the doors of the house's shortest path.
func _plan(from_room: String, from_uv: Vector2, to_room: String, to_uv: Vector2) -> Array:
	var route: Array = []
	var room: String = from_room
	var at: Vector2 = from_uv
	var rooms: Array[String] = _house.find_path(from_room, to_room)
	if from_room != to_room and rooms.is_empty():
		rooms = []   # unreachable: stay in this room and walk to the point nearest the goal
	for next: String in rooms:
		var door: Vector2 = _layout.door_uv(room, next)
		route.append({"room": room, "start": at, "targets": _targets(room, at, door)})
		at = _layout.door_uv(next, room)
		room = next
	var finish: Vector2 = to_uv if room == to_room else at
	route.append({"room": room, "start": at, "targets": _targets(room, at, finish)})
	return route


func _targets(room_id: String, from_uv: Vector2, to_uv: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = _paths.find(room_id, from_uv, to_uv)
	points.remove_at(0)
	return points


# Moves the walker [param distance] floor units along its route, through doors.
func _advance(index: int, walker: Dictionary, distance: float) -> void:
	var route: Array = walker["route"]
	while not route.is_empty():
		var segment: Dictionary = route[0]
		if String(segment["room"]) != String(walker["room"]):
			var from_room: String = String(walker["room"])
			var exit_uv: Vector2 = walker["uv"]
			walker["room"] = segment["room"]   # through the matching door
			walker["uv"] = segment["start"]
			door_crossed.emit(index, from_room, String(segment["room"]), exit_uv, Vector2(segment["start"]))
		var targets: PackedVector2Array = segment["targets"]
		if targets.is_empty():
			route.pop_front()
			continue
		if distance <= 0.0:
			break
		var at: Vector2 = walker["uv"]
		var to: Vector2 = targets[0]
		var gap: float = at.distance_to(to)
		if gap > 0.0001:
			walker["facing"] = (to - at) / gap
		if gap <= distance:
			walker["uv"] = to
			distance -= gap
			targets.remove_at(0)
			segment["targets"] = targets
		else:
			walker["uv"] = at + (to - at) / gap * distance
			distance = 0.0
	walker["route"] = route


func _rest(walker: Dictionary, goal: Dictionary) -> void:
	walker["pose"] = goal["pose"]
	walker["facing"] = goal["facing"]
	walker["marker"] = String(goal.get("marker", ""))


static func _toward(from_uv: Vector2, to_uv: Vector2) -> Vector2:
	var direction: Vector2 = to_uv - from_uv
	return direction.normalized() if direction.length() > 0.0001 else Vector2(0, 1)

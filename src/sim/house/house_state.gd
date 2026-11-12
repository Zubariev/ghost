## The house: rooms, the doors between them (with walking minutes) and the objects in them.
##
## Requirements and effects are plain dictionaries from data:
## [code]{"object": "stove", "state": "working"}[/code] is a requirement,
## [code]{"object": "meal_food", "set": "ready"}[/code] and
## [code]{"room": "kitchen", "cleanliness": "clean"}[/code] are effects.
## States change only through [method set_object_state] and the room setters
## — never by themselves (GDD §9.7).
class_name HouseState
extends RefCounted

signal object_state_changed(object_id: String, new_state: StringName)
signal room_cleanliness_changed(room_id: String, cleanliness: RoomState.Cleanliness)
signal room_temperature_changed(room_id: String, temperature: RoomState.Temperature)
signal room_light_changed(room_id: String, light: RoomState.Light)

var rooms: Dictionary[String, RoomState] = {}
var objects: Dictionary[String, ObjectState] = {}

## room id -> { neighbour room id: walking minutes }
var _doors: Dictionary[String, Dictionary] = {}


static func from_dict(data: Dictionary) -> HouseState:
	var house := HouseState.new()
	for room_data: Variant in data.get("rooms", []):
		var room: RoomState = RoomState.from_dict(room_data)
		house.rooms[room.id] = room
		house._doors[room.id] = {}
	for door: Variant in data.get("doors", []):
		house.add_door(String(door["a"]), String(door["b"]), int(door.get("walk_minutes", 1)))
	for object_data: Variant in data.get("objects", []):
		var obj: ObjectState = ObjectState.from_dict(object_data)
		house.objects[obj.id] = obj
	return house


## Connects two rooms both ways; walking through takes [param walk_minutes].
func add_door(room_a: String, room_b: String, walk_minutes: int) -> void:
	if not _doors.has(room_a) or not _doors.has(room_b):
		push_error("HouseState: door between unknown rooms %s and %s" % [room_a, room_b])
		return
	_doors[room_a][room_b] = maxi(1, walk_minutes)
	_doors[room_b][room_a] = maxi(1, walk_minutes)


func get_object_state(object_id: String) -> StringName:
	if not objects.has(object_id):
		return &""
	return objects[object_id].state


## Sets an object's state; returns false (and changes nothing) for an unknown object or state.
func set_object_state(object_id: String, new_state: StringName) -> bool:
	if not objects.has(object_id):
		push_error("HouseState: unknown object %s" % object_id)
		return false
	var obj: ObjectState = objects[object_id]
	if not obj.allows(new_state):
		push_error("HouseState: %s cannot be '%s'" % [object_id, new_state])
		return false
	if obj.state != new_state:
		obj.state = new_state
		object_state_changed.emit(object_id, new_state)
	return true


## Returns the requirements that are not met right now (empty when all are).
func unmet_requirements(requirements: Array[Dictionary]) -> Array[Dictionary]:
	var unmet: Array[Dictionary] = []
	for requirement: Dictionary in requirements:
		var wanted := StringName(requirement.get("state", ""))
		if get_object_state(String(requirement.get("object", ""))) != wanted:
			unmet.append(requirement)
	return unmet


## Sets a room's cleanliness; returns false for an unknown room.
func set_room_cleanliness(room_id: String, cleanliness: RoomState.Cleanliness) -> bool:
	if not rooms.has(room_id):
		push_error("HouseState: unknown room %s" % room_id)
		return false
	var room: RoomState = rooms[room_id]
	if room.cleanliness != cleanliness:
		room.cleanliness = cleanliness
		room_cleanliness_changed.emit(room_id, cleanliness)
	return true


## Sets a room's temperature; returns false for an unknown room.
func set_room_temperature(room_id: String, temperature: RoomState.Temperature) -> bool:
	if not rooms.has(room_id):
		push_error("HouseState: unknown room %s" % room_id)
		return false
	if rooms[room_id].temperature != temperature:
		rooms[room_id].temperature = temperature
		room_temperature_changed.emit(room_id, temperature)
	return true


## Sets a room's light; returns false for an unknown room.
func set_room_light(room_id: String, light: RoomState.Light) -> bool:
	if not rooms.has(room_id):
		push_error("HouseState: unknown room %s" % room_id)
		return false
	if rooms[room_id].light != light:
		rooms[room_id].light = light
		room_light_changed.emit(room_id, light)
	return true


func apply_effects(effects: Array[Dictionary]) -> void:
	for effect: Dictionary in effects:
		if effect.has("room"):
			var key: String = String(effect.get("cleanliness", "")).to_upper()
			if RoomState.Cleanliness.has(key):
				set_room_cleanliness(String(effect["room"]), RoomState.Cleanliness[key])
			else:
				push_error("HouseState: unknown cleanliness '%s'" % effect.get("cleanliness"))
		else:
			set_object_state(String(effect.get("object", "")), StringName(effect.get("set", "")))


## Total walking minutes of the shortest route; 0 when already there, -1 when unreachable.
func path_cost(from_room: String, to_room: String) -> int:
	if from_room == to_room:
		return 0 if rooms.has(from_room) else -1
	var route: Array[String] = find_path(from_room, to_room)
	if route.is_empty():
		return -1
	var total: int = 0
	var at: String = from_room
	for next: String in route:
		total += walk_minutes(at, next)
		at = next
	return total


func walk_minutes(room_a: String, room_b: String) -> int:
	if _doors.has(room_a) and _doors[room_a].has(room_b):
		return int(_doors[room_a][room_b])
	return -1


## Shortest route by walking time, as the rooms entered after [param from_room], ending
## with [param to_room]. Empty when already there or when no route exists.
func find_path(from_room: String, to_room: String) -> Array[String]:
	var route: Array[String] = []
	if from_room == to_room or not _doors.has(from_room) or not _doors.has(to_room):
		return route
	var cost: Dictionary[String, int] = {from_room: 0}
	var previous: Dictionary[String, String] = {}
	var open: Array[String] = [from_room]
	while not open.is_empty():
		var best_index: int = 0
		for i: int in open.size():
			if cost[open[i]] < cost[open[best_index]]:
				best_index = i
		var room: String = open.pop_at(best_index)
		if room == to_room:
			break
		for neighbour: String in _doors[room]:
			var new_cost: int = cost[room] + int(_doors[room][neighbour])
			if not cost.has(neighbour) or new_cost < cost[neighbour]:
				cost[neighbour] = new_cost
				previous[neighbour] = room
				if not open.has(neighbour):
					open.append(neighbour)
	if not previous.has(to_room):
		return route
	var step: String = to_room
	while step != from_room:
		route.push_front(step)
		step = previous[step]
	return route

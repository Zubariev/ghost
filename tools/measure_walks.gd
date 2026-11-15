## Measures how long walking between rooms takes on screen, to set the doors' walk_minutes in
## assets/data/house/rooms.json (user decision 2026-11-15: the simulation walks as slowly as
## people are seen walking). For each door: the walking route inside each of the two rooms
## from the room's middle to that door, averaged, divided by walk_speed (an adult, pace 1, in
## a room in perfect order); stairs add stairs_minutes. Prints suggested values; edit
## rooms.json by hand (or with the printed JSON).
##
## Run: /home/ther0/Games/godot --headless --path . -s res://tools/measure_walks.gd
extends SceneTree

const MIDDLE := Vector2(0.5, 0.6)
## Extra minutes for climbing the stairs between floors.
const STAIRS_MINUTES: float = 1.0


func _initialize() -> void:
	var data: Dictionary = JsonData.read("res://assets/data/house/rooms.json")
	var house := HouseState.from_dict(data)
	var layout := RoomLayout.new(JsonData.read("res://assets/data/house/furniture.json")["rooms"], house)
	var movement: Dictionary = JsonData.read("res://assets/data/house/movement.json")
	var paths := RoomPaths.new(layout, movement)
	var speed: float = float(movement["walk_speed"])
	for door: Dictionary in data["doors"]:
		var a: String = String(door["a"])
		var b: String = String(door["b"])
		var in_a: float = RoomPaths.length(paths.find(a, MIDDLE, layout.door_uv(a, b)))
		var in_b: float = RoomPaths.length(paths.find(b, MIDDLE, layout.door_uv(b, a)))
		var minutes: float = (in_a + in_b) * 0.5 / speed
		if house.rooms[a].floor_level != house.rooms[b].floor_level:
			minutes += STAIRS_MINUTES
		print("%s <-> %s: %.2f + %.2f floor units -> %.1f min (now %d), suggest %d" % [a, b, in_a, in_b, minutes, int(door["walk_minutes"]), maxi(1, roundi(minutes))])
	quit()

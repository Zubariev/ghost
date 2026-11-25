## One room and its discrete conditions (GDD §9.7, agreed for the demo):
## temperature cold / comfortable / warm, light dark / dim / bright,
## cleanliness dirty / normal / clean. Nothing here changes on its own.
class_name RoomState
extends RefCounted

enum Temperature { COLD, COMFORTABLE, WARM }
enum Light { DARK, DIM, BRIGHT }
enum Cleanliness { DIRTY, NORMAL, CLEAN }

var id: String = ""
var display_name: String = ""
var floor_level: int = 0
var temperature: Temperature = Temperature.COMFORTABLE
var light: Light = Light.BRIGHT
var cleanliness: Cleanliness = Cleanliness.NORMAL
## Daylight reaches the room (06:00–22:00), so with its lamps out it is dim, not dark.
var has_window: bool = false
## Cell on its floor's grid (column, row; row 0 = back of the house). Used by views and
## the ghost's movement through walls; the family moves only through doors.
var grid: Vector2i = Vector2i.ZERO
## Where the debug plan view draws the room. Not used by the simulation.
var plan_rect: Rect2 = Rect2()
## Real floor size in metres, width (u) × depth (v) (user decision 2026-11-20: rooms of
## different sizes, laid out in metres). ZERO when the data gives none.
var size_m: Vector2 = Vector2.ZERO
## Open air (sprint 001, 2026-11-25: the yards): lit by daylight only, no ceiling or floor to float
## through (data "outdoor").
var outdoor: bool = false
## The family goes there (data "family", default true). False for the basement, attic and yards:
## no doors lead there and nobody is given a task there (sprint 001, 2026-11-25).
var family_access: bool = true


static func from_dict(data: Dictionary) -> RoomState:
	var room := RoomState.new()
	room.id = String(data.get("id", ""))
	room.display_name = String(data.get("name", room.id))
	room.floor_level = int(data.get("floor", 0))
	room.has_window = bool(data.get("has_window", false))
	room.outdoor = bool(data.get("outdoor", false))
	room.family_access = bool(data.get("family", true))
	room.temperature = _enum_value(Temperature, data.get("temperature", "comfortable"), Temperature.COMFORTABLE) as Temperature
	room.light = _enum_value(Light, data.get("light", "bright"), Light.BRIGHT) as Light
	room.cleanliness = _enum_value(Cleanliness, data.get("cleanliness", "normal"), Cleanliness.NORMAL) as Cleanliness
	var cell: Array = data.get("grid", [0, 0])
	if cell.size() == 2:
		room.grid = Vector2i(int(cell[0]), int(cell[1]))
	var rect: Array = data.get("plan_rect", [0, 0, 0, 0])
	if rect.size() == 4:
		room.plan_rect = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	var size: Array = data.get("size_m", [])
	if size.size() == 2:
		room.size_m = Vector2(float(size[0]), float(size[1]))
	return room


static func _enum_value(enum_dict: Dictionary, name: Variant, fallback: int) -> int:
	var key: String = String(name).to_upper()
	if enum_dict.has(key):
		return int(enum_dict[key])
	push_error("RoomState: unknown value '%s'" % name)
	return fallback

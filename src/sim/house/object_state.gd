## One object with a discrete state from a fixed list, e.g. the stove
## (working / broken) or the grocery basket (available / hidden).
class_name ObjectState
extends RefCounted

var id: String = ""
var display_name: String = ""
var room_id: String = ""
var allowed_states: Array[StringName] = []
var state: StringName = &""
## Repair data, or empty when the object cannot be repaired:
## [code]{"broken": "broken", "fixed": "working", "critical": true}[/code].
var repair: Dictionary = {}


## True when the object is in its repairable broken state.
func needs_repair() -> bool:
	return not repair.is_empty() and state == StringName(repair.get("broken", ""))


static func from_dict(data: Dictionary) -> ObjectState:
	var obj := ObjectState.new()
	var repair_data: Variant = data.get("repair", {})
	if repair_data is Dictionary:
		obj.repair = repair_data
	obj.id = String(data.get("id", ""))
	obj.display_name = String(data.get("name", obj.id))
	obj.room_id = String(data.get("room", ""))
	for value: Variant in data.get("states", []):
		obj.allowed_states.append(StringName(value))
	obj.state = StringName(data.get("state", ""))
	if not obj.allowed_states.has(obj.state):
		push_error("ObjectState %s: initial state '%s' is not allowed" % [obj.id, obj.state])
	return obj


func allows(new_state: StringName) -> bool:
	return allowed_states.has(new_state)

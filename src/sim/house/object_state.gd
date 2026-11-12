## One object with a discrete state from a fixed list, e.g. the stove
## (working / broken) or the grocery basket (available / hidden).
class_name ObjectState
extends RefCounted

var id: String = ""
var display_name: String = ""
var room_id: String = ""
var allowed_states: Array[StringName] = []
var state: StringName = &""


static func from_dict(data: Dictionary) -> ObjectState:
	var obj := ObjectState.new()
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

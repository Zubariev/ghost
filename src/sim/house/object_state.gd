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
## "lamp" or "window" when the object drives its room's light or temperature; else "".
var kind: String = ""
## For a lamp: the state in which it gives light. For a window: the state in which it is open.
var condition_state: StringName = &""
## What the ghost can do to it, [code]{"to": "out"}[/code], or empty.
var ghost: Dictionary = {}
## Whoever needs it can put it right themselves, e.g. search for hidden groceries:
## [code]{"from": "hidden", "to": "available", "minutes": 20}[/code], or empty.
var self_fix: Dictionary = {}


## The role that puts it right ("repair" or "clean"); "repair" when unspecified.
func repair_role() -> String:
	return String(repair.get("role", "repair"))


## True when someone who needs it can fix it themselves from its current state.
func can_self_fix() -> bool:
	return not self_fix.is_empty() and state == StringName(self_fix.get("from", ""))


## True when the object is in its repairable broken state.
func needs_repair() -> bool:
	return not repair.is_empty() and state == StringName(repair.get("broken", ""))


static func from_dict(data: Dictionary) -> ObjectState:
	var obj := ObjectState.new()
	var repair_data: Variant = data.get("repair", {})
	if repair_data is Dictionary:
		obj.repair = repair_data
	obj.kind = String(data.get("kind", ""))
	obj.condition_state = StringName(data.get("condition_state", ""))
	var ghost_data: Variant = data.get("ghost", {})
	if ghost_data is Dictionary:
		obj.ghost = ghost_data
	var self_fix_data: Variant = data.get("self_fix", {})
	if self_fix_data is Dictionary:
		obj.self_fix = self_fix_data
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

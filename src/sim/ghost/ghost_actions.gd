## What the ghost can do to objects (stage 5a: snuff a lamp, open a window, jam the stove,
## hide the groceries). One way only: undoing is the family's job (GDD §9.7).
##
## [codeblock]
## if GhostActions.can_act(house, "lamp_kitchen"):
##     GhostActions.act(house, "lamp_kitchen")   # lamp → out; the kitchen darkens
## [/codeblock]
class_name GhostActions
extends RefCounted


## True when the object has a ghost action and is not already in its result state.
static func can_act(house: HouseState, object_id: String) -> bool:
	if not house.objects.has(object_id):
		return false
	var obj: ObjectState = house.objects[object_id]
	if obj.ghost.is_empty():
		return false
	return obj.state != StringName(obj.ghost.get("to", ""))


## Applies the object's ghost action; returns false when it cannot be done.
static func act(house: HouseState, object_id: String) -> bool:
	if not can_act(house, object_id):
		return false
	return house.set_object_state(object_id, StringName(house.objects[object_id].ghost["to"]))

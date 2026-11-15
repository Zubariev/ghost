## One piece of household work (GDD §10.4): repair a broken object, or clean a room.
## Built fresh by [TaskBoard] from the house's current state; never stored in data.
class_name HouseTask
extends RefCounted

enum Type { REPAIR, CLEAN }

## Stable identity, e.g. "repair:stove" or "clean:kitchen". Claims use it.
var key: String = ""
var type: Type = Type.REPAIR
var target_id: String = ""
var room_id: String = ""
var priority: int = 0
var work_minutes: int = 0
var on_success: Array[Dictionary] = []
## Position in the data, the last tie-breaker (keeps choices repeatable).
var order: int = 0


## The task as plain data (save games).
func to_dict() -> Dictionary:
	return {"key": key, "type": int(type), "target_id": target_id, "room_id": room_id, "priority": priority,
		"work_minutes": work_minutes, "on_success": on_success.duplicate(true), "order": order}


static func from_dict(data: Dictionary) -> HouseTask:
	var task := HouseTask.new()
	task.key = String(data["key"])
	task.type = int(data["type"]) as Type
	task.target_id = String(data["target_id"])
	task.room_id = String(data["room_id"])
	task.priority = int(data["priority"])
	task.work_minutes = int(data["work_minutes"])
	task.on_success.assign(data["on_success"])
	task.order = int(data["order"])
	return task

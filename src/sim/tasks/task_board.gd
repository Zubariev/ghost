## The household's open tasks, read from the house's current state, and who has claimed them.
##
## Approved rules (stage 3, GDD §10.4):
## [br]- every object in its broken state is a task for the role its data names (lamps and
##   the stove: repair; open windows: clean); critical objects rank higher;
## [br]- every room that is not clean is a clean task (dirty ranks above a cosmetic tidy);
## [br]- a worker gets the highest-priority unclaimed task for their role; ties go to the
##   shorter walk, then to data order; unreachable tasks are passed over;
## [br]- two workers never hold the same task.
##
## [codeblock]
## var board := TaskBoard.new(house, JsonData.read("res://assets/data/sim/tasks.json"))
## var task: HouseTask = board.pick("repair", "father", "workshop", [])
## # ... when done or abandoned:
## board.release(task.key, "father")
## [/codeblock]
class_name TaskBoard
extends RefCounted

const ROLE_REPAIR: String = "repair"
const ROLE_CLEAN: String = "clean"

var _house: HouseState
var _config: Dictionary
## task key -> npc id
var _claims: Dictionary[String, String] = {}


func _init(house: HouseState, config: Dictionary) -> void:
	_house = house
	_config = config


## Every open task for [param role], unclaimed or not, in data order.
func tasks_for_role(role: String) -> Array[HouseTask]:
	var result: Array[HouseTask] = []
	var repair_cfg: Dictionary = _config.get("repair", {})
	var clean_cfg: Dictionary = _config.get("clean", {})
	for obj: ObjectState in _house.objects.values():
		if obj.needs_repair() and obj.repair_role() == role:
			var task := HouseTask.new()
			task.key = "repair:%s" % obj.id
			task.type = HouseTask.Type.REPAIR
			task.target_id = obj.id
			task.room_id = obj.room_id
			if role == ROLE_CLEAN:
				task.priority = int(clean_cfg.get("object_priority", 5))
				task.work_minutes = int(obj.repair.get("work_minutes", clean_cfg.get("work_minutes", 30)))
			else:
				task.priority = int(repair_cfg.get("critical_priority" if bool(obj.repair.get("critical", false)) else "priority", 5))
				task.work_minutes = int(obj.repair.get("work_minutes", repair_cfg.get("work_minutes", 45)))
			task.on_success = [{"object": obj.id, "set": String(obj.repair.get("fixed", ""))}]
			task.order = result.size()
			result.append(task)
	if role == ROLE_CLEAN:
		for room: RoomState in _house.rooms.values():
			if room.cleanliness == RoomState.Cleanliness.CLEAN:
				continue
			var task := HouseTask.new()
			task.key = "clean:%s" % room.id
			task.type = HouseTask.Type.CLEAN
			task.target_id = room.id
			task.room_id = room.id
			var dirty: bool = room.cleanliness == RoomState.Cleanliness.DIRTY
			task.priority = int(clean_cfg.get("dirty_priority" if dirty else "normal_priority", 2))
			task.work_minutes = int(clean_cfg.get("work_minutes", 30))
			task.on_success = [{"room": room.id, "cleanliness": "clean"}]
			task.order = result.size()
			result.append(task)
	return result


## Claims and returns the best task for [param npc_id], or null when none is available.
## [param room_filter] limits the choice to those rooms (empty = any room).
func pick(role: String, npc_id: String, from_room: String, room_filter: Array[String]) -> HouseTask:
	var best: HouseTask = null
	var best_cost: int = 0
	for task: HouseTask in tasks_for_role(role):
		if not room_filter.is_empty() and not room_filter.has(task.room_id):
			continue
		if _claims.has(task.key) and _claims[task.key] != npc_id:
			continue
		var cost: int = _house.path_cost(from_room, task.room_id)
		if cost < 0:
			continue
		if best == null or task.priority > best.priority \
				or (task.priority == best.priority and cost < best_cost) \
				or (task.priority == best.priority and cost == best_cost and task.order < best.order):
			best = task
			best_cost = cost
	if best != null:
		_claims[best.key] = npc_id
	return best


## Frees a claim held by [param npc_id]; does nothing for anyone else's claim.
func release(task_key: String, npc_id: String) -> void:
	if _claims.get(task_key, "") == npc_id:
		_claims.erase(task_key)


func claimed_by(task_key: String) -> String:
	return _claims.get(task_key, "")

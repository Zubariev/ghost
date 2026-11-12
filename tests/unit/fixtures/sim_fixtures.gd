## Factory functions for simulation tests: a tiny house and a short schedule,
## built from dictionaries (no file I/O). Numbers here are fixture values, not tuning.
extends RefCounted

const WALK: int = 2
const STEP: int = 15
const COOK_MINUTES: int = 30
const COOK_START: int = 9 * 60        # 09:00
const MEAL_START: int = 10 * 60       # 10:00
const MEAL_END: int = 11 * 60         # 11:00
const CRITICAL_PRIORITY: int = 9
const REPAIR_PRIORITY: int = 5
const REPAIR_MINUTES: int = 45
const CLEAN_MINUTES: int = 30


## bedroom — kitchen — dining, each door WALK minutes.
static func house_data() -> Dictionary:
	return {
		"rooms": [
			{"id": "bedroom", "name": "Bedroom"},
			{"id": "kitchen", "name": "Kitchen"},
			{"id": "dining", "name": "Dining"},
			{"id": "cellar", "name": "Cellar"},
		],
		"doors": [
			{"a": "bedroom", "b": "kitchen", "walk_minutes": WALK},
			{"a": "kitchen", "b": "dining", "walk_minutes": WALK},
		],
		"objects": [
			{"id": "lamp", "room": "bedroom", "states": ["working", "broken"], "state": "working",
				"repair": {"broken": "broken", "fixed": "working", "critical": false}},
			{"id": "stove", "room": "kitchen", "states": ["working", "broken"], "state": "working",
				"repair": {"broken": "broken", "fixed": "working", "critical": true}},
			{"id": "basket", "room": "kitchen", "states": ["available", "hidden"], "state": "available"},
			{"id": "food", "room": "dining", "states": ["none", "ready"], "state": "none"},
		],
	}


## Sleep until 09:00, cook 09:00–10:00 (COOK_MINUTES of work), eat 10:00–11:00, rest after.
static func schedule_data() -> Dictionary:
	return {
		"npc_id": "tester",
		"name": "Tester",
		"start_room": "bedroom",
		"activities": [
			{"id": "sleep", "start": "00:00", "end": "09:00", "kind": "span", "room": "bedroom"},
			{"id": "cook", "start": "09:00", "end": "10:00", "kind": "work", "work_minutes": COOK_MINUTES,
				"room": "kitchen", "target": "stove",
				"requires": [{"object": "basket", "state": "available"}, {"object": "stove", "state": "working"}],
				"on_success": [{"object": "food", "set": "ready"}]},
			{"id": "meal", "start": "10:00", "end": "11:00", "kind": "span", "room": "dining",
				"requires": [{"object": "food", "state": "ready"}],
				"on_end": [{"object": "food", "set": "none"}]},
			{"id": "rest", "start": "11:00", "end": "00:00", "kind": "span", "room": "bedroom"},
		],
	}


static func task_config() -> Dictionary:
	return {
		"repair": {"work_minutes": REPAIR_MINUTES, "critical_priority": CRITICAL_PRIORITY, "priority": REPAIR_PRIORITY},
		"clean": {"work_minutes": CLEAN_MINUTES, "dirty_priority": 5, "normal_priority": 2},
	}


## A worker: rests in the bedroom, works [role] tasks 09:00–10:00 (idle in [idle_room]),
## rests after.
static func worker_schedule_data(npc_id: String, role: String, idle_room: String) -> Dictionary:
	return {
		"npc_id": npc_id,
		"name": npc_id,
		"start_room": idle_room,
		"activities": [
			{"id": npc_id + "_rest_am", "start": "00:00", "end": "09:00", "kind": "span", "room": idle_room},
			{"id": npc_id + "_work", "start": "09:00", "end": "10:00", "kind": "tasks", "role": role,
				"idle_room": idle_room},
			{"id": npc_id + "_rest_pm", "start": "10:00", "end": "00:00", "kind": "span", "room": idle_room},
		],
	}


static func worker(house_state: HouseState, board: TaskBoard, npc_id: String, role: String, idle_room: String) -> NpcRoutine:
	return NpcRoutine.new(Schedule.from_dict(worker_schedule_data(npc_id, role, idle_room)), house_state, STEP, board)


static func house() -> HouseState:
	return HouseState.from_dict(house_data())


static func routine(house_state: HouseState) -> NpcRoutine:
	return NpcRoutine.new(Schedule.from_dict(schedule_data()), house_state, STEP)


## Spends every minute in [from_minute, to_minute).
static func run(routine_under_test: NpcRoutine, from_minute: int, to_minute: int) -> void:
	for minute: int in range(from_minute, to_minute):
		routine_under_test.step(minute % GameClock.MINUTES_PER_DAY)

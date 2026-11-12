## Factory functions for simulation tests: a tiny house and a short schedule,
## built from dictionaries (no file I/O). Numbers here are fixture values, not tuning.
extends RefCounted

const WALK: int = 2
const STEP: int = 15
const COOK_MINUTES: int = 30
const COOK_START: int = 9 * 60        # 09:00
const MEAL_START: int = 10 * 60       # 10:00
const MEAL_END: int = 11 * 60         # 11:00


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
			{"id": "stove", "room": "kitchen", "states": ["working", "broken"], "state": "working"},
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
				"on_start": [{"object": "food", "set": "none"}]},
			{"id": "rest", "start": "11:00", "end": "00:00", "kind": "span", "room": "bedroom"},
		],
	}


static func house() -> HouseState:
	return HouseState.from_dict(house_data())


static func routine(house_state: HouseState) -> NpcRoutine:
	return NpcRoutine.new(Schedule.from_dict(schedule_data()), house_state, STEP)


## Spends every minute in [from_minute, to_minute).
static func run(routine_under_test: NpcRoutine, from_minute: int, to_minute: int) -> void:
	for minute: int in range(from_minute, to_minute):
		routine_under_test.step(minute % GameClock.MINUTES_PER_DAY)

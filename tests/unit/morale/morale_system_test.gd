## Morale rules (GDD §8, Demo Specification §7, values approved 2026-11-12).
## Fixture timeline (one NPC from 09:00): walks to the kitchen, cooks 09:02–09:31 (needs light),
## walks to the dining room, eats 10:01–11:00, then rests in the bedroom from 11:00.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState
var _routine: NpcRoutine
var _morale: MoraleSystem
var _deltas: Dictionary = {}     # reason -> summed delta
var _counts: Dictionary = {}     # reason -> times applied


func before_test() -> void:
	_house = Fx.house()
	_routine = Fx.routine(_house)
	_deltas = {}
	_counts = {}


func _start(routines: Array[NpcRoutine], begin_minute: int, rules: Dictionary = Fx.morale_rules()) -> void:
	_morale = MoraleSystem.new(rules, _house, routines)
	_morale.morale_changed.connect(func(_npc: String, _value: int, delta: int, reason: String) -> void:
		_deltas[reason] = int(_deltas.get(reason, 0)) + delta
		_counts[reason] = int(_counts.get(reason, 0)) + 1)
	for routine: NpcRoutine in routines:
		routine.begin(begin_minute)


func _one() -> Array[NpcRoutine]:
	return [_routine]


## The tester plus a healthy second member, so one Broken person is not the whole family
## (with everyone at the threshold the family would simply leave).
func _two() -> Array[NpcRoutine]:
	var other := NpcRoutine.new(Schedule.from_dict(Fx.worker_schedule_data("other", "clean", "bedroom")), _house, Fx.STEP)
	return [_routine, other]


func test_starts_at_configured_morale() -> void:
	_start(_one(), Fx.COOK_START)
	assert_int(_morale.get_morale("tester")).is_equal(80)


func test_meal_in_good_dining_room_gives_meal_bonus() -> void:
	_start(_one(), Fx.COOK_START)
	Fx.run_with_morale(_morale, _one(), Fx.COOK_START, Fx.MEAL_END + 1)
	assert_int(int(_deltas.get("meal_good", 0))).is_equal(10)
	assert_int(int(_deltas.get("activity_good", 0))).is_equal(3)   # the cooking itself


func test_meal_in_dirty_dining_room_gives_small_bonus_and_dirt_penalty() -> void:
	_house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	_start(_one(), Fx.COOK_START)
	Fx.run_with_morale(_morale, _one(), Fx.COOK_START, Fx.MEAL_END + 1)
	assert_int(int(_deltas.get("meal_poor", 0))).is_equal(3)
	assert_bool(_deltas.has("meal_good")).is_false()
	assert_int(int(_deltas.get("dirty", 0))).is_equal(-2)       # one half-hour tick, 10:30


func test_missed_meal_costs_hunger_at_window_end() -> void:
	_house.set_object_state("stove", &"broken")
	_start(_one(), Fx.COOK_START)
	Fx.run_with_morale(_morale, _one(), Fx.COOK_START, Fx.MEAL_END)
	assert_bool(_deltas.has("missed_meal")).is_false()
	Fx.run_with_morale(_morale, _one(), Fx.MEAL_END, Fx.MEAL_END + 1)
	assert_int(int(_deltas.get("missed_meal", 0))).is_equal(-8)


func test_dark_room_costs_once_and_removes_the_bonus() -> void:
	_house.set_room_light("kitchen", RoomState.Light.DARK)
	_start(_one(), Fx.COOK_START)
	Fx.run_with_morale(_morale, _one(), Fx.COOK_START, Fx.MEAL_START)
	assert_int(int(_counts.get("dark", 0))).is_equal(1)
	assert_int(int(_deltas.get("dark", 0))).is_equal(-4)
	assert_bool(_deltas.has("activity_good")).is_false()


func test_walking_through_a_dirty_room_costs_nothing() -> void:
	# Arrange: food ready; from the bedroom she walks through the dirty kitchen to eat
	_house.set_object_state("food", &"ready")
	_house.set_room_cleanliness("kitchen", RoomState.Cleanliness.DIRTY)
	_start(_one(), Fx.MEAL_START)
	# Act
	Fx.run_with_morale(_morale, _one(), Fx.MEAL_START, Fx.MEAL_END + 1)
	# Assert
	assert_bool(_deltas.has("dirty")).is_false()
	assert_int(int(_deltas.get("meal_good", 0))).is_equal(10)


func test_cold_penalties_stop_at_the_cap_per_activity() -> void:
	# Arrange: resting from 11:00 in a cold bedroom; ticks at every half hour
	_house.set_room_temperature("bedroom", RoomState.Temperature.COLD)
	_start(_one(), Fx.MEAL_END)
	# Act: 8 half-hour ticks (11:00 … 14:30) would be −24 uncapped
	Fx.run_with_morale(_morale, _one(), Fx.MEAL_END, Fx.MEAL_END + 240)
	# Assert
	assert_int(int(_deltas.get("cold", 0))).is_equal(-10)


func test_finished_task_gives_the_worker_a_bonus() -> void:
	var board := TaskBoard.new(_house, Fx.task_config())
	for room_id: String in _house.rooms:
		_house.set_room_cleanliness(room_id, RoomState.Cleanliness.CLEAN)
	_house.set_object_state("stove", &"broken")
	var fixer: NpcRoutine = Fx.worker(_house, board, "fixer", "repair", "kitchen")
	var routines: Array[NpcRoutine] = [fixer]
	_start(routines, Fx.COOK_START)
	Fx.run_with_morale(_morale, routines, Fx.COOK_START, Fx.COOK_START + Fx.REPAIR_MINUTES + 1)
	assert_int(int(_deltas.get("task_done", 0))).is_equal(3)
	assert_int(_morale.get_morale("fixer")).is_equal(83)


func test_broken_at_threshold_stops_the_schedule_and_recovers_to_15() -> void:
	# Arrange
	var family: Array[NpcRoutine] = _two()
	_start(family, Fx.COOK_START)
	var broke: Array[String] = []
	var recovered: Array[String] = []
	_morale.npc_broke.connect(func(npc: String) -> void: broke.append(npc))
	_morale.npc_recovered.connect(func(npc: String) -> void: recovered.append(npc))
	# Act: morale drops to the threshold
	_morale.set_morale("tester", 10)
	# Assert: Broken at once
	assert_array(broke).contains_exactly(["tester"])
	assert_bool(_routine.is_broken()).is_true()
	# Act: +1 every 10 minutes, 10 → 15 takes 50 minutes
	Fx.run_with_morale(_morale, family, Fx.COOK_START, Fx.COOK_START + 49)
	assert_bool(_routine.is_broken()).is_true()
	Fx.run_with_morale(_morale, family, Fx.COOK_START + 49, Fx.COOK_START + 50)
	# Assert: back on the schedule at 15
	assert_array(recovered).contains_exactly(["tester"])
	assert_int(_morale.get_morale("tester")).is_equal(15)
	assert_bool(_routine.is_broken()).is_false()
	assert_str(_routine.current.id).is_equal("cook")


func test_no_penalties_while_broken() -> void:
	# Arrange: no food today and a dark kitchen, but she is Broken through the meal window
	_house.set_object_state("stove", &"broken")
	_house.set_room_light("kitchen", RoomState.Light.DARK)
	var family: Array[NpcRoutine] = _two()
	_start(family, Fx.COOK_START)
	_morale.set_morale("tester", 0)
	# Act: 2 hours
	Fx.run_with_morale(_morale, family, Fx.COOK_START, Fx.COOK_START + 120)
	# Assert: only recovery moved morale (the family has not left: "other" is fine)
	assert_str(_morale.outcome).is_equal("")
	assert_bool(_deltas.has("missed_meal")).is_false()
	assert_bool(_deltas.has("dark")).is_false()
	assert_int(_morale.get_morale("tester")).is_equal(12)


func test_family_leaves_when_the_average_reaches_the_threshold() -> void:
	# Arrange: two members; the family leaves at an average of 20 (decision 2026-11-15)
	var routines: Array[NpcRoutine] = _two()
	_start(routines, Fx.COOK_START)
	var left: Array[bool] = []
	_morale.family_left.connect(func(_total: int) -> void: left.append(true))
	# Act / Assert: average 20.5 is not enough
	_morale.set_morale("tester", 30)
	_morale.set_morale("other", 11)
	assert_array(left).is_empty()
	# Act: average 20
	_morale.set_morale("other", 10)
	# Assert
	assert_array(left).has_size(1)
	assert_str(_morale.outcome).is_equal("won")
	assert_float(_morale.family_average()).is_equal(20.0)


func test_leave_threshold_comes_from_the_rules() -> void:
	# Arrange
	var rules: Dictionary = Fx.morale_rules()
	rules["family_leaves_at_average"] = 33
	# Act
	_start(_one(), Fx.COOK_START, rules)
	# Assert
	assert_int(_morale.leave_threshold()).is_equal(33)


func test_one_broken_member_alone_does_not_make_them_leave() -> void:
	# Arrange
	var routines: Array[NpcRoutine] = _two()
	_start(routines, Fx.COOK_START)
	# Act
	_morale.set_morale("tester", 0)
	# Assert: average 40
	assert_bool(_morale.is_broken("tester")).is_true()
	assert_str(_morale.outcome).is_equal("")


## The cook (tester) and a diner who only eats.
func _late_food_routines(cook_minutes: int, second_cook: bool) -> Array[NpcRoutine]:
	_routine = NpcRoutine.new(Schedule.from_dict(Fx.late_food_schedule_data(cook_minutes, second_cook)), _house, Fx.STEP)
	var diner := NpcRoutine.new(Schedule.from_dict(Fx.diner_schedule_data()), _house, Fx.STEP)
	return [_routine, diner]


func test_food_cooked_after_its_meal_window_makes_a_poor_meal() -> void:
	# Arrange: 150 minutes of cooking from 09:00 finish after breakfast (10:00–11:00) ended
	var routines: Array[NpcRoutine] = _late_food_routines(150, false)
	_start(routines, Fx.COOK_START)
	# Act
	Fx.run_with_morale(_morale, routines, Fx.COOK_START, 13 * 60 + 1)
	# Assert: the diner missed breakfast; both eat the late food at lunch as a poor meal
	assert_int(int(_deltas.get("missed_meal", 0))).is_equal(-8)
	assert_int(int(_counts.get("meal_cold", 0))).is_equal(2)
	assert_int(int(_deltas.get("meal_cold", 0))).is_equal(6)
	assert_bool(_deltas.has("meal_good")).is_false()


func test_food_cooked_fresh_after_a_missed_meal_is_a_good_meal() -> void:
	# Arrange: the stove is broken for breakfast's cooking, fixed before lunch's
	var routines: Array[NpcRoutine] = _late_food_routines(Fx.COOK_MINUTES, true)
	_house.set_object_state("stove", &"broken")
	_start(routines, Fx.COOK_START)
	Fx.run_with_morale(_morale, routines, Fx.COOK_START, 11 * 60)
	_house.set_object_state("stove", &"working")
	# Act
	Fx.run_with_morale(_morale, routines, 11 * 60, 13 * 60 + 1)
	# Assert: both missed breakfast; lunch is freshly cooked
	assert_int(int(_deltas.get("missed_meal", 0))).is_equal(-16)
	assert_int(int(_counts.get("meal_good", 0))).is_equal(2)
	assert_bool(_deltas.has("meal_cold")).is_false()


func test_scenario_is_lost_when_the_last_day_ends() -> void:
	_start(_one(), 23 * 60 + 58, Fx.morale_rules(1))
	var lost: Array[bool] = []
	_morale.scenario_lost.connect(func(_total: int) -> void: lost.append(true))
	Fx.run_with_morale(_morale, _one(), 23 * 60 + 58, 23 * 60 + 59)
	assert_array(lost).is_empty()
	Fx.run_with_morale(_morale, _one(), 23 * 60 + 59, 24 * 60)
	assert_str(_morale.outcome).is_equal("lost")


func test_sleep_started_late_costs_on_waking_and_skipped_sleep_costs_more() -> void:
	# Arrange: sleep 22:00–06:00 needs the lamp; it is broken until 22:40 for the sleeper
	var data: Dictionary = {
		"npc_id": "sleeper", "name": "Sleeper", "start_room": "bedroom",
		"activities": [
			{"id": "day", "start": "06:00", "end": "22:00", "kind": "span", "room": "bedroom"},
			{"id": "night", "start": "22:00", "end": "06:00", "kind": "span", "room": "bedroom",
				"category": "sleep", "requires": [{"object": "lamp", "state": "working"}]},
		],
	}
	var sleeper := NpcRoutine.new(Schedule.from_dict(data), _house, Fx.STEP)
	var routines: Array[NpcRoutine] = [sleeper]
	_house.set_object_state("lamp", &"broken")
	_start(routines, 22 * 60)
	Fx.run_with_morale(_morale, routines, 22 * 60, 22 * 60 + 40)
	_house.set_object_state("lamp", &"working")
	# Act: through the night to waking
	Fx.run_with_morale(_morale, routines, 22 * 60 + 40, 30 * 60 + 1)
	# Assert
	assert_int(int(_deltas.get("sleep_late", 0))).is_equal(-5)
	# Act: a night with the lamp broken throughout
	_house.set_object_state("lamp", &"broken")
	Fx.run_with_morale(_morale, routines, 30 * 60 + 1, 54 * 60 + 1)
	# Assert
	assert_int(int(_deltas.get("sleep_skipped", 0))).is_equal(-12)

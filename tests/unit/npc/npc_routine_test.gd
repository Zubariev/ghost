## Grandma's routine rules (GDD §6.2–6.5, Demo Specification §5.3–5.6) on a fixture house.
## Fixture timeline: from 09:00 she walks 2 min to the kitchen, arriving at 09:02;
## work counts from 09:02, so 30 minutes of cooking end with the minute 09:31.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState
var _routine: NpcRoutine
var _skipped: Array[String] = []
var _completed: Array[String] = []


func before_test() -> void:
	_house = Fx.house()
	_routine = Fx.routine(_house)
	_skipped = []
	_completed = []
	_routine.activity_skipped.connect(func(a: Activity, _done: int) -> void: _skipped.append(a.id))
	_routine.activity_completed.connect(func(a: Activity) -> void: _completed.append(a.id))
	_routine.begin(Fx.COOK_START)


func test_walk_to_kitchen_takes_walk_minutes() -> void:
	# Act
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK - 1)
	# Assert: still on the way after WALK - 1 minutes
	assert_int(_routine.state).is_equal(NpcRoutine.State.MOVING)
	Fx.run(_routine, Fx.COOK_START + Fx.WALK - 1, Fx.COOK_START + Fx.WALK)
	assert_str(_routine.room_id).is_equal("kitchen")
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)


func test_cooking_completes_after_work_minutes_and_food_is_ready() -> void:
	var done_at: int = Fx.COOK_START + Fx.WALK + Fx.COOK_MINUTES
	# Act: one minute short
	Fx.run(_routine, Fx.COOK_START, done_at - 1)
	# Assert
	assert_str(String(_house.get_object_state("food"))).is_equal("none")
	# Act: the last minute of work
	Fx.run(_routine, done_at - 1, done_at)
	# Assert
	assert_str(String(_house.get_object_state("food"))).is_equal("ready")
	assert_array(_completed).contains(["cook"])
	assert_int(_routine.state).is_equal(NpcRoutine.State.SCHEDULED)


func test_unmet_requirement_waits_then_skips_at_window_end() -> void:
	# Arrange
	_house.set_object_state("basket", &"hidden")
	# Act
	Fx.run(_routine, Fx.COOK_START, Fx.MEAL_START)
	# Assert: through 09:59 she waits in the kitchen, nothing skipped yet
	assert_int(_routine.state).is_equal(NpcRoutine.State.WAITING)
	assert_str(_routine.room_id).is_equal("kitchen")
	assert_array(_skipped).is_empty()
	# Act: the minute 10:00 — the cooking window has ended
	Fx.run(_routine, Fx.MEAL_START, Fx.MEAL_START + 1)
	# Assert: cooking skipped, no food, now pursuing the meal
	assert_array(_skipped).contains(["cook"])
	assert_str(String(_house.get_object_state("food"))).is_equal("none")
	assert_str(_routine.current.id).is_equal("meal")


func test_no_food_skips_meal_and_next_window_is_not_shifted() -> void:
	# Arrange
	_house.set_object_state("stove", &"broken")
	# Act: through the meal window
	Fx.run(_routine, Fx.COOK_START, Fx.MEAL_END + 1)
	# Assert: meal skipped at 11:00; rest started on time in the bedroom route
	assert_array(_skipped).contains(["cook", "meal"])
	assert_str(_routine.current.id).is_equal("rest")


func test_stove_broken_mid_work_finishes_current_step_then_waits() -> void:
	# Arrange: work starts at 09:02; first step is minutes 09:02..09:16
	var step_end: int = Fx.COOK_START + Fx.WALK + Fx.STEP
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + 5)
	# Act: the ghost breaks the stove 5 minutes into the step
	_house.set_object_state("stove", &"broken")
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 5, step_end - 1)
	# Assert: the current step is never interrupted
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)
	Fx.run(_routine, step_end - 1, step_end)
	# Assert: after the step, she waits with her progress kept
	assert_int(_routine.state).is_equal(NpcRoutine.State.WAITING)
	assert_int(_routine.work_done_minutes).is_equal(Fx.STEP)


func test_progress_is_kept_after_repair() -> void:
	# Arrange: broken during the first step, repaired 10 minutes after it ends
	var step_end: int = Fx.COOK_START + Fx.WALK + Fx.STEP
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + 1)
	_house.set_object_state("stove", &"broken")
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 1, step_end + 10)
	_house.set_object_state("stove", &"working")
	# Act: the remaining COOK_MINUTES - STEP minutes, counted from the minute after repair
	var resume: int = step_end + 10
	Fx.run(_routine, resume, resume + 1 + (Fx.COOK_MINUTES - Fx.STEP))
	# Assert
	assert_str(String(_house.get_object_state("food"))).is_equal("ready")


func test_running_work_finishes_after_window_end() -> void:
	# Arrange: hidden groceries until 09:50, so work starts at 09:50 and runs to 10:20
	_house.set_object_state("basket", &"hidden")
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + 50)
	_house.set_object_state("basket", &"available")
	# Act: past the cooking window's end (10:00) but before the work is done
	Fx.run(_routine, Fx.COOK_START + 50, Fx.MEAL_START + 5)
	# Assert: still cooking, not skipped
	assert_str(_routine.current.id).is_equal("cook")
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)
	assert_array(_skipped).is_empty()


func test_meal_waits_for_late_food_then_eats_until_window_end() -> void:
	# Arrange: as above, food ready late (about 10:20)
	_house.set_object_state("basket", &"hidden")
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + 50)
	_house.set_object_state("basket", &"available")
	# Act
	Fx.run(_routine, Fx.COOK_START + 50, Fx.MEAL_START + 40)
	# Assert: eating late, food used
	assert_str(_routine.current.id).is_equal("meal")
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)
	assert_str(String(_house.get_object_state("food"))).is_equal("none")
	# Act: the meal still ends with its window (late start does not extend it)
	Fx.run(_routine, Fx.MEAL_START + 40, Fx.MEAL_END + 1)
	assert_array(_completed).contains(["cook", "meal"])
	assert_str(_routine.current.id).is_equal("rest")


func test_waiting_work_is_abandoned_when_window_ends() -> void:
	# Arrange: broken mid-work and never repaired
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + 1)
	_house.set_object_state("stove", &"broken")
	# Act
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 1, Fx.MEAL_START + 1)
	# Assert
	assert_array(_skipped).contains(["cook"])
	assert_str(String(_house.get_object_state("food"))).is_equal("none")


func test_unreachable_room_waits_in_place() -> void:
	# Arrange: a schedule entry in the cellar, which has no door
	var schedule: Schedule = Schedule.from_dict(Fx.schedule_data())
	schedule.activities[1].room_id = "cellar"
	var routine := NpcRoutine.new(schedule, _house, Fx.STEP)
	routine.begin(Fx.COOK_START)
	# Act
	Fx.run(routine, Fx.COOK_START, Fx.COOK_START + 10)
	# Assert: she never picks a different room
	assert_int(routine.state).is_equal(NpcRoutine.State.WAITING)
	assert_str(routine.room_id).is_equal("bedroom")

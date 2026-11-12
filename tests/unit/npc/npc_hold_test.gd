## Holding a routine for a ghost sighting (Demo Specification §8.8, approved 2026-11-13):
## the activity is suspended with its progress kept; on release it resumes only if its
## window is still open, otherwise it is skipped — even work that would finish late.
## Fixture: walks to the kitchen 09:00–09:01, cooks from 09:02 (30 min), meal 10:00–11:00.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState
var _routine: NpcRoutine
var _skipped: Array[String] = []


func before_test() -> void:
	_house = Fx.house()
	_routine = Fx.routine(_house)
	_skipped = []
	_routine.activity_skipped.connect(func(a: Activity, _d: int) -> void: _skipped.append(a.id))
	_routine.begin(Fx.COOK_START)


func test_hold_keeps_progress_and_release_resumes_without_repeating_work() -> void:
	# Arrange: 10 minutes of cooking done (09:02–09:11)
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + 10)
	assert_int(_routine.work_done_minutes).is_equal(10)
	# Act: held for 5 minutes, then released inside the window
	assert_bool(_routine.hold()).is_true()
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 15)
	# Assert: nothing advanced while held
	assert_int(_routine.state).is_equal(NpcRoutine.State.HELD)
	assert_int(_routine.work_done_minutes).is_equal(10)
	_routine.release(Fx.COOK_START + Fx.WALK + 15)
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)
	assert_int(_routine.work_done_minutes).is_equal(10)
	# Act: the remaining 20 minutes finish the cooking
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 15, Fx.COOK_START + Fx.WALK + 35)
	assert_str(String(_house.get_object_state("food"))).is_equal("ready")


func test_window_expiring_while_held_skips_the_activity() -> void:
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + 10)
	_routine.hold()
	Fx.run(_routine, Fx.COOK_START + Fx.WALK + 10, Fx.MEAL_START + 2)
	# Act: released after the cooking window has closed
	_routine.release(Fx.MEAL_START + 2)
	# Assert
	assert_array(_skipped).contains(["cook"])
	assert_str(String(_house.get_object_state("food"))).is_equal("none")
	assert_str(_routine.current.id).is_equal("meal")


func test_late_running_work_held_past_its_window_is_skipped_not_finished() -> void:
	# Arrange: groceries hidden until 09:50, so cooking runs past 10:00 (it may finish late)
	_house.set_object_state("basket", &"hidden")
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + 50)
	_house.set_object_state("basket", &"available")
	Fx.run(_routine, Fx.COOK_START + 50, Fx.MEAL_START + 2)
	assert_str(_routine.current.id).is_equal("cook")
	# Act: a sighting holds her at 10:02; released at 10:04
	_routine.hold()
	Fx.run(_routine, Fx.MEAL_START + 2, Fx.MEAL_START + 4)
	_routine.release(Fx.MEAL_START + 4)
	# Assert: the expiry rule wins over finishing late
	assert_array(_skipped).contains(["cook"])
	assert_str(_routine.current.id).is_equal("meal")


func test_held_while_walking_stays_in_place() -> void:
	_routine.hold()
	Fx.run(_routine, Fx.COOK_START, Fx.COOK_START + 10)
	assert_str(_routine.room_id).is_equal("bedroom")
	_routine.release(Fx.COOK_START + 10)
	assert_int(_routine.state).is_equal(NpcRoutine.State.MOVING)


func test_broken_cannot_be_held() -> void:
	_routine.enter_broken()
	assert_bool(_routine.hold()).is_false()
	assert_int(_routine.state).is_equal(NpcRoutine.State.BROKEN)

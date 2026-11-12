## Work windows with priority tasks (stage 3, GDD §10.4). Fixture worker: tasks 09:00–10:00.
## House: bedroom —2— kitchen —2— dining. Lamp (ordinary) in the bedroom, stove (critical)
## in the kitchen. Repair 45 min, clean 30 min, steps of 15.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState
var _board: TaskBoard


func before_test() -> void:
	_house = Fx.house()
	_board = TaskBoard.new(_house, Fx.task_config())
	# Every room clean, so cleaners only see what a test makes dirty.
	for room_id: String in _house.rooms:
		_house.set_room_cleanliness(room_id, RoomState.Cleanliness.CLEAN)


func test_fixer_repairs_broken_stove_in_work_window() -> void:
	# Arrange
	_house.set_object_state("stove", &"broken")
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "bedroom")
	fixer.begin(Fx.COOK_START)
	# Act: walk 2 (arrival minute is walking) + 45 minutes of work
	Fx.run(fixer, Fx.COOK_START, Fx.COOK_START + Fx.WALK + Fx.REPAIR_MINUTES)
	# Assert
	assert_str(String(_house.get_object_state("stove"))).is_equal("working")


func test_critical_repair_is_done_before_nearer_ordinary_one() -> void:
	# Arrange: the lamp is in the fixer's own room, the stove 2 minutes away
	_house.set_object_state("lamp", &"broken")
	_house.set_object_state("stove", &"broken")
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "bedroom")
	fixer.begin(Fx.COOK_START)
	# Act
	Fx.run(fixer, Fx.COOK_START, Fx.COOK_START + 5)
	# Assert: heading for / at the stove, lamp untouched
	assert_str(fixer.current_task.key).is_equal("repair:stove")
	assert_str(String(_house.get_object_state("lamp"))).is_equal("broken")


func test_idle_worker_potters_in_idle_room() -> void:
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "bedroom")
	fixer.begin(Fx.COOK_START)
	Fx.run(fixer, Fx.COOK_START, Fx.COOK_START + 5)
	assert_object(fixer.current_task).is_null()
	assert_str(fixer.room_id).is_equal("bedroom")
	assert_int(fixer.state).is_equal(NpcRoutine.State.PERFORMING)


func test_idle_worker_takes_new_task_only_at_step_boundary() -> void:
	# Arrange: idle from 09:00; the stove breaks at 09:05
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "bedroom")
	fixer.begin(Fx.COOK_START)
	Fx.run(fixer, Fx.COOK_START, Fx.COOK_START + 5)
	_house.set_object_state("stove", &"broken")
	# Act: up to the end of the first 15-minute idle step
	Fx.run(fixer, Fx.COOK_START + 5, Fx.COOK_START + Fx.STEP - 1)
	# Assert: still pottering mid-step
	assert_object(fixer.current_task).is_null()
	# Act: the step's last minute
	Fx.run(fixer, Fx.COOK_START + Fx.STEP - 1, Fx.COOK_START + Fx.STEP)
	# Assert: the boundary picks up the repair
	assert_str(fixer.current_task.key).is_equal("repair:stove")


func test_two_cleaners_take_different_rooms() -> void:
	# Arrange
	_house.set_room_cleanliness("kitchen", RoomState.Cleanliness.DIRTY)
	_house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	var mother: NpcRoutine = Fx.worker(_house, _board, "mother", "clean", "kitchen")
	var son: NpcRoutine = Fx.worker(_house, _board, "son", "clean", "kitchen")
	mother.begin(Fx.COOK_START)
	son.begin(Fx.COOK_START)
	# Assert
	assert_str(mother.current_task.key).is_equal("clean:kitchen")
	assert_str(son.current_task.key).is_equal("clean:dining")


func test_finished_task_leads_to_next_task() -> void:
	# Arrange: two dirty rooms, one cleaner in the kitchen
	_house.set_room_cleanliness("kitchen", RoomState.Cleanliness.DIRTY)
	_house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	var cleaner: NpcRoutine = Fx.worker(_house, _board, "cleaner", "clean", "kitchen")
	cleaner.begin(Fx.COOK_START)
	# Act: 30 minutes of cleaning in place
	Fx.run(cleaner, Fx.COOK_START, Fx.COOK_START + Fx.CLEAN_MINUTES)
	# Assert
	assert_int(_house.rooms["kitchen"].cleanliness).is_equal(RoomState.Cleanliness.CLEAN)
	assert_str(cleaner.current_task.key).is_equal("clean:dining")


func test_running_task_finishes_after_window_end() -> void:
	# Arrange: the stove breaks late, so the repair starts at 09:31 and needs 45 minutes
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "kitchen")
	fixer.begin(Fx.COOK_START)
	Fx.run(fixer, Fx.COOK_START, Fx.COOK_START + 29)
	_house.set_object_state("stove", &"broken")
	# Act: past 10:00
	Fx.run(fixer, Fx.COOK_START + 29, Fx.MEAL_START + 10)
	# Assert: still repairing, not abandoned
	assert_str(fixer.current_task.key).is_equal("repair:stove")
	assert_int(fixer.state).is_equal(NpcRoutine.State.PERFORMING)
	# Act: let it finish
	Fx.run(fixer, Fx.MEAL_START + 10, Fx.MEAL_START + 30)
	assert_str(String(_house.get_object_state("stove"))).is_equal("working")


func test_claim_is_released_when_window_ends_before_start() -> void:
	# Arrange: the fixer claims the stove at 09:59 and sets off on a 2-minute walk,
	# so the window ends before the repair can start
	_house.set_object_state("stove", &"broken")
	var fixer: NpcRoutine = Fx.worker(_house, _board, "fixer", "repair", "bedroom")
	fixer.begin(Fx.MEAL_START - 1)
	# Act: the window ends during the walk
	Fx.run(fixer, Fx.MEAL_START - 1, Fx.MEAL_START + 1)
	# Assert: the claim is free for someone else
	assert_str(_board.claimed_by("repair:stove")).is_equal("")

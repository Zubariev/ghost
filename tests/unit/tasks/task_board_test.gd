## Task generation, priority order, tie-breaks and claims (stage 3, GDD §10.4).
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState
var _board: TaskBoard
var _no_filter: Array[String] = []


func before_test() -> void:
	_house = Fx.house()
	_board = TaskBoard.new(_house, Fx.task_config())


func test_nothing_broken_means_no_repair_tasks() -> void:
	assert_object(_board.pick("repair", "fixer", "bedroom", _no_filter)).is_null()


func test_critical_repair_comes_before_ordinary_repair() -> void:
	# Arrange: the ordinary lamp is nearer than the critical stove
	_house.set_object_state("lamp", &"broken")
	_house.set_object_state("stove", &"broken")
	# Act
	var task: HouseTask = _board.pick("repair", "fixer", "bedroom", _no_filter)
	# Assert
	assert_str(task.key).is_equal("repair:stove")
	assert_int(task.priority).is_equal(Fx.CRITICAL_PRIORITY)


func test_dirty_room_comes_before_cosmetic_tidy() -> void:
	# Arrange: every room starts "normal"; make the far one dirty
	_house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	# Act
	var task: HouseTask = _board.pick("clean", "cleaner", "bedroom", _no_filter)
	# Assert
	assert_str(task.key).is_equal("clean:dining")


func test_equal_priority_goes_to_shorter_walk() -> void:
	# Arrange: all rooms "normal" (same priority); kitchen is 2 min from bedroom, dining 4
	var task: HouseTask = _board.pick("clean", "cleaner", "dining", _no_filter)
	# Assert: from the dining room, the dining room itself (0 min) wins
	assert_str(task.key).is_equal("clean:dining")


func test_claimed_task_is_not_given_to_a_second_worker() -> void:
	# Arrange
	_house.set_room_cleanliness("kitchen", RoomState.Cleanliness.DIRTY)
	var first: HouseTask = _board.pick("clean", "mother", "kitchen", _no_filter)
	# Act
	var second: HouseTask = _board.pick("clean", "son", "kitchen", _no_filter)
	# Assert
	assert_str(first.key).is_equal("clean:kitchen")
	assert_str(second.key).is_not_equal("clean:kitchen")


func test_released_task_can_be_picked_again() -> void:
	_house.set_object_state("stove", &"broken")
	var task: HouseTask = _board.pick("repair", "fixer", "kitchen", _no_filter)
	_board.release(task.key, "fixer")
	assert_str(_board.pick("repair", "helper", "kitchen", _no_filter).key).is_equal("repair:stove")


func test_unreachable_task_is_passed_over() -> void:
	_house.set_room_cleanliness("cellar", RoomState.Cleanliness.DIRTY)
	var task: HouseTask = _board.pick("clean", "cleaner", "bedroom", _no_filter)
	assert_str(task.key).is_not_equal("clean:cellar")


func test_room_filter_limits_the_choice() -> void:
	_house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	var only_kitchen: Array[String] = ["kitchen"]
	var task: HouseTask = _board.pick("clean", "cleaner", "bedroom", only_kitchen)
	assert_str(task.key).is_equal("clean:kitchen")


func test_clean_rooms_have_no_task() -> void:
	for room_id: String in _house.rooms:
		_house.set_room_cleanliness(room_id, RoomState.Cleanliness.CLEAN)
	assert_object(_board.pick("clean", "cleaner", "bedroom", _no_filter)).is_null()

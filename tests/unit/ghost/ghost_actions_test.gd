## Ghost actions and the room conditions they drive (stage 5a, approved 2026-11-13):
## a lamp lights its room; with it out, a room with a window is dim by day and dark at night,
## a room without one is dark any time; an open window makes its room cold.
## The ghost changes objects one way only; undoing is the family's job (GDD §9.7).
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

var _house: HouseState


func before_test() -> void:
	_house = Fx.house()


func test_lit_lamp_makes_the_room_bright() -> void:
	assert_int(_house.rooms["kitchen"].light).is_equal(RoomState.Light.BRIGHT)


func test_snuffed_lamp_by_day_leaves_a_room_with_a_window_dim() -> void:
	_house.set_daylight(true)
	GhostActions.act(_house, "kitchen_lamp")
	assert_int(_house.rooms["kitchen"].light).is_equal(RoomState.Light.DIM)


func test_snuffed_lamp_at_night_makes_the_room_dark() -> void:
	GhostActions.act(_house, "kitchen_lamp")
	_house.set_daylight(false)
	assert_int(_house.rooms["kitchen"].light).is_equal(RoomState.Light.DARK)


func test_snuffed_lamp_in_a_windowless_room_is_dark_by_day() -> void:
	_house.set_daylight(true)
	GhostActions.act(_house, "bedroom_lamp")
	assert_int(_house.rooms["bedroom"].light).is_equal(RoomState.Light.DARK)


func test_relit_lamp_makes_the_room_bright_again() -> void:
	GhostActions.act(_house, "bedroom_lamp")
	_house.set_object_state("bedroom_lamp", &"lit")
	assert_int(_house.rooms["bedroom"].light).is_equal(RoomState.Light.BRIGHT)


func test_open_window_makes_the_room_cold_and_closing_restores_it() -> void:
	GhostActions.act(_house, "kitchen_window")
	assert_int(_house.rooms["kitchen"].temperature).is_equal(RoomState.Temperature.COLD)
	_house.set_object_state("kitchen_window", &"closed")
	assert_int(_house.rooms["kitchen"].temperature).is_equal(RoomState.Temperature.COMFORTABLE)


func test_ghost_cannot_undo_its_own_action() -> void:
	assert_bool(GhostActions.act(_house, "kitchen_lamp")).is_true()
	assert_bool(GhostActions.can_act(_house, "kitchen_lamp")).is_false()
	assert_bool(GhostActions.act(_house, "kitchen_lamp")).is_false()
	assert_str(String(_house.get_object_state("kitchen_lamp"))).is_equal("out")


func test_object_without_a_ghost_action_cannot_be_used() -> void:
	assert_bool(GhostActions.can_act(_house, "food")).is_false()


func test_snuffed_lamp_is_a_repair_task_and_open_window_a_clean_task() -> void:
	var board := TaskBoard.new(_house, Fx.task_config())
	for room_id: String in _house.rooms:
		_house.set_room_cleanliness(room_id, RoomState.Cleanliness.CLEAN)
	GhostActions.act(_house, "kitchen_lamp")
	GhostActions.act(_house, "kitchen_window")
	var no_filter: Array[String] = []
	var repair: HouseTask = board.pick("repair", "father", "kitchen", no_filter)
	var clean: HouseTask = board.pick("clean", "mother", "kitchen", no_filter)
	assert_str(repair.key).is_equal("repair:kitchen_lamp")
	assert_int(repair.work_minutes).is_equal(Fx.LAMP_MINUTES)
	assert_str(clean.key).is_equal("repair:kitchen_window")
	assert_int(clean.priority).is_equal(Fx.OBJECT_CLEAN_PRIORITY)
	assert_int(clean.work_minutes).is_equal(Fx.WINDOW_MINUTES)


func test_grandma_searches_for_hidden_groceries_then_cooks() -> void:
	# Arrange: hidden groceries she can find herself (self-search, approved for stage 5a)
	_house.objects["basket"].self_fix = {"from": "hidden", "to": "available", "minutes": Fx.SEARCH_MINUTES}
	GhostActions.act(_house, "basket")
	var routine: NpcRoutine = Fx.routine(_house)
	routine.begin(Fx.COOK_START)
	# Act: walk 2 (arrives 09:01, searching from 09:02) + 20 minutes of searching
	Fx.run(routine, Fx.COOK_START, Fx.COOK_START + Fx.WALK + Fx.SEARCH_MINUTES)
	# Assert: groceries found; cooking has started, nothing skipped
	assert_str(String(_house.get_object_state("basket"))).is_equal("available")
	Fx.run(routine, Fx.COOK_START + Fx.WALK + Fx.SEARCH_MINUTES, Fx.COOK_START + Fx.WALK + Fx.SEARCH_MINUTES + 5)
	assert_int(routine.state).is_equal(NpcRoutine.State.PERFORMING)
	assert_str(routine.current.id).is_equal("cook")
	assert_int(routine.work_done_minutes).is_greater(0)

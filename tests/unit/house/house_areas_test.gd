## New kinds of location (sprint 001, phase B, 2026-11-25): outdoor areas whose light follows the
## day, and areas the family never enters (no doors, no tasks). Fixture:
##   floor 0:  [yard 1,0 outdoor] behind [hall 1,1]
##   floor -1: [cellar 1,1, family false] under the hall
##   floor 1:  [up 1,0] above the yard
extends GdUnitTestSuite


func _house() -> HouseState:
	return HouseState.from_dict({
		"rooms": [
			{"id": "hall", "floor": 0, "grid": [1, 1]},
			{"id": "yard", "floor": 0, "grid": [1, 0], "outdoor": true, "family": false},
			{"id": "cellar", "floor": -1, "grid": [1, 1], "family": false, "light": "dark"},
			{"id": "up", "floor": 1, "grid": [1, 0]},
		],
		"doors": [], "objects": [],
	})


func test_room_flags_are_read_from_data_with_indoor_family_defaults() -> void:
	var house := _house()
	assert_bool(house.rooms["yard"].outdoor).is_true()
	assert_bool(house.rooms["yard"].family_access).is_false()
	assert_bool(house.rooms["hall"].outdoor).is_false()
	assert_bool(house.rooms["hall"].family_access).is_true()


func test_outdoor_light_is_bright_by_day_and_dark_at_night() -> void:
	# Arrange
	var house := _house()
	# Act / Assert
	house.set_daylight(true)
	assert_int(house.rooms["yard"].light).is_equal(RoomState.Light.BRIGHT)
	house.set_daylight(false)
	assert_int(house.rooms["yard"].light).is_equal(RoomState.Light.DARK)


func test_indoor_room_without_lamps_keeps_its_data_light_at_any_hour() -> void:
	var house := _house()
	house.set_daylight(true)
	assert_int(house.rooms["cellar"].light).is_equal(RoomState.Light.DARK)


func test_family_gets_no_cleaning_task_in_a_room_it_never_enters() -> void:
	# Arrange: both rooms dirty
	var house := _house()
	house.set_room_cleanliness("cellar", RoomState.Cleanliness.DIRTY)
	house.set_room_cleanliness("hall", RoomState.Cleanliness.DIRTY)
	var board := TaskBoard.new(house, {"clean": {}, "repair": {}})
	# Act
	var keys: Array[String] = []
	for task: HouseTask in board.tasks_for_role(TaskBoard.ROLE_CLEAN):
		keys.append(task.key)
	# Assert
	assert_array(keys).contains(["clean:hall"])
	assert_array(keys).not_contains(["clean:cellar", "clean:yard"])


func test_ghost_floats_down_into_a_cellar_under_the_hall() -> void:
	var nav := GhostNavigator.new(_house())
	nav.place("hall", Vector2(0.5, 0.5))
	assert_bool(nav.change_floor(-1)).is_true()
	assert_str(nav.room_id).is_equal("cellar")


func test_ghost_cannot_float_up_out_of_an_outdoor_area() -> void:
	# "up" is at the yard's cell one floor up, but the sky is not a ceiling
	var nav := GhostNavigator.new(_house())
	nav.place("yard", Vector2(0.5, 0.5))
	assert_bool(nav.change_floor(1)).is_false()
	assert_str(nav.room_id).is_equal("yard")


func test_ghost_cannot_float_down_into_an_outdoor_area() -> void:
	var nav := GhostNavigator.new(_house())
	nav.place("up", Vector2(0.5, 0.5))
	assert_bool(nav.change_floor(-1)).is_false()
	assert_str(nav.room_id).is_equal("up")

## The ghost drifts through walls into the next room on its floor's grid, and through
## the ceiling or floor into the room above or below (stage 5a). Fixture grid:
##   floor 0:  [a 0,1] [b 1,1] [c 2,1]      [back 1,0] behind b
##   floor 1:  [up 1,1] above b
extends GdUnitTestSuite


func _house() -> HouseState:
	return HouseState.from_dict({
		"rooms": [
			{"id": "a", "floor": 0, "grid": [0, 1]},
			{"id": "b", "floor": 0, "grid": [1, 1]},
			{"id": "c", "floor": 0, "grid": [2, 1]},
			{"id": "back", "floor": 0, "grid": [1, 0]},
			{"id": "up", "floor": 1, "grid": [1, 1]},
		],
		"doors": [], "objects": [],
	})


func _nav(room_id: String, at: Vector2) -> GhostNavigator:
	var nav := GhostNavigator.new(_house())
	nav.place(room_id, at)
	return nav


func test_moving_inside_a_room_stays_in_it() -> void:
	var nav := _nav("b", Vector2(0.5, 0.5))
	nav.move(Vector2(0.2, 0.1))
	assert_str(nav.room_id).is_equal("b")
	assert_vector(nav.uv).is_equal_approx(Vector2(0.7, 0.6), Vector2(0.001, 0.001))


func test_drifting_through_the_left_wall_enters_the_room_on_the_left() -> void:
	var nav := _nav("b", Vector2(GhostNavigator.U_MIN + 0.01, 0.5))
	nav.move(Vector2(-0.05, 0.0))
	assert_str(nav.room_id).is_equal("a")
	assert_float(nav.uv.x).is_greater(0.9)


func test_drifting_through_the_right_wall_enters_the_room_on_the_right() -> void:
	var nav := _nav("b", Vector2(GhostNavigator.U_MAX - 0.01, 0.5))
	nav.move(Vector2(0.05, 0.0))
	assert_str(nav.room_id).is_equal("c")
	assert_float(nav.uv.x).is_less(0.1)


func test_drifting_through_the_back_wall_enters_the_room_behind() -> void:
	var nav := _nav("b", Vector2(0.5, GhostNavigator.V_MIN + 0.01))
	nav.move(Vector2(0.0, -0.05))
	assert_str(nav.room_id).is_equal("back")
	assert_float(nav.uv.y).is_greater(0.9)


func test_no_room_beyond_a_wall_keeps_the_ghost_inside() -> void:
	var nav := _nav("a", Vector2(GhostNavigator.U_MIN + 0.01, 0.5))
	nav.move(Vector2(-0.5, 0.0))
	assert_str(nav.room_id).is_equal("a")
	assert_float(nav.uv.x).is_equal_approx(GhostNavigator.U_MIN, 0.001)


func test_floating_up_enters_the_room_above_and_keeps_position() -> void:
	var nav := _nav("b", Vector2(0.3, 0.6))
	assert_bool(nav.change_floor(1)).is_true()
	assert_str(nav.room_id).is_equal("up")
	assert_vector(nav.uv).is_equal_approx(Vector2(0.3, 0.6), Vector2(0.001, 0.001))


func test_no_room_above_means_no_floor_change() -> void:
	var nav := _nav("a", Vector2(0.5, 0.5))
	assert_bool(nav.change_floor(1)).is_false()
	assert_str(nav.room_id).is_equal("a")


func test_inside_wall_reports_which_wall() -> void:
	assert_str(_nav("b", Vector2(-0.1, 0.5)).wall()).is_equal("left")
	assert_str(_nav("b", Vector2(1.1, 0.5)).wall()).is_equal("right")
	assert_str(_nav("b", Vector2(0.5, -0.2)).wall()).is_equal("back")
	assert_str(_nav("b", Vector2(0.5, 0.5)).wall()).is_equal("")

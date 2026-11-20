## The room is seen through one pinhole camera (user review 2026-11-20): the full box is the
## spike's box exactly; a thing at any depth is drawn at the same px per metre as the floor
## there; depth rows crowd toward the back; walls rise to the same real ceiling everywhere.
extends GdUnitTestSuite


func after_test() -> void:
	RoomGeometry.set_room(RoomGeometry.FULL_SIZE_M)


func test_the_full_room_is_the_spike_box() -> void:
	RoomGeometry.set_room(RoomGeometry.FULL_SIZE_M)
	var eps := Vector2(1.0, 1.0)
	assert_vector(RoomGeometry.BACK_LEFT).is_equal_approx(RoomGeometry.FULL_BACK_LEFT, eps)
	assert_vector(RoomGeometry.BACK_RIGHT).is_equal_approx(RoomGeometry.FULL_BACK_RIGHT, eps)
	assert_vector(RoomGeometry.FRONT_LEFT).is_equal_approx(RoomGeometry.FULL_FRONT_LEFT, eps)
	assert_vector(RoomGeometry.FRONT_RIGHT).is_equal_approx(RoomGeometry.FULL_FRONT_RIGHT, eps)
	assert_float(RoomGeometry.BACK_WALL_HEIGHT).is_equal_approx(170.0, 1.0)
	assert_float(RoomGeometry.SIDE_WALL_FRONT_HEIGHT).is_equal_approx(290.0, 1.0)


func test_things_are_drawn_at_the_floors_scale_at_their_depth() -> void:
	# In a 5 × 4 m room, a metre of floor across at the back, middle and front is as many px as
	# a metre of a painted prop standing there (art 75 px per metre × scale_at)
	RoomGeometry.set_room(Vector2(5.0, 4.0))
	for v: float in [0.0, 0.5, 1.0]:
		var floor_px: float = RoomGeometry.to_screen(Vector2(0.6, v)).x - RoomGeometry.to_screen(Vector2(0.4, v)).x
		var prop_px: float = RoomGeometry.ART_PX_PER_M * RoomGeometry.scale_at(v)
		assert_float(floor_px).is_equal_approx(prop_px, 0.01)
	# and nearer means bigger
	assert_float(RoomGeometry.scale_at(1.0)).is_greater(RoomGeometry.scale_at(0.0))


func test_depth_rows_crowd_toward_the_back() -> void:
	# Equal steps of floor depth cover fewer screen px the further they are
	RoomGeometry.set_room(Vector2(5.0, 4.0))
	var near: float = RoomGeometry.to_screen(Vector2(0.5, 1.0)).y - RoomGeometry.to_screen(Vector2(0.5, 0.75)).y
	var far: float = RoomGeometry.to_screen(Vector2(0.5, 0.25)).y - RoomGeometry.to_screen(Vector2(0.5, 0.0)).y
	assert_float(near).is_greater(far * 1.2)


func test_a_wall_point_is_its_real_height_above_the_floor() -> void:
	# Half way up a side wall at the middle of the room is 1.45 m: as many px as 1.45 m of a prop there
	RoomGeometry.set_room(Vector2(5.0, 4.0))
	var rise: float = RoomGeometry.to_screen(Vector2(0.0, 0.5)).y - RoomGeometry.side_wall_point(true, 0.5, 0.5).y
	assert_float(rise).is_equal_approx(RoomGeometry.WALL_HEIGHT_M * 0.5 * RoomGeometry.px_per_m(0.5), 0.01)

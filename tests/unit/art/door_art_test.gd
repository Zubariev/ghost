## Painted doors (sprint 001, phase H, 2026-11-26): the image sits exactly on the frame the drawn
## doors used, so doors stay where people walk through them; the shipped door image loads.
extends GdUnitTestSuite


func before_test() -> void:
	RoomGeometry.set_room(Vector2(5.0, 4.5))


func test_the_back_door_sits_on_the_back_wall_round_the_door_position() -> void:
	var rect: Rect2 = DoorArt.back_rect()
	var door_x: float = RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U, 0.0).x
	assert_float(rect.end.y).is_equal_approx(RoomGeometry.BACK_LEFT.y, 0.01)   # stands on the floor line
	assert_float(rect.get_center().x).is_equal_approx(door_x, 0.5)
	assert_float(rect.size.y).is_equal_approx(RoomGeometry.BACK_WALL_HEIGHT * DoorArt.SIDE_HEIGHT, 0.5)
	assert_float(rect.size.x).is_greater(0.0)


func test_the_side_door_frame_is_the_drawn_doors_frame() -> void:
	# the storybook doors' frame: 0.39..0.61 along the wall, 0.64 of its height
	assert_vector(DoorArt.SIDE_V).is_equal(Vector2(0.39, 0.61))
	assert_float(DoorArt.SIDE_HEIGHT).is_equal(0.64)


func test_the_shipped_door_image_loads_for_every_room() -> void:
	var visuals := PropVisuals.new(JsonData.read(PropVisuals.STYLE_PATH))
	for room_id: String in ["hall", "kitchen", "living_room", "upper_corridor"]:
		assert_object(visuals.texture_for("door", "", &"", room_id)).is_not_null()

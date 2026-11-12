## Sight zones and line of sight (Demo Specification §8.5, §8.8): walls and tall furniture
## block sight; a ghost inside a wall is never seen.
extends GdUnitTestSuite

const CFG: Dictionary = {"peripheral_angle_deg": 120, "peripheral_range": 0.5, "deep_angle_deg": 40, "deep_range": 0.33}


func _occluders() -> Array[Rect2]:
	# A wardrobe-sized block in the middle of the floor: centre (0.5, 0.5), half size 0.10 × 0.06
	return [Rect2(Vector2(0.4, 0.44), Vector2(0.2, 0.12))]


func test_ghost_straight_ahead_and_close_is_in_the_deep_zone() -> void:
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.5, 0.2), Vector2(0, 1), Vector2(0.5, 0.4), CFG, [])
	assert_int(zone).is_equal(RoomLayout.Zone.DEEP)


func test_ghost_off_to_the_side_is_in_the_peripheral_zone() -> void:
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.5, 0.2), Vector2(0, 1), Vector2(0.75, 0.4), CFG, [])
	assert_int(zone).is_equal(RoomLayout.Zone.PERIPHERAL)


func test_ghost_behind_the_person_is_not_seen() -> void:
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.5, 0.5), Vector2(0, 1), Vector2(0.5, 0.3), CFG, [])
	assert_int(zone).is_equal(RoomLayout.Zone.NONE)


func test_ghost_beyond_range_is_not_seen() -> void:
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.5, 0.1), Vector2(0, 1), Vector2(0.5, 0.9), CFG, [])
	assert_int(zone).is_equal(RoomLayout.Zone.NONE)


func test_ghost_inside_a_wall_is_never_seen() -> void:
	# Close and straight ahead, but inside the left wall (u < 0)
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.15, 0.5), Vector2(-1, 0), Vector2(-0.05, 0.5), CFG, [])
	assert_int(zone).is_equal(RoomLayout.Zone.NONE)
	assert_bool(RoomLayout.line_of_sight(Vector2(0.15, 0.5), Vector2(-0.05, 0.5), [])).is_false()


func test_tall_furniture_blocks_sight() -> void:
	# Looking straight through the wardrobe at a ghost close behind it
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.5, 0.25), Vector2(0, 1), Vector2(0.5, 0.56), CFG, _occluders())
	assert_int(zone).is_equal(RoomLayout.Zone.NONE)
	assert_bool(RoomLayout.line_of_sight(Vector2(0.5, 0.25), Vector2(0.5, 0.56), _occluders())).is_false()


func test_sight_past_the_furniture_is_clear() -> void:
	assert_bool(RoomLayout.line_of_sight(Vector2(0.2, 0.25), Vector2(0.2, 0.56), _occluders())).is_true()

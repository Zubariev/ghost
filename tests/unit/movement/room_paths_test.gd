## Walking paths inside a room (stage 5c, roadmap step 1): around furniture footprints,
## straight where clear, and into furniture (a bed, the stairs) only by the last step.
extends GdUnitTestSuite

const BOX_UV := Vector2(0.5, 0.5)


func _paths() -> RoomPaths:
	var layout := RoomLayout.new({"room": [{"kind": "box", "u": BOX_UV.x, "v": BOX_UV.y}, {"kind": "rug", "u": 0.2, "v": 0.8}]}, null)
	return RoomPaths.new(layout, {"grid_cells": [40, 24], "clearance": 0.0, "footprints": {"box": [0.1, 0.1]}})


## Every straight piece of [param points] between [param first] and [param last] (indices)
## is clear of furniture.
func _assert_clear(paths: RoomPaths, points: PackedVector2Array, first: int, last: int) -> void:
	for i: int in range(first, last):
		assert_bool(paths.is_clear("room", points[i], points[i + 1])).override_failure_message(
			"segment %d %s → %s crosses furniture" % [i, points[i], points[i + 1]]).is_true()


func test_clear_floor_gives_a_straight_walk() -> void:
	# Act
	var points: PackedVector2Array = _paths().find("room", Vector2(0.1, 0.2), Vector2(0.9, 0.2))
	# Assert
	assert_int(points.size()).is_equal(2)
	assert_vector(points[1]).is_equal(Vector2(0.9, 0.2))


func test_walk_goes_round_furniture_in_the_way() -> void:
	# Arrange
	var paths: RoomPaths = _paths()
	var from := Vector2(0.5, 0.2)
	var to := Vector2(0.5, 0.8)
	# Act
	var points: PackedVector2Array = paths.find("room", from, to)
	# Assert: starts and ends exactly, every piece avoids the box, and it is a detour
	assert_vector(points[0]).is_equal(from)
	assert_vector(points[points.size() - 1]).is_equal(to)
	assert_int(points.size()).is_greater(2)
	_assert_clear(paths, points, 0, points.size() - 1)
	assert_float(RoomPaths.length(points)).is_greater(from.distance_to(to))


func test_rugs_and_unlisted_kinds_are_walked_over() -> void:
	assert_bool(_paths().is_free("room", Vector2(0.2, 0.8))).is_true()


func test_walk_into_furniture_reaches_it_only_on_the_last_step() -> void:
	# Arrange: the target is inside the box (like a bed or the stairs)
	var paths: RoomPaths = _paths()
	# Act
	var points: PackedVector2Array = paths.find("room", Vector2(0.5, 0.05), BOX_UV)
	# Assert
	assert_vector(points[points.size() - 1]).is_equal(BOX_UV)
	assert_bool(paths.is_free("room", points[points.size() - 2])).is_true()
	_assert_clear(paths, points, 0, points.size() - 2)


func test_walk_out_of_furniture_leaves_it_on_the_first_step() -> void:
	# Arrange: getting up from the bed
	var paths: RoomPaths = _paths()
	# Act
	var points: PackedVector2Array = paths.find("room", BOX_UV, Vector2(0.5, 0.95))
	# Assert
	assert_vector(points[0]).is_equal(BOX_UV)
	assert_bool(paths.is_free("room", points[1])).is_true()
	_assert_clear(paths, points, 1, points.size() - 1)


func test_door_points_on_the_wall_are_reached() -> void:
	# Arrange: a side door sits on the floor's edge, u = 0
	var paths: RoomPaths = _paths()
	# Act
	var points: PackedVector2Array = paths.find("room", Vector2(0.9, 0.5), Vector2(0.0, 0.5))
	# Assert
	assert_vector(points[points.size() - 1]).is_equal(Vector2(0.0, 0.5))
	_assert_clear(paths, points, 0, points.size() - 1)


func test_nearest_free_point_is_outside_the_furniture() -> void:
	# Act
	var free: Vector2 = _paths().nearest_free("room", BOX_UV + Vector2(0.09, 0.0))
	# Assert: just past the box's right edge
	assert_bool(_paths().is_free("room", free)).is_true()
	assert_float(free.x).is_greater(0.6)


# Art test (2026-11-15): decor is drawn only and never blocks walking.

func test_decor_pieces_never_block_walking() -> void:
	# Arrange: a decor box right across the straight walk
	var layout := RoomLayout.new({"room": [{"kind": "box", "u": 0.5, "v": 0.5, "decor": true}]}, null)
	var paths := RoomPaths.new(layout, {"grid_cells": [40, 24], "clearance": 0.0, "footprints": {"box": [0.1, 0.1]}})
	# Act
	var points: PackedVector2Array = paths.find("room", Vector2(0.5, 0.2), Vector2(0.5, 0.8))
	# Assert
	assert_array(paths.blocked("room")).is_empty()
	assert_int(points.size()).is_equal(2)

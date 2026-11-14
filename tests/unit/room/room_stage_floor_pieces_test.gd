## Sight zones are clipped to the floor before drawing (stage 5b/5c). Regression: someone
## standing exactly on the floor's edge looking outward (a side door) left a zero-area
## sliver that Godot could not fill ("Invalid polygon data, triangulation failed").
extends GdUnitTestSuite

## Boundary values from the failing case found by sweeping origins: on the left edge,
## looking down-left, the narrow deep zone.
const EDGE_ORIGIN := Vector2(0.0, 0.2)
const LOOK_DEGREES: float = 250.0
const FAN_DEGREES: float = 40.0
const REACH: float = 0.33


func _fan(origin: Vector2, look: Vector2, angle_deg: float, reach: float) -> PackedVector2Array:
	var points := PackedVector2Array([RoomGeometry.to_screen(origin)])
	var half: float = deg_to_rad(angle_deg) * 0.5
	for step: int in 19:
		points.append(RoomGeometry.to_screen(origin + look.rotated(-half + 2.0 * half * float(step) / 18.0) * reach))
	return points


func test_a_cone_from_the_floor_edge_looking_out_gives_only_fillable_pieces() -> void:
	# Arrange
	var fan: PackedVector2Array = _fan(EDGE_ORIGIN, Vector2.RIGHT.rotated(deg_to_rad(LOOK_DEGREES)), FAN_DEGREES, REACH)
	# Act
	var pieces: Array[PackedVector2Array] = RoomStage.floor_pieces(fan)
	# Assert
	for piece: PackedVector2Array in pieces:
		assert_bool(Geometry2D.triangulate_polygon(piece).is_empty()).override_failure_message(
			"unfillable piece %s" % piece).is_false()


func test_a_cone_in_the_middle_of_the_floor_is_kept() -> void:
	# Act
	var pieces: Array[PackedVector2Array] = RoomStage.floor_pieces(_fan(Vector2(0.5, 0.5), Vector2.DOWN, FAN_DEGREES, REACH))
	# Assert
	assert_int(pieces.size()).is_equal(1)
	assert_bool(Geometry2D.triangulate_polygon(pieces[0]).is_empty()).is_false()

## Rooms of different sizes on one scale (user decision 2026-11-20, "zoomed"): the widest room
## fills the view, a smaller one is a smaller floor at the same zoom, centred; HUD points follow
## the zoom; reset restores the full box.
extends GdUnitTestSuite

const AREA: Array = [20, 60, 1240, 585]


func after_test() -> void:
	RoomView.reset()


func _view() -> RoomView:
	return RoomView.new({"full_box_size_m": [10.0, 8.0], "view_area": AREA},
		{"big": Vector2(8.0, 6.0), "small": Vector2(4.0, 2.0)})


func test_the_widest_room_fills_the_view_and_a_smaller_one_sits_centred_at_the_same_zoom() -> void:
	# Arrange
	var view: RoomView = _view()
	var area := Rect2(AREA[0], AREA[1], AREA[2], AREA[3])
	var stage: Node2D = auto_free(Node2D.new())
	# Act
	view.apply("big", stage)
	var big: Rect2 = Rect2(RoomGeometry.to_display(RoomGeometry.bounds().position), RoomGeometry.bounds().size * view.zoom())
	var big_zoom: Vector2 = stage.scale
	view.apply("small", stage)
	var small: Rect2 = Rect2(RoomGeometry.to_display(RoomGeometry.bounds().position), RoomGeometry.bounds().size * view.zoom())
	# Assert: the big room touches the view's edges; the small one is inside, centred, same zoom
	assert_bool(is_equal_approx(big.size.x, area.size.x) or is_equal_approx(big.size.y, area.size.y)).is_true()
	assert_bool(area.grow(0.5).encloses(big)).is_true()
	assert_vector(stage.scale).is_equal(big_zoom)
	assert_bool(area.encloses(small) and small.size.x < big.size.x).is_true()
	assert_vector(small.get_center()).is_equal_approx(area.get_center(), Vector2(0.5, 0.5))
	assert_vector(view.floor_scale("small")).is_equal_approx(Vector2(0.4, 0.25), Vector2(0.0001, 0.0001))


func test_hud_points_follow_the_zoom_and_reset_restores_the_full_box() -> void:
	# Arrange
	var view: RoomView = _view()
	var stage: Node2D = auto_free(Node2D.new())
	view.apply("small", stage)
	var uv := Vector2(0.3, 0.7)
	# Act: where the stage draws a floor point vs where the HUD puts it
	var drawn: Vector2 = stage.transform * RoomGeometry.to_screen(uv)
	var hud: Vector2 = RoomGeometry.to_display(RoomGeometry.to_screen(uv))
	RoomView.reset()
	# Assert
	assert_vector(hud).is_equal_approx(drawn, Vector2(0.01, 0.01))
	assert_vector(RoomGeometry.BACK_LEFT).is_equal(RoomGeometry.FULL_BACK_LEFT)
	assert_vector(RoomGeometry.to_display(Vector2(5, 7))).is_equal(Vector2(5, 7))


func test_an_unknown_room_uses_the_full_box() -> void:
	assert_vector(_view().floor_scale("attic")).is_equal(Vector2.ONE)


func test_a_shallow_room_is_less_deep_than_wide() -> void:
	# A room 4 m wide and 2 m deep in a 10 × 8 m full box: 0.4 of the width, a quarter of the depth
	_view().apply("small", auto_free(Node2D.new()))
	var depth: float = RoomGeometry.FRONT_LEFT.y - RoomGeometry.BACK_LEFT.y
	var width: float = RoomGeometry.FRONT_RIGHT.x - RoomGeometry.FRONT_LEFT.x
	assert_float(depth).is_equal_approx((RoomGeometry.FULL_FRONT_LEFT.y - RoomGeometry.FULL_BACK_LEFT.y) * 0.25, 0.01)
	assert_float(width).is_equal_approx((RoomGeometry.FULL_FRONT_RIGHT.x - RoomGeometry.FULL_FRONT_LEFT.x) * 0.4, 0.01)

## Where the roots screen puts nodes and how focus moves between them (sprint 002, P5, task S2-06;
## design/ux/roots-progression.md): hand-placed positions from data, an automatic place along the
## branch for a node without one, Tab order by branch, arrows to the nearest node that way,
## generous hit areas, stable root curves.
extends GdUnitTestSuite


func _data() -> Dictionary:
	return {
		"branches": [
			{"id": "trunk", "colour": "amber", "direction": [0, 1]},
			{"id": "left", "colour": "gold", "direction": [-1, 0], "coffin": {"x": 100, "y": 400}},
			{"id": "right", "colour": "green", "direction": [1, 0]},
		],
		"nodes": [
			{"id": "T0", "branch": "trunk", "parents": [], "tier": 0, "layout": {"x": 640, "y": 200}},
			{"id": "T1", "branch": "trunk", "parents": ["T0"], "tier": 1, "layout": {"x": 640, "y": 300}},
			{"id": "L1", "branch": "left", "parents": ["T1"], "layout": {"x": 540, "y": 300}},
			{"id": "L2", "branch": "left", "parents": ["L1"]},
			{"id": "R1", "branch": "right", "parents": ["T1"], "layout": {"x": 740, "y": 300}},
			{"id": "R2", "branch": "right", "parents": ["R1"], "layout": {"x": 740, "y": 400}},
		],
	}


func _layout() -> RootsLayout:
	return RootsLayout.new(_data())


func test_a_hand_placed_node_sits_where_the_data_says() -> void:
	assert_vector(_layout().position("L1")).is_equal(Vector2(540, 300))


func test_a_node_without_a_place_goes_one_step_on_along_its_branch() -> void:
	var at: Vector2 = _layout().position("L2")
	assert_float(at.x).is_equal_approx(540.0 - RootsLayout.STEP, 0.001)
	assert_float(at.y).is_equal_approx(300.0, 0.001)


func test_tab_walks_the_nodes_branch_by_branch_and_wraps() -> void:
	var layout := _layout()
	assert_array(layout.tab_order()).is_equal(["T0", "T1", "L1", "L2", "R1", "R2"])
	assert_str(layout.next_in_order("L2", 1)).is_equal("R1")
	assert_str(layout.next_in_order("R2", 1)).is_equal("T0")
	assert_str(layout.next_in_order("T0", -1)).is_equal("R2")


func test_arrows_go_to_the_nearest_node_that_way() -> void:
	var layout := _layout()
	assert_str(layout.neighbour("T1", Vector2.LEFT)).is_equal("L1")
	assert_str(layout.neighbour("T1", Vector2.RIGHT)).is_equal("R1")
	assert_str(layout.neighbour("T1", Vector2.UP)).is_equal("T0")
	assert_str(layout.neighbour("R1", Vector2.DOWN)).is_equal("R2")


func test_an_arrow_with_nothing_that_way_stays_put() -> void:
	assert_str(_layout().neighbour("R2", Vector2.DOWN)).is_equal("R2")


func test_a_click_near_a_node_hits_it_and_empty_soil_hits_nothing() -> void:
	var layout := _layout()
	assert_str(layout.node_at(Vector2(540, 300) + Vector2(RootsLayout.HIT_RADIUS - 1.0, 0))).is_equal("L1")
	assert_str(layout.node_at(Vector2(590, 420))).is_empty()


func test_root_curves_join_parent_and_child_and_are_the_same_every_time() -> void:
	var a: PackedVector2Array = _layout().root_points("T1", "L1")
	var b: PackedVector2Array = _layout().root_points("T1", "L1")
	assert_vector(a[0]).is_equal(Vector2(640, 300))
	assert_vector(a[a.size() - 1]).is_equal(Vector2(540, 300))
	assert_array(Array(a)).is_equal(Array(b))


func test_the_coffin_sits_where_its_branch_data_says() -> void:
	var layout := _layout()
	assert_vector(layout.coffin_position()).is_equal(Vector2(100, 400))
	assert_str(layout.coffin_branch()).is_equal("left")

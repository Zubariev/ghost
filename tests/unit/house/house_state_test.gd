## House rooms, doors, object states and requirements.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")


func test_find_path_returns_rooms_entered_in_order() -> void:
	var house: HouseState = Fx.house()
	assert_array(house.find_path("bedroom", "dining")).contains_exactly(["kitchen", "dining"])


func test_find_path_is_empty_for_unreachable_room() -> void:
	var house: HouseState = Fx.house()
	assert_array(house.find_path("bedroom", "cellar")).is_empty()


func test_walk_minutes_read_from_doors() -> void:
	var house: HouseState = Fx.house()
	assert_int(house.walk_minutes("bedroom", "kitchen")).is_equal(Fx.WALK)
	assert_int(house.walk_minutes("bedroom", "dining")).is_equal(-1)


func test_unmet_requirements_lists_only_failing_ones() -> void:
	var house: HouseState = Fx.house()
	house.set_object_state("stove", &"broken")
	var requirements: Array[Dictionary] = [
		{"object": "basket", "state": "available"},
		{"object": "stove", "state": "working"},
	]
	var unmet: Array[Dictionary] = house.unmet_requirements(requirements)
	assert_int(unmet.size()).is_equal(1)
	assert_str(String(unmet[0]["object"])).is_equal("stove")


func test_unknown_state_is_rejected_and_state_kept() -> void:
	var house: HouseState = Fx.house()
	assert_bool(house.set_object_state("stove", &"melted")).is_false()
	assert_str(String(house.get_object_state("stove"))).is_equal("working")


func test_effects_set_object_states() -> void:
	var house: HouseState = Fx.house()
	var effects: Array[Dictionary] = [{"object": "food", "set": "ready"}]
	house.apply_effects(effects)
	assert_str(String(house.get_object_state("food"))).is_equal("ready")

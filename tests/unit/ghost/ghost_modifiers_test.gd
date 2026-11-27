## Value changes from owned progression nodes (sprint 002, P3, task S2-04; catalog
## design/crafting-progression-catalog.md): adds first, then multipliers, each limited to a room,
## to some family members or to one ghost action when the effect says so.
extends GdUnitTestSuite


func _mods(effects: Array) -> GhostModifiers:
	var mods := GhostModifiers.new()
	var typed: Array[Dictionary] = []
	typed.assign(effects)
	mods.set_effects(typed)
	return mods


func test_with_no_effects_the_base_value_is_unchanged() -> void:
	assert_float(GhostModifiers.new().value("energy.max", 100.0)).is_equal(100.0)


func test_adds_apply_before_multipliers() -> void:
	var mods := _mods([
		{"key": "energy.action_cost", "op": "mul", "value": 0.5},
		{"key": "energy.action_cost", "op": "add", "value": -10.0},
	])
	assert_float(mods.value("energy.action_cost", 30.0)).is_equal_approx(10.0, 0.0001)


func test_a_room_effect_works_only_in_its_room() -> void:
	var mods := _mods([{"key": "energy.regen", "op": "mul", "value": 1.5, "room": "kitchen"}])
	assert_float(mods.value("energy.regen", 0.2, {"room": "kitchen"})).is_equal_approx(0.3, 0.0001)
	assert_float(mods.value("energy.regen", 0.2, {"room": "hall"})).is_equal_approx(0.2, 0.0001)
	assert_float(mods.value("energy.regen", 0.2)).is_equal_approx(0.2, 0.0001)


func test_an_effect_for_some_family_members_skips_the_others() -> void:
	var mods := _mods([{"key": "energy.detection_penalty.peripheral", "op": "add", "value": -5.0, "npcs": ["son", "daughter"]}])
	assert_float(mods.value("energy.detection_penalty.peripheral", 10.0, {"npc": "son"})).is_equal(5.0)
	assert_float(mods.value("energy.detection_penalty.peripheral", 10.0, {"npc": "father"})).is_equal(10.0)


func test_an_action_effect_works_only_for_that_action() -> void:
	var mods := _mods([{"key": "energy.action_cost", "op": "add", "value": -10.0, "action": "computer"}])
	assert_float(mods.value("energy.action_cost", 25.0, {"action": "computer"})).is_equal(15.0)
	assert_float(mods.value("energy.action_cost", 10.0, {"action": "lamp"})).is_equal(10.0)


func test_effects_of_several_nodes_stack() -> void:
	var mods := _mods([
		{"key": "energy.action_cost", "op": "add", "value": -10.0, "action": "computer"},
		{"key": "energy.action_cost", "op": "mul", "value": 0.7, "room": "children_bedroom"},
	])
	assert_float(mods.value("energy.action_cost", 25.0, {"action": "computer", "room": "children_bedroom"})).is_equal_approx(10.5, 0.0001)


func test_a_value_never_goes_below_zero() -> void:
	var mods := _mods([{"key": "loot.search_minutes", "op": "add", "value": -5.0}])
	assert_float(mods.value("loot.search_minutes", 3.0)).is_equal(0.0)


func test_changing_the_effects_signals_once() -> void:
	var mods := GhostModifiers.new()
	var count: Array[int] = [0]
	mods.changed.connect(func() -> void: count[0] += 1)
	var effects: Array[Dictionary] = [{"key": "energy.max", "op": "add", "value": 20.0}]
	mods.set_effects(effects)
	assert_int(count[0]).is_equal(1)


func test_unknown_keys_ops_and_filters_are_reported() -> void:
	assert_str(GhostModifiers.check({"key": "energy.max", "op": "add", "value": 1})).is_empty()
	assert_str(GhostModifiers.check({"key": "ghost.fly", "op": "add", "value": 1})).is_not_empty()
	assert_str(GhostModifiers.check({"key": "energy.max", "op": "pow", "value": 1})).is_not_empty()
	assert_str(GhostModifiers.check({"key": "energy.max", "op": "add"})).is_not_empty()
	assert_str(GhostModifiers.check({"key": "energy.max", "op": "add", "value": 1, "colour": "red"})).is_not_empty()

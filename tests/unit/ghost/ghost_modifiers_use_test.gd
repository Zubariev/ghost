## Owned progression nodes change the values the ghost's systems use (sprint 002, P3, task
## S2-04): energy (maximum, refill, action cost and time, per room and action) and the inventory
## (search time, slots). Without modifiers every value is the configured one.
extends GdUnitTestSuite

const Ex := preload("res://tests/unit/fixtures/energy_fixtures.gd")


func _mods(effects: Array) -> GhostModifiers:
	var mods := GhostModifiers.new()
	var typed: Array[Dictionary] = []
	typed.assign(effects)
	mods.set_effects(typed)
	return mods


func _energy(effects: Array, start: float = Ex.MAX) -> GhostEnergy:
	var energy := GhostEnergy.new(Ex.config(start))
	energy.modifiers = _mods(effects)
	return energy


func test_a_bigger_reserve_raises_the_maximum_and_refill_reaches_it() -> void:
	var energy := _energy([{"key": "energy.max", "op": "add", "value": 20}])
	assert_float(energy.max_value()).is_equal(Ex.MAX + 20.0)
	energy.regenerate(10000.0, false, false, false, false)
	assert_float(energy.value).is_equal(Ex.MAX + 20.0)


func test_a_room_bond_cheapens_actions_and_speeds_refill_only_in_its_room() -> void:
	var energy := _energy([
		{"key": "energy.action_cost", "op": "mul", "value": 0.7, "room": "kitchen"},
		{"key": "energy.regen", "op": "mul", "value": 1.5, "room": "kitchen"},
	])
	energy.room_id = "kitchen"
	assert_float(energy.action_cost("lamp")).is_equal_approx(Ex.CHEAP_COST * 0.7, 0.0001)
	assert_float(energy.rate(false, false, false)).is_equal_approx(Ex.REGEN * 1.5, 0.0001)
	energy.room_id = "hall"
	assert_float(energy.action_cost("lamp")).is_equal(Ex.CHEAP_COST)
	assert_float(energy.rate(false, false, false)).is_equal_approx(Ex.REGEN, 0.0001)


func test_an_action_node_changes_only_its_action() -> void:
	var energy := _energy([
		{"key": "energy.action_minutes", "op": "add", "value": -1, "action": "lamp"},
	])
	assert_float(energy.action_minutes("lamp")).is_equal(Ex.CHEAP_MINUTES - 1.0)
	assert_float(energy.action_cost("lamp")).is_equal(Ex.CHEAP_COST)


func test_spending_pays_the_changed_cost() -> void:
	var energy := _energy([{"key": "energy.action_cost", "op": "add", "value": -4, "action": "lamp"}])
	energy.spend_action("lamp")
	assert_float(energy.value).is_equal(Ex.MAX - (Ex.CHEAP_COST - 4.0))


func test_hidden_dark_and_cold_multipliers_can_grow() -> void:
	var energy := _energy([
		{"key": "energy.hidden_multiplier", "op": "add", "value": 1},
		{"key": "energy.dark_multiplier", "op": "add", "value": 0.25},
	])
	assert_float(energy.rate(true, true, false)).is_equal_approx(Ex.REGEN * (Ex.HIDDEN + 1.0) * (Ex.DARK + 0.25), 0.0001)


func test_without_modifiers_energy_is_unchanged() -> void:
	var energy := GhostEnergy.new(Ex.config())
	energy.room_id = "kitchen"
	assert_float(energy.max_value()).is_equal(Ex.MAX)
	assert_float(energy.action_cost("lamp")).is_equal(Ex.CHEAP_COST)


func _loot(effects: Array) -> GhostLoot:
	var loot := GhostLoot.new({"search_minutes": 3, "inventory_slots": 10, "grid": {"small": 4, "large": 9},
		"spots": {"chest": {"size": "small", "unique": [], "renewable": ["dust"]}},
		"items": {"dust": {"name": "ITEM_dust", "kind": "material", "respawn_minutes": 100}}})
	loot.modifiers = _mods(effects)
	return loot


func test_quick_fingers_shorten_the_search() -> void:
	var loot := _loot([{"key": "loot.search_minutes", "op": "add", "value": -1}])
	loot.start_search("chest")
	loot.hold(true)
	loot.update(2.0, 0)
	assert_bool(loot.is_open()).is_true()


func test_deeper_pockets_add_slots() -> void:
	var loot := _loot([{"key": "loot.inventory_slots", "op": "add", "value": 2}])
	assert_int(loot.slot_count()).is_equal(12)

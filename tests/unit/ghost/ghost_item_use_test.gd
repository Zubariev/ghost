## Using an item by dragging it from the slot bar onto the ghost (sprint 001, phase C, 2026-11-26).
## The item's data names its effect; a handler registered for that effect decides whether it
## worked. One unit is used up only when the effect worked; a refused or unknown use leaves the
## inventory exactly as it was. Kinds marked "keep" (the monocle) are not used up here: their
## own effect takes them out of the inventory.
extends GdUnitTestSuite

var _loot: GhostLoot
var _use: GhostItemUse
var _calls: Array[Dictionary] = []


func _config() -> Dictionary:
	return {
		"inventory_slots": 5,
		"spots": {},
		"items": {
			"dust": {"name": "ITEM_dust", "kind": "material"},
			"tonic": {"name": "ITEM_tonic", "kind": "consumable", "use": {"effect": "restore", "amount": 30}},
			"broken_tonic": {"name": "ITEM_x", "kind": "consumable", "use": {"effect": "no_such_effect"}},
			"lens": {"name": "ITEM_lens", "kind": "tool", "use": {"effect": "lens", "keep": true}},
		},
	}


func before_test() -> void:
	_loot = GhostLoot.new(_config())
	_use = GhostItemUse.new(_loot)
	_calls = []
	_use.register("restore", func(item: String, params: Dictionary) -> bool:
		_calls.append({"item": item, "amount": params.get("amount")})
		return true)


func test_using_an_item_runs_its_effect_and_uses_up_one_unit() -> void:
	# Arrange
	_loot.add("tonic", 2)
	# Act
	var used: bool = _use.use("tonic")
	# Assert
	assert_bool(used).is_true()
	assert_int(_loot.count("tonic")).is_equal(1)
	assert_array(_calls).is_equal([{"item": "tonic", "amount": 30}])


func test_an_item_without_a_use_cannot_be_used_and_stays() -> void:
	_loot.add("dust", 3)
	assert_bool(_use.can_use("dust")).is_false()
	assert_bool(_use.use("dust")).is_false()
	assert_int(_loot.count("dust")).is_equal(3)


func test_an_effect_with_no_handler_is_refused_and_the_item_stays() -> void:
	_loot.add("broken_tonic", 1)
	assert_bool(_use.use("broken_tonic")).is_false()
	assert_int(_loot.count("broken_tonic")).is_equal(1)


func test_an_effect_that_refuses_leaves_the_item() -> void:
	# Arrange: the effect cannot work right now (e.g. energy already full)
	_use.register("restore", func(_item: String, _params: Dictionary) -> bool: return false)
	_loot.add("tonic", 1)
	# Act / Assert
	assert_bool(_use.use("tonic")).is_false()
	assert_int(_loot.count("tonic")).is_equal(1)


func test_an_item_not_held_cannot_be_used() -> void:
	assert_bool(_use.use("tonic")).is_false()
	assert_array(_calls).is_empty()


func test_a_kept_item_is_not_used_up_by_the_drop() -> void:
	# Arrange: the lens effect takes the item out itself when it starts
	_use.register("lens", func(_item: String, _params: Dictionary) -> bool: return true)
	_loot.add("lens", 1)
	# Act / Assert
	assert_bool(_use.use("lens")).is_true()
	assert_int(_loot.count("lens")).is_equal(1)

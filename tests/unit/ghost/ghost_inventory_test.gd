## The ghost's inventory as a store other systems move units in and out of (sprint 001, phase C,
## 2026-11-26): crafting takes ingredients out one unit at a time and puts results back, the spider
## trades flies for nests, elixirs and the monocle are used up from it. Materials, consumables and
## tools each take one slot per kind; lore and the map never do. Counts never go below zero and
## an emptied kind frees its slot.
extends GdUnitTestSuite

const SLOTS: int = 3

var _loot: GhostLoot


func _config() -> Dictionary:
	return {
		"inventory_slots": SLOTS,
		"spots": {},
		"items": {
			"dust": {"name": "ITEM_dust", "kind": "material"},
			"thread": {"name": "ITEM_thread", "kind": "material"},
			"bone": {"name": "ITEM_bone", "kind": "material"},
			"elixir": {"name": "ITEM_elixir", "kind": "consumable"},
			"monocle": {"name": "ITEM_monocle", "kind": "tool"},
			"letter": {"name": "ITEM_letter", "kind": "lore", "text": "LORE_letter"},
		},
	}


func before_test() -> void:
	_loot = GhostLoot.new(_config())


func test_adding_units_stacks_them_in_one_slot() -> void:
	assert_int(_loot.add("dust", 3)).is_equal(3)
	assert_int(_loot.add("dust", 2)).is_equal(2)
	assert_int(_loot.count("dust")).is_equal(5)
	assert_array(_loot.slot_items()).is_equal(["dust"])


func test_consumables_and_tools_take_a_slot_like_materials() -> void:
	_loot.add("elixir", 1)
	_loot.add("monocle", 1)
	assert_array(_loot.slot_items()).is_equal(["elixir", "monocle"])


func test_a_new_kind_is_refused_when_every_slot_is_in_use() -> void:
	# Arrange: three kinds fill the three slots
	_loot.add("dust", 1)
	_loot.add("thread", 1)
	_loot.add("elixir", 1)
	# Act / Assert: a fourth kind is refused, more of a held kind is not
	assert_bool(_loot.can_add("bone")).is_false()
	assert_int(_loot.add("bone", 1)).is_equal(0)
	assert_int(_loot.count("bone")).is_equal(0)
	assert_int(_loot.add("dust", 4)).is_equal(4)


func test_lore_never_uses_a_slot() -> void:
	_loot.add("dust", 1)
	_loot.add("thread", 1)
	_loot.add("elixir", 1)
	assert_bool(_loot.can_add("letter")).is_true()


func test_removing_takes_units_away_and_an_emptied_kind_frees_its_slot() -> void:
	# Arrange
	_loot.add("dust", 2)
	_loot.add("thread", 1)
	_loot.add("elixir", 1)
	# Act
	assert_bool(_loot.remove("dust", 1)).is_true()
	assert_int(_loot.count("dust")).is_equal(1)
	assert_bool(_loot.remove("dust", 1)).is_true()
	# Assert: dust is gone and its slot is free for a new kind
	assert_bool(_loot.inventory.has("dust")).is_false()
	assert_array(_loot.slot_items()).is_equal(["thread", "elixir"])
	assert_int(_loot.add("bone", 1)).is_equal(1)


func test_removing_more_than_held_removes_nothing() -> void:
	_loot.add("dust", 2)
	assert_bool(_loot.remove("dust", 3)).is_false()
	assert_bool(_loot.remove("bone", 1)).is_false()
	assert_int(_loot.count("dust")).is_equal(2)


func test_adding_or_removing_zero_or_less_changes_nothing() -> void:
	_loot.add("dust", 2)
	assert_int(_loot.add("dust", 0)).is_equal(0)
	assert_int(_loot.add("dust", -1)).is_equal(0)
	assert_bool(_loot.remove("dust", 0)).is_false()
	assert_int(_loot.count("dust")).is_equal(2)


func test_inventory_changes_are_announced() -> void:
	var changes: Array[String] = []
	_loot.inventory_changed.connect(func() -> void: changes.append("x"))
	_loot.add("dust", 1)
	_loot.remove("dust", 1)
	_loot.remove("dust", 1)   # refused: no announcement
	assert_int(changes.size()).is_equal(2)


func test_slots_keep_their_order_when_a_kind_is_refilled() -> void:
	_loot.add("dust", 1)
	_loot.add("thread", 1)
	_loot.remove("dust", 1)
	_loot.add("dust", 1)
	assert_array(_loot.slot_items()).is_equal(["thread", "dust"])

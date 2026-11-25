## The crafting tree's board (sprint 001, phase D, 2026-11-26): five ingredient slots round an
## inverted pentagram and a result slot in the middle. Units come from and go back to the ghost's
## inventory one at a time; a slot holds one kind; a recipe is ready when the board holds what
## it needs; crafting uses up exactly that and puts the result in the middle; the result goes to
## the inventory or stays put. Upgrading the tree unlocks more recipes. Nothing is ever lost or
## duplicated.
extends GdUnitTestSuite

var _loot: GhostLoot
var _board: CraftingBoard


func _loot_config(slots: int = 10) -> Dictionary:
	return {
		"inventory_slots": slots,
		"spots": {},
		"items": {
			"dust": {"name": "ITEM_dust", "kind": "material"},
			"thread": {"name": "ITEM_thread", "kind": "material"},
			"bone": {"name": "ITEM_bone", "kind": "material"},
			"ink": {"name": "ITEM_ink", "kind": "material"},
			"tonic": {"name": "ITEM_tonic", "kind": "consumable"},
		},
	}


func _config() -> Dictionary:
	return {
		"slots": 5,
		"start_tier": 0,
		"upgrades": [{"tier": 1, "cost": {"bone": 2}}],
		"recipes": [
			{"id": "tonic", "result": "tonic", "amount": 1, "tier": 0, "ingredients": {"dust": 2, "thread": 1}},
			{"id": "big_tonic", "result": "tonic", "amount": 2, "tier": 1, "ingredients": {"ink": 1, "dust": 1}},
			{"id": "ink", "result": "ink", "amount": 1, "tier": 0, "ingredients": {"bone": 1}},
		],
	}


func _make(slots: int = 10) -> void:
	_loot = GhostLoot.new(_loot_config(slots))
	_board = CraftingBoard.new(_config(), _loot)


func before_test() -> void:
	_make()


# --- placing and taking back ----------------------------------------------------------------

func test_placing_moves_exactly_one_unit_from_the_inventory() -> void:
	# Arrange: five threads in the inventory
	_loot.add("thread", 5)
	# Act
	assert_bool(_board.place_unit(0, "thread")).is_true()
	# Assert
	assert_int(_loot.count("thread")).is_equal(4)
	assert_dict(_board.slot(0)).is_equal({"item": "thread", "count": 1})


func test_a_slot_stacks_more_units_of_its_own_kind() -> void:
	_loot.add("thread", 5)
	_board.place_unit(0, "thread")
	_board.place_unit(0, "thread")
	assert_int(int(_board.slot(0)["count"])).is_equal(2)
	assert_int(_loot.count("thread")).is_equal(3)


func test_a_slot_refuses_a_second_kind_and_nothing_moves() -> void:
	_loot.add("thread", 1)
	_loot.add("dust", 1)
	_board.place_unit(0, "thread")
	assert_bool(_board.place_unit(0, "dust")).is_false()
	assert_int(_loot.count("dust")).is_equal(1)
	assert_dict(_board.slot(0)).is_equal({"item": "thread", "count": 1})


func test_placing_an_item_not_held_or_into_a_missing_slot_is_refused() -> void:
	_loot.add("dust", 1)
	assert_bool(_board.place_unit(0, "thread")).is_false()
	assert_bool(_board.place_unit(5, "dust")).is_false()
	assert_bool(_board.place_unit(-1, "dust")).is_false()
	assert_int(_loot.count("dust")).is_equal(1)


func test_taking_back_returns_one_unit_to_the_inventory() -> void:
	_loot.add("thread", 2)
	_board.place_unit(1, "thread")
	_board.place_unit(1, "thread")
	assert_bool(_board.return_unit(1)).is_true()
	assert_int(_loot.count("thread")).is_equal(1)
	assert_dict(_board.slot(1)).is_equal({"item": "thread", "count": 1})
	assert_bool(_board.return_unit(1)).is_true()
	assert_dict(_board.slot(1)).is_equal({"item": "", "count": 0})
	assert_bool(_board.return_unit(1)).is_false()


func test_a_unit_that_no_longer_fits_the_inventory_stays_on_the_board() -> void:
	# Arrange: one inventory slot; all dust goes on the board, freeing it; thread fills it
	_make(1)
	_loot.add("dust", 1)
	_board.place_unit(0, "dust")
	_loot.add("thread", 1)
	# Act / Assert: dust cannot come back, and is not lost
	assert_bool(_board.return_unit(0)).is_false()
	assert_dict(_board.slot(0)).is_equal({"item": "dust", "count": 1})
	assert_bool(_board.return_all()).is_false()


func test_return_all_empties_the_board_into_the_inventory() -> void:
	_loot.add("dust", 3)
	_loot.add("thread", 1)
	_board.place_unit(0, "dust")
	_board.place_unit(0, "dust")
	_board.place_unit(3, "thread")
	assert_bool(_board.return_all()).is_true()
	assert_int(_loot.count("dust")).is_equal(3)
	assert_int(_loot.count("thread")).is_equal(1)
	assert_bool(_board.is_empty()).is_true()


# --- recipes and crafting -------------------------------------------------------------------

func _fill_tonic() -> void:
	_loot.add("dust", 2)
	_loot.add("thread", 1)
	_board.place_unit(0, "dust")
	_board.place_unit(0, "dust")
	_board.place_unit(2, "thread")


func test_a_recipe_is_ready_only_when_the_board_holds_all_it_needs() -> void:
	_loot.add("dust", 2)
	_loot.add("thread", 1)
	_board.place_unit(0, "dust")
	_board.place_unit(2, "thread")
	assert_bool(_board.is_ready("tonic")).is_false()
	_board.place_unit(0, "dust")
	assert_bool(_board.is_ready("tonic")).is_true()
	assert_array(_board.ready_recipes()).is_equal(["tonic"])


func test_amounts_split_over_two_slots_of_the_same_kind_count_together() -> void:
	_loot.add("dust", 2)
	_loot.add("thread", 1)
	_board.place_unit(0, "dust")
	_board.place_unit(4, "dust")
	_board.place_unit(2, "thread")
	assert_bool(_board.is_ready("tonic")).is_true()


func test_crafting_uses_up_exactly_the_ingredients_and_fills_the_result_slot() -> void:
	# Arrange: one dust more than needed
	_fill_tonic()
	_loot.add("dust", 1)
	_board.place_unit(1, "dust")
	# Act
	assert_bool(_board.craft("tonic")).is_true()
	# Assert: two dust and one thread gone, the extra dust still on the board
	assert_dict(_board.result()).is_equal({"item": "tonic", "count": 1})
	assert_dict(_board.totals()).is_equal({"dust": 1})
	assert_int(_loot.count("tonic")).is_equal(0)


func test_crafting_a_recipe_that_is_not_ready_changes_nothing() -> void:
	_loot.add("dust", 1)
	_board.place_unit(0, "dust")
	assert_bool(_board.craft("tonic")).is_false()
	assert_dict(_board.totals()).is_equal({"dust": 1})
	assert_dict(_board.result()).is_equal({"item": "", "count": 0})


func test_a_result_of_the_same_kind_stacks_in_the_middle() -> void:
	# Arrange: an earlier tonic is still in the middle
	_fill_tonic()
	_board.craft("tonic")
	_fill_tonic()
	assert_bool(_board.craft("tonic")).is_true()
	assert_dict(_board.result()).is_equal({"item": "tonic", "count": 2})


func test_a_result_of_another_kind_waiting_in_the_middle_blocks_crafting() -> void:
	# Arrange: a tonic waits in the middle; the board holds a bone for ink
	_fill_tonic()
	_board.craft("tonic")
	_loot.add("bone", 1)
	_board.place_unit(4, "bone")
	# Act / Assert: ink would replace the tonic, so it is refused and the bone stays
	assert_bool(_board.is_ready("ink")).is_false()
	assert_bool(_board.craft("ink")).is_false()
	assert_dict(_board.slot(4)).is_equal({"item": "bone", "count": 1})
	assert_dict(_board.result()).is_equal({"item": "tonic", "count": 1})


func test_the_result_goes_to_the_inventory_whole() -> void:
	_fill_tonic()
	_board.craft("tonic")
	assert_bool(_board.take_result()).is_true()
	assert_int(_loot.count("tonic")).is_equal(1)
	assert_dict(_board.result()).is_equal({"item": "", "count": 0})


func test_a_result_that_does_not_fit_the_inventory_stays_in_the_middle() -> void:
	# Arrange: one inventory slot; each kind goes on the board before the next is added, then
	# bone takes the freed slot
	_make(1)
	_loot.add("dust", 2)
	_board.place_unit(0, "dust")
	_board.place_unit(0, "dust")
	_loot.add("thread", 1)
	_board.place_unit(2, "thread")
	_loot.add("bone", 1)
	_board.craft("tonic")
	# Act / Assert
	assert_bool(_board.take_result()).is_false()
	assert_dict(_board.result()).is_equal({"item": "tonic", "count": 1})


# --- the tree's upgrades --------------------------------------------------------------------

func test_a_recipe_above_the_trees_level_is_locked_and_cannot_be_crafted() -> void:
	_loot.add("ink", 1)
	_loot.add("dust", 1)
	_board.place_unit(0, "ink")
	_board.place_unit(1, "dust")
	assert_bool(_board.is_unlocked("big_tonic")).is_false()
	assert_bool(_board.is_ready("big_tonic")).is_false()
	assert_bool(_board.craft("big_tonic")).is_false()


func test_upgrading_pays_from_the_inventory_and_unlocks_the_next_recipes() -> void:
	# Arrange
	_loot.add("bone", 3)
	# Act
	assert_bool(_board.can_upgrade()).is_true()
	assert_bool(_board.upgrade()).is_true()
	# Assert
	assert_int(_board.tier).is_equal(1)
	assert_int(_loot.count("bone")).is_equal(1)
	assert_bool(_board.is_unlocked("big_tonic")).is_true()
	assert_dict(_board.next_upgrade()).is_empty()
	assert_bool(_board.upgrade()).is_false()


func test_an_upgrade_without_its_cost_changes_nothing() -> void:
	_loot.add("bone", 1)
	assert_bool(_board.can_upgrade()).is_false()
	assert_bool(_board.upgrade()).is_false()
	assert_int(_board.tier).is_equal(0)
	assert_int(_loot.count("bone")).is_equal(1)


# --- keeping state --------------------------------------------------------------------------

func test_the_board_the_result_and_the_tier_survive_save_and_load() -> void:
	# Arrange
	_loot.add("bone", 2)
	_board.upgrade()
	_fill_tonic()
	_board.craft("tonic")
	_loot.add("dust", 1)
	_board.place_unit(3, "dust")
	var saved: Dictionary = _board.save_state()
	# Act
	var other := CraftingBoard.new(_config(), _loot)
	other.load_state(saved)
	# Assert
	assert_int(other.tier).is_equal(1)
	assert_dict(other.slot(3)).is_equal({"item": "dust", "count": 1})
	assert_dict(other.result()).is_equal({"item": "tonic", "count": 1})


func test_every_change_is_announced() -> void:
	var changes: Array[int] = []
	_board.changed.connect(func() -> void: changes.append(1))
	_loot.add("dust", 1)
	_board.place_unit(0, "dust")
	_board.place_unit(0, "thread")   # refused
	_board.return_unit(0)
	assert_int(changes.size()).is_equal(2)

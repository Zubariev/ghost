## Searching hiding spots for things (user decision 2026-11-15): hold E while hidden to
## search; a 4- or 9-slot grid shows what is there; take items one by one; unique items are
## found once, renewable ones come back after a while; leaving the spot closes the grid.
extends GdUnitTestSuite

const SEARCH: float = 3.0
const RESPAWN: int = 100
const SPOT: String = "chest"
const BIG_SPOT: String = "wardrobe"

var _loot: GhostLoot
var _found: Array[String] = []


func _config() -> Dictionary:
	return {
		"search_minutes": SEARCH,
		"grid": {"small": 4, "large": 9},
		"spots": {
			SPOT: {"size": "small", "unique": ["letter"], "renewable": ["dust"]},
			BIG_SPOT: {"size": "large", "unique": [], "renewable": ["dust", "thread"]},
		},
		"items": {
			"dust": {"name": "ITEM_dust", "kind": "material", "respawn_minutes": RESPAWN},
			"thread": {"name": "ITEM_thread", "kind": "material", "respawn_minutes": RESPAWN},
			"letter": {"name": "ITEM_letter", "kind": "lore", "text": "LORE_letter"},
			"map": {"name": "ITEM_map", "kind": "map", "text": "LORE_map"},
		},
	}


func before_test() -> void:
	_loot = GhostLoot.new(_config())
	_found = []
	_loot.searched.connect(func(spot: String, slots: Array[String]) -> void: _found.append(spot))


## Holds E for the whole search at game time [param now].
func _search(spot: String, now: int) -> void:
	_loot.start_search(spot)
	_loot.hold(true)
	_loot.update(SEARCH, now)


func test_holding_e_for_the_search_time_opens_the_grid() -> void:
	# Act
	_loot.start_search(SPOT)
	_loot.hold(true)
	_loot.update(SEARCH - 0.5, 0)
	var before: bool = _loot.is_open()
	_loot.update(0.5, 0)
	# Assert
	assert_bool(before).is_false()
	assert_bool(_loot.is_open()).is_true()
	assert_array(_found).is_equal([SPOT])


func test_letting_go_of_e_stops_the_search() -> void:
	# Act
	_loot.start_search(SPOT)
	_loot.hold(true)
	_loot.update(SEARCH - 0.5, 0)
	_loot.hold(false)
	_loot.update(SEARCH, 0)
	# Assert
	assert_bool(_loot.is_searching()).is_false()
	assert_bool(_loot.is_open()).is_false()


func test_small_spots_have_four_slots_and_large_spots_nine() -> void:
	_search(SPOT, 0)
	assert_int(_loot.grid().size()).is_equal(4)
	_loot.close()
	_search(BIG_SPOT, 0)
	assert_int(_loot.grid().size()).is_equal(9)


func test_the_grid_shows_the_spots_items() -> void:
	_search(SPOT, 0)
	var items: Array[String] = _loot.grid().filter(func(id: String) -> bool: return not id.is_empty())
	assert_array(items).contains_exactly_in_any_order(["letter", "dust"])


func test_taking_an_item_moves_it_to_the_inventory() -> void:
	# Arrange
	_search(SPOT, 0)
	var slot: int = _loot.grid().find("dust")
	# Act
	var taken: String = _loot.take(slot, 0)
	# Assert
	assert_str(taken).is_equal("dust")
	assert_int(_loot.count("dust")).is_equal(1)
	assert_str(_loot.grid()[slot]).is_empty()


func test_taking_an_empty_slot_gives_nothing() -> void:
	_search(SPOT, 0)
	var empty: int = _loot.grid().find("")
	assert_str(_loot.take(empty, 0)).is_empty()
	assert_dict(_loot.inventory).is_empty()


func test_leaving_the_spot_closes_the_grid_and_a_new_search_is_needed() -> void:
	# Arrange
	_search(SPOT, 0)
	# Act
	_loot.close()
	# Assert
	assert_bool(_loot.is_open()).is_false()
	assert_array(_loot.grid()).is_empty()
	assert_str(_loot.take(0, 0)).is_empty()


func test_a_unique_item_is_found_once_ever() -> void:
	# Arrange: take the letter
	_search(SPOT, 0)
	_loot.take(_loot.grid().find("letter"), 0)
	_loot.close()
	# Act: search again much later
	_search(SPOT, RESPAWN * 10)
	# Assert
	assert_bool(_loot.grid().has("letter")).is_false()
	assert_array(_loot.lore_found).is_equal(["letter"])


func test_items_left_behind_are_still_there_next_time() -> void:
	# Arrange: open but take nothing
	_search(SPOT, 0)
	_loot.close()
	# Act
	_search(SPOT, 1)
	# Assert
	assert_bool(_loot.grid().has("letter")).is_true()
	assert_bool(_loot.grid().has("dust")).is_true()


func test_a_renewable_item_comes_back_after_its_time() -> void:
	# Arrange: take the dust at minute 10
	_search(SPOT, 10)
	_loot.take(_loot.grid().find("dust"), 10)
	_loot.close()
	# Act: too soon, then after the respawn time
	_search(SPOT, 10 + RESPAWN - 1)
	var too_soon: bool = _loot.grid().has("dust")
	_loot.close()
	_search(SPOT, 10 + RESPAWN)
	# Assert
	assert_bool(too_soon).is_false()
	assert_bool(_loot.grid().has("dust")).is_true()


func test_the_grid_is_the_same_every_search_of_the_same_contents() -> void:
	_search(BIG_SPOT, 0)
	var first: Array[String] = _loot.grid()
	_loot.close()
	_search(BIG_SPOT, 0)
	assert_array(_loot.grid()).is_equal(first)


func test_a_spot_without_loot_data_opens_an_empty_small_grid() -> void:
	_search("unknown_spot", 0)
	assert_int(_loot.grid().size()).is_equal(4)
	assert_int(_loot.grid().filter(func(id: String) -> bool: return not id.is_empty()).size()).is_equal(0)


func test_materials_stack_in_slots_and_a_new_kind_is_refused_when_all_slots_are_used() -> void:
	# Arrange: one slot, a large spot holding dust and thread
	var cfg: Dictionary = _config()
	cfg["inventory_slots"] = 1
	_loot = GhostLoot.new(cfg)
	_search(BIG_SPOT, 0)
	# Act
	var first: String = _loot.take(0, 0)        # dust: takes the only slot
	var refused: bool = _loot.can_take(1)       # thread: a new kind, no slot left
	var nothing: String = _loot.take(1, 0)
	_loot.close()
	_search(BIG_SPOT, RESPAWN)                  # dust is back
	var stacked: String = _loot.take(0, RESPAWN)
	# Assert
	assert_str(first).is_equal("dust")
	assert_bool(refused).is_false()
	assert_str(nothing).is_equal("")
	assert_array(_loot.grid()).contains(["thread"])   # left in the spot
	assert_str(stacked).is_equal("dust")
	assert_int(_loot.count("dust")).is_equal(2)
	assert_array(_loot.slot_items()).is_equal(["dust"])


func test_lore_and_the_map_never_use_a_slot_and_the_map_is_known_once_taken() -> void:
	# Arrange: no free slot at all
	var cfg: Dictionary = _config()
	cfg["inventory_slots"] = 0
	cfg["spots"][SPOT]["unique"] = ["letter", "map"]
	_loot = GhostLoot.new(cfg)
	_search(SPOT, 0)
	var before: bool = _loot.has_map()
	# Act
	var letter: String = _loot.take(0, 0)
	var map: String = _loot.take(1, 0)
	# Assert
	assert_bool(before).is_false()
	assert_str(letter).is_equal("letter")
	assert_str(map).is_equal("map")
	assert_bool(_loot.has_map()).is_true()
	assert_array(_loot.slot_items()).is_empty()

## The attic spider's trade and the nests it gives (sprint 001, phase F, 2026-11-26): six flies
## for a spider nest; nothing moves unless the whole trade works; a nest dropped on the ghost
## makes the room it is in dirty again, through the room's own cleanliness.
extends GdUnitTestSuite

var _loot: GhostLoot
var _trade: SpiderTrade


func _loot_config(slots: int = 10) -> Dictionary:
	return {"inventory_slots": slots, "spots": {}, "items": {
		"fly": {"name": "ITEM_fly", "kind": "material"},
		"dust": {"name": "ITEM_dust", "kind": "material"},
		"spider_nest": {"name": "ITEM_spider_nest", "kind": "consumable"},
	}}


func _make(slots: int = 10) -> void:
	_loot = GhostLoot.new(_loot_config(slots))
	_trade = SpiderTrade.new({"give": {"fly": 6}, "get": {"spider_nest": 1}}, _loot)


func before_test() -> void:
	_make()


func test_six_flies_buy_a_nest() -> void:
	# Arrange
	_loot.add("fly", 7)
	# Act
	var ok: bool = _trade.trade()
	# Assert
	assert_bool(ok).is_true()
	assert_int(_loot.count("fly")).is_equal(1)
	assert_int(_loot.count("spider_nest")).is_equal(1)


func test_too_few_flies_trade_nothing_and_say_how_many_are_missing() -> void:
	_loot.add("fly", 5)
	assert_int(_trade.missing()).is_equal(1)
	assert_bool(_trade.can_trade()).is_false()
	assert_bool(_trade.trade()).is_false()
	assert_int(_loot.count("fly")).is_equal(5)
	assert_int(_loot.count("spider_nest")).is_equal(0)


func test_repeated_trades_never_duplicate_or_lose_anything() -> void:
	_loot.add("fly", 13)
	assert_bool(_trade.trade()).is_true()
	assert_bool(_trade.trade()).is_true()
	assert_bool(_trade.trade()).is_false()
	assert_int(_loot.count("fly")).is_equal(1)
	assert_int(_loot.count("spider_nest")).is_equal(2)


func test_a_nest_that_does_not_fit_leaves_the_flies() -> void:
	# Arrange: two slots, both taken (flies and dust), and more flies than the price
	_make(2)
	_loot.add("fly", 7)
	_loot.add("dust", 1)
	# Act / Assert: the nest has no slot, so the flies stay
	assert_bool(_trade.can_trade()).is_false()
	assert_bool(_trade.trade()).is_false()
	assert_int(_loot.count("fly")).is_equal(7)


func test_paying_with_every_fly_frees_the_slot_the_nest_takes() -> void:
	# Arrange: two slots, flies and dust; exactly six flies
	_make(2)
	_loot.add("fly", 6)
	_loot.add("dust", 1)
	# Act / Assert
	assert_bool(_trade.can_trade()).is_true()
	assert_bool(_trade.trade()).is_true()
	assert_int(_loot.count("spider_nest")).is_equal(1)
	assert_int(_loot.count("fly")).is_equal(0)


# --- the nest -------------------------------------------------------------------------------

func _house() -> HouseState:
	return HouseState.from_dict({"rooms": [
		{"id": "kitchen", "floor": 0, "grid": [0, 0], "cleanliness": "clean"},
		{"id": "hall", "floor": 0, "grid": [1, 0], "cleanliness": "dirty"},
		{"id": "yard", "floor": 0, "grid": [2, 0], "outdoor": true, "family": false},
	], "doors": [], "objects": []})


func test_a_nest_makes_a_cleaned_room_dirty_again() -> void:
	var house := _house()
	assert_bool(SpiderTrade.dirty_room(house, "kitchen")).is_true()
	assert_int(house.rooms["kitchen"].cleanliness).is_equal(RoomState.Cleanliness.DIRTY)


func test_a_nest_in_a_room_already_dirty_or_outdoors_is_refused() -> void:
	var house := _house()
	assert_bool(SpiderTrade.dirty_room(house, "hall")).is_false()
	assert_bool(SpiderTrade.dirty_room(house, "yard")).is_false()
	assert_bool(SpiderTrade.dirty_room(house, "nowhere")).is_false()


func test_a_room_made_dirty_by_a_nest_is_cleaned_by_the_family_again() -> void:
	# The existing cleaning tasks pick the room up: no new room-state system
	var house := _house()
	SpiderTrade.dirty_room(house, "kitchen")
	var board := TaskBoard.new(house, {"clean": {"dirty_priority": 5}, "repair": {}})
	var keys: Array[String] = []
	for task: HouseTask in board.tasks_for_role(TaskBoard.ROLE_CLEAN):
		keys.append(task.key)
	assert_array(keys).contains(["clean:kitchen"])

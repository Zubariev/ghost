## Grandpa's monocle (sprint 001, phase G, 2026-11-26; user brief items 12 to 14): found once on the
## dresser (with a message, the first time only), kept in the inventory, activated by dragging it
## onto the ghost for a set time; when the time is up it turns up again in a random hiding spot,
## to be searched for. There is always exactly one monocle: on the dresser, in the inventory,
## active, or in one hiding spot.
extends GdUnitTestSuite

const MINUTES: float = 90.0

var _loot: GhostLoot
var _effects: GhostEffects
var _monocle: Monocle
var _rng := RandomNumberGenerator.new()


func _loot_config(slots: int = 10) -> Dictionary:
	return {"inventory_slots": slots, "search_minutes": 1, "grid": {"small": 4, "large": 9},
		"spots": {
			"chest": {"size": "small", "unique": [], "renewable": ["dust"]},
			"wardrobe": {"size": "large", "unique": [], "renewable": ["dust"]},
			"sofa": {"size": "small", "unique": [], "renewable": ["dust", "dust", "dust", "dust"]},
		},
		"items": {
			"dust": {"name": "ITEM_dust", "kind": "material", "respawn_minutes": 100},
			"monocle": {"name": "ITEM_monocle", "kind": "tool", "use": {"effect": "monocle", "minutes": MINUTES}},
		}}


func _make(slots: int = 10) -> void:
	_loot = GhostLoot.new(_loot_config(slots))
	_effects = GhostEffects.new()
	_rng.seed = 7
	_monocle = Monocle.new(_loot, _effects, _rng)


func before_test() -> void:
	_make()


## Where the monocle is now (for the one-monocle rule).
func _places() -> Array[String]:
	var out: Array[String] = []
	if not _monocle.found:
		out.append("dresser")
	for i: int in _loot.count("monocle"):
		out.append("inventory")
	if _effects.is_active("monocle"):
		out.append("active")
	if not _loot.placed_spot("monocle").is_empty():
		out.append("spot")
	return out


func _search_and_take(spot: String) -> void:
	_loot.start_search(spot); _loot.hold(true); _loot.update(5.0, 0)
	_loot.take(_loot.grid().find("monocle"), 0)
	_loot.close()


func test_before_it_is_found_the_monocle_is_on_the_dresser_only() -> void:
	assert_array(_places()).is_equal(["dresser"])
	assert_bool(_monocle.is_active()).is_false()


func test_finding_it_puts_it_in_the_inventory_and_says_so_the_first_time() -> void:
	assert_bool(_monocle.take_from_dresser()).is_true()
	assert_bool(_monocle.first_find_message).is_true()
	assert_array(_places()).is_equal(["inventory"])


func test_the_dresser_gives_it_only_once() -> void:
	_monocle.take_from_dresser()
	assert_bool(_monocle.take_from_dresser()).is_false()
	assert_int(_loot.count("monocle")).is_equal(1)


func test_a_full_inventory_leaves_it_on_the_dresser() -> void:
	_make(1)
	_loot.add("dust", 1)
	assert_bool(_monocle.take_from_dresser()).is_false()
	assert_array(_places()).is_equal(["dresser"])


func test_activating_takes_it_out_of_the_inventory_for_its_time() -> void:
	_monocle.take_from_dresser()
	assert_bool(_monocle.activate({"minutes": MINUTES})).is_true()
	assert_bool(_monocle.is_active()).is_true()
	assert_float(_effects.remaining("monocle")).is_equal(MINUTES)
	assert_array(_places()).is_equal(["active"])


func test_it_cannot_be_activated_without_holding_it() -> void:
	assert_bool(_monocle.activate({"minutes": MINUTES})).is_false()
	assert_bool(_monocle.is_active()).is_false()


func test_when_its_time_is_up_it_turns_up_in_a_hiding_spot() -> void:
	# Arrange
	_monocle.take_from_dresser()
	_monocle.activate({"minutes": MINUTES})
	# Act
	_effects.update(MINUTES)
	# Assert: no longer active, in exactly one known spot
	assert_bool(_monocle.is_active()).is_false()
	assert_array(_places()).is_equal(["spot"])
	assert_array(["chest", "wardrobe", "sofa"]).contains([_loot.placed_spot("monocle")])


func test_it_can_be_found_by_searching_and_activated_again() -> void:
	_monocle.take_from_dresser()
	_monocle.activate({"minutes": MINUTES})
	_effects.update(MINUTES)
	_search_and_take(_loot.placed_spot("monocle"))
	assert_array(_places()).is_equal(["inventory"])
	assert_bool(_monocle.activate({"minutes": MINUTES})).is_true()
	assert_bool(_monocle.first_find_message).is_true()   # unchanged: the message was the first time only


func test_it_shows_first_in_a_full_spots_grid() -> void:
	# the sofa's four slots are full of dust; the monocle must still be visible
	_loot.place("monocle", "sofa")
	_loot.start_search("sofa"); _loot.hold(true); _loot.update(5.0, 0)
	assert_str(_loot.grid()[0]).is_equal("monocle")


func test_the_spot_is_random_but_reproducible_and_varies() -> void:
	var spots: Dictionary = {}
	for seed: int in 12:
		_make()
		_rng.seed = seed
		_monocle.take_from_dresser()
		_monocle.activate({"minutes": MINUTES})
		_effects.update(MINUTES)
		spots[_loot.placed_spot("monocle")] = true
	assert_int(spots.size()).is_greater(1)


func test_there_is_never_a_second_monocle() -> void:
	# a placed monocle cannot be placed again, nor one that is held
	_monocle.take_from_dresser()
	assert_bool(_loot.place("monocle", "chest")).is_false()
	_monocle.activate({"minutes": MINUTES})
	_effects.update(MINUTES)
	var spot: String = _loot.placed_spot("monocle")
	assert_bool(_loot.place("monocle", "wardrobe" if spot != "wardrobe" else "chest")).is_false()
	assert_array(_places()).is_equal(["spot"])


func test_found_and_placed_survive_save_and_load() -> void:
	_monocle.take_from_dresser()
	_monocle.activate({"minutes": MINUTES})
	_effects.update(MINUTES)
	var spot: String = _loot.placed_spot("monocle")
	var saved_loot: Dictionary = _loot.save_state()
	var saved_monocle: Dictionary = _monocle.save_state()
	_make()
	_loot.load_state(saved_loot)
	_monocle.load_state(saved_monocle)
	assert_bool(_monocle.found).is_true()
	assert_str(_loot.placed_spot("monocle")).is_equal(spot)
	assert_array(_places()).is_equal(["spot"])

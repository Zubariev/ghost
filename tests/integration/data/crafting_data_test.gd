## The shipped crafting data fits the items and the board (sprint 001, phase D, 2026-11-26).
extends GdUnitTestSuite


func _crafting() -> Dictionary:
	return JsonData.read(CraftingBoard.RECIPES_PATH)


func _items() -> Dictionary:
	return JsonData.read(GhostLoot.LOOT_PATH)["items"]


func test_every_recipe_uses_and_makes_known_slot_items_and_fits_the_board() -> void:
	Localization.load_csv("res://assets/i18n/strings.csv", "uk")
	var data: Dictionary = _crafting()
	var loot := GhostLoot.new(JsonData.read(GhostLoot.LOOT_PATH))
	var ids: Array[String] = []
	for r: Dictionary in data["recipes"]:
		var id: String = String(r["id"])
		assert_bool(ids.has(id)).override_failure_message("duplicate recipe " + id).is_false()
		ids.append(id)
		assert_bool(_items().has(String(r["result"]))).override_failure_message(id + ": unknown result").is_true()
		assert_bool(loot.uses_slot(String(r["result"]))).override_failure_message(id + ": result takes no slot").is_true()
		assert_int((r["ingredients"] as Dictionary).size()).is_between(1, int(data["slots"]))
		for item: String in r["ingredients"]:
			assert_bool(_items().has(item)).override_failure_message(id + ": unknown ingredient " + item).is_true()
			assert_int(int(r["ingredients"][item])).is_greater(0)
		assert_str(String(r["text"])).is_not_empty()
		assert_str(TranslationServer.translate(String(r["text"]))).is_not_equal(String(r["text"]))


func test_every_tier_with_recipes_can_be_reached_by_upgrades() -> void:
	var data: Dictionary = _crafting()
	var reachable: Array[int] = [int(data["start_tier"])]
	for u: Dictionary in data["upgrades"]:
		reachable.append(int(u["tier"]))
		for item: String in u["cost"]:
			assert_bool(_items().has(item)).override_failure_message("upgrade cost: unknown " + item).is_true()
	for r: Dictionary in data["recipes"]:
		assert_bool(reachable.has(int(r["tier"]))).override_failure_message(String(r["id"]) + " tier unreachable").is_true()
	# at least one recipe needs an upgrade (the tree's growth matters)
	assert_bool(data["recipes"].any(func(r: Dictionary) -> bool: return int(r["tier"]) > int(data["start_tier"]))).is_true()


func test_both_elixirs_can_be_crafted_from_the_start() -> void:
	var start: int = int(_crafting()["start_tier"])
	var results: Array[String] = []
	for r: Dictionary in _crafting()["recipes"]:
		if int(r["tier"]) <= start:
			results.append(String(r["result"]))
	assert_array(results).contains(["elixir_energy", "elixir_speed"])


func test_every_starting_ingredient_can_be_found_in_a_hiding_spot() -> void:
	# The base recipes must be makeable from what searching finds.
	var found: Dictionary = {}
	for spot: Dictionary in JsonData.read(GhostLoot.LOOT_PATH)["spots"].values():
		for item: String in spot.get("renewable", []) + spot.get("unique", []):
			found[item] = true
	for r: Dictionary in _crafting()["recipes"]:
		for item: String in r["ingredients"]:
			assert_bool(found.has(item)).override_failure_message(String(r["id"]) + ": " + item + " is never found").is_true()

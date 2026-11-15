## The shipped loot data fits the house and the texts (reads assets/; user decision
## 2026-11-15): every hiding spot can be searched, every item exists and is named, unique
## items live in one place only, renewables come back, lore has a text.
extends GdUnitTestSuite

const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"


func _loot() -> Dictionary:
	return JsonData.read(GhostLoot.LOOT_PATH)


func _hide_ids() -> Array[String]:
	var ids: Array[String] = []
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		for piece: Dictionary in rooms[room_id]:
			if piece.has("hide_id"):
				ids.append(String(piece["hide_id"]))
	return ids


func test_every_hiding_spot_has_loot_and_every_loot_spot_is_a_hiding_spot() -> void:
	var spots: Dictionary = _loot()["spots"]
	var hide_ids: Array[String] = _hide_ids()
	for id: String in hide_ids:
		assert_bool(spots.has(id)).override_failure_message("no loot for " + id).is_true()
	for id: String in spots:
		assert_bool(hide_ids.has(id)).override_failure_message("loot for unknown spot " + id).is_true()


func test_spots_fit_their_grid_and_name_known_items() -> void:
	var loot: Dictionary = _loot()
	var items: Dictionary = loot["items"]
	for id: String in loot["spots"]:
		var spot: Dictionary = loot["spots"][id]
		var size: int = int(loot["grid"][String(spot["size"])])
		var listed: Array = (spot["unique"] as Array) + (spot["renewable"] as Array)
		assert_int(listed.size()).override_failure_message(id + " overflows its grid").is_less_equal(size)
		for item: String in listed:
			assert_bool(items.has(item)).override_failure_message(id + ": unknown item " + item).is_true()


func test_unique_items_live_in_one_spot_only() -> void:
	var seen: Dictionary = {}
	var spots: Dictionary = _loot()["spots"]
	for id: String in spots:
		for item: String in spots[id]["unique"]:
			assert_bool(seen.has(item)).override_failure_message(item + " is in two spots").is_false()
			seen[item] = id


func test_renewables_come_back_and_lore_has_text_and_every_item_is_named() -> void:
	Localization.load_csv("res://assets/i18n/strings.csv", "uk")
	var items: Dictionary = _loot()["items"]
	var renewable: Array = []
	for spot: Dictionary in (_loot()["spots"] as Dictionary).values():
		renewable.append_array(spot["renewable"])
	for id: String in items:
		var item: Dictionary = items[id]
		var name_key: String = String(item["name"])
		assert_str(tr(name_key)).override_failure_message("no text for " + name_key).is_not_equal(name_key)
		if renewable.has(id):
			assert_int(int(item.get("respawn_minutes", 0))).override_failure_message(id).is_greater(0)
		if String(item["kind"]) == "lore":
			var text_key: String = String(item.get("text", ""))
			assert_str(tr(text_key)).override_failure_message("no lore text for " + id).is_not_equal(text_key)

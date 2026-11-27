## The shipped roots (sprint 002, P3, task S2-04) match the approved catalog
## (design/crafting-progression-catalog.md) and the rest of the game's data.
extends GdUnitTestSuite

const CATALOG_IDS: Array[String] = ["T0", "T1", "T2",
	"R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10", "R11",
	"G1", "G2", "G3", "G4", "G5", "G6", "G7", "G8", "K1", "K2", "K3", "K4"]


func _prog() -> Dictionary:
	return JsonData.read(CraftingProgression.PROGRESSION_PATH)


func _nodes() -> Array:
	return _prog()["nodes"]


func test_the_shipped_graph_has_no_problems() -> void:
	var problems: PackedStringArray = CraftingProgression.check(_prog(), JsonData.read(CraftingBoard.RECIPES_PATH))
	assert_array(Array(problems)).is_empty()


func test_exactly_the_catalog_nodes_are_shipped() -> void:
	var ids: Array = _nodes().map(func(n: Dictionary) -> String: return String(n["id"]))
	ids.sort()
	var expected: Array = CATALOG_IDS.duplicate()
	expected.sort()
	assert_array(ids).is_equal(expected)


func test_the_rooms_branch_is_the_longest_with_one_bond_per_family_room() -> void:
	var count: Dictionary = {}
	var bonded: Array[String] = []
	for n: Dictionary in _nodes():
		count[n["branch"]] = int(count.get(n["branch"], 0)) + 1
		if n["branch"] == "rooms":
			bonded.append(String(n["effects"][0]["room"]))
	for branch: String in count:
		if branch != "rooms":
			assert_int(int(count["rooms"])).is_greater(int(count[branch]))
	var house: HouseState = HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))
	for room_id: String in house.rooms:
		var room: RoomState = house.rooms[room_id]
		assert_bool(bonded.has(room_id)).override_failure_message("bond for " + room_id).is_equal(room.family_access)


func test_costs_name_known_items_and_effects_name_known_rooms_people_and_actions() -> void:
	var items: Dictionary = JsonData.read(GhostLoot.LOOT_PATH)["items"]
	var house: HouseState = HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))
	var people: Array = []
	for path: String in HouseSim.SCHEDULE_PATHS:
		people.append(String(JsonData.read(path)["npc_id"]))
	var actions: Dictionary = JsonData.read("res://assets/data/ghost/energy.json")["actions"]
	for n: Dictionary in _nodes():
		for item: String in n.get("cost", {}):
			assert_bool(items.has(item)).override_failure_message("%s cost: %s" % [n["id"], item]).is_true()
		for e: Dictionary in n.get("effects", []):
			if e.has("room"):
				assert_bool(house.rooms.has(String(e["room"]))).override_failure_message("%s room" % n["id"]).is_true()
			for who: Variant in e.get("npcs", []):
				assert_bool(people.has(String(who))).override_failure_message("%s npc %s" % [n["id"], who]).is_true()
			if e.has("action"):
				assert_bool(actions.has(String(e["action"]))).override_failure_message("%s action %s" % [n["id"], e["action"]]).is_true()


func test_the_trunk_is_the_trees_existing_levels() -> void:
	var tiers: Array = []
	for n: Dictionary in _nodes():
		if n.has("tier"):
			tiers.append(int(n["tier"]))
	var board: Dictionary = JsonData.read(CraftingBoard.RECIPES_PATH)
	var expected: Array = [int(board["start_tier"])]
	for u: Dictionary in board["upgrades"]:
		expected.append(int(u["tier"]))
	assert_array(tiers).is_equal(expected)


# --- Sprint 002 (P5): the shipped layout fits the roots screen (design/ux/roots-progression.md) ---

func test_every_node_sits_in_the_soil_and_none_crowd_each_other() -> void:
	var layout := RootsLayout.new(_prog())
	var ids: Array[String] = layout.tab_order()
	for id: String in ids:
		var at: Vector2 = layout.position(id)
		assert_bool(at.x >= 20.0 and at.x <= 1260.0 and at.y >= RootsScreen.GROUND_Y + 20.0 and at.y <= RootsScreen.PANEL_Y - 20.0) \
			.override_failure_message("%s at %s outside the soil" % [id, at]).is_true()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var d: float = layout.position(ids[i]).distance_to(layout.position(ids[j]))
			assert_float(d).override_failure_message("%s and %s only %d px apart" % [ids[i], ids[j], d]).is_greater_equal(30.0)


func test_the_rooms_root_runs_left_to_the_coffin() -> void:
	var layout := RootsLayout.new(_prog())
	assert_str(layout.coffin_branch()).is_equal("rooms")
	var coffin: Vector2 = layout.coffin_position()
	assert_float(coffin.x).is_less(layout.position("T0").x * 0.5)   # far to the left
	for n: Dictionary in _nodes():
		if n["branch"] != "rooms":
			assert_float(layout.position(String(n["id"])).x).is_greater(coffin.x)


func test_every_node_and_branch_has_its_text() -> void:
	var csv := FileAccess.open("res://assets/i18n/strings.csv", FileAccess.READ).get_as_text()
	for n: Dictionary in _nodes():
		for key: String in [String(n["name"]), String(n["name"]) + "_TEXT"]:
			assert_bool(csv.contains("\n" + key + ",")).override_failure_message("missing string " + key).is_true()
	for b: Dictionary in _prog()["branches"]:
		assert_bool(csv.contains("\n" + String(b["name"]) + ",")).override_failure_message("missing string " + String(b["name"])).is_true()

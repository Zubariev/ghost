## The shipped spider, flies and nests (sprint 001, phase F, 2026-11-26): the spider lives in the
## attic for good; flies can be found in several rooms but come back far more often in the kitchen;
## the trade uses known items and the nest is usable on the ghost.
extends GdUnitTestSuite

const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"


## Flies found per game day in each room, if every fly is taken as soon as it is back.
func _flies_per_day() -> Dictionary:
	var loot: Dictionary = JsonData.read(GhostLoot.LOOT_PATH)
	var room_of: Dictionary = {}
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		for piece: Dictionary in rooms[room_id]:
			if piece.has("hide_id"):
				room_of[String(piece["hide_id"])] = room_id
	var usual: float = float(loot["items"]["fly"]["respawn_minutes"])
	var out: Dictionary = {}
	for spot_id: String in loot["spots"]:
		var spot: Dictionary = loot["spots"][spot_id]
		if (spot.get("renewable", []) as Array).has("fly"):
			var minutes: float = float(spot.get("respawn", {}).get("fly", usual))
			var room: String = String(room_of[spot_id])
			out[room] = float(out.get(room, 0.0)) + float(GameClock.MINUTES_PER_DAY) / minutes
	return out


func test_flies_are_found_in_several_rooms_and_most_in_the_kitchen() -> void:
	var per_day: Dictionary = _flies_per_day()
	assert_int(per_day.size()).is_greater_equal(3)
	assert_bool(per_day.has("kitchen")).is_true()
	for room: String in per_day:
		if room != "kitchen":
			assert_float(float(per_day["kitchen"])).override_failure_message("kitchen vs " + room).is_greater(float(per_day[room]) * 2.0)


func test_the_spider_lives_in_the_attic() -> void:
	var spider: Dictionary = JsonData.read(SpiderTrade.SPIDER_PATH)
	var count: int = 0
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		for piece: Dictionary in rooms[room_id]:
			if String(piece.get("kind", "")) == String(spider["kind"]):
				count += 1
				assert_str(room_id).is_equal("attic")
	assert_int(count).is_equal(1)


func test_the_trade_takes_flies_and_gives_a_usable_nest() -> void:
	var spider: Dictionary = JsonData.read(SpiderTrade.SPIDER_PATH)
	var items: Dictionary = JsonData.read(GhostLoot.LOOT_PATH)["items"]
	assert_array((spider["give"] as Dictionary).keys()).is_equal(["fly"])
	assert_int(int(spider["give"]["fly"])).is_equal(6)
	for item: String in spider["get"]:
		assert_bool(items.has(item)).is_true()
		assert_int(int(spider["get"][item])).is_greater(0)
	assert_str(String(items["spider_nest"]["use"]["effect"])).is_equal("dirty_room")

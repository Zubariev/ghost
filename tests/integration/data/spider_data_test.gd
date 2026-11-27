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


# --- Sprint 002 (P2, S2-03): the shipped appetite and web keep the agreed balance targets ---

## Trades (6 flies each) until the shipped spider turns hostile, one every [param days] game days;
## -1 when it never does within [param limit] trades.
func _trades_to_hostile(days: float, limit: int = 40) -> int:
	var data: Dictionary = JsonData.read(SpiderTrade.SPIDER_PATH)
	var spider := SpiderEcology.new(data["ecology"])
	for trade: int in limit:
		spider.feed(int(data["give"]["fly"]))
		if spider.mood == SpiderEcology.Mood.HOSTILE:
			return trade + 1
		spider.advance(days * GameClock.MINUTES_PER_DAY)
	return -1


func test_a_trade_every_day_turns_the_spider_hostile_in_four_to_six_trades() -> void:
	assert_int(_trades_to_hostile(1.0)).is_between(4, 6)


func test_a_trade_every_other_day_never_turns_it_hostile() -> void:
	assert_int(_trades_to_hostile(2.0)).is_equal(-1)


func test_hostility_and_recovery_last_several_game_days_not_forever() -> void:
	var data: Dictionary = JsonData.read(SpiderTrade.SPIDER_PATH)
	var spider := SpiderEcology.new(data["ecology"])
	spider.feed(100)
	var days: int = 0
	while spider.mood != SpiderEcology.Mood.FRIENDLY and days < 30:
		spider.advance(GameClock.MINUTES_PER_DAY)
		days += 1
	assert_int(days).is_between(3, 10)


func test_the_web_is_fair_and_capped() -> void:
	var web: Dictionary = JsonData.read(SpiderTrade.SPIDER_PATH)["web"]
	var ghost: Dictionary = JsonData.read("res://assets/data/ghost/ghost.json")
	# a ghost moving at its slowest (a tidy room) leaves the hit circle before the web lands
	var dodge_m: float = float(ghost["speed"]) * float(ghost["slowest_in_order"]) * float(web["telegraph_seconds"])
	assert_float(dodge_m).is_greater(float(web["hit_radius_m"]) * 2.0)
	assert_float(float(web["cooldown_seconds"])).is_greater(float(web["telegraph_seconds"]))
	# a whole day of hits takes at most half the energy pool
	assert_float(float(web["damage_pct"]) * float(web["max_hits_per_day"])).is_less_equal(50.0)

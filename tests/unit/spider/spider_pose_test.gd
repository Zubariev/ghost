## The spider's rig (sprint 002, P4, task S2-05; user brief B2): one pose per moment, part by part
## (thread, abdomen, head, eight legs, the feeding front pair), so painted parts can follow the same
## transforms. Pixels at depth 1 from the piece's floor point.
extends GdUnitTestSuite


func _pose(anim: String = "idle", t: float = 0.0, size: float = 1.0, drop: float = 0.0) -> Dictionary:
	return SpiderPose.compute(anim, t, size, drop, 110.0)


func test_every_part_is_there() -> void:
	var p: Dictionary = _pose()
	for key: String in ["thread_top", "body", "head", "mouth", "legs"]:
		assert_bool(p.has(key)).override_failure_message(key).is_true()
	assert_int((p["legs"] as Array).size()).is_equal(8)
	for leg: Dictionary in p["legs"]:
		for joint: String in ["hip", "knee", "foot"]:
			assert_bool(leg.has(joint)).is_true()


func test_the_same_moment_gives_the_same_pose() -> void:
	assert_dict(_pose("idle", 1.3)).is_equal(_pose("idle", 1.3))


func test_dropping_lowers_the_body_and_lengthens_the_thread() -> void:
	var high: Dictionary = _pose("idle", 0.0, 1.0, 0.0)
	var low: Dictionary = _pose("idle", 0.0, 1.0, 1.0)
	assert_float((low["body"] as Vector2).y - (high["body"] as Vector2).y).is_equal_approx(110.0, 0.5)
	assert_vector(low["thread_top"]).is_equal(high["thread_top"])


func test_a_bigger_spider_spreads_its_legs_wider() -> void:
	var small: Dictionary = _pose("idle", 0.0, 1.0)
	var big: Dictionary = _pose("idle", 0.0, 1.6)
	var span := func(p: Dictionary) -> float: return absf(Vector2(p["legs"][2]["foot"]).x - Vector2(p["legs"][3]["foot"]).x)
	assert_float(span.call(big)).is_greater(span.call(small) * 1.5)


func test_eating_brings_the_front_legs_to_the_mouth() -> void:
	var idle: Dictionary = _pose("idle", 0.6)
	var eat: Dictionary = _pose("feed", 0.6)
	for i: int in 2:
		var near_idle: float = Vector2(idle["legs"][i]["foot"]).distance_to(idle["mouth"])
		var near_eat: float = Vector2(eat["legs"][i]["foot"]).distance_to(eat["mouth"])
		assert_float(near_eat).is_less(near_idle * 0.6)


func test_idle_moves_a_little_over_time() -> void:
	var a: Dictionary = _pose("idle", 0.0)
	var b: Dictionary = _pose("idle", 0.7)
	var moved: float = Vector2(a["legs"][4]["foot"]).distance_to(b["legs"][4]["foot"])
	assert_float(moved).is_greater(0.2)
	assert_float(moved).is_less(8.0)


func test_the_wind_up_rears_the_head_back() -> void:
	assert_float(Vector2(_pose("telegraph", 0.5)["head"]).y).is_less(Vector2(_pose("idle", 0.5)["head"]).y)

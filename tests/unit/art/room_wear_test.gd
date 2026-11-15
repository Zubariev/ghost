## Room wear (art Phase 2, 2026-11-15): what dirt, polish and cold show, eased; where dust and
## stains lie (never in a doorway); how embers fade after the fire goes out; breath puffs in
## a cold room; drifting dust motes. Presentation only.
extends GdUnitTestSuite


func _config() -> Dictionary:
	return {
		"fade_per_second": 2.0, "dust_patches": 8, "door_clear": 0.15, "floor_margin": 0.05,
		"ember_seconds": 20.0, "breath_period": 4.0, "breath_alpha": 0.5, "motes": 10,
	}


func _room(cleanliness: RoomState.Cleanliness, temperature: RoomState.Temperature = RoomState.Temperature.COMFORTABLE) -> RoomState:
	var room := RoomState.new()
	room.cleanliness = cleanliness
	room.temperature = temperature
	return room


func test_only_a_dirty_room_shows_dirt_and_only_a_clean_one_polish() -> void:
	assert_float(RoomWear.dirt_target(_room(RoomState.Cleanliness.DIRTY))).is_equal(1.0)
	assert_float(RoomWear.dirt_target(_room(RoomState.Cleanliness.NORMAL))).is_equal(0.0)
	assert_float(RoomWear.polish_target(_room(RoomState.Cleanliness.CLEAN))).is_equal(1.0)
	assert_float(RoomWear.polish_target(_room(RoomState.Cleanliness.NORMAL))).is_equal(0.0)
	assert_float(RoomWear.polish_target(_room(RoomState.Cleanliness.DIRTY))).is_equal(0.0)


func test_only_a_cold_room_shows_breath() -> void:
	assert_float(RoomWear.cold_target(_room(RoomState.Cleanliness.NORMAL, RoomState.Temperature.COLD))).is_equal(1.0)
	assert_float(RoomWear.cold_target(_room(RoomState.Cleanliness.NORMAL))).is_equal(0.0)


func test_shown_wear_eases_toward_its_target() -> void:
	# Arrange: 2 per second
	var wear := RoomWear.new(_config())
	# Act / Assert: a quarter second moves half way, never past the target
	assert_float(wear.ease(1.0, 0.0, 0.25)).is_equal_approx(0.5, 0.0001)
	assert_float(wear.ease(0.2, 0.0, 1.0)).is_equal(0.0)
	assert_float(wear.ease(0.0, 1.0, 0.1)).is_equal_approx(0.2, 0.0001)


func test_dust_lies_on_the_floor_clear_of_doors_and_always_in_the_same_place() -> void:
	# Arrange: many patches and two wide door zones in mid-floor, so random placement alone
	# would land in them (a missing clearance check cannot pass by luck)
	var cfg: Dictionary = _config()
	cfg["dust_patches"] = 40
	cfg["door_clear"] = 0.25
	var wear := RoomWear.new(cfg)
	var doors: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(0.2, 0.8)]
	# Act
	var first: Array[Vector3] = wear.dust_patches("kitchen", doors)
	var again: Array[Vector3] = wear.dust_patches("kitchen", doors)
	var other: Array[Vector3] = wear.dust_patches("hall", doors)
	# Assert
	assert_int(first.size()).is_equal(40)
	assert_array(again).is_equal(first)
	assert_array(other).is_not_equal(first)
	for patch: Vector3 in first:
		assert_bool(patch.x >= 0.05 and patch.x <= 0.95 and patch.y >= 0.05 and patch.y <= 0.95).is_true()
		for door: Vector2 in doors:
			assert_float(Vector2(patch.x, patch.y).distance_to(door)).is_greater_equal(0.25)


func test_embers_glow_when_the_fire_goes_out_and_fade_away() -> void:
	var wear := RoomWear.new(_config())
	assert_float(wear.ember_glow(0.0)).is_equal(1.0)
	assert_float(wear.ember_glow(10.0)).is_equal_approx(0.5, 0.0001)
	assert_float(wear.ember_glow(20.0)).is_equal(0.0)
	assert_float(wear.ember_glow(60.0)).is_equal(0.0)
	assert_float(wear.ember_glow(-1.0)).is_equal(0.0)   # never seen burning: no embers


func test_breath_puffs_come_and_go_and_people_breathe_out_of_step() -> void:
	# Arrange
	var wear := RoomWear.new(_config())
	# Act: sample one period for two people
	var lo: float = 1.0
	var hi: float = 0.0
	var same: int = 0
	for i: int in 40:
		var t: float = 4.0 * float(i) / 40.0
		var a: float = wear.breath_alpha(t, 0)
		lo = minf(lo, a)
		hi = maxf(hi, a)
		if is_equal_approx(a, wear.breath_alpha(t, 1)):
			same += 1
	# Assert
	assert_float(lo).is_equal(0.0)
	assert_float(hi).is_equal_approx(0.5, 0.05)
	assert_int(same).is_less(40)


func test_dust_motes_drift_inside_their_light_and_are_repeatable() -> void:
	var wear := RoomWear.new(_config())
	var a: Array[Vector2] = wear.mote_offsets(12.5, 3.0)
	var b: Array[Vector2] = wear.mote_offsets(12.5, 3.0)
	var later: Array[Vector2] = wear.mote_offsets(14.0, 3.0)
	assert_int(a.size()).is_equal(10)
	assert_array(b).is_equal(a)
	assert_array(later).is_not_equal(a)
	for p: Vector2 in a:
		assert_bool(absf(p.x) <= 1.0 and absf(p.y) <= 1.0).is_true()

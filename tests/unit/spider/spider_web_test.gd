## The hostile spider's web (sprint 002, P2, task S2-03): it marks a spot on the ghost, winds up,
## then spits a web at that spot. One web hits at most once; a ghost that moves away, hides or
## leaves the attic is not hit; attacks have a cooldown and a daily cap.
extends GdUnitTestSuite

const Sx := preload("res://tests/unit/fixtures/spider_fixtures.gd")
const SPIDER := Vector2(4.0, 1.0)
const GHOST := Vector2(4.0, 4.0)   # 3 m away, in range
const STEP: float = 0.05


func _web() -> SpiderWeb:
	return SpiderWeb.new(Sx.web())


## Runs [param seconds] of frames with the ghost given by [param ghost_at] (time -> position);
## returns the number of hits.
func _run(web: SpiderWeb, seconds: float, ghost_at: Callable, hostile: bool = true, exposed: bool = true, day: int = 1) -> int:
	var hits: int = 0
	var t: float = 0.0
	while t < seconds:
		if web.update(STEP, hostile, exposed, ghost_at.call(t), SPIDER, day):
			hits += 1
		t += STEP
	return hits


func test_a_calm_spider_never_attacks() -> void:
	var web := _web()
	assert_int(_run(web, 60.0, func(_t: float) -> Vector2: return GHOST, false)).is_equal(0)
	assert_int(web.phase).is_equal(SpiderWeb.Phase.READY)


func test_a_ghost_standing_still_is_hit() -> void:
	var web := _web()
	assert_int(_run(web, 3.0, func(_t: float) -> Vector2: return GHOST)).is_equal(1)


func test_the_wind_up_comes_first_and_marks_the_spot() -> void:
	var web := _web()
	web.update(STEP, true, true, GHOST, SPIDER, 1)
	assert_int(web.phase).is_equal(SpiderWeb.Phase.TELEGRAPH)
	assert_vector(web.target).is_equal(GHOST)


func test_a_ghost_that_keeps_moving_is_never_hit() -> void:
	# circling the attic at the ghost's normal speed (1.75 m/s), even close to the spider
	var web := _web()
	var circling := func(t: float) -> Vector2: return SPIDER + Vector2(1.2, 0).rotated(t * 1.75 / 1.2)
	assert_int(_run(web, 120.0, circling)).is_equal(0)


func test_one_web_hits_at_most_once() -> void:
	var web := _web()
	var hits: int = _run(web, Sx.COOLDOWN_S - 0.5 + Sx.TELEGRAPH_S + 1.0, func(_t: float) -> Vector2: return GHOST)
	assert_int(hits).is_equal(1)


func test_attacks_wait_for_the_cooldown() -> void:
	var web := _web()
	var still := func(_t: float) -> Vector2: return GHOST
	_run(web, 3.0, still)   # first hit
	assert_int(_run(web, Sx.COOLDOWN_S - 0.2, still)).is_equal(0)
	assert_int(_run(web, Sx.TELEGRAPH_S + 2.0, still)).is_equal(1)


func test_a_hidden_or_absent_ghost_is_not_attacked_and_a_web_in_flight_misses() -> void:
	var web := _web()
	assert_int(_run(web, 30.0, func(_t: float) -> Vector2: return GHOST, true, false)).is_equal(0)
	# spat while visible, then the ghost hides before it lands
	_run(web, Sx.TELEGRAPH_S + 0.1, func(_t: float) -> Vector2: return GHOST)
	assert_int(web.phase).is_equal(SpiderWeb.Phase.FLIGHT)
	assert_int(_run(web, 2.0, func(_t: float) -> Vector2: return GHOST, true, false)).is_equal(0)


func test_hiding_during_the_wind_up_cancels_the_attack() -> void:
	var web := _web()
	web.update(STEP, true, true, GHOST, SPIDER, 1)
	web.update(STEP, true, false, GHOST, SPIDER, 1)
	assert_int(web.phase).is_equal(SpiderWeb.Phase.READY)


func test_a_ghost_out_of_range_is_not_attacked() -> void:
	var web := _web()
	var far := SPIDER + Vector2(0, Sx.RANGE_M + 0.5)
	assert_int(_run(web, 30.0, func(_t: float) -> Vector2: return far)).is_equal(0)


func test_no_more_than_the_daily_cap_of_hits_then_a_new_day_resets_it() -> void:
	var web := _web()
	var still := func(_t: float) -> Vector2: return GHOST
	assert_int(_run(web, 600.0, still, true, true, 1)).is_equal(Sx.MAX_HITS_PER_DAY)
	assert_int(_run(web, 30.0, still, true, true, 2)).is_greater(0)


func test_damage_is_a_share_of_the_maximum_energy() -> void:
	var web := _web()
	assert_float(web.damage_for(100.0)).is_equal_approx(Sx.DAMAGE_PCT, 0.0001)
	assert_float(web.damage_for(120.0)).is_equal_approx(120.0 * Sx.DAMAGE_PCT / 100.0, 0.0001)


func test_flight_progress_runs_from_zero_to_one() -> void:
	var web := _web()
	assert_float(web.flight_progress()).is_equal(0.0)
	_run(web, Sx.TELEGRAPH_S + 0.1, func(_t: float) -> Vector2: return GHOST)
	var mid: float = web.flight_progress()
	assert_float(mid).is_greater(0.0)
	assert_float(mid).is_less(1.0)

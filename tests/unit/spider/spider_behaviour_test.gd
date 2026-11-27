## How the attic spider moves (sprint 002, P4, task S2-05; user brief B3): it drops smoothly toward
## the floor when the ghost comes near, climbs back a while after it leaves, eats after a trade
## and winds up before a web. Real seconds; values from spider.json "behaviour".
extends GdUnitTestSuite

const CFG: Dictionary = {"react_m": 2.5, "drop_px": 110.0, "descend_seconds": 1.2, "return_delay_seconds": 2.0, "feed_seconds": 2.5}
const STEP: float = 0.05


func _run(b: SpiderBehaviour, seconds: float, distance: float, hostile: bool = false, telegraph: bool = false) -> void:
	var t: float = 0.0
	while t < seconds:
		b.update(STEP, distance, hostile, telegraph)
		t += STEP


func test_at_rest_it_hangs_high_and_idles() -> void:
	var b := SpiderBehaviour.new(CFG)
	_run(b, 3.0, 10.0)
	assert_float(b.drop).is_equal(0.0)
	assert_str(b.anim()).is_equal("idle")


func test_a_near_ghost_makes_it_drop_smoothly_not_at_once() -> void:
	var b := SpiderBehaviour.new(CFG)
	_run(b, 0.3, 1.5)
	assert_float(b.drop).is_greater(0.0)
	assert_float(b.drop).is_less(1.0)
	_run(b, 1.2, 1.5)
	assert_float(b.drop).is_equal(1.0)


func test_it_climbs_back_only_after_the_ghost_has_been_away_a_while() -> void:
	var b := SpiderBehaviour.new(CFG)
	_run(b, 2.0, 1.5)
	_run(b, 1.9, 10.0)
	assert_float(b.drop).is_equal(1.0)
	_run(b, 0.3, 10.0)
	assert_float(b.drop).is_less(1.0)
	_run(b, 2.0, 10.0)
	assert_float(b.drop).is_equal(0.0)


func test_feeding_plays_for_its_time_then_it_idles_again() -> void:
	var b := SpiderBehaviour.new(CFG)
	b.feed()
	_run(b, 2.0, 1.0)
	assert_str(b.anim()).is_equal("feed")
	_run(b, 0.6, 1.0)
	assert_str(b.anim()).is_equal("idle")


func test_the_wind_up_shows_while_the_web_is_telegraphed_and_hostility_otherwise() -> void:
	var b := SpiderBehaviour.new(CFG)
	_run(b, 0.2, 2.0, true, true)
	assert_str(b.anim()).is_equal("telegraph")
	_run(b, 0.2, 2.0, true, false)
	assert_str(b.anim()).is_equal("hostile")


func test_a_ghost_out_of_sight_counts_as_far() -> void:
	var b := SpiderBehaviour.new(CFG)
	_run(b, 3.0, INF)
	assert_float(b.drop).is_equal(0.0)

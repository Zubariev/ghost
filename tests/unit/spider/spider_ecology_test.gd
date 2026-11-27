## The attic spider's appetite (sprint 002, P2, task S2-03): flies feed it calories, it burns
## them slowly by game time, grows with them, turns hostile when overfed, stays hostile for some
## game days and then calms and shrinks back to friendly.
extends GdUnitTestSuite

const Sx := preload("res://tests/unit/fixtures/spider_fixtures.gd")
const DAY: float = float(GameClock.MINUTES_PER_DAY)


func _spider() -> SpiderEcology:
	return SpiderEcology.new(Sx.ecology())


func test_a_new_spider_is_friendly_small_and_hungry() -> void:
	var spider := _spider()
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.FRIENDLY)
	assert_float(spider.calories).is_equal(0.0)
	assert_float(spider.size()).is_equal_approx(Sx.SIZE_MIN, 0.0001)
	assert_bool(spider.accepts_food()).is_true()


func test_each_fly_adds_its_calories() -> void:
	# Arrange
	var spider := _spider()
	# Act
	var ok: bool = spider.feed(6)
	# Assert
	assert_bool(ok).is_true()
	assert_float(spider.calories).is_equal_approx(6.0 * Sx.CAL_PER_FLY, 0.0001)


func test_calories_burn_by_game_time_never_below_zero() -> void:
	var spider := _spider()
	spider.feed(6)
	spider.advance(DAY)
	assert_float(spider.calories).is_equal_approx(6.0 * Sx.CAL_PER_FLY - Sx.DECAY_PER_DAY, 0.0001)
	spider.advance(5.0 * DAY)
	assert_float(spider.calories).is_equal(0.0)


func test_size_grows_with_calories_up_to_the_maximum() -> void:
	var spider := _spider()
	spider.feed(9)   # 90 of 180: halfway
	assert_float(spider.size()).is_equal_approx(lerpf(Sx.SIZE_MIN, Sx.SIZE_MAX, 0.5), 0.0001)
	spider.feed(9)
	assert_float(spider.size()).is_equal_approx(Sx.SIZE_MAX, 0.0001)


func test_reaching_the_grown_threshold_warns_but_still_trades() -> void:
	var spider := _spider()
	spider.feed(10)
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.GROWN)
	assert_bool(spider.accepts_food()).is_true()


func test_overfeeding_makes_it_hostile_and_it_refuses_food() -> void:
	# Arrange
	var spider := _spider()
	var moods: Array[int] = []
	spider.mood_changed.connect(func(m: int) -> void: moods.append(m))
	# Act
	spider.feed(18)
	# Assert
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.HOSTILE)
	assert_bool(spider.accepts_food()).is_false()
	assert_bool(spider.feed(6)).is_false()
	assert_float(spider.calories).is_equal_approx(Sx.HOSTILE_AT, 0.0001)
	assert_array(moods).contains([SpiderEcology.Mood.HOSTILE])


func test_calories_never_pile_up_past_the_hostile_threshold() -> void:
	var spider := _spider()
	spider.feed(40)
	assert_float(spider.calories).is_equal_approx(Sx.HOSTILE_AT, 0.0001)


func test_hostility_lasts_its_game_days_then_it_recovers() -> void:
	var spider := _spider()
	spider.feed(18)
	spider.advance(Sx.HOSTILE_DAYS * DAY - 1.0)
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.HOSTILE)
	assert_float(spider.calories).is_equal_approx(Sx.HOSTILE_AT, 0.0001)   # no burning while hostile
	spider.advance(1.0)
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.RECOVERING)
	assert_bool(spider.accepts_food()).is_false()


func test_recovery_shrinks_it_back_to_friendly_at_the_calm_level() -> void:
	# Arrange: hostile, then recovering
	var spider := _spider()
	spider.feed(18)
	spider.advance(Sx.HOSTILE_DAYS * DAY)
	var to_calm: float = (Sx.HOSTILE_AT - Sx.CALM_AT) / Sx.RECOVER_PER_DAY * DAY
	# Act / Assert
	spider.advance(to_calm - 1.0)
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.RECOVERING)
	spider.advance(1.0)
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.FRIENDLY)
	assert_float(spider.calories).is_less_equal(Sx.CALM_AT)
	assert_float(spider.size()).is_less(lerpf(Sx.SIZE_MIN, Sx.SIZE_MAX, Sx.GROWN_AT / Sx.HOSTILE_AT))
	assert_bool(spider.accepts_food()).is_true()


func test_one_long_step_crosses_hostile_and_recovery_like_many_small_ones() -> void:
	var a := _spider()
	var b := _spider()
	a.feed(18)
	b.feed(18)
	a.advance(6.0 * DAY)
	for i: int in 6 * 24:
		b.advance(60.0)
	assert_int(a.mood).is_equal(b.mood)
	assert_float(a.calories).is_equal_approx(b.calories, 0.01)


func test_feeding_every_day_turns_it_hostile_on_the_fifth_feed() -> void:
	var spider := _spider()
	var feeds: int = 0
	while spider.mood != SpiderEcology.Mood.HOSTILE and feeds < 20:
		spider.feed(6)
		feeds += 1
		spider.advance(DAY)
	assert_int(feeds).is_equal(5)


func test_feeding_every_other_day_never_turns_it_hostile() -> void:
	var spider := _spider()
	for i: int in 30:
		spider.feed(6)
		spider.advance(2.0 * DAY)
		assert_int(spider.mood).is_not_equal(SpiderEcology.Mood.HOSTILE)


func test_state_survives_save_and_load() -> void:
	var spider := _spider()
	spider.feed(18)
	spider.advance(DAY)
	var copy := _spider()
	copy.load_state(spider.save_state())
	assert_int(copy.mood).is_equal(spider.mood)
	assert_float(copy.calories).is_equal_approx(spider.calories, 0.0001)
	assert_float(copy.hostile_minutes_left()).is_equal_approx(spider.hostile_minutes_left(), 0.0001)


func test_an_older_save_without_spider_data_starts_friendly() -> void:
	var spider := _spider()
	spider.load_state({})
	assert_int(spider.mood).is_equal(SpiderEcology.Mood.FRIENDLY)
	assert_float(spider.calories).is_equal(0.0)

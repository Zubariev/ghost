## Game clock rules (Demo Specification §6).
extends GdUnitTestSuite

const SIX_AM: int = 6 * 60
const NIGHT: int = 22 * 60


func _clock(start_minute: int = SIX_AM) -> GameClock:
	var speeds: Array[int] = [1, 2, 4]
	return GameClock.new(1.0, SIX_AM, NIGHT, speeds, start_minute)


func test_one_real_second_at_x1_adds_one_minute() -> void:
	var clock := _clock()
	var passed: int = clock.advance(1.0)
	assert_int(passed).is_equal(1)
	assert_int(clock.minute_of_day()).is_equal(SIX_AM + 1)


func test_speed_x4_adds_four_minutes_per_second() -> void:
	var clock := _clock()
	clock.set_speed_index(2)
	clock.advance(1.0)
	assert_int(clock.minute_of_day()).is_equal(SIX_AM + 4)


func test_paused_clock_does_not_advance() -> void:
	var clock := _clock()
	clock.paused = true
	assert_int(clock.advance(10.0)).is_equal(0)
	assert_int(clock.minute_of_day()).is_equal(SIX_AM)


func test_half_seconds_accumulate_to_whole_minutes() -> void:
	var clock := _clock()
	assert_int(clock.advance(0.5)).is_equal(0)
	assert_int(clock.advance(0.5)).is_equal(1)


func test_full_day_takes_1440_seconds_at_x1() -> void:
	var clock := _clock()
	clock.advance(1440.0)
	assert_int(clock.minute_of_day()).is_equal(SIX_AM)
	assert_int(clock.day_number()).is_equal(2)


func test_phase_turns_to_night_at_22_00() -> void:
	var clock := _clock(NIGHT - 1)
	var phases: Array[bool] = []
	clock.phase_changed.connect(func(is_day: bool) -> void: phases.append(is_day))
	assert_bool(clock.is_day()).is_true()
	clock.advance(1.0)
	assert_bool(clock.is_day()).is_false()
	assert_array(phases).contains_exactly([false])


func test_parse_time_reads_hours_and_minutes() -> void:
	assert_int(GameClock.parse_time("06:00")).is_equal(360)
	assert_int(GameClock.parse_time("22:30")).is_equal(1350)
	assert_int(GameClock.parse_time("25:00")).is_equal(-1)
	assert_int(GameClock.parse_time("noon")).is_equal(-1)


func test_format_time_wraps_past_midnight() -> void:
	assert_str(GameClock.format_time(1440 + 75)).is_equal("01:15")

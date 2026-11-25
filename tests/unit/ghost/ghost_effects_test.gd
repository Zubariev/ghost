## Timed effects on the ghost (sprint 001, phase E, 2026-11-26): the speed elixir now, the monocle
## in phase G. An effect runs for its game minutes and ends by itself; taking the same effect again
## restarts its time and never stacks its strength; the speed factor is exactly 1 with nothing
## running, so speed always returns to normal; effects survive save and load.
extends GdUnitTestSuite

var _fx: GhostEffects
var _ended: Array[String] = []


func before_test() -> void:
	_fx = GhostEffects.new()
	_ended = []
	_fx.ended.connect(func(id: String) -> void: _ended.append(id))


func test_nothing_running_means_normal_speed() -> void:
	assert_float(_fx.speed_multiplier()).is_equal(1.0)
	assert_bool(_fx.is_active("speed")).is_false()


func test_a_speed_effect_raises_speed_while_it_runs() -> void:
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	assert_bool(_fx.is_active("speed")).is_true()
	assert_float(_fx.speed_multiplier()).is_equal(1.5)
	_fx.update(59.0)
	assert_float(_fx.remaining("speed")).is_equal_approx(1.0, 0.0001)
	assert_float(_fx.speed_multiplier()).is_equal(1.5)


func test_an_effect_ends_after_its_time_and_speed_is_normal_again() -> void:
	# Arrange
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	# Act
	_fx.update(30.0)
	_fx.update(30.0)
	# Assert
	assert_bool(_fx.is_active("speed")).is_false()
	assert_float(_fx.speed_multiplier()).is_equal(1.0)
	assert_array(_ended).is_equal(["speed"])


func test_taking_it_again_restarts_the_time_and_does_not_stack() -> void:
	# Arrange: half the first dose has run
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	_fx.update(30.0)
	# Act
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	# Assert: full time again, the same strength
	assert_float(_fx.remaining("speed")).is_equal(60.0)
	assert_float(_fx.speed_multiplier()).is_equal(1.5)
	_fx.update(60.0)
	assert_array(_ended).is_equal(["speed"])


func test_a_shorter_new_dose_never_cuts_a_longer_one() -> void:
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	_fx.start("speed", 10.0, {"multiplier": 1.5})
	assert_float(_fx.remaining("speed")).is_equal(60.0)


func test_a_non_positive_duration_starts_nothing() -> void:
	_fx.start("speed", 0.0, {"multiplier": 2.0})
	_fx.start("speed", -5.0, {"multiplier": 2.0})
	assert_bool(_fx.is_active("speed")).is_false()
	assert_float(_fx.speed_multiplier()).is_equal(1.0)


func test_a_slowing_or_missing_multiplier_never_makes_the_ghost_slower_or_stop() -> void:
	_fx.start("speed", 10.0, {"multiplier": 0.0})
	assert_float(_fx.speed_multiplier()).is_equal(1.0)
	_fx.start("other", 10.0, {})
	assert_float(_fx.speed_multiplier()).is_equal(1.0)


func test_no_time_passes_while_the_clock_gives_no_minutes() -> void:
	_fx.start("speed", 10.0, {"multiplier": 1.5})
	_fx.update(0.0)
	assert_float(_fx.remaining("speed")).is_equal(10.0)


func test_running_effects_survive_save_and_load() -> void:
	_fx.start("speed", 60.0, {"multiplier": 1.5})
	_fx.update(20.0)
	var other := GhostEffects.new()
	other.load_state(_fx.save_state())
	assert_float(other.remaining("speed")).is_equal(40.0)
	assert_float(other.speed_multiplier()).is_equal(1.5)

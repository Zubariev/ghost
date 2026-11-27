## Player settings (main menu, 2026-11-15): defaults, a round trip through the config format,
## invalid values falling back, copies being independent. No file I/O (configs in memory).
extends GdUnitTestSuite


func test_a_new_player_gets_a_1280_window_with_both_game_aids_on() -> void:
	var s := GameSettings.defaults()
	assert_bool(s.fullscreen).is_false()
	assert_that(s.window_size).is_equal(Vector2i(1280, 720))
	assert_bool(s.show_help_at_start).is_true()
	assert_bool(s.show_morale_floats).is_true()


func test_settings_survive_the_saved_format_unchanged() -> void:
	# Arrange
	var s := GameSettings.defaults()
	s.fullscreen = true
	s.window_size = Vector2i(1600, 900)
	s.show_help_at_start = false
	s.show_morale_floats = false
	# Act
	var back := GameSettings.from_config(s.to_config())
	# Assert
	assert_bool(back.equals(s)).is_true()
	assert_bool(back.fullscreen).is_true()
	assert_that(back.window_size).is_equal(Vector2i(1600, 900))


func test_an_unknown_window_size_or_missing_value_falls_back_to_the_default() -> void:
	# Arrange: a hand-edited file with a size the menu does not offer and no game section
	var config := ConfigFile.new()
	config.set_value("display", "window_size", Vector2i(333, 222))
	# Act
	var s := GameSettings.from_config(config)
	# Assert
	assert_that(s.window_size).is_equal(Vector2i(1280, 720))
	assert_bool(s.show_help_at_start).is_true()


func test_a_copy_can_be_edited_without_changing_the_original() -> void:
	var s := GameSettings.defaults()
	var copy := s.duplicate_settings()
	copy.fullscreen = true
	assert_bool(s.fullscreen).is_false()
	assert_bool(copy.equals(s)).is_false()


# --- Sprint 002 (P5): "Менше руху" (reduced motion), user decision 2026-11-27 ---

func test_reduced_motion_is_off_by_default_and_survives_the_saved_format() -> void:
	var s := GameSettings.defaults()
	assert_bool(s.reduced_motion).is_false()
	s.reduced_motion = true
	var back := GameSettings.from_config(s.to_config())
	assert_bool(back.reduced_motion).is_true()
	assert_bool(back.equals(s)).is_true()
	assert_bool(GameSettings.defaults().equals(s)).is_false()


func test_a_settings_file_from_before_reduced_motion_loads_with_it_off() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "show_help_at_start", false)
	assert_bool(GameSettings.from_config(config).reduced_motion).is_false()

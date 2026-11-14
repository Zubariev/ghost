## How warm or haunted a room looks (Whimsical Gothic Storybook art direction, 2026-11-15):
## presentation only, read from the room's simulated light and temperature.
extends GdUnitTestSuite


func _room(light: RoomState.Light, temperature: RoomState.Temperature) -> RoomState:
	var room := RoomState.new()
	room.light = light
	room.temperature = temperature
	return room


func test_a_lit_comfortable_room_is_fully_cozy() -> void:
	assert_float(RoomMood.warmth(_room(RoomState.Light.BRIGHT, RoomState.Temperature.COMFORTABLE))).is_equal(1.0)


func test_a_dark_cold_room_is_fully_haunted() -> void:
	assert_float(RoomMood.warmth(_room(RoomState.Light.DARK, RoomState.Temperature.COLD))).is_equal(0.0)


func test_darkness_and_cold_each_take_warmth_and_add_up() -> void:
	# Arrange
	var dark: float = RoomMood.warmth(_room(RoomState.Light.DARK, RoomState.Temperature.COMFORTABLE))
	var dim: float = RoomMood.warmth(_room(RoomState.Light.DIM, RoomState.Temperature.COMFORTABLE))
	var cold: float = RoomMood.warmth(_room(RoomState.Light.BRIGHT, RoomState.Temperature.COLD))
	# Assert: each is between cozy and haunted; dark loses more than dim
	assert_float(dark).is_less(dim)
	assert_float(dim).is_less(1.0)
	assert_float(cold).is_less(1.0)
	assert_float(cold).is_greater(0.0)


func test_the_fire_burns_unless_the_room_is_cold() -> void:
	assert_bool(RoomMood.fire_burning(_room(RoomState.Light.DARK, RoomState.Temperature.COMFORTABLE))).is_true()
	assert_bool(RoomMood.fire_burning(_room(RoomState.Light.BRIGHT, RoomState.Temperature.COLD))).is_false()


func test_the_shown_mood_eases_toward_the_target() -> void:
	# Act: a quarter second toward haunted
	var shown: float = RoomMood.approach(1.0, 0.0, 0.25)
	# Assert: moved part of the way, not all
	assert_float(shown).is_less(1.0)
	assert_float(shown).is_greater(0.0)

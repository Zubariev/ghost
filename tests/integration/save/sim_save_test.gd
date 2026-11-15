## Saving the simulation (2026-11-16, save anywhere): a game saved mid-day and loaded into a
## freshly built simulation continues exactly like the original — the same state minute for
## minute, through ghost harm, repairs, meals, a night and the next dawn. A field the save
## forgets makes the two drift apart and fails this test.
extends GdUnitTestSuite

const SAVE_AT: int = 7 * 60 + 23     # minutes after the 06:00 start: mid-afternoon of day 1
const CONTINUE: int = 20 * 60        # then on past midnight into day 2


## The ghost's harm, at fixed minutes after the start, applied the same way to both games.
func _harm(sim: HouseSim, minute: int) -> void:
	match minute:
		90: sim.house.set_object_state("stove", &"broken")
		200: sim.house.set_object_state("lamp_living_room", &"out")
		420: sim.house.set_object_state("grocery_basket", &"hidden")
		600: sim.house.set_object_state("window_kitchen", &"open")
		900: sim.house.set_object_state("computer", &"broken")


func _run(sim: HouseSim, from: int, to: int) -> void:
	for minute: int in range(from, to):
		_harm(sim, minute)
		sim.advance(1.0)


func test_a_loaded_game_continues_exactly_like_the_original() -> void:
	# Arrange: play the original to the save point and save
	var original := HouseSim.from_data_files()
	original.start()
	_run(original, 0, SAVE_AT)
	var saved: Dictionary = original.save_state()
	var bytes: PackedByteArray = var_to_bytes(saved)   # through the file format
	# Act: load into a fresh game, then run both on with the same harm
	var loaded := HouseSim.from_data_files()
	loaded.start()
	loaded.load_state(bytes_to_var(bytes))
	var same_at_load: bool = var_to_str(loaded.save_state()) == var_to_str(saved)
	var first_difference: int = -1
	for minute: int in range(SAVE_AT, SAVE_AT + CONTINUE):
		_harm(original, minute)
		_harm(loaded, minute)
		original.advance(1.0)
		loaded.advance(1.0)
		if first_difference < 0 and var_to_str(loaded.save_state()) != var_to_str(original.save_state()):
			first_difference = minute
	# Assert
	assert_bool(same_at_load).is_true()
	assert_int(first_difference).override_failure_message("the loaded game drifted at minute %d" % first_difference).is_equal(-1)
	assert_int(original.clock.day_number()).is_equal(2)

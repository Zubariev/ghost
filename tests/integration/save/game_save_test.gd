## Saving the whole game (2026-11-16, save anywhere): the ghost stands in the kitchen where
## grandma cooks, so she notices it, searches and makes contact; the game is saved while an
## incident is running and loaded into a second, freshly started game; both then run on, frame for frame with the same
## ghost, and must stay identical — simulation, family movement, stealth incidents, energy,
## finds and stats. Within day 1 (no dawn autosave is written).
extends GdUnitTestSuite

const GAME_SCENE: String = "res://src/game/house_game.tscn"
const STEP: float = 0.25          # real seconds per frame (a quarter game minute at ×1)
const BEFORE_SAVE: int = 160      # frames before saving (06:00 -> 06:40)
const AFTER_SAVE: int = 480       # frames after (-> 08:40)

var _games: Array[HouseGame] = []


func after_test() -> void:
	for game: HouseGame in _games:
		if is_instance_valid(game):
			game.free()
	_games.clear()
	await get_tree().process_frame


func _start_game() -> HouseGame:
	var game := load(GAME_SCENE).instantiate() as HouseGame
	get_tree().root.add_child(game)
	game.set_process(false)   # the test steps it, without keyboard input
	_games.append(game)
	return game


## One frame of the game with the ghost standing still (what _process does without input).
func _step(game: HouseGame) -> void:
	var minutes: float = game._sim.clock.minutes_for(STEP)
	game._sim.advance(STEP)
	game._motion.update(minutes)
	game._update_energy(minutes)
	game._update_loot(minutes)
	game._stealth.observe()


func _incident_running(game: HouseGame) -> bool:
	for incident: Dictionary in game._stealth._incidents.values():
		if int(incident["phase"]) != StealthSystem.Phase.NONE:
			return true
	return false


func test_a_loaded_game_continues_frame_for_frame_like_the_original() -> void:
	# Arrange: the ghost in the kitchen, a find in its pocket, the monocle taken
	var original: HouseGame = _start_game()
	original._navigator.place("kitchen", Vector2(0.55, 0.55))
	original._loot.inventory["dust"] = 2
	original._has_monocle = true
	# Run until someone is mid-incident (noticing, searching…), so the save holds one
	var frames: int = 0
	while frames < BEFORE_SAVE or (not _incident_running(original) and frames < BEFORE_SAVE * 4):
		_step(original)
		frames += 1
	var incident_at_save: bool = _incident_running(original)
	var saved: Dictionary = original.save_state()
	# Act: load into a fresh game and run both on
	var loaded: HouseGame = _start_game()
	loaded.load_state(bytes_to_var(var_to_bytes(saved)))
	var same_at_load: bool = var_to_str(loaded.save_state()) == var_to_str(saved)
	var first_difference: int = -1
	for frame: int in AFTER_SAVE:
		_step(original)
		_step(loaded)
		if first_difference < 0 and frame % 8 == 0 and var_to_str(loaded.save_state()) != var_to_str(original.save_state()):
			first_difference = frame
	# Assert
	assert_bool(same_at_load).is_true()
	assert_int(first_difference).override_failure_message("the loaded game drifted at frame %d" % first_difference).is_equal(-1)
	assert_str(var_to_str(loaded.save_state())).is_equal(var_to_str(original.save_state()))
	# The scenario really exercised stealth (else the test proves little)
	assert_int(original._stealth.energy_ledger.size()).is_greater(0)
	assert_bool(incident_at_save).override_failure_message("no incident running at the save").is_true()

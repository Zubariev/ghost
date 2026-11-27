## Sprint 002 save round trip (task S2-09, QA plan 2026-11-27): a hostile spider, a half-unlocked
## roots tree (paid from the inventory through the normal unlock rules) and a speed elixir running
## are saved together and loaded into a second, freshly started game. Everything comes back: the
## spider's mood and calories, the owned nodes and their effects (energy maximum, slots), the
## elixir's remaining time, and the whole save is identical.
extends GdUnitTestSuite

const GAME_SCENE: String = "res://src/game/house_game.tscn"
const MATERIALS_EACH: int = 40   # enough of every material to pay for half the tree

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
	game.set_process(false)
	_games.append(game)
	return game


## Unlocks nodes in catalogue order, through the normal rules, until half of them are owned.
func _unlock_half(game: HouseGame) -> int:
	var nodes: Array[Dictionary] = game._progression.nodes()
	var owned: int = 0
	var progress: bool = true
	while progress and owned < nodes.size() / 2:
		progress = false
		for node: Dictionary in nodes:
			var id: String = String(node["id"])
			if owned >= nodes.size() / 2:
				break
			if game._progression.can_unlock(id) and game._progression.unlock(id):
				owned += 1
				progress = true
	return owned


func _owned_ids(game: HouseGame) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in game._progression.nodes():
		if game._progression.state(String(node["id"])) == CraftingProgression.NodeState.OWNED:
			ids.append(String(node["id"]))
	return ids


func test_a_hostile_spider_half_a_roots_tree_and_a_running_elixir_survive_save_and_load() -> void:
	# Arrange
	var original: HouseGame = _start_game()
	original._loot.add("elixir_speed", 1)   # first: ten material stacks below fill every slot
	original._use_item("elixir_speed")
	for item: String in ["dust", "cobweb", "candle_stub", "rusty_nail", "old_thread", "bone", "feather", "ectoplasm", "ink", "fly"]:
		original._loot.inventory[item] = MATERIALS_EACH
	var unlocked: int = _unlock_half(original)
	original._spider_eco.feed(100)   # far past the hostile threshold (capped there)
	var saved: Dictionary = original.save_state()
	# Act
	var loaded: HouseGame = _start_game()
	loaded.load_state(bytes_to_var(var_to_bytes(saved)))
	# Assert: the scenario really set up what it claims
	assert_int(unlocked).override_failure_message("no roots node could be unlocked").is_greater(1)
	assert_int(original._progression.active_effects().size()).override_failure_message("owned nodes give no effects").is_greater(0)
	assert_int(original._spider_eco.mood).is_equal(SpiderEcology.Mood.HOSTILE)
	assert_bool(original._effects.is_active("speed")).override_failure_message("the speed elixir is not running").is_true()
	# ...and it all came back
	assert_int(loaded._spider_eco.mood).is_equal(SpiderEcology.Mood.HOSTILE)
	assert_float(loaded._spider_eco.calories).is_equal_approx(original._spider_eco.calories, 0.001)
	assert_float(loaded._spider_eco.hostile_minutes_left()).is_equal_approx(original._spider_eco.hostile_minutes_left(), 0.001)
	assert_array(_owned_ids(loaded)).is_equal(_owned_ids(original))
	assert_float(loaded._energy.max_value()).is_equal_approx(original._energy.max_value(), 0.001)
	assert_int(loaded._loot.slot_count()).is_equal(original._loot.slot_count())
	assert_bool(loaded._effects.is_active("speed")).is_true()
	assert_float(loaded._effects.remaining("speed")).is_equal_approx(original._effects.remaining("speed"), 0.001)
	assert_str(var_to_str(loaded.save_state())).is_equal(var_to_str(saved))

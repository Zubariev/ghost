## The roots screen (sprint 002, P5, task S2-06; design/ux/roots-progression.md, approved
## 2026-11-27): opens from the hollow with R, selects the first available node, unlocks with one
## press only when affordable, moves focus with arrows and Tab, steps back one level with Esc, E
## or right-click, and honours "Менше руху".
extends GdUnitTestSuite

var _loot: GhostLoot
var _board: CraftingBoard
var _prog: CraftingProgression


func _loot_config() -> Dictionary:
	var items: Dictionary = {}
	for id: String in ["dust", "bone"]:
		items[id] = {"name": "ITEM_" + id, "kind": "material"}
	return {"inventory_slots": 10, "spots": {}, "items": items}


func _board_config() -> Dictionary:
	return {"slots": 5, "start_tier": 0, "upgrades": [{"tier": 1, "cost": {"bone": 2}}], "recipes": []}


func _prog_config() -> Dictionary:
	return {
		"branches": [
			{"id": "trunk", "colour": "amber", "direction": [0, 1]},
			{"id": "rooms", "colour": "gold", "direction": [-1, 0], "coffin": {"x": 120, "y": 480}},
			{"id": "ghost", "colour": "green", "direction": [1, 0]},
		],
		"nodes": [
			{"id": "T0", "branch": "trunk", "parents": [], "tier": 0, "name": "NODE_T0", "layout": {"x": 640, "y": 200}},
			{"id": "T1", "branch": "trunk", "parents": ["T0"], "tier": 1, "name": "NODE_T1", "layout": {"x": 640, "y": 300}},
			{"id": "R1", "branch": "rooms", "parents": ["T1"], "name": "NODE_R1", "cost": {"dust": 3},
				"effects": [{"key": "energy.regen", "op": "mul", "value": 1.5, "room": "hall"}], "layout": {"x": 540, "y": 300}},
			{"id": "G1", "branch": "ghost", "parents": ["T1"], "name": "NODE_G1", "cost": {"dust": 2},
				"effects": [{"key": "energy.max", "op": "add", "value": 20}], "layout": {"x": 740, "y": 300}},
		],
	}


## The game adds its own actions (E = interact, Esc = pause) at start; tests add the ones they
## use and remove them afterwards.
const GAME_ACTIONS: Array[StringName] = [&"interact", &"pause"]
var _added: Array[StringName] = []


func before() -> void:
	for action: StringName in GAME_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			_added.append(action)


func after() -> void:
	for action: StringName in _added:
		InputMap.erase_action(action)
	_added.clear()


func _screen(reduced_motion: bool = true) -> RootsScreen:
	_loot = GhostLoot.new(_loot_config())
	_board = CraftingBoard.new(_board_config(), _loot)
	_prog = CraftingProgression.new(_prog_config(), _board, _loot)
	var screen: RootsScreen = auto_free(RootsScreen.new())
	add_child(screen)
	screen.open(_prog, _loot, reduced_motion)
	return screen


func _action(name: StringName) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = name
	e.pressed = true
	return e


func test_opening_selects_the_first_available_node() -> void:
	var screen := _screen()
	assert_bool(screen.is_open()).is_true()
	assert_str(screen.selected()).is_equal("T1")


func test_unlock_is_disabled_and_pays_nothing_when_short() -> void:
	var screen := _screen()
	_loot.add("bone", 1)
	assert_bool(screen.unlock_enabled()).is_false()
	assert_bool(screen.unlock_selected()).is_false()
	assert_int(_loot.count("bone")).is_equal(1)


func test_one_press_unlocks_an_affordable_node_and_says_so() -> void:
	var screen := _screen()
	var said: Array[String] = []
	screen.message.connect(func(text: String) -> void: said.append(text))
	_loot.add("bone", 2)
	assert_bool(screen.unlock_enabled()).is_true()
	screen._unhandled_input(_action(&"ui_accept"))
	assert_int(_prog.state("T1")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_int(_loot.count("bone")).is_equal(0)
	assert_int(said.size()).is_equal(1)


func test_arrows_and_tab_move_the_selection() -> void:
	var screen := _screen()
	screen._unhandled_input(_action(&"ui_left"))
	assert_str(screen.selected()).is_equal("R1")
	screen._unhandled_input(_action(&"ui_focus_next"))
	assert_str(screen.selected()).is_equal("G1")
	screen._unhandled_input(_action(&"ui_left"))
	assert_str(screen.selected()).is_equal("T1")
	screen._unhandled_input(_action(&"ui_up"))
	assert_str(screen.selected()).is_equal("T0")


func test_esc_e_and_right_click_each_step_back_once() -> void:
	for event: InputEvent in [_action(&"ui_cancel"), _action(&"interact"), _right_click()]:
		var screen := _screen()
		var closed: Array[int] = [0]
		screen.closed.connect(func() -> void: closed[0] += 1)
		screen._unhandled_input(event)
		assert_bool(screen.is_open()).is_false()
		assert_int(closed[0]).is_equal(1)


func test_with_reduced_motion_nothing_animates() -> void:
	var screen := _screen(true)
	assert_bool(screen.is_animating()).is_false()
	_loot.add("bone", 2)
	screen.unlock_selected()
	assert_bool(screen.is_animating()).is_false()


func test_with_motion_opening_slides_in() -> void:
	var screen := _screen(false)
	assert_bool(screen.is_animating()).is_true()


func test_r_in_the_hollow_opens_the_roots_and_esc_returns_to_the_hollow() -> void:
	# Arrange
	_loot = GhostLoot.new(_loot_config())
	_board = CraftingBoard.new(_board_config(), _loot)
	_prog = CraftingProgression.new(_prog_config(), _board, _loot)
	var hollow: CraftingScreen = auto_free(CraftingScreen.new())
	add_child(hollow)
	hollow.reduced_motion = true
	hollow.open(_board, _loot, _prog)
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R   # the R key wherever it is on the layout
	r.pressed = true
	# Act / Assert
	hollow._unhandled_input(r)
	assert_bool(hollow.roots_open()).is_true()
	hollow.roots_screen()._unhandled_input(_action(&"ui_cancel"))
	assert_bool(hollow.roots_open()).is_false()
	assert_bool(hollow.is_open()).is_true()   # one level back: the hollow stays
	hollow._unhandled_input(_action(&"ui_cancel"))
	assert_bool(hollow.is_open()).is_false()   # Esc in the hollow closes it as before


func test_while_the_roots_are_open_the_hollow_ignores_its_keys() -> void:
	_loot = GhostLoot.new(_loot_config())
	_board = CraftingBoard.new(_board_config(), _loot)
	_prog = CraftingProgression.new(_prog_config(), _board, _loot)
	var hollow: CraftingScreen = auto_free(CraftingScreen.new())
	add_child(hollow)
	hollow.reduced_motion = true
	hollow.open(_board, _loot, _prog)
	hollow.open_roots()
	hollow._unhandled_input(_action(&"ui_cancel"))
	assert_bool(hollow.is_open()).is_true()
	assert_bool(hollow.roots_open()).is_true()


func _right_click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_RIGHT
	e.pressed = true
	return e


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e


func test_after_the_mouse_hovers_a_plaque_tab_and_arrows_still_move_the_selection() -> void:
	# through the viewport, as real keys arrive: a hovered plaque that took keyboard focus made
	# Godot spend Tab and the arrow toward the other plaque on button focus (code review 2026-11-27)
	for idx: int in 2:
		for step: Array in [[KEY_TAB, "R1"], [KEY_UP, "T0"], [KEY_RIGHT, "G1"]]:
			var screen := _screen()
			await get_tree().process_frame
			var plaque := screen.find_children("*", "Button", true, false)[idx] as Button
			plaque.mouse_entered.emit()   # the hover
			get_viewport().push_input(_key(step[0]))
			await get_tree().process_frame
			assert_str(screen.selected()).override_failure_message("plaque %d hovered, %s: selection %s, expected %s"
				% [idx, OS.get_keycode_string(step[0]), screen.selected(), step[1]]).is_equal(String(step[1]))
			remove_child(screen)
			screen.free()


func test_leaving_the_soil_un_hovers_the_node() -> void:
	# a node hovered near the bottom of the soil stayed enlarged when the mouse moved onto the panel
	var screen := _screen()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(640, 300)   # on T1 in the fixture layout
	screen._on_canvas_input(motion)
	assert_str(screen._hover).is_equal("T1")
	screen._canvas.mouse_exited.emit()
	assert_str(screen._hover).is_empty()


func test_a_hovered_hollow_plaque_does_not_take_the_keys_of_the_roots_screen() -> void:
	# the hollow underneath kept keyboard focus on a hovered plaque: Godot's focus navigation then
	# spent Tab and arrows there before the roots screen saw them (code re-review 2026-11-27)
	_loot = GhostLoot.new(_loot_config())
	_board = CraftingBoard.new(_board_config(), _loot)
	_prog = CraftingProgression.new(_prog_config(), _board, _loot)
	var hollow: CraftingScreen = auto_free(CraftingScreen.new())
	add_child(hollow)
	hollow.reduced_motion = true
	hollow.open(_board, _loot, _prog)
	await get_tree().process_frame
	var hovered: bool = false
	for node: Node in hollow.find_children("*", "Button", true, false):
		var plaque := node as Button
		if plaque.focus_mode != Control.FOCUS_NONE and not plaque.disabled and plaque.is_visible_in_tree():
			plaque.mouse_entered.emit()   # the hover takes keyboard focus in the hollow
			hovered = true
			break
	hollow.open_roots()
	await get_tree().process_frame
	get_viewport().push_input(_key(KEY_TAB))
	await get_tree().process_frame
	assert_bool(hovered).override_failure_message("no hollow plaque to hover").is_true()
	assert_str(hollow.roots_screen().selected()).is_equal("R1")

## The main menu (2026-11-15): five entries in order, the first focused; a sub-screen opens
## over the menu with its own focus and closes with Esc, giving the focus back; the menu's
## plaques cannot take focus while a sub-screen is open.
extends GdUnitTestSuite

const MENU_SCENE: String = "res://src/game/menu/main_menu.tscn"

var _menu: MainMenu


func before_test() -> void:
	MainMenu._settings_applied = true   # never resize the test window from saved settings
	MainMenu.save_dir = "user://test_no_saves_here"   # never the player's own saves
	_menu = load(MENU_SCENE).instantiate() as MainMenu
	get_tree().root.add_child(_menu)
	await get_tree().process_frame


func after_test() -> void:
	MainMenu.save_dir = SaveStore.DIR
	if is_instance_valid(_menu):
		_menu.free()
	await get_tree().process_frame   # let closed panels finish freeing


func test_the_five_entries_are_in_order_and_the_first_has_focus() -> void:
	var texts: Array = _menu._buttons.map(func(b: Button) -> String: return b.text)
	assert_array(texts).is_equal([tr("MENU_NEW_GAME"), tr("MENU_LOAD"), tr("MENU_SETTINGS"), tr("MENU_CREDITS"), tr("MENU_EXIT")])
	assert_bool(_menu._buttons[0].has_focus()).is_true()


func test_a_sub_screen_takes_the_focus_and_esc_closes_it_and_gives_the_focus_back() -> void:
	# Act: open Credits from its plaque
	_menu._buttons[3].pressed.emit()
	await get_tree().process_frame
	var open: bool = _menu._panel != null and _menu._overlay.visible
	var plaques_blocked: bool = _menu._buttons.all(func(b: Button) -> bool: return b.focus_mode == Control.FOCUS_NONE)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	_menu._unhandled_input(esc)
	await get_tree().process_frame
	# Assert
	assert_bool(open).is_true()
	assert_bool(plaques_blocked).is_true()
	assert_object(_menu._panel).is_null()
	assert_bool(_menu._overlay.visible).is_false()
	assert_bool(_menu._buttons[3].has_focus()).is_true()


func test_load_game_shows_the_empty_state_without_a_save_system() -> void:
	_menu._buttons[1].pressed.emit()
	await get_tree().process_frame
	var texts: Array = _menu._panel.body.get_children().map(func(n: Node) -> String: return (n as Label).text if n is Label else "")
	assert_array(texts).contains([tr("LOAD_EMPTY")])


func test_every_sub_screen_fits_on_the_screen() -> void:
	# Regression (2026-11-15 capture): wrapped text with no width made Settings, Load and Credits
	# taller than the screen, their text pushed off it.
	for index: int in [1, 2, 3, 4]:
		_menu._buttons[index].pressed.emit()
		await get_tree().process_frame
		var rect: Rect2 = _menu._panel.get_rect()
		assert_bool(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(rect)).override_failure_message(
			"%s panel %s does not fit" % [_menu._buttons[index].text, rect]).is_true()
		_menu._close_panel()
		await get_tree().process_frame


func test_the_load_screen_lists_saves_and_delete_asks_then_removes() -> void:
	# Arrange: one save in the test folder
	var store := SaveStore.new(MainMenu.save_dir)
	var path: String = store.save({"x": 1}, {"day": 2, "time": "14:30", "room": "Кухня", "resolve": 42})
	# Act: open Load, then Delete on the row, then Yes
	_menu._buttons[1].pressed.emit()
	await get_tree().process_frame
	var plaques: Array[Node] = _menu._panel.body.find_children("*", "PlaqueButton", true, false)
	var listed: bool = plaques.size() == 2   # Load and Delete for the one save
	(plaques[1] as Button).pressed.emit()
	await get_tree().process_frame
	var asked: bool = _menu._panel.buttons.get_child_count() == 2   # Yes / No
	(_menu._panel.buttons.get_child(0) as Button).pressed.emit()
	await get_tree().process_frame
	# Assert
	assert_bool(listed).is_true()
	assert_bool(asked).is_true()
	assert_bool(FileAccess.file_exists(path)).is_false()
	assert_bool(store.has_any()).is_false()

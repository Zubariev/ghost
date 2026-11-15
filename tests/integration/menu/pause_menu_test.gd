## The in-game pause menu (2026-11-15): opens with the focus on Resume; Settings and the
## main-menu question open over it; Esc steps back out of a sub-screen first, then closes the
## menu and reports that the game resumes.
extends GdUnitTestSuite

var _menu: PauseMenu
var _resumed: int = 0


func before_test() -> void:
	_resumed = 0
	_menu = PauseMenu.new()
	get_tree().root.add_child(_menu)
	_menu.resumed.connect(func() -> void: _resumed += 1)
	await get_tree().process_frame


func after_test() -> void:
	if is_instance_valid(_menu):
		_menu.free()
	await get_tree().process_frame


func _esc() -> void:
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	_menu._unhandled_input(esc)
	await get_tree().process_frame


func test_opening_focuses_resume_and_resume_closes_and_resumes() -> void:
	_menu.open()
	await get_tree().process_frame
	var focused: bool = _menu._resume.has_focus()
	_menu._resume.pressed.emit()
	await get_tree().process_frame
	assert_bool(focused).is_true()
	assert_bool(_menu.is_open()).is_false()
	assert_int(_resumed).is_equal(1)


func test_esc_leaves_settings_first_then_closes_the_menu() -> void:
	# Arrange: open the menu, then Settings from it
	_menu.open()
	await get_tree().process_frame
	(_menu._main.body.get_child(1) as Button).pressed.emit()
	await get_tree().process_frame
	var in_settings: bool = _menu._sub is SettingsPanel and not _menu._main.visible
	# Act / Assert: the first Esc returns to the pause menu, the second resumes the game
	await _esc()
	var back_in_menu: bool = _menu.is_open() and _menu._sub == null and _menu._main.visible
	await _esc()
	assert_bool(in_settings).is_true()
	assert_bool(back_in_menu).is_true()
	assert_bool(_menu.is_open()).is_false()
	assert_int(_resumed).is_equal(1)

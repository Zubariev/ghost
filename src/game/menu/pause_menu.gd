## The in-game pause menu (2026-11-15): Esc pauses the game and opens it over a dimmed room —
## Продовжити (resume), Зберегти гру (a new entry in the save list, 2026-11-16), Налаштування (the shared [SettingsPanel]), Головне меню (asks first: the
## game is not saved; saving is the next task). Esc closes a sub-screen, or the menu itself
## (resuming). Built from the main menu's pieces ([MenuPanel], [PlaqueButton]). It only shows
## and reports; the game pauses and resumes the clock.
class_name PauseMenu
extends CanvasLayer

## The menu closed; the game resumes.
signal resumed()
## The player applied new settings in the pause menu's Settings.
signal settings_applied(settings: GameSettings)
## The player asked to save; the game saves and answers with [method show_saved].
signal save_requested()

const MENU_SCENE: String = "res://src/game/menu/main_menu.tscn"

var _overlay: ColorRect
var _main: MenuPanel
var _sub: MenuPanel
var _sub_opener: Button
var _resume: Button
var _status: Label


func _ready() -> void:
	layer = 5
	visible = false
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.015, 0.01, 0.6)
	_overlay.size = Vector2(1280, 720)
	add_child(_overlay)


## True while the menu is shown.
func is_open() -> bool:
	return visible


## Shows the menu with the focus on Resume.
func open() -> void:
	if visible:
		return
	visible = true
	_main = MenuPanel.create(tr("PAUSE_TITLE"), Vector2(420, 0))
	_main.body.alignment = BoxContainer.ALIGNMENT_CENTER
	_resume = _plaque(tr("PAUSE_RESUME"), close)
	_plaque(tr("PAUSE_SAVE"), func() -> void: save_requested.emit())
	var settings: Button = _plaque(tr("MENU_SETTINGS"), Callable())
	settings.pressed.connect(func() -> void: _open_settings(settings))
	var to_menu: Button = _plaque(tr("PAUSE_MAIN_MENU"), Callable())
	to_menu.pressed.connect(func() -> void: _confirm_main_menu(to_menu))
	_status = _main.add_text("", 15, Palette.SB_CANDLELIGHT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_show(_main)
	_resume.grab_focus()


## Tells the player whether the save worked.
func show_saved(ok: bool) -> void:
	if _status != null:
		_status.text = tr("PAUSE_SAVED") if ok else tr("PAUSE_SAVE_FAILED")


## Closes the menu (and any sub-screen) and resumes the game.
func close() -> void:
	if not visible:
		return
	for panel: MenuPanel in [_sub, _main]:
		if panel != null:
			panel.queue_free()
	_sub = null
	_main = null
	visible = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if _sub != null:
			_close_sub()
		else:
			close()


func _plaque(text: String, action: Callable) -> Button:
	var button := PlaqueButton.create(text, 300.0, 23)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if action.is_valid():
		button.pressed.connect(action)
	_main.body.add_child(button)
	return button


func _open_settings(from: Button) -> void:
	var panel := SettingsPanel.open()
	panel.closed.connect(_close_sub)
	panel.applied.connect(func(settings: GameSettings) -> void: settings_applied.emit(settings))
	_open_sub(panel, from, panel.first_focus())


func _confirm_main_menu(from: Button) -> void:
	var panel := MenuPanel.create(tr("PAUSE_MAIN_MENU"), Vector2(520, 0))
	panel.add_text(tr("PAUSE_QUIT_CONFIRM"), 18, Palette.SB_CREAM, "story").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_button(PlaqueButton.create(tr("EXIT_YES"), 180.0, 22)).pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MENU_SCENE))
	var no: Button = panel.add_button(PlaqueButton.create(tr("EXIT_NO"), 180.0, 22))
	no.pressed.connect(_close_sub)
	_open_sub(panel, from, no)


func _open_sub(panel: MenuPanel, from: Button, focus: Control) -> void:
	_sub = panel
	_sub_opener = from
	_main.visible = false
	_show(panel)
	focus.grab_focus()


func _close_sub() -> void:
	if _sub == null:
		return
	_sub.queue_free()
	_sub = null
	_main.visible = true
	if _sub_opener != null:
		_sub_opener.grab_focus()


func _show(panel: MenuPanel) -> void:
	add_child(panel)
	panel.reset_size()
	panel.position = (Vector2(1280, 720) - panel.size) * 0.5

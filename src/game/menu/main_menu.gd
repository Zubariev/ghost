## The main menu (2026-11-15; the user's concept `art/references/Примарний маєток_ Привид проти
## людей.png` as the visual and compositional reference — not used as an image): the illustrated
## room behind ([MenuBackdrop]), the title top left with a small ghost, and five plaque buttons
## ([PlaqueButton]): New Game · Load Game · Settings · Credits · Exit. Sub-screens are
## [MenuPanel]s over a dimmed room; Esc closes them and returns focus to the button that opened
## them. Keyboard: arrows move, Enter / Space activate; the mouse moves the focus too.
##
## [br]- New Game: the existing briefing screen (`title_screen.tscn`: premise, family, controls),
##   then the game, as before. No save system exists, so nothing can be overwritten and no
##   confirmation is needed yet.
## [br]- Load Game: the save-selection screen, showing its empty state (no save system yet).
## [br]- Settings: [SettingsPanel] (shared with the pause menu).
## [br]- Credits; Exit asks first, then quits.
## Settings are applied once at launch. [code]--capture=<dir>[/code] saves the screens and quits
## (verification only).
class_name MainMenu
extends Control

const BRIEFING_SCENE: String = "res://src/game/title/title_screen.tscn"
const STRINGS_PATH: String = "res://assets/i18n/strings.csv"
const LOCALE: String = "uk"
## Captures show the background at a moment the ghost is in the window.
const CAPTURE_MOMENT: float = MenuBackdrop.GHOST_EVERY - MenuBackdrop.GHOST_SECONDS * 0.5

## Display settings are applied once per launch (not again when returning from a game).
static var _settings_applied: bool = false

var _buttons: Array[PlaqueButton] = []
var _overlay: ColorRect
var _panel: MenuPanel
var _panel_opener: Button
var _backdrop: MenuBackdrop
var _title_ghost: Control
var _time: float = 0.0


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	Localization.load_csv(STRINGS_PATH, LOCALE)
	UiFonts.apply()
	size = Vector2(1280, 720)
	var capture_dir: String = _capture_dir()
	if not _settings_applied and capture_dir.is_empty():
		GameSettings.load_saved().apply_display(get_window())
	_settings_applied = true
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	_build_title()
	_build_buttons()
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.015, 0.01, 0.55)
	_overlay.size = size
	_overlay.visible = false
	add_child(_overlay)
	_buttons[0].grab_focus()
	if not capture_dir.is_empty():
		_capture(capture_dir)


func _process(delta: float) -> void:
	_time += delta
	_title_ghost.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _panel != null:
		_close_panel()
		get_viewport().set_input_as_handled()


func _build_title() -> void:
	var block := VBoxContainer.new()
	block.position = Vector2(92, 54)
	block.add_theme_constant_override(&"separation", -14)
	add_child(block)
	var lines: Array = [["MENU_TITLE_1", 72, Palette.SB_CREAM, 0], ["MENU_TITLE_2", 34, Palette.SB_CANDLELIGHT, 120], ["MENU_TITLE_3", 72, Palette.SB_CREAM, 40]]
	for line: Array in lines:
		var label := Label.new()
		label.text = tr(String(line[0]))
		label.add_theme_font_size_override(&"font_size", int(line[1]))
		label.add_theme_color_override(&"font_color", line[2])
		label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.6))
		label.add_theme_constant_override(&"shadow_offset_y", 3)
		UiFonts.use(label, "title")
		var row := MarginContainer.new()
		row.add_theme_constant_override(&"margin_left", int(line[3]))
		row.add_child(label)
		block.add_child(row)
	# The small ghost beside the title, gently bobbing, and a gold flourish.
	_title_ghost = Control.new()
	_title_ghost.position = Vector2(0, 0)
	_title_ghost.size = Vector2(640, 300)
	_title_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_ghost.draw.connect(func() -> void:
		FamilyArt.draw_ghost(_title_ghost, Vector2(432, 104), 0.7, _time, false)
		var gold := Color(Palette.SB_GOLD, 0.75)
		_title_ghost.draw_arc(Vector2(70, 150), 22, PI * 0.2, PI * 1.6, 18, gold, 2.0, true)
		_title_ghost.draw_arc(Vector2(52, 172), 10, PI * 1.2, PI * 2.6, 12, gold, 2.0, true)
		_title_ghost.draw_arc(Vector2(470, 156), 20, PI * 1.2, PI * 2.4, 18, gold, 2.0, true))
	add_child(_title_ghost)


func _build_buttons() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(110, 330)
	column.add_theme_constant_override(&"separation", 12)
	add_child(column)
	var entries: Array = [["MENU_NEW_GAME", _new_game], ["MENU_LOAD", _open_load], ["MENU_SETTINGS", _open_settings],
		["MENU_CREDITS", _open_credits], ["MENU_EXIT", _open_exit]]
	for entry: Array in entries:
		var button := PlaqueButton.create(tr(String(entry[0])), 300.0)
		var action: Callable = entry[1]
		button.pressed.connect(func() -> void: action.call(button))
		column.add_child(button)
		_buttons.append(button)
	column.add_child(MenuPanel.divider(220.0))


# --- Entries -------------------------------------------------------------------------

func _new_game(_from: Button) -> void:
	get_tree().change_scene_to_file(BRIEFING_SCENE)


func _open_load(from: Button) -> void:
	var panel := MenuPanel.create(tr("LOAD_TITLE"), Vector2(600, 0))
	panel.add_text(tr("LOAD_EMPTY"), 20, Palette.SB_CREAM, "story").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_text(tr("LOAD_EMPTY_NOTE"), 15, Color(Palette.SB_CREAM, 0.65)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_button(PlaqueButton.create(tr("MENU_BACK"), 220.0, 22)).pressed.connect(_close_panel)
	_open_panel(panel, from)


func _open_settings(from: Button) -> void:
	var panel := SettingsPanel.open()
	panel.closed.connect(_close_panel)
	_open_panel(panel, from, panel.first_focus())


func _open_credits(from: Button) -> void:
	var panel := MenuPanel.create(tr("CREDITS_TITLE"), Vector2(660, 0))
	panel.add_text(tr("GAME_TITLE"), 24, Palette.SB_CANDLELIGHT, "story").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for key: String in ["CREDITS_DEVELOPMENT", "CREDITS_ART", "CREDITS_AUDIO", "CREDITS_FONTS", "CREDITS_ENGINE"]:
		panel.add_text(tr(key), 15)
	panel.add_button(PlaqueButton.create(tr("MENU_BACK"), 220.0, 22)).pressed.connect(_close_panel)
	_open_panel(panel, from)


func _open_exit(from: Button) -> void:
	var panel := MenuPanel.create(tr("EXIT_CONFIRM"), Vector2(480, 0))
	panel.add_button(PlaqueButton.create(tr("EXIT_YES"), 180.0, 22)).pressed.connect(func() -> void: get_tree().quit())
	var no: Button = panel.add_button(PlaqueButton.create(tr("EXIT_NO"), 180.0, 22))
	no.pressed.connect(_close_panel)
	_open_panel(panel, from, no)


# --- Panels ----------------------------------------------------------------------------

## Shows [param panel] centred over the dimmed room; [param focus] (default: its first button)
## gets the keyboard focus; [param from] gets it back when the panel closes.
func _open_panel(panel: MenuPanel, from: Button, focus: Control = null) -> void:
	_close_panel()
	_panel = panel
	_panel_opener = from
	_overlay.visible = true
	add_child(panel)
	for button: PlaqueButton in _buttons:
		button.focus_mode = Control.FOCUS_NONE
	panel.reset_size()
	panel.position = (size - panel.size) * 0.5
	var first: Control = focus if focus != null else (panel.buttons.get_child(0) as Control)
	first.grab_focus()


func _close_panel() -> void:
	if _panel == null:
		return
	_panel.queue_free()
	_panel = null
	_overlay.visible = false
	for button: PlaqueButton in _buttons:
		button.focus_mode = Control.FOCUS_ALL
	if _panel_opener != null:
		_panel_opener.grab_focus()


# --- Capture (verification only) -----------------------------------------------------------

func _capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	set_process(false)
	_backdrop.set_process(false)
	_backdrop.set_time(CAPTURE_MOMENT)
	_time = 1.0
	await _shot(dir, "40-main-menu")
	_buttons[2].grab_focus()   # keyboard focus moved down to Settings
	await _shot(dir, "41-main-menu-focus-settings")
	_open_settings(_buttons[2])
	await _shot(dir, "42-settings")
	_close_panel()
	_open_load(_buttons[1])
	await _shot(dir, "43-load-empty")
	_close_panel()
	_open_credits(_buttons[3])
	await _shot(dir, "44-credits")
	_close_panel()
	_open_exit(_buttons[4])
	await _shot(dir, "45-exit-confirm")
	get_tree().quit()


func _shot(dir: String, shot_name: String) -> void:
	_title_ghost.queue_redraw()
	for i: int in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
	print("captured ", shot_name)


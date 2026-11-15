## The Settings screen (2026-11-15), shared by the main menu and the pause menu: display mode,
## window size, the controls help at the start of a game, morale changes above people. It edits
## a copy of the saved [GameSettings]; Apply saves, applies the display settings and emits
## [signal applied]; Restore defaults fills in the defaults (applied only by Apply); Back
## discards. Emits [signal closed] after Apply or Back.
class_name SettingsPanel
extends MenuPanel

## The settings were saved and the display ones applied; listeners apply the rest.
signal applied(settings: GameSettings)
## Apply or Back was pressed; the owner closes the panel.
signal closed()

var _editing: GameSettings
var _mode_choice: OptionButton
var _size_choice: OptionButton
var _help_box: CheckBox
var _floats_box: CheckBox


## A settings screen showing the saved settings.
static func open() -> SettingsPanel:
	var panel := SettingsPanel.new()
	panel.custom_minimum_size = Vector2(680, 0)
	panel.content_width = 628.0
	panel._build(TranslationServer.translate("SETTINGS_TITLE"))
	panel._build_settings()
	return panel


## The control that should take the keyboard focus first.
func first_focus() -> Control:
	return _mode_choice


func _build_settings() -> void:
	_editing = GameSettings.load_saved()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 24)
	grid.add_theme_constant_override(&"v_separation", 12)
	body.add_child(grid)
	_mode_choice = _choice(grid, tr("SET_DISPLAY_MODE"), [tr("SET_WINDOWED"), tr("SET_FULLSCREEN")])
	var sizes: Array = []
	for s: Vector2i in GameSettings.WINDOW_SIZES:
		sizes.append("%d × %d" % [s.x, s.y])
	_size_choice = _choice(grid, tr("SET_WINDOW_SIZE"), sizes)
	_mode_choice.item_selected.connect(func(index: int) -> void:
		_editing.fullscreen = index == 1
		_size_choice.disabled = _editing.fullscreen)
	_size_choice.item_selected.connect(func(index: int) -> void: _editing.window_size = GameSettings.WINDOW_SIZES[index])
	_help_box = _check(tr("SET_HELP_AT_START"))
	_help_box.toggled.connect(func(on: bool) -> void: _editing.show_help_at_start = on)
	_floats_box = _check(tr("SET_MORALE_FLOATS"))
	_floats_box.toggled.connect(func(on: bool) -> void: _editing.show_morale_floats = on)
	add_text(tr("SET_AUDIO_LATER"), 14, Color(Palette.SB_CREAM, 0.55))
	add_button(PlaqueButton.create(tr("SET_APPLY"), 200.0, 21)).pressed.connect(func() -> void:
		_editing.save()
		_editing.apply_display(get_window())
		applied.emit(_editing)
		closed.emit())
	add_button(PlaqueButton.create(tr("SET_DEFAULTS"), 240.0, 21)).pressed.connect(func() -> void:
		_editing = GameSettings.defaults()
		_show())
	add_button(PlaqueButton.create(tr("MENU_BACK"), 170.0, 21)).pressed.connect(func() -> void: closed.emit())
	_show()


## Shows the edited settings in the controls.
func _show() -> void:
	_mode_choice.select(1 if _editing.fullscreen else 0)
	_size_choice.select(maxi(0, GameSettings.WINDOW_SIZES.find(_editing.window_size)))
	_size_choice.disabled = _editing.fullscreen
	_help_box.set_pressed_no_signal(_editing.show_help_at_start)
	_floats_box.set_pressed_no_signal(_editing.show_morale_floats)


func _choice(grid: GridContainer, caption: String, items: Array) -> OptionButton:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override(&"font_size", 18)
	label.add_theme_color_override(&"font_color", Palette.SB_CREAM)
	grid.add_child(label)
	var choice := OptionButton.new()
	for item: Variant in items:
		choice.add_item(String(item))
	choice.add_theme_font_size_override(&"font_size", 18)
	choice.custom_minimum_size = Vector2(240, 36)
	grid.add_child(choice)
	return choice


func _check(caption: String) -> CheckBox:
	var box := CheckBox.new()
	box.text = caption
	box.add_theme_font_size_override(&"font_size", 17)
	box.add_theme_color_override(&"font_color", Palette.SB_CREAM)
	box.add_theme_color_override(&"font_hover_color", Palette.SB_CANDLELIGHT)
	box.add_theme_color_override(&"font_focus_color", Palette.SB_CANDLELIGHT)
	box.add_theme_color_override(&"font_pressed_color", Palette.SB_CREAM)
	body.add_child(box)
	return box

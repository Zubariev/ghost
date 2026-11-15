## The start screen (stage 6, Demo Spec §10.4; §10.1 phase 1 "introduction"): the title, the
## premise and goal, the six family members with their role and one trait, the controls and
## Start (button or Enter). Goal numbers come from morale.json; names from the schedules.
## [code]--capture=<dir>[/code] saves 00-title.png there and quits (verification only).
class_name TitleScreen
extends Control

const GAME_SCENE: String = "res://src/game/house_game.tscn"
const STRINGS_PATH: String = "res://assets/i18n/strings.csv"
const LOCALE: String = "uk"


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	Localization.load_csv(STRINGS_PATH, LOCALE)
	UiFonts.apply()
	size = Vector2(1280, 720)
	var background := ColorRect.new()
	background.color = Palette.SB_CHARCOAL.darkened(0.45)
	background.size = size
	add_child(background)
	var page := VBoxContainer.new()
	page.position = Vector2(140, 44)
	page.custom_minimum_size = Vector2(1000, 0)
	page.add_theme_constant_override(&"separation", 10)
	add_child(page)
	var rules: Dictionary = JsonData.read(HouseSim.MORALE_PATH)
	UiFonts.use(_text(page, tr("GAME_TITLE"), 46, Palette.SB_GHOST), "title")
	UiFonts.use(_text(page, tr("TITLE_PREMISE"), 19, Palette.SB_CREAM), "story")
	UiFonts.use(_text(page, tr("TITLE_GOAL") % [int(rules.get("family_leaves_at_average", 20)), int(rules.get("scenario_days", 3))], 19, Palette.SB_CANDLELIGHT), "story")
	page.add_child(_gap(6))
	UiFonts.use(_text(page, tr("TITLE_FAMILY"), 22, Palette.SB_PARCHMENT), "title")
	var family := GridContainer.new()
	family.columns = 2
	family.add_theme_constant_override(&"h_separation", 18)
	family.add_theme_constant_override(&"v_separation", 6)
	page.add_child(family)
	for path: String in HouseSim.SCHEDULE_PATHS:
		var schedule: Dictionary = JsonData.read(path)
		var npc_id: String = String(schedule.get("npc_id", ""))
		_text(family, String(schedule.get("name", npc_id)), 17, GameHud.NPC_COLORS.get(npc_id, Color.WHITE)).custom_minimum_size = Vector2(110, 0)
		UiFonts.use(_text(family, tr("INTRO_" + npc_id), 17, Palette.SB_CREAM), "story")
	page.add_child(_gap(6))
	UiFonts.use(_text(page, tr("TITLE_CONTROLS"), 22, Palette.SB_PARCHMENT), "title")
	_text(page, tr("HELP_LINE"), 15, Color(Palette.SB_CREAM, 0.85))
	page.add_child(_gap(10))
	var start := Button.new()
	start.text = tr("TITLE_START")
	start.add_theme_font_size_override(&"font_size", 22)
	start.custom_minimum_size = Vector2(220, 48)
	start.pressed.connect(_start)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 18)
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(start)
	var hint := _text(row, tr("TITLE_START_HINT"), 14, Color(1, 1, 1, 0.55))
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page.add_child(row)
	start.grab_focus()
	var capture_dir: String = _capture_dir()
	if not capture_dir.is_empty():
		_capture(capture_dir)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		_start()


func _start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _text(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if parent is VBoxContainer:
		label.custom_minimum_size = Vector2(1000, 0)
	elif parent is GridContainer:
		label.custom_minimum_size = Vector2(860, 0)
	parent.add_child(label)
	return label


func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	return gap


func _capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for i: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("00-title.png"))
	print("captured 00-title")
	get_tree().quit()

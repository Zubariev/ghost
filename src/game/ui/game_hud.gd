## The in-game HUD (stage 5a): clock and speed, each family member's morale, the ghost's
## prompt, a short event log, a house overview map, and the end-of-scenario banner.
## All text goes through tr() (assets/i18n/strings.csv). Reads the simulation; never changes it.
class_name GameHud
extends CanvasLayer

const LOG_LINES: int = 3
const NPC_COLORS: Dictionary = {
	"father": Color("6fa8dc"), "mother": Color("93c47d"), "grandma": Color("c27ba0"),
	"grandpa": Color("d5a66a"), "son": Color("e06666"), "daughter": Color("f1c232"),
}

var _sim: HouseSim
var _navigator: GhostNavigator
var _clock: Label
var _room: Label
var _paused: Label
var _prompt: Label
var _log: Label
var _log_lines: Array[String] = []
var _chips: Dictionary[String, Label] = {}
var _map: Control
var _banner: PanelContainer
var _banner_text: Label


func setup(sim: HouseSim, navigator: GhostNavigator) -> void:
	_sim = sim
	_navigator = navigator
	var top := _panel(Vector2(14, 10), Vector2(250, 0))
	_clock = _label(top, 24, Color(1, 0.95, 0.85))
	_room = _label(top, 16, Color(0.85, 0.85, 0.9))
	var help := _label(self, 14, Color(1, 1, 1, 0.7))
	help.text = tr("HELP_LINE")
	help.position = Vector2(300, 14)
	help.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	help.add_theme_constant_override(&"outline_size", 4)
	_paused = _label(self, 40, Color(1, 0.85, 0.5))
	_paused.text = tr("PAUSED")
	_paused.position = Vector2(560, 300)
	_prompt = _label(self, 19, Color(0.85, 0.97, 1))
	_prompt.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override(&"outline_size", 6)
	_prompt.visible = false
	var bottom := _panel(Vector2(14, 650), Vector2(1252, 60))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	bottom.add_child(row)
	for routine: NpcRoutine in sim.routines:
		var chip := Label.new()
		chip.add_theme_font_size_override(&"font_size", 13)
		chip.add_theme_color_override(&"font_color", NPC_COLORS.get(routine.schedule.npc_id, Color.WHITE))
		chip.custom_minimum_size = Vector2(118, 0)
		row.add_child(chip)
		_chips[routine.schedule.npc_id] = chip
	_log = Label.new()
	_log.add_theme_font_size_override(&"font_size", 12)
	_log.add_theme_color_override(&"font_color", Color(0.9, 0.88, 0.82))
	_log.custom_minimum_size = Vector2(500, 0)
	_log.clip_text = true
	row.add_child(_log)
	_map = Control.new()
	_map.position = Vector2(1036, 8)
	_map.size = Vector2(236, 120)
	_map.draw.connect(_draw_map)
	add_child(_map)
	_banner = _panel(Vector2(240, 150), Vector2(800, 0))
	_banner_text = _label(_banner, 18, Color(1, 0.95, 0.85))
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_text.custom_minimum_size = Vector2(780, 0)
	_banner.visible = false


func refresh() -> void:
	var clock: GameClock = _sim.clock
	_clock.text = "%s  %s · %s   %s" % [tr("DAY_N") % clock.day_number(), GameClock.format_time(clock.minute_of_day()),
		tr("PHASE_DAY") if clock.is_day() else tr("PHASE_NIGHT"), tr("SPEED_X") % clock.get_speed()]
	_room.text = _sim.house.rooms[_navigator.room_id].display_name
	_paused.visible = clock.paused
	for routine: NpcRoutine in _sim.routines:
		var npc_id: String = routine.schedule.npc_id
		var value: int = _sim.morale.get_morale(npc_id)
		var bar: String = "█".repeat(value / 10) + "·".repeat(10 - value / 10)
		_chips[npc_id].text = "%s%s\n%3d %s" % [routine.schedule.display_name, " ✕" if routine.is_broken() else "", value, bar]
	_map.queue_redraw()


## Shows [param text] above [param screen_point]; empty hides it. Unavailable text is grey.
func set_prompt(text: String, screen_point: Vector2, available: bool) -> void:
	_prompt.visible = not text.is_empty()
	if text.is_empty():
		return
	_prompt.text = text
	_prompt.modulate = Color(1, 1, 1) if available else Color(0.7, 0.7, 0.7, 0.85)
	_prompt.reset_size()
	_prompt.position = screen_point - Vector2(_prompt.size.x * 0.5, 40)


func add_log(text: String) -> void:
	_log_lines.append("%s  %s" % [GameClock.format_time(_sim.clock.minute_of_day()), text])
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func show_outcome(won: bool, key_events: Array[String]) -> void:
	var title: String = tr("WIN_TITLE") if won else tr("LOSS_TITLE") % _sim.morale.scenario_days()
	var lines: Array[String] = [title, "", tr("KEY_EVENTS")]
	lines.append_array(key_events.slice(maxi(0, key_events.size() - 10)))
	_banner_text.text = "\n".join(lines)
	_banner.visible = true


func _draw_map() -> void:
	var cell := Vector2(36, 26)
	var font: Font = ThemeDB.fallback_font
	_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(0.05, 0.05, 0.08, 0.85))
	for floor_level: int in [1, 0]:
		var origin := Vector2(6, 6 + (1 - floor_level) * 60)
		for room: RoomState in _sim.house.rooms.values():
			if room.floor_level != floor_level:
				continue
			var rect := Rect2(origin + Vector2(float(room.grid.x) * cell.x, float(room.grid.y) * cell.y * 0.62),
				Vector2(cell.x - 3.0, cell.y * 0.58))
			var here: bool = room.id == _navigator.room_id
			_map.draw_rect(rect, Color(0.25, 0.23, 0.3) if not here else Color(0.45, 0.42, 0.55))
			_map.draw_rect(rect, Color(0.6, 0.58, 0.7), false, 1.0)
			var dots: int = 0
			for routine: NpcRoutine in _sim.routines:
				if routine.room_id == room.id:
					_map.draw_rect(Rect2(rect.position + Vector2(3 + (dots % 5) * 6, 3 + (dots / 5) * 6), Vector2(4, 4)), NPC_COLORS.get(routine.schedule.npc_id, Color.WHITE))
					dots += 1
			if here:
				_map.draw_rect(Rect2(rect.end - Vector2(9, 9), Vector2(6, 6)), Color(0.93, 0.96, 1.0))
	_map.draw_string(font, Vector2(6, 116), "2 / 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.5))


func _panel(pos: Vector2, min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.09, 0.82)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.position = pos
	panel.custom_minimum_size = min_size
	add_child(panel)
	return panel


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	if parent is PanelContainer and parent.get_child_count() > 0 and parent.get_child(0) is VBoxContainer:
		parent.get_child(0).add_child(label)
	elif parent is PanelContainer:
		var box := VBoxContainer.new()
		parent.add_child(box)
		box.add_child(label)
	else:
		parent.add_child(label)
	return label

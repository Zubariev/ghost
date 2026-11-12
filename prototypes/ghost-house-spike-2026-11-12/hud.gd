# PROTOTYPE - NOT FOR PRODUCTION
#
## Minimal HUD for the room spike: clock and phase, speed, pause, the target
## object's prompt, a short event log and the controls line. All text Ukrainian.
extends CanvasLayer

const Strings := preload("res://prototypes/ghost-house-spike-2026-11-12/strings_uk.gd")

const LOG_LINES := 3

var _clock: Label
var _speed: Label
var _paused: Label
var _prompt: Label
var _log: Label
var _log_lines: Array[String] = []


func _ready() -> void:
	var top := _panel(Vector2(16, 14), Vector2(230, 78))
	_clock = _label(top, 28, Color(1, 0.95, 0.85))
	_speed = _label(top, 17, Color(0.85, 0.85, 0.9))
	var title := _label(self, 16, Color(1, 1, 1, 0.55))
	title.text = Strings.t(&"title")
	title.position = Vector2(520, 22)
	_paused = _label(self, 40, Color(1, 0.85, 0.5))
	_paused.text = Strings.t(&"paused")
	_paused.position = Vector2(560, 300)
	_paused.visible = false
	_prompt = _label(self, 19, Color(0.85, 0.97, 1))
	_prompt.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override(&"outline_size", 6)
	_prompt.visible = false
	# Top-right corner, clear of the room's walls and floor.
	var log_panel := _panel(Vector2(936, 12), Vector2(332, 0))
	_log = _label(log_panel, 13, Color(0.9, 0.88, 0.82))
	_log.custom_minimum_size = Vector2(312, 0)
	_log.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_log.clip_text = true
	var help := _label(self, 16, Color(1, 1, 1, 0.8))
	help.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	help.add_theme_constant_override(&"outline_size", 5)
	help.text = Strings.t(&"help")
	help.position = Vector2(20, 688)


func set_clock(minutes: float, speed: int, is_paused: bool) -> void:
	var total: int = int(minutes) % (24 * 60)
	var is_day: bool = total >= 6 * 60 and total < 22 * 60
	var phase: String = Strings.t(&"phase_day") if is_day else Strings.t(&"phase_night")
	_clock.text = "%02d:%02d  ·  %s" % [total / 60, total % 60, phase]
	_speed.text = Strings.t(&"speed") % speed
	_paused.visible = is_paused


## Shows [param text] centred above [param screen_point]; an empty text hides it.
func set_prompt(text: String, screen_point: Vector2, available: bool) -> void:
	_prompt.visible = not text.is_empty()
	if text.is_empty():
		return
	_prompt.text = text
	_prompt.modulate = Color(1, 1, 1) if available else Color(0.75, 0.75, 0.75, 0.85)
	_prompt.reset_size()
	_prompt.position = screen_point - Vector2(_prompt.size.x * 0.5, 70)


func add_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func _panel(pos: Vector2, size: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.09, 0.78)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.position = pos
	panel.custom_minimum_size = size
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	return box


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	parent.add_child(label)
	return label

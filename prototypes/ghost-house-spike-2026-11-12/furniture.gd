# PROTOTYPE - NOT FOR PRODUCTION
#
## A piece of furniture drawn from flat shapes. Interactable pieces can be
## highlighted: a faint outline when the ghost is near, a bright pulsing one
## when the piece is the ghost's current target.
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const Strings := preload("res://prototypes/ghost-house-spike-2026-11-12/strings_uk.gd")

enum Highlight { NONE, NOTICED, SELECTED }

## Translation key of the object's display name.
var name_key: StringName = &""
## Whether the ghost can target this object at all (decor cannot).
var is_interactable: bool = false
## Offset from the foot point to where interaction is measured and the prompt shows.
var interact_offset: Vector2 = Vector2.ZERO
## Parts as built by shapes.gd, drawn back to front.
var shapes: Array[Dictionary] = []

var _highlight: Highlight = Highlight.NONE
var _pulse: float = 0.0


func set_highlight(level: Highlight) -> void:
	if level == _highlight:
		return
	_highlight = level
	queue_redraw()


func get_interact_point() -> Vector2:
	return global_position + interact_offset


## Player-facing prompt for the ghost's interact key.
func get_prompt() -> String:
	return Strings.t(&"prompt_unavailable") % Strings.t(name_key)


## Whether interacting does something in this spike.
func has_action() -> bool:
	return false


## Performs the action; returns the log message key, or an empty key when nothing happened.
func interact() -> StringName:
	return &""


func _process(delta: float) -> void:
	if _highlight == Highlight.SELECTED:
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	if _highlight != Highlight.NONE:
		var glow: Color = Config.HIGHLIGHT_COLOR
		var width: float = Config.HIGHLIGHT_WIDTH
		if _highlight == Highlight.NOTICED:
			glow = Config.NOTICE_COLOR
			width = Config.NOTICE_WIDTH
		else:
			glow.a *= 0.7 + 0.3 * sin(_pulse * 6.0)
		for shape: Dictionary in shapes:
			draw_polyline(_closed(shape["poly"]), glow, width, true)
	for shape: Dictionary in shapes:
		draw_colored_polygon(shape["poly"], shape["color"])
		draw_polyline(_closed(shape["poly"]), Config.INK, 2.5, true)


static func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	return closed

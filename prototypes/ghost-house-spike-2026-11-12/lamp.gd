# PROTOTYPE - NOT FOR PRODUCTION
#
## The one working ghost action in this spike: snuff or relight the lamp.
## Visual only — no morale, no NPC reaction (not part of the spike).
extends "res://prototypes/ghost-house-spike-2026-11-12/furniture.gd"

const Shapes := preload("res://prototypes/ghost-house-spike-2026-11-12/shapes.gd")

signal lit_changed(is_lit: bool)

var lit: bool = true


func _ready() -> void:
	shapes = Shapes.lamp(lit)


func get_prompt() -> String:
	return Strings.t(&"prompt_snuff_lamp") if lit else Strings.t(&"prompt_light_lamp")


func has_action() -> bool:
	return true


func interact() -> StringName:
	lit = not lit
	shapes = Shapes.lamp(lit)
	queue_redraw()
	lit_changed.emit(lit)
	return &"log_lamp_lit" if lit else &"log_lamp_snuffed"

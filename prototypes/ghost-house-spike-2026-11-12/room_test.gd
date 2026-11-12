# PROTOTYPE - NOT FOR PRODUCTION
# Spike question: can Godot 4.7 2D present a Hamlet-style room interior so that walls,
# floor, doors, furniture, a wall-passing ghost, a walking NPC and object highlighting
# all read clearly?
# Date: 2026-11-12
#
## Spike root. Builds the room, furniture, ghost, one NPC and the HUD in code,
## then runs input, time speed, pause and interaction targeting.
## Run with `-- --capture=<dir>` to play a scripted tour and save screenshots.
extends Node2D

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")
const Strings := preload("res://prototypes/ghost-house-spike-2026-11-12/strings_uk.gd")
const Shapes := preload("res://prototypes/ghost-house-spike-2026-11-12/shapes.gd")
const RoomView := preload("res://prototypes/ghost-house-spike-2026-11-12/room_view.gd")
const Furniture := preload("res://prototypes/ghost-house-spike-2026-11-12/furniture.gd")
const Lamp := preload("res://prototypes/ghost-house-spike-2026-11-12/lamp.gd")
const Ghost := preload("res://prototypes/ghost-house-spike-2026-11-12/ghost.gd")
const TestNpc := preload("res://prototypes/ghost-house-spike-2026-11-12/test_npc.gd")
const SightCone := preload("res://prototypes/ghost-house-spike-2026-11-12/sight_cone.gd")
const Hud := preload("res://prototypes/ghost-house-spike-2026-11-12/hud.gd")

const KEYS: Dictionary = {
	&"ghost_left": KEY_A,
	&"ghost_right": KEY_D,
	&"ghost_up": KEY_W,
	&"ghost_down": KEY_S,
	&"interact": KEY_E,
	&"toggle_sight": KEY_Q,
	&"pause": KEY_SPACE,
	&"speed_1": KEY_1,
	&"speed_2": KEY_2,
	&"speed_3": KEY_3,
}

var _room: RoomView
var _world: Node2D
var _ghost: Ghost
var _npc: TestNpc
var _cone: SightCone
var _hud: Hud
var _lamp: Lamp
var _ambient: CanvasModulate
var _lamp_light: PointLight2D
var _interactables: Array[Furniture] = []
var _target: Furniture = null

var _minutes: float = Config.START_MINUTES
var _speed_index: int = 0
var _paused: bool = false


func _ready() -> void:
	get_window().content_scale_size = Config.VIEW_SIZE
	_setup_input()
	_build_scene()
	_hud.add_log(Strings.t(&"log_start"))
	var capture_dir := _capture_dir()
	if not capture_dir.is_empty():
		_run_capture(capture_dir)


func _process(delta: float) -> void:
	if not _paused:
		var sim_delta: float = delta * float(Config.SPEEDS[_speed_index])
		_minutes += sim_delta * Config.GAME_MINUTES_PER_SECOND
		_npc.advance(sim_delta)
		_ghost.move(delta)
	_ghost.over_floor = RoomView.is_on_floor(_ghost.position)
	_room.update_ghost(_ghost.get_body_point())
	_update_target()
	_hud.set_clock(_minutes, Config.SPEEDS[_speed_index], _paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_paused = not _paused
		_hud.add_log(Strings.t(&"log_paused") if _paused else Strings.t(&"log_resumed"))
	elif event.is_action_pressed(&"toggle_sight"):
		_toggle_sight()
	elif event.is_action_pressed(&"interact"):
		_try_interact()
	else:
		for i: int in Config.SPEEDS.size():
			if event.is_action_pressed(StringName("speed_%d" % (i + 1))):
				_speed_index = i
				_hud.add_log(Strings.t(&"log_speed") % Config.SPEEDS[i])


func _setup_input() -> void:
	for action: StringName in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEYS[action]  # physical: works on Ukrainian layouts too
		InputMap.action_add_event(action, key_event)


func _build_scene() -> void:
	_room = RoomView.new()
	add_child(_room)

	var floor_overlay := Node2D.new()
	add_child(floor_overlay)
	_cone = SightCone.new()
	_cone.visible = false
	floor_overlay.add_child(_cone)

	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)

	_add_furniture(Furniture.new(), Vector2(560, 260), Shapes.window(), &"obj_window", Vector2(0, -115), true)
	_add_furniture(Furniture.new(), Vector2(420, 400), Shapes.bed(), &"", Vector2.ZERO, false)
	_add_furniture(Furniture.new(), Vector2(865, 300), Shapes.wardrobe(), &"", Vector2.ZERO, false)
	_add_furniture(Furniture.new(), Vector2(1030, 470), Shapes.stove(), &"obj_stove", Vector2(0, -70), true)
	_add_furniture(Furniture.new(), Vector2(640, 500), Shapes.table(), &"", Vector2.ZERO, false)
	_add_furniture(Furniture.new(), Vector2(515, 478), Shapes.chair(), &"", Vector2.ZERO, false)
	_add_furniture(Furniture.new(), Vector2(765, 478), Shapes.chair(), &"", Vector2.ZERO, false)
	_lamp = Lamp.new()
	_add_furniture(_lamp, Vector2(285, 575), [], &"obj_lamp", Vector2(0, -80), true)
	_lamp.lit_changed.connect(_on_lamp_lit_changed)

	_npc = TestNpc.new()
	_npc.display_name = Strings.t(&"npc_grandma")
	_npc.waypoints = [Vector2(540, 420), Vector2(800, 400), Vector2(985, 500), Vector2(900, 600), Vector2(640, 590), Vector2(430, 600), Vector2(560, 330), Vector2(760, 272)]
	_npc.waits = [3.0, 0.0, 4.0, 0.0, 3.0, 0.0, 0.0, 2.0]
	_npc.look_dirs = [Vector2.LEFT, Vector2.ZERO, Vector2.UP, Vector2.ZERO, Vector2.UP, Vector2.ZERO, Vector2.ZERO, Vector2.UP]
	_npc.position = _npc.waypoints[0]
	_world.add_child(_npc)
	_cone.npc = _npc

	_ghost = Ghost.new()
	_ghost.position = Config.GHOST_START
	_world.add_child(_ghost)

	_ambient = CanvasModulate.new()
	_ambient.color = Config.AMBIENT_LAMP_LIT
	add_child(_ambient)
	_lamp_light = PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	_lamp_light.texture = texture
	_lamp_light.texture_scale = Config.LAMP_LIGHT_SCALE
	_lamp_light.color = Config.LAMP_LIGHT_COLOR
	_lamp_light.energy = Config.LAMP_LIGHT_ENERGY
	_lamp_light.position = _lamp.position + Vector2(0, -140)
	add_child(_lamp_light)

	_hud = Hud.new()
	add_child(_hud)


func _add_furniture(piece: Furniture, pos: Vector2, shapes: Array[Dictionary], name_key: StringName, offset: Vector2, interactable: bool) -> void:
	piece.position = pos
	if not shapes.is_empty():
		piece.shapes = shapes
	piece.name_key = name_key
	piece.interact_offset = offset
	piece.is_interactable = interactable
	_world.add_child(piece)
	if interactable:
		_interactables.append(piece)


## Picks the nearest interactable in range as the target; nearby ones get a faint outline.
func _update_target() -> void:
	var best: Furniture = null
	var best_distance: float = Config.INTERACT_RANGE
	for piece: Furniture in _interactables:
		var distance: float = _distance_to(piece)
		if distance <= best_distance:
			best = piece
			best_distance = distance
	_target = best
	for piece: Furniture in _interactables:
		if piece == _target:
			piece.set_highlight(Furniture.Highlight.SELECTED)
		elif _distance_to(piece) <= Config.NOTICE_RANGE:
			piece.set_highlight(Furniture.Highlight.NOTICED)
		else:
			piece.set_highlight(Furniture.Highlight.NONE)
	if _target == null:
		_hud.set_prompt("", Vector2.ZERO, false)
	else:
		_hud.set_prompt(_target.get_prompt(), _target.get_interact_point(), _target.has_action())


## The nearer of body-to-interact-point and floor-to-foot, so hovering in front
## of an object counts as well as floating over its body.
func _distance_to(piece: Furniture) -> float:
	var by_body: float = _ghost.get_body_point().distance_to(piece.get_interact_point())
	var by_floor: float = _ghost.global_position.distance_to(piece.global_position)
	return minf(by_body, by_floor)


func _try_interact() -> void:
	if _target == null:
		return
	if not _target.has_action():
		_hud.add_log(Strings.t(&"log_unavailable") % Strings.t(_target.name_key))
		return
	var message: StringName = _target.interact()
	if message != &"":
		_hud.add_log(Strings.t(message))


func _toggle_sight() -> void:
	_cone.visible = not _cone.visible
	_hud.add_log(Strings.t(&"log_sight_on") if _cone.visible else Strings.t(&"log_sight_off"))


func _on_lamp_lit_changed(is_lit: bool) -> void:
	_lamp_light.enabled = is_lit
	_ambient.color = Config.AMBIENT_LAMP_LIT if is_lit else Config.AMBIENT_LAMP_OUT


# --- Scripted capture (verification only) -------------------------------------

func _capture_dir() -> String:
	# Accept the flag after `--` (user args) or without it (engine args).
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _run_capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_speed_index = 2
	await _frames(150)
	await _shot(dir, "01-overview")
	_ghost.position = _lamp.position + Vector2(50, 20)
	await _frames(20)
	await _shot(dir, "02-lamp-targeted")
	_try_interact()
	await _frames(20)
	await _shot(dir, "03-lamp-snuffed")
	_try_interact()
	_toggle_sight()
	_ghost.position = Vector2(215, 420)
	await _frames(40)
	await _shot(dir, "04-sight-cones-ghost-in-left-wall")
	_ghost.position = Vector2(1030, 535)
	await _frames(20)
	await _shot(dir, "05-stove-targeted-no-action")
	_toggle_sight()
	_ghost.position = Vector2(700, 300)
	await _frames(20)
	await _shot(dir, "06-window-noticed")
	get_tree().quit()


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _shot(dir: String, shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(dir.path_join(shot_name + ".png"))
	print("captured ", shot_name)

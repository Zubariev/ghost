## The playable game (stage 5a, Demo Specification §8.7): the house simulation, the ghost
## the player steers through walls and floors, one Hamlet-style room on screen at a time,
## and the HUD. Ghost actions go through [GhostActions]; the family reacts only through the
## simulation's own rules.
##
## Controls (user decision 3; R/C approved for stage 5a): WASD move · R / C float up / down ·
## E act on the highlighted object · Space pause · 1/2/3 ×1/×2/×4.
## Run with `--capture=<dir>` for a scripted tour that saves screenshots and quits.
extends Node2D

const STRINGS_PATH: String = "res://assets/i18n/strings.csv"
const LOCALE: String = "uk"
const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
const GHOST_PATH: String = "res://assets/data/ghost/ghost.json"
const KEYS: Dictionary = {
	&"ghost_left": KEY_A, &"ghost_right": KEY_D, &"ghost_up": KEY_W, &"ghost_down": KEY_S,
	&"interact": KEY_E, &"floor_up": KEY_R, &"floor_down": KEY_C,
	&"pause": KEY_SPACE, &"speed_1": KEY_1, &"speed_2": KEY_2, &"speed_3": KEY_3,
}

var _sim: HouseSim
var _navigator: GhostNavigator
var _stage: RoomStage
var _tint: CanvasModulate
var _hud: GameHud
var _ghost_speed: float = 0.5
var _interact_range: float = 0.16
var _target: String = ""
var _key_events: Array[String] = []
var _outcome_shown: bool = false


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	Localization.load_csv(STRINGS_PATH, LOCALE)
	_setup_input()
	_sim = HouseSim.from_data_files()
	_sim.start()
	var ghost_cfg: Dictionary = JsonData.read(GHOST_PATH)
	_ghost_speed = float(ghost_cfg.get("speed", 0.5))
	_interact_range = float(ghost_cfg.get("interact_range", 0.16))
	var start_uv: Array = ghost_cfg.get("start_uv", [0.5, 0.7])
	_navigator = GhostNavigator.new(_sim.house)
	_navigator.place(String(ghost_cfg.get("start_room", "hall")), Vector2(float(start_uv[0]), float(start_uv[1])))
	_stage = RoomStage.new()
	_stage.sim = _sim
	_stage.navigator = _navigator
	_stage.furniture = JsonData.read(FURNITURE_PATH).get("rooms", {})
	add_child(_stage)
	_tint = CanvasModulate.new()
	add_child(_tint)
	_hud = GameHud.new()
	add_child(_hud)
	_hud.setup(_sim, _navigator)
	_connect_events()
	_update_view()
	var capture_dir: String = _capture_dir()
	if not capture_dir.is_empty():
		_run_capture(capture_dir)


func _process(delta: float) -> void:
	if _sim.advance(delta) > 0:
		_hud.refresh()
	if not _sim.clock.paused and not _sim.is_over():
		var direction: Vector2 = Input.get_vector(&"ghost_left", &"ghost_right", &"ghost_up", &"ghost_down")
		_navigator.move(direction * _ghost_speed * delta)
	_update_view()
	if _sim.is_over() and not _outcome_shown:
		_outcome_shown = true
		_hud.show_outcome(_sim.morale.outcome == MoraleSystem.OUTCOME_WON, _key_events)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_sim.clock.paused = not _sim.clock.paused
	elif event.is_action_pressed(&"interact"):
		_act()
	elif event.is_action_pressed(&"floor_up"):
		_hud.add_log(tr("LOG_FLOOR_UP") if _navigator.change_floor(1) else tr("LOG_NO_FLOOR"))
	elif event.is_action_pressed(&"floor_down"):
		_hud.add_log(tr("LOG_FLOOR_DOWN") if _navigator.change_floor(-1) else tr("LOG_NO_FLOOR"))
	else:
		for i: int in 3:
			if event.is_action_pressed(StringName("speed_%d" % (i + 1))):
				_sim.clock.set_speed_index(i)
	_hud.refresh()


func _setup_input() -> void:
	for action: StringName in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = KEYS[action]   # physical keys: works on Ukrainian layouts
		InputMap.action_add_event(action, key)


## Picks the nearest object with a ghost action in this room, highlights it and sets the
## prompt; sets the room's light tint.
func _update_view() -> void:
	var room_id: String = _navigator.room_id
	var best: String = ""
	var best_distance: float = _interact_range
	for piece: Dictionary in _stage.furniture.get(room_id, []):
		var object_id: String = String(piece.get("object", ""))
		if object_id.is_empty() or _sim.house.objects[object_id].ghost.is_empty():
			continue
		var at := Vector2(float(piece["u"]), float(piece["v"]))
		var distance: float = _navigator.uv.distance_to(at)
		if distance <= best_distance:
			best = object_id
			best_distance = distance
	_target = best
	_stage.target_object = best
	if best.is_empty():
		_hud.set_prompt("", Vector2.ZERO, false)
	else:
		var obj: ObjectState = _sim.house.objects[best]
		var at_screen: Vector2 = RoomGeometry.to_screen(_stage.object_uv(room_id, best)) - Vector2(0, 150)
		if GhostActions.can_act(_sim.house, best):
			_hud.set_prompt(tr(String(obj.ghost.get("prompt", ""))), at_screen, true)
		else:
			_hud.set_prompt(tr("GHOST_ALREADY_DONE") % obj.display_name, at_screen, false)
	var room: RoomState = _sim.house.rooms[room_id]
	match room.light:
		RoomState.Light.DARK:
			_tint.color = Palette.TINT_DARK
		RoomState.Light.DIM:
			_tint.color = Palette.TINT_DIM
		_:
			_tint.color = Palette.TINT_BRIGHT_DAY if _sim.house.is_day else Palette.TINT_BRIGHT_NIGHT
	_hud.refresh()


func _act() -> void:
	if _target.is_empty() or _sim.is_over():
		return
	var obj: ObjectState = _sim.house.objects[_target]
	var room_name: String = _sim.house.rooms[obj.room_id].display_name
	if GhostActions.act(_sim.house, _target):
		var what: String = tr("ACT_" + (obj.kind if not obj.kind.is_empty() else obj.id))
		_hud.add_log(tr("LOG_GHOST_ACTED") % [what, room_name])


func _connect_events() -> void:
	var names: Dictionary[String, String] = {}
	for routine: NpcRoutine in _sim.routines:
		var who: String = routine.schedule.display_name
		names[routine.schedule.npc_id] = who
		routine.task_completed.connect(func(task: HouseTask) -> void:
			_hud.add_log(tr("LOG_TASK_DONE") % [who, _describe_task(task)]))
		routine.self_fix_started.connect(func(object_id: String) -> void:
			_hud.add_log(tr("LOG_SEARCHING") % [who, _sim.house.objects[object_id].display_name]))
	_sim.morale.morale_changed.connect(func(npc: String, value: int, delta: int, reason: String) -> void:
		if delta < 0 and reason != "set":
			_hud.add_log(tr("LOG_MORALE_DROP") % [names[npc], delta, tr("REASON_" + reason), value]))
	_sim.morale.npc_broke.connect(func(npc: String) -> void: _key_event(tr("LOG_BROKEN") % names[npc]))
	_sim.morale.npc_recovered.connect(func(npc: String) -> void: _key_event(tr("LOG_RECOVERED") % names[npc]))


func _describe_task(task: HouseTask) -> String:
	if task.type == HouseTask.Type.CLEAN:
		return _sim.house.rooms[task.room_id].display_name
	return "%s (%s)" % [_sim.house.objects[task.target_id].display_name, _sim.house.rooms[task.room_id].display_name]


func _key_event(text: String) -> void:
	_key_events.append("%s %s  %s" % [tr("DAY_N") % _sim.clock.day_number(), GameClock.format_time(_sim.clock.minute_of_day()), text])
	_hud.add_log(text)


# --- Scripted capture (verification only) ---------------------------------------

func _capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _run_capture(dir: String) -> void:
	set_process(false)
	DirAccess.make_dir_recursive_absolute(dir)
	await _show(dir, "01-hall-start", "07:00", "hall", Vector2(0.5, 0.75))
	await _show(dir, "02-family-breakfast", "07:30", "dining_room", Vector2(0.5, 0.85))
	await _show(dir, "03-stove-targeted", "08:50", "kitchen", Vector2(0.80, 0.42))
	_act()
	await _show(dir, "04-father-repairs-stove", "09:40", "kitchen", Vector2(0.15, 0.9))
	await _show(dir, "05-living-room-evening", "21:30", "living_room", Vector2(0.14, 0.86))
	_act()
	await _show(dir, "06-lamp-snuffed-dark", "22:30", "living_room", Vector2(0.4, 0.9))
	await _show(dir, "07-children-window-targeted", "22:40", "children_bedroom", Vector2(0.5, 0.06))
	_act()
	await _show(dir, "08-window-open-cold", "23:30", "children_bedroom", Vector2(0.6, 0.9))
	await _show(dir, "09-wall-fade-left", "23:31", "children_bedroom", Vector2(-0.12, 0.5))
	get_tree().quit()


## Runs the simulation to [param time_text] (the next time it comes round), places the
## ghost and saves a screenshot.
func _show(dir: String, shot_name: String, time_text: String, room_id: String, at: Vector2) -> void:
	var target: int = GameClock.parse_time(time_text)
	while _sim.clock.minute_of_day() != target and not _sim.is_over():
		_sim.advance(1.0)
	_navigator.place(room_id, at)
	_update_view()
	for i: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
	print("captured ", shot_name)

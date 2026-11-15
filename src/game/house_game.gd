## The playable game (stage 5a, Demo Specification §8.7): the house simulation, the ghost
## the player steers through walls and floors, one Hamlet-style room on screen at a time,
## and the HUD. Ghost actions go through [GhostActions]; the family reacts only through the
## simulation's own rules.
##
## Controls (user decision 3; floor keys and pause changed in stage 5e, 2026-11-15): WASD move ·
## W + Space / S + Space float up / down a floor · E act on the highlighted object · F hide /
## leave a hiding spot · Q sight zones (after the monocle is found, stage 5b) · Esc pause ·
## 1/2/3 ×1/×2/×4.
## Stage 5d (Demo Specification §8.10): E starts harm that takes time and costs energy
## ([GhostCasting], [GhostEnergy]); floating off, hiding, changing floor or contact
## interrupts it at no cost. Energy refills by itself (faster hidden, in dark or cold rooms).
## Art test (2026-11-15): storybook rooms (assets/art/visual_style.json) get a colour-grade
## layer between the room and the HUD that follows the room's warm-to-haunted mood.
## Stage 6 (Demo Spec §10.4): a day card at each dawn, the ghost's stats ([GhostStats]) and
## the end summary with Play again (reloads this scene: a fresh run) and To title.
## Run with `--capture=<dir>` for a scripted tour that saves screenshots and quits; add
## `--art-test` to capture only the cozy and haunted living room, or `--capture-loss` to
## play three days without the ghost and capture the loss summary.
extends Node2D

const STRINGS_PATH: String = "res://assets/i18n/strings.csv"
const LOCALE: String = "uk"
const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
const GHOST_PATH: String = "res://assets/data/ghost/ghost.json"
const STEALTH_PATH: String = "res://assets/data/ghost/stealth.json"
const MOVEMENT_PATH: String = "res://assets/data/house/movement.json"
const ENERGY_PATH: String = "res://assets/data/ghost/energy.json"
const TITLE_SCENE: String = "res://src/game/title/title_screen.tscn"
const GRADE_SHADER_PATH: String = "res://assets/shaders/post_art_room_grade.gdshader"
## Draw order: room (0), colour grade (1), HUD (2).
const GRADE_LAYER: int = 1
const HUD_LAYER: int = 2
const KEYS: Dictionary = {
	&"ghost_left": KEY_A, &"ghost_right": KEY_D, &"ghost_up": KEY_W, &"ghost_down": KEY_S,
	&"interact": KEY_E, &"change_floor": KEY_SPACE, &"hide": KEY_F, &"sight_view": KEY_Q,
	&"pause": KEY_ESCAPE, &"journal": KEY_J, &"speed_1": KEY_1, &"speed_2": KEY_2, &"speed_3": KEY_3,
}

var _sim: HouseSim
var _navigator: GhostNavigator
var _stage: RoomStage
var _tint: CanvasModulate
## Colour grade for storybook rooms (full-screen, under the HUD).
var _grade_layer: CanvasLayer
var _grade: ColorRect
var _hud: GameHud
var _stealth: StealthSystem
var _motion: FamilyMotion
var _energy: GhostEnergy
var _casting: GhostCasting
var _loot: GhostLoot
var _hide_range: float = 0.16
var _has_monocle: bool = false
var _ghost_speed: float = 0.5
## Ghost speed factor in a room in perfect order (1 when fully run-down).
var _ghost_slowest: float = 1.0
var _interact_range: float = 0.16
var _target: String = ""
var _key_events: Array[String] = []
var _stats := GhostStats.new()
var _outcome_shown: bool = false
## Capture only: keep the day card in the next shot (the tour does not run the HUD's fade).
var _keep_day_card: bool = false


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	Localization.load_csv(STRINGS_PATH, LOCALE)
	_setup_input()
	_sim = HouseSim.from_data_files()
	_sim.start()
	var ghost_cfg: Dictionary = JsonData.read(GHOST_PATH)
	_ghost_speed = float(ghost_cfg.get("speed", 0.5))
	_ghost_slowest = float(ghost_cfg.get("slowest_in_order", 1.0))
	_interact_range = float(ghost_cfg.get("interact_range", 0.16))
	var start_uv: Array = ghost_cfg.get("start_uv", [0.5, 0.7])
	_navigator = GhostNavigator.new(_sim.house)
	_navigator.place(String(ghost_cfg.get("start_room", "hall")), Vector2(float(start_uv[0]), float(start_uv[1])))
	_stage = RoomStage.new()
	_stage.sim = _sim
	_stage.navigator = _navigator
	_stage.layout = RoomLayout.new(JsonData.read(FURNITURE_PATH).get("rooms", {}), _sim.house)
	add_child(_stage)
	var stealth_cfg: Dictionary = JsonData.read(STEALTH_PATH)
	_hide_range = float(stealth_cfg.get("hide_range", 0.16))
	# Stage 5d: detection penalties live with the rest of the energy numbers.
	var energy_cfg: Dictionary = JsonData.read(ENERGY_PATH)
	stealth_cfg["energy_penalty"] = energy_cfg.get("detection_penalty", {})
	_energy = GhostEnergy.new(energy_cfg)
	_casting = GhostCasting.new(_sim.house, _energy)
	_stealth = StealthSystem.new(stealth_cfg, _sim.house, _sim.routines, _sim.morale, _stage.layout, _navigator,
		String(ghost_cfg.get("start_room", "hall")), Vector2(float(start_uv[0]), float(start_uv[1])))
	_stage.stealth = _stealth
	# Stage 5c: the family walks around furniture and through doors; sight follows them.
	var movement_cfg: Dictionary = JsonData.read(MOVEMENT_PATH)
	_motion = FamilyMotion.new(_sim.routines, _sim.house, _stage.layout, RoomPaths.new(_stage.layout, movement_cfg), movement_cfg)
	_motion.stealth = _stealth
	_motion.set_glances(stealth_cfg.get("glance", {}))
	_stealth.person_source = _motion.person
	_stage.motion = _motion
	_stage.casting = _casting
	_loot = GhostLoot.new(JsonData.read(GhostLoot.LOOT_PATH))
	_stage.loot = _loot
	_stage.sight_config = stealth_cfg
	_stage.visuals = PropVisuals.new(JsonData.read(PropVisuals.STYLE_PATH))
	_sim.clock.minute_advanced.connect(func(total: int) -> void:
		if not _sim.is_over():
			_stealth.on_minute(posmod(total - 1, GameClock.MINUTES_PER_DAY)))
	_tint = CanvasModulate.new()
	add_child(_tint)
	_grade_layer = CanvasLayer.new()
	_grade_layer.layer = GRADE_LAYER
	add_child(_grade_layer)
	_grade = ColorRect.new()
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade.position = Vector2.ZERO
	_grade.size = Vector2(1280, 720)
	var grade_material := ShaderMaterial.new()
	grade_material.shader = load(GRADE_SHADER_PATH)
	_grade.material = grade_material
	_grade_layer.add_child(_grade)
	_hud = GameHud.new()
	_hud.layer = HUD_LAYER
	add_child(_hud)
	_hud.setup(_sim, _navigator)
	_hud.set_energy(_energy)
	_connect_events()
	_update_view()
	_hud.show_day_card(_sim.clock.day_number())
	var capture_dir: String = _capture_dir()
	if not capture_dir.is_empty():
		_run_capture(capture_dir)


func _process(delta: float) -> void:
	var minutes: float = _sim.clock.minutes_for(delta) if not _sim.is_over() else 0.0
	if _sim.advance(delta) > 0:
		_hud.refresh()
	_motion.update(minutes)
	_update_energy(minutes)
	_update_loot(minutes)
	_hud.tick(delta)
	if not _sim.clock.paused and not _sim.is_over():
		var direction: Vector2 = Input.get_vector(&"ghost_left", &"ghost_right", &"ghost_up", &"ghost_down")
		if direction != Vector2.ZERO and not _stealth.hidden_in.is_empty():
			_stealth.unhide()   # floating off leaves the hiding spot
			_hud.add_log(tr("LOG_UNHIDDEN"))
		if direction != Vector2.ZERO:
			_casting.cancel()   # floating off interrupts harm
		_casting.hold(Input.is_action_pressed(&"interact"))   # hold E to act (2026-11-15)
		var room_factor: float = RoomCondition.ghost_factor(RoomCondition.run_down(_sim.house, _navigator.room_id), _ghost_slowest)
		_navigator.move(direction * _ghost_speed * room_factor * delta)
		_stealth.observe()
	_update_view()
	_show_outcome_if_over()


## Shows the end summary once, when the scenario has ended.
func _show_outcome_if_over() -> void:
	if _sim.is_over() and not _outcome_shown:
		_outcome_shown = true
		_casting.cancel()
		_hud.show_outcome(_sim.morale.outcome == MoraleSystem.OUTCOME_WON, _key_events, _stats)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_sim.clock.paused = not _sim.clock.paused
	elif event.is_action_pressed(&"interact"):
		_act()
	elif event.is_action_pressed(&"journal"):
		_hud.toggle_journal(_journal_entries())
	elif event.is_action_pressed(&"hide"):
		_toggle_hide()
	elif event.is_action_pressed(&"sight_view"):
		if _has_monocle:
			_stage.show_cones = not _stage.show_cones
		else:
			_hud.add_log(tr("LOG_NEED_MONOCLE"))
	elif event.is_action_pressed(&"change_floor"):
		var direction: int = GhostNavigator.floor_direction(Input.is_action_pressed(&"ghost_up"), Input.is_action_pressed(&"ghost_down"))
		if direction == 0:
			_hud.add_log(tr("LOG_FLOOR_HOW"))
		else:
			_casting.cancel()
			if _navigator.change_floor(direction):
				_hud.add_log(tr("LOG_FLOOR_UP") if direction > 0 else tr("LOG_FLOOR_DOWN"))
			else:
				_hud.add_log(tr("LOG_NO_FLOOR"))
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
	for piece: Dictionary in _stage.layout.pieces(room_id):
		var object_id: String = String(piece.get("object", ""))
		var at := Vector2(float(piece["u"]), float(piece["v"]))
		var distance: float = _navigator.uv.distance_to(at)
		if piece.has("pickup") and not _has_monocle and distance <= best_distance:
			best = "pickup:" + String(piece["pickup"])
			best_distance = distance
			continue
		if object_id.is_empty() or _sim.house.objects[object_id].ghost.is_empty():
			continue
		if distance <= best_distance:
			best = object_id
			best_distance = distance
	_target = best
	_stage.target_object = best.trim_prefix("pickup:")
	_stage.monocle_taken = _has_monocle
	var hide_spot: String = _nearest_hiding_spot()
	if not _stealth.hidden_in.is_empty():
		var hidden_uv := Vector2(0.5, 0.5)
		for spot: Dictionary in _stage.layout.hiding_spots(room_id):
			if String(spot["id"]) == _stealth.hidden_in:
				hidden_uv = spot["uv"]
		if _loot.is_open():
			_hud.set_prompt("", Vector2.ZERO, false)
		else:
			_hud.set_prompt(tr("GHOST_SEARCH"), RoomGeometry.to_screen(hidden_uv) - Vector2(0, 150), true)
	elif best.is_empty() and not hide_spot.is_empty() and _stealth.hidden_in.is_empty():
		var spot_uv := Vector2(0.5, 0.5)
		for spot: Dictionary in _stage.layout.hiding_spots(room_id):
			if String(spot["id"]) == hide_spot:
				spot_uv = spot["uv"]
		_hud.set_prompt(tr("GHOST_HIDE"), RoomGeometry.to_screen(spot_uv) - Vector2(0, 150), true)
	elif best.begins_with("pickup:"):
		var pickup_uv: Vector2 = _stage.layout.kind_uv(room_id, "dresser")
		_hud.set_prompt(tr("GHOST_TAKE_MONOCLE"), RoomGeometry.to_screen(pickup_uv) - Vector2(0, 150), true)
	elif best.is_empty():
		_hud.set_prompt("", Vector2.ZERO, false)
	else:
		var obj: ObjectState = _sim.house.objects[best]
		var at_screen: Vector2 = RoomGeometry.to_screen(_stage.layout.object_uv(room_id, best)) - Vector2(0, 150)
		var action: String = tr(String(obj.ghost.get("prompt", "")))
		var key: String = GhostEnergy.action_key(obj)
		var cost: int = roundi(_energy.action_cost(key))
		if _casting.object_id == best:
			_hud.set_prompt(tr("GHOST_ACTING") % action, at_screen - Vector2(0, 40), true)
		elif not GhostActions.can_act(_sim.house, best):
			_hud.set_prompt(tr("GHOST_ALREADY_DONE") % obj.display_name, at_screen, false)
		elif not _energy.can_afford(key):
			_hud.set_prompt(tr("GHOST_NO_ENERGY") % [action, cost], at_screen, false)
		else:
			_hud.set_prompt(tr("GHOST_COST") % [action, cost], at_screen, true)
	var room: RoomState = _sim.house.rooms[room_id]
	_grade.visible = _stage.is_storybook()
	if _grade.visible:
		# The grade carries the light in storybook rooms; the old whole-room tint stays neutral.
		_tint.color = Color.WHITE
		var grade_material: ShaderMaterial = _grade.material
		grade_material.set_shader_parameter(&"warmth", _stage.shown_warmth())
		grade_material.set_shader_parameter(&"night", _stage.shown_night())
	else:
		_set_placeholder_tint(room)
	_hud.refresh()


## The original whole-room light tint (rooms not yet in the storybook style).
func _set_placeholder_tint(room: RoomState) -> void:
	match room.light:
		RoomState.Light.DARK:
			_tint.color = Palette.TINT_DARK
		RoomState.Light.DIM:
			_tint.color = Palette.TINT_DIM
		_:
			_tint.color = Palette.TINT_BRIGHT_DAY if _sim.house.is_day else Palette.TINT_BRIGHT_NIGHT


## The hiding spot within reach of the ghost in its room, or "".
func _nearest_hiding_spot() -> String:
	var best: String = ""
	var best_distance: float = _hide_range
	for spot: Dictionary in _stage.layout.hiding_spots(_navigator.room_id):
		var distance: float = _navigator.uv.distance_to(spot["uv"])
		if distance <= best_distance:
			best = String(spot["id"])
			best_distance = distance
	return best


func _toggle_hide() -> void:
	if _sim.is_over():
		return
	if not _stealth.hidden_in.is_empty():
		_stealth.unhide()
		_hud.add_log(tr("LOG_UNHIDDEN"))
		return
	var spot: String = _nearest_hiding_spot()
	if spot.is_empty():
		return
	_casting.cancel()   # hiding interrupts harm
	if _stealth.hide(spot):
		_hud.add_log(tr("LOG_HIDDEN"))


func _act() -> void:
	if _sim.is_over():
		return
	if not _stealth.hidden_in.is_empty():
		_loot.start_search(_stealth.hidden_in)   # hold E while hidden: search the spot
		return
	if _target.is_empty():
		return
	if _target.begins_with("pickup:"):
		_has_monocle = true
		_hud.add_log(tr("LOG_MONOCLE"))
		return
	if _casting.object_id == _target:
		return   # already at it
	_casting.cancel()
	var key: String = GhostEnergy.action_key(_sim.house.objects[_target])
	if _casting.start(_target) == GhostCasting.NOT_ENOUGH_ENERGY:
		_hud.flash_not_enough_energy()
		_hud.add_log(tr("LOG_NO_ENERGY") % [roundi(_energy.action_cost(key)), floori(_energy.value)])


## Searching hiding spots (2026-11-15): runs while E is held; leaving or losing the spot
## closes it.
func _update_loot(minutes: float) -> void:
	if _stealth.hidden_in.is_empty() or (_loot.is_open() and _loot.open_spot() != _stealth.hidden_in):
		if _loot.is_open() or _loot.is_searching():
			_loot.close()
			_hud.hide_loot_grid()
		return
	_loot.hold(Input.is_action_pressed(&"interact"))
	_loot.update(minutes, _sim.clock.total_minutes)


func _show_loot_grid(spot_id: String, slots: Array[String]) -> void:
	var icons: Dictionary = {}
	var names: Dictionary = {}
	for item: String in slots:
		if not item.is_empty():
			icons[item] = _loot.icon(item)
			names[item] = tr(_loot.name_key(item))
	var spot_uv := Vector2(0.5, 0.5)
	for spot: Dictionary in _stage.layout.hiding_spots(_navigator.room_id):
		if String(spot["id"]) == spot_id:
			spot_uv = spot["uv"]
	_hud.show_loot_grid(slots, RoomGeometry.to_screen(spot_uv) - Vector2(0, 90), icons, names)


func _take_loot(slot: int) -> void:
	var item: String = _loot.take(slot, _sim.clock.total_minutes)
	if item.is_empty():
		return
	_hud.update_loot_grid(_loot.grid())
	_hud.add_log(tr("LOG_FOUND") % tr(_loot.name_key(item)))
	var lines: Array[String] = []
	for id: String in _loot.inventory:
		lines.append("%s ×%d" % [tr(_loot.name_key(id)), _loot.count(id)])
	_hud.set_inventory(lines)
	if _loot.kind_of(item) == "lore":
		_hud.show_note(tr(_loot.name_key(item)), tr(_loot.text_key(item)))


func _journal_entries() -> Array[String]:
	var entries: Array[String] = []
	for item: String in _loot.lore_found:
		entries.append("%s\n%s" % [tr(_loot.name_key(item)), tr(_loot.text_key(item))])
	return entries


## Energy refills (stage 5d): faster hidden, in a dark or cold room; not while acting. The
## running action moves on by the same game minutes.
func _update_energy(minutes: float) -> void:
	if minutes <= 0.0:
		return
	var room: RoomState = _sim.house.rooms[_navigator.room_id]
	_energy.regenerate(minutes, not _stealth.hidden_in.is_empty(), room.light == RoomState.Light.DARK,
		room.temperature == RoomState.Temperature.COLD, _casting.is_casting())
	_casting.update(minutes)


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
	_stealth.noticed.connect(func(npc: String) -> void: _hud.add_log(tr("LOG_NOTICED") % names[npc]))
	_stealth.search_started.connect(func(npc: String) -> void: _hud.add_log(tr("LOG_SEARCH_STARTED") % names[npc]))
	_stealth.search_ended.connect(func(npc: String) -> void: _hud.add_log(tr("LOG_SEARCH_ENDED") % names[npc]))
	_stealth.contact.connect(func(npc: String, how: String) -> void: _key_event(tr("LOG_CONTACT_" + how) % names[npc]))
	_sim.morale.npc_broke.connect(func(npc: String) -> void: _key_event(tr("LOG_BROKEN") % names[npc]))
	_sim.morale.npc_recovered.connect(func(npc: String) -> void: _key_event(tr("LOG_RECOVERED") % names[npc]))
	# Stage 5d: energy
	_stealth.ghost_energy_penalty.connect(func(zone: String, _amount: int) -> void:
		var lost: float = _energy.penalize(zone)
		if lost > 0.0:
			_hud.add_log(tr("LOG_ENERGY_LOST") % roundi(lost)))
	_stealth.contact.connect(func(_npc: String, _how: String) -> void: _casting.cancel())
	_stealth.ghost_returned.connect(func() -> void: _casting.cancel())
	_energy.low_warning.connect(func() -> void: _hud.add_log(tr("LOG_LOW_ENERGY")))
	# Loot (2026-11-15)
	_loot.searched.connect(_show_loot_grid)
	_hud.slot_clicked.connect(_take_loot)
	_casting.completed.connect(func(object_id: String) -> void:
		var obj: ObjectState = _sim.house.objects[object_id]
		var what: String = tr("ACT_" + GhostEnergy.action_key(obj))
		_hud.add_log(tr("LOG_GHOST_ACTED") % [what, _sim.house.rooms[obj.room_id].display_name]))
	_casting.cancelled.connect(func(_object_id: String) -> void: _hud.add_log(tr("LOG_ACT_CANCELLED")))
	# Stage 6: the ghost's stats for the end summary, the day card, the summary's buttons
	_casting.completed.connect(func(object_id: String) -> void:
		_stats.record_action(GhostEnergy.action_key(_sim.house.objects[object_id])))
	_energy.lost.connect(_stats.record_energy)
	_stealth.noticed.connect(func(_npc: String) -> void: _stats.record_noticed())
	_stealth.contact.connect(func(_npc: String, _how: String) -> void: _stats.record_caught())
	_loot.taken.connect(func(item_id: String) -> void: _stats.record_find(_loot.kind_of(item_id)))
	_sim.clock.phase_changed.connect(func(is_day: bool) -> void:
		if is_day and not _sim.is_over():
			_hud.show_day_card(_sim.clock.day_number()))
	_hud.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	_hud.title_requested.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))
	_casting.failed.connect(func(_object_id: String, why: String) -> void:
		if why == GhostCasting.NOT_ENOUGH_ENERGY:
			_hud.flash_not_enough_energy()
			_hud.add_log(tr("LOG_ACT_FAILED_ENERGY")))


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
	_hud.hide_day_card()
	if OS.get_cmdline_user_args().has("--capture-loss"):
		await _run_loss_capture(dir)
		get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--art-test") or OS.get_cmdline_args().has("--art-test"):
		await _run_art_test(dir)
		get_tree().quit()
		return
	await _show(dir, "01-hall-start", "07:00", "hall", Vector2(0.5, 0.75))
	await _show(dir, "02-family-breakfast", "07:30", "dining_room", Vector2(0.5, 0.85))
	await _show(dir, "03-stove-targeted", "08:50", "kitchen", Vector2(0.80, 0.42))
	_act_now()
	await _show(dir, "04-father-repairs-stove", "09:40", "kitchen", Vector2(0.15, 0.9))
	await _show(dir, "05-living-room-evening", "21:30", "living_room", Vector2(0.14, 0.86))
	_act_now()
	await _show(dir, "06-lamp-snuffed-dark", "22:30", "living_room", Vector2(0.4, 0.9))
	await _show(dir, "07-children-window-targeted", "22:40", "children_bedroom", Vector2(0.5, 0.06))
	_act_now()
	await _show(dir, "08-window-open-cold", "23:30", "children_bedroom", Vector2(0.6, 0.9))
	await _show(dir, "09-wall-fade-left", "23:31", "children_bedroom", Vector2(-0.12, 0.5))
	# Stage 5b: the monocle, sight zones, being glimpsed, hiding and a search, contact
	await _show(dir, "10-monocle-on-dresser", "09:00", "grandparents_bedroom", Vector2(0.12, 0.22))
	_act_now()
	_stage.show_cones = true
	await _show(dir, "11-kitchen-sight-zones", "09:20", "kitchen", Vector2(0.15, 0.92))
	var cook: Dictionary = _stage.layout.person(_sim.routines[2], 2, "kitchen", _sim.routines)
	_navigator.place("kitchen", Vector2(cook["uv"]) + Vector2(cook["facing"]).rotated(deg_to_rad(-50.0)) * 0.3)
	_stealth.observe()
	await _show(dir, "12-glimpsed-grandma-turns", "09:21", "kitchen", _navigator.uv)
	_navigator.place("kitchen", Vector2(0.62, 0.10))
	_stealth.hide(_nearest_hiding_spot())
	await _show(dir, "13-hidden-grandma-searches", "09:23", "kitchen", _navigator.uv)
	_stealth.unhide()
	await _show(dir, "14-deep-contact", "09:40", "kitchen", Vector2(cook["uv"]) + Vector2(cook["facing"]) * 0.12)
	_stealth.observe()
	await _show(dir, "15-ghost-back-in-hall", "09:41", _navigator.room_id, _navigator.uv)
	# Stage 5c: the family walking (next morning), half a game minute after each room change;
	# sight zones on, so they show sight following the walk.
	# Stage 6: the tour reaches day 3 here; the dawn day card.
	_keep_day_card = true
	await _show(dir, "26-day-card-dawn", "06:00", "hall", Vector2(0.5, 0.75))
	_keep_day_card = false
	await _show(dir, "16-family-down-the-stairs", "07:04", "hall", Vector2(0.95, 0.95), "06:58", 0.5)
	await _show(dir, "17-family-to-the-table", "07:05", "dining_room", Vector2(0.95, 0.95), "07:04", 0.5)
	await _show(dir, "18-mother-into-the-kitchen", "08:01", "kitchen", Vector2(0.05, 0.95), "07:58", 1.0)
	await _show(dir, "19-children-round-the-beds", "08:05", "children_bedroom", Vector2(0.05, 0.95), "08:03", 0.5)
	# Stage 5d: harm takes time (ring half full on the stove), energy lost to contact, and
	# too little energy for the stove.
	_stage.show_cones = false
	_energy.value = _energy.max_value()   # earlier contacts in the tour drained it
	_goto("08:40", "kitchen", Vector2(0.80, 0.42))
	_act()
	_casting.update(_casting.minutes_left() * 0.5)
	await _show(dir, "20-stove-harm-half-done", "08:40", "kitchen", Vector2(0.80, 0.42))
	_casting.cancel()
	_energy.value = 60.0
	_energy.penalize("deep")
	await _show(dir, "21-energy-lost-to-contact", "08:41", "kitchen", Vector2(0.5, 0.95))
	_energy.value = 12.0
	_goto("08:42", "kitchen", Vector2(0.80, 0.42))
	_act()
	await _show(dir, "22-not-enough-energy-for-stove", "08:42", "kitchen", Vector2(0.80, 0.42))
	# Search and loot (2026-11-15): hidden in the living-room sofa, searched; the photo taken.
	_energy.value = _energy.max_value()
	_goto("09:30", "living_room", Vector2(0.38, 0.36))
	_toggle_hide()
	_act()
	_loot.hold(true)
	_loot.update(9999.0, _sim.clock.total_minutes)
	await _show(dir, "23-sofa-searched-grid", "09:30", "living_room", Vector2(0.38, 0.36))
	_take_loot(_loot.grid().find("lore_photo"))
	await _show(dir, "24-photo-note", "09:30", "living_room", Vector2(0.38, 0.36))
	_hud._note.visible = false
	_hud.toggle_journal(_journal_entries())
	await _show(dir, "25-journal", "09:30", "living_room", Vector2(0.38, 0.36))
	_hud.toggle_journal(_journal_entries())
	_loot.close()
	_hud.hide_loot_grid()
	_stealth.unhide()
	# Stage 6 (still day 3): the family-resolve bar low, then the win summary.
	for routine: NpcRoutine in _sim.routines:
		_sim.morale.set_morale(routine.schedule.npc_id, 30)
	_hud.refresh()
	_hud.set_family_hover(true)
	await _show(dir, "27-family-resolve-low", "09:35", "hall", Vector2(0.5, 0.75))
	_hud.set_family_hover(false)
	for routine: NpcRoutine in _sim.routines:
		_sim.morale.set_morale(routine.schedule.npc_id, 18)
	_show_outcome_if_over()
	await _show(dir, "28-win-summary", "09:36", "hall", Vector2(0.5, 0.75))
	get_tree().quit()


## Stage 6 capture: three days with a ghost that does nothing; the scenario ends lost at
## midnight of day 3 and the summary is saved.
func _run_loss_capture(dir: String) -> void:
	await _show(dir, "29a-day-1-start", "06:00", "hall", Vector2(0.5, 0.75))
	while not _sim.is_over():
		_sim.advance(1.0)
	_show_outcome_if_over()
	await _show(dir, "29-loss-summary", "00:00", "hall", Vector2(0.5, 0.75))


## Art test capture (2026-11-15): the living room at night, cozy (lamp lit, window shut,
## fire burning), then haunted (lamp out, window open, fire out) — same moment, same people,
## same camera; only the room's state differs. Changed through the same rules the ghost's
## actions use, without advancing time.
func _run_art_test(dir: String) -> void:
	# Art Phase 2: the run-down start — dirty, cold rooms (dust, stains, cobwebs, motes in the
	# window light, frost and a draught at the open window, cold corners; breath on the cook).
	await _show(dir, "00-run-down-morning-living-room", "06:30", "living_room", Vector2(0.5, 0.93))
	await _show(dir, "00b-run-down-morning-kitchen-breath", "06:40", "kitchen", Vector2(0.5, 0.93))
	# 21:30 — the family's evening in the living room (still daytime in the game's clock).
	await _show(dir, "01-cozy-evening-family", "21:30", "living_room", Vector2(0.5, 0.93))
	_stage.track_fire()   # the fire is burning; seen going out below (embers)
	_haunt_living_room()
	_stage.track_fire()
	await _show(dir, "02-haunted-evening-family", "21:30", "living_room", Vector2(0.5, 0.93))
	# 22:10 — night, the room empty: cozy, then fully haunted.
	_cozy_living_room()
	await _show(dir, "03-cozy-night", "22:10", "living_room", Vector2(0.5, 0.93))
	_haunt_living_room()
	await _show(dir, "04-haunted-night", "22:10", "living_room", Vector2(0.5, 0.93))
	await _show(dir, "05-haunted-night-ghost-at-lamp", "22:10", "living_room", Vector2(0.17, 0.8))
	# Art Phase 1 review: the ghost is depth-sorted with the furniture (behind the sofa, then
	# in front of it) and its glint when hidden in the sofa; cozy light.
	_cozy_living_room()
	await _show(dir, "06-cozy-night-ghost-behind-sofa", "22:10", "living_room", Vector2(0.38, 0.25))
	await _show(dir, "07-cozy-night-ghost-before-sofa", "22:10", "living_room", Vector2(0.38, 0.42))
	_navigator.place("living_room", Vector2(0.38, 0.36))
	_toggle_hide()
	await _show(dir, "08-cozy-night-ghost-hidden-in-sofa", "22:10", "living_room", _navigator.uv)


## Art test only: lamp out and window open, through the ghost's own rules.
func _haunt_living_room() -> void:
	GhostActions.act(_sim.house, "lamp_living_room")
	GhostActions.act(_sim.house, "window_living_room")


## Art test only: lamp lit and window shut again (what the family's repairs would do).
func _cozy_living_room() -> void:
	_sim.house.set_object_state("lamp_living_room", &"lit")
	_sim.house.set_object_state("window_living_room", &"closed")


## Capture only: starts the action on the highlighted object and lets it land at once.
func _act_now() -> void:
	_act()
	_casting.update(_casting.minutes_left() + 1.0)


## Capture only: runs the simulation to [param time_text], places the ghost and picks its target.
func _goto(time_text: String, room_id: String, at: Vector2) -> void:
	var target: int = GameClock.parse_time(time_text)
	while _sim.clock.minute_of_day() != target and not _sim.is_over():
		_sim.advance(1.0)
	_navigator.place(room_id, at)
	_update_view()


## Runs the simulation to [param time_text] (the next time it comes round), places the
## ghost and saves a screenshot. Everyone is settled at their spot, unless
## [param walk_from] is a time: then the run settles there and the family walks on, frame
## by frame, until [param time_text] and [param extra_minutes] past it (stage 5c walking shots).
func _show(dir: String, shot_name: String, time_text: String, room_id: String, at: Vector2, walk_from: String = "", extra_minutes: float = 0.0) -> void:
	var target: int = GameClock.parse_time(time_text)
	var settle_at: int = target if walk_from.is_empty() else GameClock.parse_time(walk_from)
	while _sim.clock.minute_of_day() != settle_at and not _sim.is_over():
		_sim.advance(1.0)
	_motion.settle()
	var extra: float = -1.0 if not walk_from.is_empty() else extra_minutes
	while extra < extra_minutes and not _sim.is_over():
		var minutes: float = _sim.clock.minutes_for(0.05)
		_sim.advance(0.05)
		_motion.update(minutes)
		if extra >= 0.0 or _sim.clock.minute_of_day() == target:
			extra = maxf(extra, 0.0) + minutes
	_navigator.place(room_id, at)
	if not _keep_day_card:
		_hud.hide_day_card()
	_stage.settle_mood()
	_update_view()
	for i: int in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
	print("captured ", shot_name)

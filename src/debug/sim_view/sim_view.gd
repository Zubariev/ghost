## DEBUG ONLY — not part of the game. A plan view of the house simulation: rooms as
## boxes (tinted by cleanliness), the family as tokens, object states, each person's
## activity, state and task, an event log, and controls that stand in for the ghost.
##
## Keys: Space pause · 1/2/3 ×1/×2/×4 · F debug fast-forward ×30 (debug only).
## Mouse on a room: click = dirty · right-click = cold on/off · Shift+click = dark on/off.
## Buttons: break/repair objects, hide groceries, and a DEBUG "−20 morale (all)".
## Run with `--capture=<dir>` for a scripted, deterministic run that saves screenshots.
extends Node2D

const LOG_LINES: int = 11
const DEBUG_FAST_SPEED: float = 30.0
const STATE_NAMES: Dictionary = {
	NpcRoutine.State.SCHEDULED: "idle",
	NpcRoutine.State.MOVING: "walking",
	NpcRoutine.State.PERFORMING: "doing it",
	NpcRoutine.State.WAITING: "WAITING",
	NpcRoutine.State.BROKEN: "BROKEN",
}
const NPC_COLORS: Array[Color] = [
	Color("6fa8dc"), Color("e06666"), Color("f0c36a"), Color("93c47d"), Color("b4a7d6"), Color("f6b26b"),
]
## object id -> [normal state, sabotaged state]
const REPAIRABLE: Dictionary = {
	"stove": [&"working", &"broken"],
	"computer": [&"working", &"broken"],
	"lamp_living_room": [&"lit", &"out"],
}
const BACKGROUND := Color("16141c")
const ROOM_FILL := {
	RoomState.Cleanliness.CLEAN: Color("2f3a33"),
	RoomState.Cleanliness.NORMAL: Color("2b2833"),
	RoomState.Cleanliness.DIRTY: Color("4a3424"),
}
const ROOM_EDGE := Color("6e6880")
const DOOR := Color("5f587a")
const TEXT := Color("e8e4f0")
const DIM_TEXT := Color("a29cb3")
const OK := Color("7fc98a")
const BAD := Color("e0735f")

var _sim: HouseSim
var _fast: bool = false
var _log_lines: Array[String] = []
var _status: Label
var _log: Label
var _object_buttons: Dictionary[String, Button] = {}
var _basket_button: Button
var _key_events: Array[String] = []


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	_sim = HouseSim.from_data_files()
	_connect_log()
	_build_panel()
	_sim.start()
	_refresh()
	var capture_dir: String = _capture_dir()
	if not capture_dir.is_empty():
		_run_capture(capture_dir)


func _process(delta: float) -> void:
	var seconds: float = delta * (DEBUG_FAST_SPEED if _fast else 1.0)
	if _sim.advance(seconds) > 0:
		_refresh()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse := event as InputEventMouseButton
		var point: Vector2 = get_global_mouse_position()
		for room: RoomState in _sim.house.rooms.values():
			if room.plan_rect.has_point(point):
				if mouse.button_index == MOUSE_BUTTON_RIGHT:
					_toggle_cold(room.id)
				elif mouse.button_index == MOUSE_BUTTON_LEFT and mouse.shift_pressed:
					_toggle_dark(room.id)
				elif mouse.button_index == MOUSE_BUTTON_LEFT:
					_make_dirty(room.id)
				return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_SPACE:
			_sim.clock.paused = not _sim.clock.paused
		KEY_1:
			_sim.clock.set_speed_index(0)
		KEY_2:
			_sim.clock.set_speed_index(1)
		KEY_3:
			_sim.clock.set_speed_index(2)
		KEY_F:
			_fast = not _fast
	_refresh()


# --- Drawing --------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-200, -200, 1680, 1120), BACKGROUND)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(20, 24), "DEBUG — house simulation (stage 4) · room: click dirty · right-click cold · Shift+click dark", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEXT)
	draw_string(font, Vector2(20, 60), "Upper floor", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM_TEXT)
	draw_string(font, Vector2(20, 280), "Ground floor", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM_TEXT)
	for room: RoomState in _sim.house.rooms.values():
		for other: RoomState in _sim.house.rooms.values():
			if room.id < other.id and _sim.house.walk_minutes(room.id, other.id) > 0:
				draw_line(room.plan_rect.get_center(), other.plan_rect.get_center(), DOOR, 2.0)
	for room: RoomState in _sim.house.rooms.values():
		draw_rect(room.plan_rect, ROOM_FILL[room.cleanliness])
		if room.light == RoomState.Light.DARK:
			draw_rect(room.plan_rect, Color(0, 0, 0, 0.55))
		var cold_room: bool = room.temperature == RoomState.Temperature.COLD
		draw_rect(room.plan_rect, Color("6fa8dc") if cold_room else ROOM_EDGE, false, 4.0 if cold_room else 2.0)
		draw_string(font, room.plan_rect.position + Vector2(8, 18), room.display_name, HORIZONTAL_ALIGNMENT_LEFT, room.plan_rect.size.x - 16, 13, TEXT)
		var clean_text: String = String(RoomState.Cleanliness.keys()[room.cleanliness]).to_lower()
		if cold_room:
			clean_text += " · COLD"
		if room.light == RoomState.Light.DARK:
			clean_text += " · DARK"
		draw_string(font, room.plan_rect.position + Vector2(8, 34), clean_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			BAD if room.cleanliness == RoomState.Cleanliness.DIRTY else DIM_TEXT)
		var line: int = 0
		for obj: ObjectState in _sim.house.objects.values():
			if obj.room_id == room.id:
				var color: Color = DIM_TEXT
				if obj.state in [&"broken", &"hidden", &"out", &"open"]:
					color = BAD
				elif obj.state in [&"working", &"available", &"ready", &"lit", &"closed"]:
					color = OK
				draw_string(font, room.plan_rect.position + Vector2(8, 52 + line * 15), "%s: %s" % [obj.display_name, obj.state],
					HORIZONTAL_ALIGNMENT_LEFT, room.plan_rect.size.x - 16, 11, color)
				line += 1
	_draw_tokens(font)
	_draw_outcome(font)


func _draw_outcome(font: Font) -> void:
	if not _sim.is_over():
		return
	draw_rect(Rect2(240, 110, 800, 300), Color(0.05, 0.04, 0.08, 0.94))
	draw_rect(Rect2(240, 110, 800, 300), TEXT, false, 2.0)
	var won: bool = _sim.morale.outcome == MoraleSystem.OUTCOME_WON
	var title: String = "THE FAMILY LEFT THE HOUSE — the ghost wins" if won else "DAY %d IS OVER — the family stays (lost)" % (_sim.clock.day_number() - 1)
	draw_string(font, Vector2(260, 150), title, HORIZONTAL_ALIGNMENT_LEFT, 760, 20, OK if won else BAD)
	draw_string(font, Vector2(260, 178), "Key events:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, DIM_TEXT)
	var shown: Array[String] = _key_events.slice(maxi(0, _key_events.size() - 11))
	for i: int in shown.size():
		draw_string(font, Vector2(260, 200 + i * 18), shown[i], HORIZONTAL_ALIGNMENT_LEFT, 760, 13, TEXT)


func _draw_tokens(font: Font) -> void:
	var per_room: Dictionary[String, int] = {}
	for i: int in _sim.routines.size():
		var routine: NpcRoutine = _sim.routines[i]
		var slot: int = per_room.get(routine.room_id, 0)
		per_room[routine.room_id] = slot + 1
		var pos: Vector2 = _slot_point(routine.room_id, slot)
		var walk: Dictionary = routine.get_walk_progress()
		if not walk.is_empty():
			pos = _slot_point(walk["from"], slot).lerp(_slot_point(walk["to"], slot), float(walk["t"]))
		var color: Color = NPC_COLORS[i % NPC_COLORS.size()]
		if routine.is_broken():
			color = Color("6b6578")
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-8, 0), pos + Vector2(8, 0), pos + Vector2(5, -20), pos + Vector2(-5, -20)]), color)
		draw_circle(pos + Vector2(0, -26), 6.0, color)
		if routine.is_broken():
			draw_string(font, pos + Vector2(-6, -36), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BAD)
		elif routine.state == NpcRoutine.State.WAITING:
			draw_string(font, pos + Vector2(-4, -36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BAD)
		draw_string(font, pos + Vector2(-24, 12), routine.schedule.display_name, HORIZONTAL_ALIGNMENT_CENTER, 48, 10, color)


func _slot_point(room_id: String, slot: int) -> Vector2:
	var rect: Rect2 = _sim.house.rooms[room_id].plan_rect
	return rect.position + Vector2(24 + (slot % 6) * 36, rect.size.y - 22)


# --- Panel and log -----------------------------------------------------------------

func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.position = Vector2(20, 486)
	panel.custom_minimum_size = Vector2(1240, 222)
	layer.add_child(panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 16)
	panel.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(760, 0)
	columns.add_child(left)
	_status = Label.new()
	_status.add_theme_font_size_override(&"font_size", 13)
	left.add_child(_status)
	var buttons := HBoxContainer.new()
	left.add_child(buttons)
	for object_id: String in REPAIRABLE:
		var button := Button.new()
		button.add_theme_font_size_override(&"font_size", 12)
		button.pressed.connect(_toggle_object.bind(object_id, REPAIRABLE[object_id][0], REPAIRABLE[object_id][1]))
		buttons.add_child(button)
		_object_buttons[object_id] = button
	_basket_button = Button.new()
	_basket_button.add_theme_font_size_override(&"font_size", 12)
	_basket_button.pressed.connect(_toggle_object.bind("grocery_basket", &"available", &"hidden"))
	buttons.add_child(_basket_button)
	var drain := Button.new()
	drain.text = "DEBUG −20 morale (all)"
	drain.add_theme_font_size_override(&"font_size", 12)
	drain.pressed.connect(_drain_all)
	buttons.add_child(drain)
	_log = Label.new()
	_log.add_theme_font_size_override(&"font_size", 11)
	_log.add_theme_color_override(&"font_color", DIM_TEXT)
	_log.custom_minimum_size = Vector2(440, 0)
	_log.clip_text = true
	columns.add_child(_log)


func _toggle_object(object_id: String, normal: StringName, sabotaged: StringName) -> void:
	var now: StringName = _sim.house.get_object_state(object_id)
	_sim.house.set_object_state(object_id, sabotaged if now == normal else normal)
	_add_log("[ghost stand-in] %s → %s" % [object_id, _sim.house.get_object_state(object_id)])
	_refresh()


func _toggle_cold(room_id: String) -> void:
	var cold: bool = _sim.house.rooms[room_id].temperature == RoomState.Temperature.COLD
	_sim.house.set_room_temperature(room_id, RoomState.Temperature.COMFORTABLE if cold else RoomState.Temperature.COLD)
	_add_log("[ghost stand-in] %s → %s" % [room_id, "comfortable" if cold else "COLD"])
	_refresh()


func _toggle_dark(room_id: String) -> void:
	var dark: bool = _sim.house.rooms[room_id].light == RoomState.Light.DARK
	_sim.house.set_room_light(room_id, RoomState.Light.BRIGHT if dark else RoomState.Light.DARK)
	_add_log("[ghost stand-in] %s → %s" % [room_id, "bright" if dark else "DARK"])
	_refresh()


func _drain_all() -> void:
	for routine: NpcRoutine in _sim.routines:
		var npc_id: String = routine.schedule.npc_id
		_sim.morale.set_morale(npc_id, _sim.morale.get_morale(npc_id) - 20)
	_add_log("[DEBUG] everyone −20 morale")
	_refresh()


func _make_dirty(room_id: String) -> void:
	_sim.house.set_room_cleanliness(room_id, RoomState.Cleanliness.DIRTY)
	_add_log("[ghost stand-in] %s → dirty" % room_id)
	_refresh()


func _refresh() -> void:
	var clock: GameClock = _sim.clock
	var lines: PackedStringArray = []
	lines.append("Day %d  %s  %s   ×%d%s%s      Space pause · 1/2/3 speed · F debug ×30" % [clock.day_number(),
		GameClock.format_time(clock.minute_of_day()), "day" if clock.is_day() else "night", clock.get_speed(),
		"  [DEBUG ×30]" if _fast else "", "  PAUSED" if clock.paused else ""])
	for routine: NpcRoutine in _sim.routines:
		var activity: Activity = routine.current
		var npc_morale: int = _sim.morale.get_morale(routine.schedule.npc_id)
		var bar: String = "█".repeat(npc_morale / 10) + "·".repeat(10 - npc_morale / 10)
		var text: String = "%-8s %3d %s  %s" % [routine.schedule.display_name, npc_morale, bar, activity.display_name if activity != null else "—"]
		text += " · " + String(STATE_NAMES[routine.state])
		if routine.current_task != null:
			text += " · task %s %d/%d" % [routine.current_task.key, routine.work_done_minutes, routine.get_job_work_minutes()]
		elif routine.is_idle():
			text += " · pottering (no task)"
		elif activity != null and activity.kind == Activity.Kind.WORK:
			text += " · %d/%d min" % [routine.work_done_minutes, activity.work_minutes]
		text += " · " + _sim.house.rooms[routine.room_id].display_name
		lines.append(text)
	_status.text = "\n".join(lines)
	for object_id: String in _object_buttons:
		var broken: bool = _sim.house.get_object_state(object_id) == REPAIRABLE[object_id][1]
		_object_buttons[object_id].text = ("Repair " if broken else "Break ") + _sim.house.objects[object_id].display_name
	_basket_button.text = "Return groceries" if _sim.house.get_object_state("grocery_basket") == &"hidden" else "Hide groceries"


func _connect_log() -> void:
	var names: Dictionary[String, String] = {}
	for routine: NpcRoutine in _sim.routines:
		names[routine.schedule.npc_id] = routine.schedule.display_name
	_sim.morale.morale_changed.connect(func(npc: String, value: int, delta: int, reason: String) -> void:
		if delta < 0 and reason != "set":
			_add_log("%s %d (%s) → %d" % [names[npc], delta, reason, value]))
	_sim.morale.npc_broke.connect(func(npc: String) -> void: _key_event("%s is BROKEN" % names[npc]))
	_sim.morale.npc_recovered.connect(func(npc: String) -> void: _key_event("%s recovered (15)" % names[npc]))
	_sim.morale.family_left.connect(func(_t: int) -> void: _key_event("All six at ≤10 at once — the family leaves"))
	_sim.morale.scenario_lost.connect(func(_t: int) -> void: _key_event("Last day ended without breaking the family"))
	for routine: NpcRoutine in _sim.routines:
		var who: String = routine.schedule.display_name
		routine.activity_skipped.connect(func(a: Activity, done: int) -> void: _add_log("%s SKIP %s (%d min done)" % [who, a.display_name, done]))
		routine.activity_waiting.connect(func(a: Activity, unmet: Array[Dictionary]) -> void: _add_log("%s waits: %s — %s" % [who, a.display_name, _describe(unmet)]))
		routine.task_started.connect(func(t: HouseTask) -> void: _add_log("%s starts %s (priority %d)" % [who, t.key, t.priority]))
		routine.task_completed.connect(func(t: HouseTask) -> void: _add_log("%s done %s" % [who, t.key]))


func _key_event(text: String) -> void:
	var line: String = "Day %d %s  %s" % [_sim.clock.day_number(), GameClock.format_time(_sim.clock.minute_of_day()), text]
	_key_events.append(line)
	_add_log(text)


func _describe(unmet: Array[Dictionary]) -> String:
	var parts: PackedStringArray = []
	for need: Dictionary in unmet:
		parts.append("%s=%s" % [need.get("object", need.get("room", "?")), need.get("state", "reachable")])
	return ", ".join(parts)


func _add_log(text: String) -> void:
	_log_lines.append("%s  %s" % [GameClock.format_time(_sim.clock.minute_of_day()), text])
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	if _log != null:
		_log.text = "\n".join(_log_lines)


# --- Scripted capture (verification only) ---------------------------------------

func _capture_dir() -> String:
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=")
	return ""


func _run_capture(dir: String) -> void:
	set_process(false)
	DirAccess.make_dir_recursive_absolute(dir)
	await _run_until("07:20")
	await _shot(dir, "01-family-breakfast")
	await _run_until("08:30")
	_toggle_object("lamp_living_room", &"lit", &"out")
	_toggle_object("stove", &"working", &"broken")
	_make_dirty("kitchen")
	_make_dirty("library")
	await _run_until("09:20")
	await _shot(dir, "02-father-repairs-stove-first")
	await _run_until("10:30")
	await _shot(dir, "03-lamp-next-grandma-cooking")
	await _run_until("14:20")
	await _shot(dir, "04-son-helps-cleaning")
	_toggle_cold("living_room")
	_toggle_dark("library")
	await _run_until("17:40")
	await _shot(dir, "05-cold-and-dark-penalties")
	for i: int in 4:
		_drain_all()
	await _run_until("18:00")
	await _shot(dir, "06-broken-members")
	_drain_all()
	await _run_until("18:01")
	await _shot(dir, "07-family-leaves")
	get_tree().quit()


## Advances the simulation minute by minute (at ×1) to the given time today, or until the
## scenario is over (the simulation stops advancing then).
func _run_until(time_text: String) -> void:
	var target: int = GameClock.parse_time(time_text)
	while _sim.clock.minute_of_day() != target and not _sim.is_over():
		_sim.advance(1.0)
	_refresh()
	queue_redraw()
	await get_tree().process_frame


func _shot(dir: String, shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))
	print("captured ", shot_name)

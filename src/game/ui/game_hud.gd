## The in-game HUD (stage 5a): clock and speed, each family member's morale, the ghost's
## prompt, a short event log, a house overview map, and the end-of-scenario banner.
## Stage 5d: the ghost's energy bar under the room name — the number shows while the mouse is
## over it; it flashes red with the amount when energy is lost to being seen, flashes when an
## action cannot be afforded, and pulses red while energy is low.
## Loot (2026-11-15): the searched spot's grid (click a slot to take it), the inventory line
## under the energy bar, a lore note when one is found, and the journal of finds (J).
## Stage 6 (Demo Spec §10.4): the family-resolve bar (the family average, with a mark at the
## leaving threshold; the number while the mouse is over it; it flashes when it drops), the
## day card at each dawn, and the end summary (outcome, when, the ghost's stats, key events,
## Play again / To title).
## HUD layout (user decision 2026-11-15): energy top left (under the clock); the family-resolve
## bar top right, left of the house map; the map only once the ghost has found it (library);
## collected materials in a bottom-centre slot bar (count badges; flashes red when full); no
## per-person morale and no event log at the bottom: ghost messages show briefly above the slot
## bar, per-person morale changes float above that person in the room (RoomStage). The controls
## help shows for the first HELP_FIRST_SECONDS, while H is held and while paused.
## All text goes through tr() (assets/i18n/strings.csv). Reads the simulation; never changes it.
class_name GameHud
extends CanvasLayer

## A loot grid slot was clicked.
signal slot_clicked(index: int)
## The end summary's buttons.
signal restart_requested()
signal title_requested()

const TOAST_SECONDS: float = 3.0
const HELP_FIRST_SECONDS: float = 20.0
const BAR_SLOT_SIZE := Vector2(46, 46)
const BAR_SLOT_GAP: float = 6.0
const SCREEN_RIGHT: float = 1266.0
const MAP_POS := Vector2(1036, 8)
const MAP_SIZE := Vector2(236, 120)
const SLOT_SIZE := Vector2(52, 52)
const ENERGY_BAR_SIZE := Vector2(232, 16)
const ENERGY_FLASH_SECONDS: float = 1.2
const ENERGY_COLOR := Color(0.62, 0.86, 1.0)
const ENERGY_LOW_COLOR := Color(0.95, 0.42, 0.36)
const FAMILY_BAR_SIZE := Vector2(300, 18)
const FAMILY_COLOR := Color(0.85, 0.72, 0.5)
const DAY_CARD_SECONDS: float = 3.5
const DAY_CARD_FADE_SECONDS: float = 1.0
const SUMMARY_KEY_EVENTS: int = 8
const NPC_COLORS: Dictionary = {
	"father": Color("6fa8dc"), "mother": Color("93c47d"), "grandma": Color("c27ba0"),
	"grandpa": Color("d5a66a"), "son": Color("e06666"), "daughter": Color("f1c232"),
}

var _sim: HouseSim
var _navigator: GhostNavigator
var _clock: Label
var _room: Label
var _energy_bar: Control
var _energy: GhostEnergy
var _energy_hover: bool = false
## Seconds left of the red "energy lost" flash, and the amount shown with it.
var _lost_flash: float = 0.0
var _lost_amount: float = 0.0
## Seconds left of the "cannot afford" flash.
var _short_flash: float = 0.0
var _time: float = 0.0
var _slot_panel: PanelContainer
var _slot_row: HBoxContainer
## Per bar slot: [icon, count, name]; empty array = empty slot.
var _slot_entries: Array = []
## Seconds left of the "slots full" flash.
var _slots_full_flash: float = 0.0
var _toast: Label
var _toast_left: float = 0.0
var _help: Label
var _help_hint: Label
var _help_held: bool = false
var _family_panel: PanelContainer
## Morale texts floating above people, drawn here so the room's darkness never dims them.
var _float_layer: Control
var _float_source: Callable
var _loot_panel: PanelContainer
var _loot_grid: GridContainer
var _loot_slots: Array[String] = []
var _loot_icons: Dictionary = {}
var _note: PanelContainer
var _note_text: Label
var _journal: PanelContainer
var _journal_text: Label
var _paused: Label
var _prompt: Label
var _map: Control
var _banner: PanelContainer
var _banner_text: Label
var _family_bar: Control
var _family_hover: bool = false
var _family_last: float = -1.0
## Seconds left of the "resolve dropped" flash.
var _family_flash: float = 0.0
var _day_card: PanelContainer
var _day_card_title: Label
var _day_card_sub: Label
var _day_card_left: float = 0.0


func setup(sim: HouseSim, navigator: GhostNavigator) -> void:
	_sim = sim
	_navigator = navigator
	var top := _panel(Vector2(14, 10), Vector2(250, 0))
	_clock = _label(top, 24, Color(1, 0.95, 0.85))
	_room = _label(top, 16, Color(0.85, 0.85, 0.9))
	_energy_bar = Control.new()
	_energy_bar.custom_minimum_size = ENERGY_BAR_SIZE
	_energy_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_energy_bar.mouse_entered.connect(func() -> void: _energy_hover = true)
	_energy_bar.mouse_exited.connect(func() -> void: _energy_hover = false)
	_energy_bar.draw.connect(_draw_energy)
	_energy_bar.visible = false
	top.get_child(0).add_child(_energy_bar)
	_loot_panel = _panel(Vector2.ZERO, Vector2.ZERO)
	_loot_grid = GridContainer.new()
	_loot_grid.add_theme_constant_override(&"h_separation", 4)
	_loot_grid.add_theme_constant_override(&"v_separation", 4)
	_loot_panel.add_child(_loot_grid)
	_loot_panel.visible = false
	_note = _panel(Vector2(340, 200), Vector2(600, 0))
	_note_text = _label(_note, 18, Color(0.95, 0.9, 0.78))
	_note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_text.custom_minimum_size = Vector2(580, 0)
	_note.visible = false
	_note.mouse_filter = Control.MOUSE_FILTER_STOP
	_note.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_note.visible = false)
	_journal = _panel(Vector2(240, 110), Vector2(800, 0))
	_journal_text = _label(_journal, 15, Color(0.95, 0.9, 0.78))
	_journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_text.custom_minimum_size = Vector2(780, 0)
	_journal.visible = false
	# Controls help: in the top band between the energy panel and the family bar, above the
	# room (it covered the back wall at y 140); shown at the start, while H is held or paused.
	_help = _label(self, 13, Color(1, 1, 1, 0.85))
	_help.text = tr("HELP_LINE")
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help.custom_minimum_size = Vector2(620, 0)
	_help.size = Vector2(620, 0)
	_help.position = Vector2(310, 10)
	_help.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_help.add_theme_constant_override(&"outline_size", 5)
	_help_hint = _label(self, 12, Color(1, 1, 1, 0.55))
	_help_hint.text = tr("HELP_HINT")
	_help_hint.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_help_hint.add_theme_constant_override(&"outline_size", 4)
	_help_hint.reset_size()
	_help_hint.position = Vector2(SCREEN_RIGHT - _help_hint.size.x, 694)
	_help_hint.visible = false
	_paused = _label(self, 40, Color(1, 0.85, 0.5))
	_paused.text = tr("PAUSED")
	_paused.position = Vector2(560, 300)
	_prompt = _label(self, 19, Color(0.85, 0.97, 1))
	_prompt.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override(&"outline_size", 6)
	_prompt.visible = false
	# Collected materials: bottom-centre slot bar.
	_slot_panel = _panel(Vector2.ZERO, Vector2.ZERO)
	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override(&"separation", int(BAR_SLOT_GAP))
	_slot_panel.add_child(_slot_row)
	set_slots(10, [])
	_toast = _label(self, 16, Color(0.92, 0.96, 1.0))
	_toast.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	_toast.add_theme_constant_override(&"outline_size", 5)
	_toast.visible = false
	_float_layer = Control.new()
	_float_layer.size = Vector2(1280, 720)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_float_layer.draw.connect(_draw_floats)
	add_child(_float_layer)
	move_child(_float_layer, 0)   # under the panels
	_map = Control.new()
	_map.position = MAP_POS
	_map.size = MAP_SIZE
	_map.draw.connect(_draw_map)
	_map.visible = false
	add_child(_map)
	var family := _panel(Vector2(0, 10), Vector2(0, 0))
	_family_panel = family
	_family_bar = Control.new()
	_family_bar.custom_minimum_size = FAMILY_BAR_SIZE
	_family_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_family_bar.mouse_entered.connect(func() -> void: _family_hover = true)
	_family_bar.mouse_exited.connect(func() -> void: _family_hover = false)
	_family_bar.draw.connect(_draw_family)
	family.add_child(_family_bar)
	family.mouse_filter = Control.MOUSE_FILTER_PASS
	_place_family()
	_day_card = _panel(Vector2(390, 230), Vector2(500, 0))
	_day_card_title = _label(_day_card, 44, Palette.SB_CANDLELIGHT)
	_day_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_card_sub = _label(_day_card, 17, Palette.SB_CREAM)
	_day_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_card.visible = false
	_banner = _panel(Vector2(240, 90), Vector2(800, 0))
	_banner_text = _label(_banner, 17, Color(1, 0.95, 0.85))
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_text.custom_minimum_size = Vector2(780, 0)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.get_child(0).add_child(buttons)
	for entry: Array in [[tr("BTN_RESTART"), restart_requested], [tr("BTN_TITLE"), title_requested]]:
		var button := Button.new()
		button.text = String(entry[0])
		button.add_theme_font_size_override(&"font_size", 18)
		button.custom_minimum_size = Vector2(200, 42)
		var requested: Signal = entry[1]
		button.pressed.connect(func() -> void: requested.emit())
		buttons.add_child(button)
	_banner.visible = false


func refresh() -> void:
	var clock: GameClock = _sim.clock
	_clock.text = "%s  %s · %s   %s" % [tr("DAY_N") % clock.day_number(), GameClock.format_time(clock.minute_of_day()),
		tr("PHASE_DAY") if clock.is_day() else tr("PHASE_NIGHT"), tr("SPEED_X") % clock.get_speed()]
	_room.text = _sim.house.rooms[_navigator.room_id].display_name
	_paused.visible = clock.paused
	_energy_bar.queue_redraw()
	if _map.visible:
		_map.queue_redraw()
	var average: float = _sim.morale.family_average()
	if _family_last >= 0.0 and average < _family_last:
		_family_flash = ENERGY_FLASH_SECONDS
	_family_last = average
	_family_bar.queue_redraw()


## Shows [param energy] as the bar (stage 5d).
func set_energy(energy: GhostEnergy) -> void:
	_energy = energy
	_energy_bar.visible = true
	energy.lost.connect(func(amount: float, reason: String) -> void:
		if reason == "peripheral" or reason == "deep":
			_lost_flash = ENERGY_FLASH_SECONDS
			_lost_amount = amount)


## Shows the searched spot's grid above [param screen_point]: [param slots] item ids ("" =
## empty), [param icons] / [param names] look-ups by item id. Clicking a slot emits
## [signal slot_clicked].
func show_loot_grid(slots: Array[String], screen_point: Vector2, icons: Dictionary, names: Dictionary) -> void:
	_loot_slots = slots
	_loot_icons = icons
	_loot_grid.columns = 3 if slots.size() > 4 else 2
	for child: Node in _loot_grid.get_children():
		_loot_grid.remove_child(child)
		child.queue_free()
	for i: int in slots.size():
		var slot := Control.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.tooltip_text = String(names.get(slots[i], ""))
		slot.draw.connect(_draw_slot.bind(slot, i))
		slot.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
				slot_clicked.emit(i))
		_loot_grid.add_child(slot)
	var columns: int = _loot_grid.columns
	var size := Vector2(columns * (SLOT_SIZE.x + 4) + 16, ceili(float(slots.size()) / columns) * (SLOT_SIZE.y + 4) + 16)
	_loot_panel.reset_size()
	_loot_panel.position = screen_point - Vector2(size.x * 0.5, size.y)
	_loot_panel.visible = true


## Updates the open grid after a slot was emptied.
func update_loot_grid(slots: Array[String]) -> void:
	_loot_slots = slots
	for child: Node in _loot_grid.get_children():
		(child as Control).queue_redraw()


func hide_loot_grid() -> void:
	_loot_panel.visible = false
	_loot_slots = []


func is_loot_grid_open() -> bool:
	return _loot_panel.visible


## The bottom slot bar: [param slot_count] slots; [param entries] fill them from the left,
## each [icon, count, name].
func set_slots(slot_count: int, entries: Array) -> void:
	_slot_entries = entries
	if _slot_row.get_child_count() != slot_count:
		for child: Node in _slot_row.get_children():
			_slot_row.remove_child(child)
			child.queue_free()
		for i: int in slot_count:
			var slot := Control.new()
			slot.custom_minimum_size = BAR_SLOT_SIZE
			slot.mouse_filter = Control.MOUSE_FILTER_PASS
			slot.draw.connect(_draw_bar_slot.bind(slot, i))
			_slot_row.add_child(slot)
		_slot_panel.reset_size()
		var width: float = slot_count * BAR_SLOT_SIZE.x + maxi(0, slot_count - 1) * BAR_SLOT_GAP + 16.0
		_slot_panel.position = Vector2(640.0 - width * 0.5, 720.0 - BAR_SLOT_SIZE.y - 16.0 - 8.0)
	for i: int in _slot_row.get_child_count():
		var slot := _slot_row.get_child(i) as Control
		slot.tooltip_text = String(entries[i][2]) if i < entries.size() else ""
		slot.queue_redraw()


## Where the floating texts come from: a Callable returning RoomStage.visible_floats().
func set_float_source(source: Callable) -> void:
	_float_source = source


func _process(_delta: float) -> void:
	if _float_source.is_valid():
		_float_layer.queue_redraw()


func _draw_floats() -> void:
	if not _float_source.is_valid():
		return
	var font: Font = ThemeDB.fallback_font
	var size: int = 15
	for f: Dictionary in _float_source.call():
		var text: String = String(f["text"])
		var alpha: float = float(f["alpha"])
		var at: Vector2 = Vector2(f["at"]) - Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, 0.0)
		_float_layer.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, 0.85 * alpha))
		_float_layer.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(f["color"], alpha))


## Flashes the slot bar red: every slot is in use, a new kind cannot be taken.
func flash_slots_full() -> void:
	_slots_full_flash = ENERGY_FLASH_SECONDS


## Shows or hides the house map (top right) and moves the family bar beside it.
func show_map(on: bool) -> void:
	_map.visible = on
	_place_family()


## True while the house map is shown.
func is_map_shown() -> bool:
	return _map.visible


## While [param held] (H), the controls help shows.
func set_help_held(held: bool) -> void:
	_help_held = held


func _place_family() -> void:
	_family_panel.reset_size()
	var right: float = MAP_POS.x - 8.0 if _map.visible else SCREEN_RIGHT
	_family_panel.position = Vector2(right - _family_panel.size.x, 10)


func _draw_bar_slot(slot: Control, index: int) -> void:
	var rect := Rect2(Vector2.ZERO, slot.size)
	slot.draw_rect(rect, Color(0.12, 0.1, 0.13, 0.92))
	var border: Color = Color(Palette.SB_GOLD, 0.55)
	if _slots_full_flash > 0.0:
		border = border.lerp(ENERGY_LOW_COLOR, _slots_full_flash / ENERGY_FLASH_SECONDS)
	slot.draw_rect(rect, border, false, 1.5)
	if index >= _slot_entries.size():
		return
	var entry: Array = _slot_entries[index]
	ItemArt.draw(slot, String(entry[0]), rect.get_center() - Vector2(0, 2), rect.size.x * 0.78)
	var font: Font = ThemeDB.fallback_font
	var count: String = str(int(entry[1]))
	var at := Vector2(rect.size.x - 4.0 - font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, rect.size.y - 4.0)
	slot.draw_string_outline(font, at, count, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
	slot.draw_string(font, at, count, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.SB_CREAM)


## Shows a found lore note until clicked.
func show_note(title: String, text: String) -> void:
	_note_text.text = "%s\n\n%s\n\n%s" % [title, text, tr("NOTE_CLOSE")]
	_note.reset_size()
	_note.visible = true


## Opens or closes the journal of finds: [param entries] "title\ntext" per lore note.
func toggle_journal(entries: Array[String]) -> void:
	_journal.visible = not _journal.visible
	if _journal.visible:
		_journal_text.text = tr("JOURNAL_TITLE") + "\n\n" + ("\n\n".join(entries) if not entries.is_empty() else tr("JOURNAL_EMPTY"))
		_journal.reset_size()


func _draw_slot(slot: Control, index: int) -> void:
	var rect := Rect2(Vector2.ZERO, slot.size)
	slot.draw_rect(rect, Color(0.12, 0.1, 0.13, 0.9))
	slot.draw_rect(rect, Color(Palette.SB_GOLD, 0.7), false, 1.5)
	if index < _loot_slots.size() and not _loot_slots[index].is_empty():
		ItemArt.draw(slot, String(_loot_icons.get(_loot_slots[index], "")), rect.get_center(), rect.size.x * 0.8)


## Flashes the bar: an action could not be afforded.
func flash_not_enough_energy() -> void:
	_short_flash = ENERGY_FLASH_SECONDS


## Animates the energy bar's flashes and pulse; call every frame with real seconds.
func tick(delta: float) -> void:
	_time += delta
	_lost_flash = maxf(0.0, _lost_flash - delta)
	_short_flash = maxf(0.0, _short_flash - delta)
	_energy_bar.queue_redraw()
	if _slots_full_flash > 0.0:
		_slots_full_flash = maxf(0.0, _slots_full_flash - delta)
		for slot: Node in _slot_row.get_children():
			(slot as Control).queue_redraw()
	if _toast_left > 0.0:
		_toast_left = maxf(0.0, _toast_left - delta)
		_toast.modulate.a = clampf(_toast_left / 0.6, 0.0, 1.0)
		_toast.visible = _toast_left > 0.0
	_help.visible = _sim.clock.paused or _help_held or _time < HELP_FIRST_SECONDS
	_help_hint.visible = not _help.visible
	if _family_flash > 0.0:
		_family_flash = maxf(0.0, _family_flash - delta)
		_family_bar.queue_redraw()
	if _day_card_left > 0.0:
		_day_card_left = maxf(0.0, _day_card_left - delta)
		_day_card.modulate.a = clampf(_day_card_left / DAY_CARD_FADE_SECONDS, 0.0, 1.0)
		_day_card.visible = _day_card_left > 0.0


## The day card (stage 6): "Day N" and how the family is holding up; fades by itself.
func show_day_card(day: int) -> void:
	_day_card_title.text = tr("DAY_N") % day
	_day_card_sub.text = tr("DAY_CARD_SUB") % [roundi(_sim.morale.family_average()), _sim.morale.leave_threshold()]
	_day_card.reset_size()
	_day_card.position = Vector2(640 - _day_card.size.x * 0.5, 230)
	_day_card.modulate.a = 1.0
	_day_card.visible = true
	_day_card_left = DAY_CARD_SECONDS


func hide_day_card() -> void:
	_day_card_left = 0.0
	_day_card.visible = false


## Shows the number on the family bar as if hovered (capture only).
func set_family_hover(on: bool) -> void:
	_family_hover = on
	_family_bar.queue_redraw()


func _draw_family() -> void:
	var font: Font = ThemeDB.fallback_font
	var label_width: float = 118.0
	var bar := Rect2(Vector2(label_width, 3), Vector2(FAMILY_BAR_SIZE.x - label_width, FAMILY_BAR_SIZE.y - 6))
	var max_value: float = 100.0
	var average: float = _sim.morale.family_average()
	var threshold: float = float(_sim.morale.leave_threshold())
	var color: Color = FAMILY_COLOR
	if _family_flash > 0.0:
		color = color.lerp(ENERGY_LOW_COLOR, _family_flash / ENERGY_FLASH_SECONDS)
	_family_bar.draw_string(font, Vector2(0, 14), tr("FAMILY_RESOLVE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.88, 0.75))
	_family_bar.draw_rect(bar, Color(0.15, 0.15, 0.2))
	_family_bar.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(average / max_value, 0.0, 1.0), bar.size.y)), color)
	var mark_x: float = bar.position.x + bar.size.x * threshold / max_value
	_family_bar.draw_line(Vector2(mark_x, 0), Vector2(mark_x, FAMILY_BAR_SIZE.y), ENERGY_LOW_COLOR, 2.0)
	_family_bar.draw_rect(bar, Color(0.6, 0.58, 0.5), false, 1.5)
	if _family_hover:
		var value_text: String = tr("FAMILY_RESOLVE_VALUE") % [roundi(average), int(threshold)]
		_family_bar.draw_string_outline(font, Vector2(mark_x + 6, 13), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0, 0, 0, 0.9))
		_family_bar.draw_string(font, Vector2(mark_x + 6, 13), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.97, 0.9))


func _draw_energy() -> void:
	if _energy == null:
		return
	var font: Font = ThemeDB.fallback_font
	var label_width: float = 70.0
	var bar := Rect2(Vector2(label_width, 3), Vector2(ENERGY_BAR_SIZE.x - label_width, ENERGY_BAR_SIZE.y - 6))
	var fill: float = clampf(_energy.value / _energy.max_value(), 0.0, 1.0)
	var color: Color = ENERGY_COLOR
	if _energy.is_low():
		color = ENERGY_LOW_COLOR.lerp(Color(1, 0.75, 0.6), 0.5 + 0.5 * sin(_time * 6.0))
	if _lost_flash > 0.0:
		color = color.lerp(ENERGY_LOW_COLOR, _lost_flash / ENERGY_FLASH_SECONDS)
	_energy_bar.draw_string(font, Vector2(0, 13), tr("ENERGY_LABEL"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		ENERGY_LOW_COLOR if _energy.is_low() else Color(0.8, 0.9, 1.0, 0.9))
	_energy_bar.draw_rect(bar, Color(0.15, 0.15, 0.2))
	_energy_bar.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), color)
	var outline: Color = Color(1, 0.9, 0.5) if _short_flash > 0.0 and fmod(_short_flash, 0.3) > 0.15 else Color(0.6, 0.62, 0.72)
	_energy_bar.draw_rect(bar, outline, false, 1.5 if _short_flash <= 0.0 else 2.5)
	if _energy_hover:
		var value_text: String = tr("ENERGY_VALUE") % [roundi(_energy.value), roundi(_energy.max_value())]
		_energy_bar.draw_string_outline(font, bar.position + Vector2(6, 9), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0, 0, 0, 0.9))
		_energy_bar.draw_string(font, bar.position + Vector2(6, 9), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.97, 0.9))
	if _lost_flash > 0.0:
		var rise: float = (1.0 - _lost_flash / ENERGY_FLASH_SECONDS) * 10.0
		_energy_bar.draw_string(font, Vector2(bar.end.x - 30, 12 - rise), "−%d" % roundi(_lost_amount),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(ENERGY_LOW_COLOR, _lost_flash / ENERGY_FLASH_SECONDS))


## Shows [param text] above [param screen_point]; empty hides it. Unavailable text is grey.
func set_prompt(text: String, screen_point: Vector2, available: bool) -> void:
	_prompt.visible = not text.is_empty()
	if text.is_empty():
		return
	_prompt.text = text
	_prompt.modulate = Color(1, 1, 1) if available else Color(0.7, 0.7, 0.7, 0.85)
	_prompt.reset_size()
	_prompt.position = screen_point - Vector2(_prompt.size.x * 0.5, 40)


## A short ghost message above the slot bar; fades after TOAST_SECONDS (no event log).
func add_log(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast.reset_size()
	_toast.position = Vector2(640.0 - _toast.size.x * 0.5, _slot_panel.position.y - _toast.size.y - 6.0)
	_toast_left = TOAST_SECONDS


## The end summary (stage 6): outcome, when it ended, the family's final resolve, what the
## ghost did ([param stats]) and the last key events; Play again / To title below.
func show_outcome(won: bool, key_events: Array[String], stats: GhostStats) -> void:
	hide_day_card()
	var clock: GameClock = _sim.clock
	var title: String = tr("WIN_TITLE") if won else tr("LOSS_TITLE") % _sim.morale.scenario_days()
	var day: int = mini(clock.day_number(), _sim.morale.scenario_days())
	var time_text: String = GameClock.format_time(clock.minute_of_day()) if won else "24:00"
	var lines: Array[String] = [title, tr("SUMMARY_WHEN") % [tr("DAY_N") % day, time_text],
		tr("SUMMARY_FAMILY") % [roundi(_sim.morale.family_average()), _sim.morale.leave_threshold()], ""]
	lines.append(tr("SUMMARY_GHOST"))
	var kinds: Array[String] = []
	for key: String in stats.action_keys():
		kinds.append(tr("SUMMARY_ACTION_LINE") % [tr("SUMMARY_KIND_" + key), stats.actions_of(key)])
	lines.append(tr("SUMMARY_ACTIONS") % stats.total_actions() + ("  (" + " · ".join(kinds) + ")" if not kinds.is_empty() else ""))
	lines.append(tr("SUMMARY_SEEN") % [stats.noticed, stats.caught])
	lines.append(tr("SUMMARY_FINDS") % [stats.items_found, stats.notes_found])
	lines.append(tr("SUMMARY_ENERGY") % [roundi(stats.energy_spent), roundi(stats.energy_lost)])
	lines.append("")
	lines.append(tr("KEY_EVENTS"))
	if key_events.is_empty():
		lines.append(tr("KEY_EVENTS_NONE"))
	lines.append_array(key_events.slice(maxi(0, key_events.size() - SUMMARY_KEY_EVENTS)))
	_banner_text.text = "\n".join(lines)
	_banner.reset_size()
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

## The crafting screen: looking straight into the old tree's hollow (sprint 001, phase D,
## 2026-11-26; user brief items 3 to 7). Opened by holding E next to the tree in the back yard.
##
## Layout (1280 × 720): the hollow's bark rim fills the screen; in its dark middle an inverted
## pentagram with an ingredient slot on each of its five points and the result slot at its centre.
## Left: the recipe list (locked recipes show as "???" with the level that opens them) and the
## selected recipe's needs. Bottom: the ghost's slot bar, with the Craft button just above it.
## Top right: the tree's level and its next upgrade.
##
## Every action goes through [CraftingBoard] and [GhostLoot]; the screen keeps no state of its own
## and redraws from them on every change, so it cannot drift from the inventory.
## [br]- Drag one unit from the bottom bar onto a point: [method CraftingBoard.place_unit].
## [br]- Click a point, or drag it onto the bottom bar: one unit back ([method CraftingBoard.return_unit]).
## [br]- Click the centre, or drag it onto the bottom bar: the result to the inventory.
## [br]- E or Esc closes; the board is emptied back into the inventory as far as it fits.
class_name CraftingScreen
extends CanvasLayer

## The screen closed. [param all_returned]: false when some units stayed in the hollow.
signal closed(all_returned: bool)
## A root node was unlocked on the roots screen (sprint 002, P5).
signal node_unlocked(id: String)
## Something to tell the player (shown on the screen; the game may log it too).
signal message(text: String)

const SCREEN := Vector2(1280, 720)
const CENTRE := Vector2(660, 300)
const STAR_RADIUS: float = 165.0
const POINT_SLOT := Vector2(64, 64)
const RESULT_SLOT := Vector2(84, 84)
const BAR_SLOT := Vector2(52, 52)
const BAR_GAP: float = 6.0
const BAR_Y: float = 640.0
const LIST_RECT := Rect2(24, 70, 300, 600)
## Drag data from a pentagram point / the centre (the bottom bar uses [constant GameHud.DRAG_UNIT]).
const DRAG_BOARD_UNIT: String = "board_unit"
const DRAG_RESULT: String = "board_result"

var _board: CraftingBoard
var _loot: GhostLoot
var _selected: String = ""
var _root: Control
var _back: Control
var _points: Array[Control] = []
var _centre: Control
var _bar: Array[Control] = []
var _bar_items: Array[String] = []
var _list: VBoxContainer
var _details: Label
var _craft_button: Button
var _upgrade_button: Button
var _level: Label
var _upgrade_cost: Label
var _feedback: Label
## The tree's roots (sprint 002, P5; design/ux/roots-progression.md): opened from here with the
## "Коріння" button or R; null progression = no roots button.
var _progression: CraftingProgression
var _roots: RootsScreen
## "Менше руху" (settings): passed on to the roots screen.
var reduced_motion: bool = false


func _ready() -> void:
	layer = 4
	visible = false


## True while the hollow is shown.
func is_open() -> bool:
	return visible


## Opens the hollow on [param board], moving units with [param loot]; [param progression] adds
## the way down to the roots.
func open(board: CraftingBoard, loot: GhostLoot, progression: CraftingProgression = null) -> void:
	if visible:
		return
	_board = board
	_loot = loot
	_progression = progression
	_build()
	visible = true
	_board.changed.connect(_refresh)
	_loot.inventory_changed.connect(_refresh)
	if _selected.is_empty() and not _board.recipes().is_empty():
		_selected = String(_board.recipes()[0]["id"])
	_refresh()


## Returns the board to the inventory as far as it fits and closes.
func close() -> void:
	if not visible:
		return
	if roots_open():
		_roots.close()
	var all_back: bool = _board.return_all()
	if _board.changed.is_connected(_refresh):
		_board.changed.disconnect(_refresh)
	if _loot.inventory_changed.is_connected(_refresh):
		_loot.inventory_changed.disconnect(_refresh)
	visible = false
	if _root != null:
		_root.queue_free()
		_root = null
	closed.emit(all_back)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or roots_open():
		return   # the roots screen, on top, takes the keys while it is open
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R and _progression != null:   # physical key: works on Ukrainian layouts
		get_viewport().set_input_as_handled()
		open_roots()
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


# --- Actions (also used by tests and captures) ----------------------------------------------

## Opens the roots screen over the hollow (when a progression was given).
func open_roots() -> void:
	if _progression == null or roots_open():
		return
	if _roots == null:
		_roots = RootsScreen.new()
		add_child(_roots)
		_roots.closed.connect(_refresh)
		_roots.node_unlocked.connect(func(id: String) -> void: node_unlocked.emit(id))
		_roots.message.connect(_say)
	_roots.open(_progression, _loot, reduced_motion)


func roots_open() -> bool:
	return _roots != null and _roots.is_open()


func roots_screen() -> RootsScreen:
	return _roots


## Drops one unit of [param item_id] on point [param index].
func place(index: int, item_id: String) -> bool:
	if _board.place_unit(index, item_id):
		return true
	var held: String = String(_board.slot(index)["item"])
	if not held.is_empty() and held != item_id:
		_say(tr("CRAFT_ONE_KIND"))
	return false


## Takes one unit off point [param index] back to the bar.
func take_back(index: int) -> bool:
	if _board.return_unit(index):
		return true
	if int(_board.slot(index)["count"]) > 0:
		_say(tr("CRAFT_LEFT_ON_BOARD"))
	return false


## Moves the result to the bar.
func take_result() -> bool:
	if _board.take_result():
		return true
	if int(_board.result()["count"]) > 0:
		_say(tr("CRAFT_RESULT_FULL"))
	return false


## Crafts the selected recipe.
func craft() -> bool:
	if not _board.craft(_selected):
		if _board.has_ingredients(_selected) and _board.is_unlocked(_selected):
			_say(tr("CRAFT_RESULT_BLOCKED"))
		return false
	var r: Dictionary = _board.recipe(_selected)
	_say(tr("CRAFT_MADE") % tr(_loot.name_key(String(r["result"]))))
	return true


func upgrade() -> bool:
	if not _board.upgrade():
		return false
	_say(tr("CRAFT_UPGRADED"))
	return true


func select(recipe_id: String) -> void:
	_selected = recipe_id
	_refresh()


func selected() -> String:
	return _selected


func craft_enabled() -> bool:
	return _craft_button != null and not _craft_button.disabled


func _say(text: String) -> void:
	if text.is_empty():
		return
	if _feedback != null:
		_feedback.text = text
	message.emit(text)


# --- Building -------------------------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_back = Control.new()
	_back.size = SCREEN
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.draw.connect(_draw_hollow.bind(_back))
	_root.add_child(_back)
	_points.clear()
	for i: int in _board.slot_count():
		var p := _slot_control(POINT_SLOT, star_point(i) - POINT_SLOT * 0.5)
		p.draw.connect(_draw_point.bind(p, i))
		p.gui_input.connect(_click.bind(func() -> void: take_back(i)))
		p.set_drag_forwarding(_drag_point.bind(p, i), _can_drop_point.bind(i), _drop_point.bind(i))
		_points.append(p)
	_centre = _slot_control(RESULT_SLOT, CENTRE - RESULT_SLOT * 0.5)
	_centre.draw.connect(_draw_centre.bind(_centre))
	_centre.gui_input.connect(_click.bind(func() -> void: take_result()))
	_centre.set_drag_forwarding(_drag_centre.bind(_centre), Callable(), Callable())
	# the bottom bar: drag a unit up; drop a point's unit or the result back on it
	_bar.clear()
	var count: int = _loot.slot_count()
	var width: float = count * BAR_SLOT.x + (count - 1) * BAR_GAP
	for i: int in count:
		var b := _slot_control(BAR_SLOT, Vector2(SCREEN.x * 0.5 - width * 0.5 + i * (BAR_SLOT.x + BAR_GAP), BAR_Y))
		b.draw.connect(_draw_bar_slot.bind(b, i))
		b.set_drag_forwarding(_drag_bar.bind(b, i), _can_drop_bar, _drop_bar)
		_bar.append(b)
	_craft_button = PlaqueButton.create(tr("CRAFT_BUTTON"), 220.0, 22)
	_craft_button.position = Vector2(SCREEN.x * 0.5 - 110.0, BAR_Y - 70.0)
	_craft_button.pressed.connect(func() -> void: craft())
	_root.add_child(_craft_button)
	_feedback = _label(Vector2(SCREEN.x * 0.5 - 300, BAR_Y - 104), 600, 15, Palette.SB_CANDLELIGHT)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# the left panel: recipes and the selected one's needs
	var panel := _label(LIST_RECT.position + Vector2(0, -44), LIST_RECT.size.x, 24, Palette.SB_CREAM)
	panel.text = tr("CRAFT_RECIPES")
	UiFonts.use(panel, "title")
	_list = VBoxContainer.new()
	_list.position = LIST_RECT.position
	_list.custom_minimum_size = Vector2(LIST_RECT.size.x, 0)
	_list.add_theme_constant_override(&"separation", 6)
	_root.add_child(_list)
	_details = _label(LIST_RECT.position + Vector2(0, 300), LIST_RECT.size.x, 15, Palette.SB_CREAM)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# the tree's level, its next upgrade, closing
	var title := _label(Vector2(SCREEN.x * 0.5 - 300, 14), 600, 28, Palette.SB_CREAM)
	title.text = tr("CRAFT_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.use(title, "title")
	_level = _label(Vector2(986, 70), 270, 17, Palette.SB_CREAM)
	_upgrade_cost = _label(Vector2(986, 98), 270, 14, Palette.SB_CREAM)
	_upgrade_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_button = PlaqueButton.create(tr("CRAFT_UPGRADE"), 260.0, 18)
	_upgrade_button.position = Vector2(986, 160)
	_upgrade_button.pressed.connect(func() -> void: upgrade())
	_root.add_child(_upgrade_button)
	var hint := _label(Vector2(986, 230), 270, 13, Color(Palette.SB_CREAM, 0.75))
	hint.text = tr("CRAFT_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _progression != null:   # the way down to the roots (sprint 002, P5)
		var roots_button := PlaqueButton.create(tr("ROOTS_BUTTON"), 150.0, 18)
		roots_button.position = Vector2(170, 12)
		roots_button.pressed.connect(open_roots)
		_root.add_child(roots_button)
	var close_label := _label(Vector2(986, 20), 270, 14, Color(Palette.SB_CREAM, 0.8))
	close_label.text = tr("CRAFT_CLOSE")
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _slot_control(size: Vector2, at: Vector2) -> Control:
	var c := Control.new()
	c.size = size
	c.position = at
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(c)
	return c


func _label(at: Vector2, width: float, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.custom_minimum_size = Vector2(width, 0)
	l.size = Vector2(width, 0)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override(&"outline_size", 4)
	_root.add_child(l)
	return l


func _click(event: InputEvent, action: Callable) -> void:
	# on release, so pressing to start a drag does not also take a unit back
	var click := event as InputEventMouseButton
	if click != null and not click.pressed and click.button_index == MOUSE_BUTTON_LEFT \
			and not _root.get_viewport().gui_is_dragging():
		action.call()


## Screen point of pentagram point [param index]: an inverted star, point 0 straight down.
static func star_point(index: int) -> Vector2:
	var angle: float = PI * 0.5 + TAU * float(index) / 5.0
	return CENTRE + Vector2(cos(angle), sin(angle)) * STAR_RADIUS


# --- Refreshing -----------------------------------------------------------------------------

func _refresh() -> void:
	if _root == null:
		return
	_bar_items = _loot.slot_items()
	for c: Control in _points + _bar + [_centre]:
		c.queue_redraw()
	for child: Node in _list.get_children():
		child.queue_free()
	var ready: Array[String] = _board.ready_recipes()
	for r: Dictionary in _board.recipes():
		_list.add_child(_recipe_row(r, ready.has(String(r["id"]))))
	_details.text = _details_text()
	_craft_button.disabled = not ready.has(_selected)
	_level.text = tr("CRAFT_TREE_LEVEL") % _board.tier
	var up: Dictionary = _board.next_upgrade()
	_upgrade_cost.text = tr("CRAFT_UPGRADE_MAX") if up.is_empty() else tr("CRAFT_UPGRADE_COST") % _cost_text(up["cost"])
	_upgrade_button.visible = not up.is_empty()
	_upgrade_button.disabled = not _board.can_upgrade()


func _recipe_row(r: Dictionary, ready: bool) -> Control:
	var id: String = String(r["id"])
	var unlocked: bool = _board.is_unlocked(id)
	var row := Control.new()
	row.custom_minimum_size = Vector2(LIST_RECT.size.x, 44)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = tr(String(r.get("text", ""))) if unlocked else ""
	row.draw.connect(func() -> void:
		var rect := Rect2(Vector2.ZERO, row.size)
		var fill := Color(0.1, 0.07, 0.06, 0.85)
		if id == _selected:
			fill = Color(0.24, 0.17, 0.12, 0.95)
		row.draw_rect(rect, fill)
		var border: Color = Color(Palette.SB_CANDLELIGHT, 0.95) if ready else Color(Palette.SB_GOLD, 0.35)
		row.draw_rect(rect, border, false, 3.0 if ready else 1.0)
		var font: Font = UiFonts.ui()
		if unlocked:
			ItemArt.draw(row, _loot.icon(String(r["result"])), Vector2(24, 22), 34)
			var amount: int = int(r.get("amount", 1))
			var name: String = tr(_loot.name_key(String(r["result"]))) + (" ×%d" % amount if amount > 1 else "")
			row.draw_string(font, Vector2(50, 28), name, HORIZONTAL_ALIGNMENT_LEFT, LIST_RECT.size.x - 56, 17,
				Palette.SB_CANDLELIGHT if ready else Palette.SB_CREAM)
		else:
			row.draw_string(font, Vector2(14, 28), tr("CRAFT_LOCKED") % int(r.get("tier", 0)), HORIZONTAL_ALIGNMENT_LEFT,
				LIST_RECT.size.x - 20, 15, Color(Palette.SB_CREAM, 0.45)))
	row.gui_input.connect(_click.bind(func() -> void: select(id)))
	return row


func _details_text() -> String:
	var r: Dictionary = _board.recipe(_selected)
	if r.is_empty() or not _board.is_unlocked(_selected):
		return ""
	var have: Dictionary = _board.totals()
	var lines: Array[String] = [tr(String(r.get("text", ""))), "", tr("CRAFT_NEEDS")]
	for item: String in r["ingredients"]:
		var need: int = int(r["ingredients"][item])
		var on_board: int = int(have.get(item, 0))
		var mark: String = "✓" if on_board >= need else "·"
		lines.append("%s %s  %d / %d   (%d)" % [mark, tr(_loot.name_key(item)), mini(on_board, need), need, _loot.count(item)])
	lines.append("")
	if _board.is_ready(_selected):
		lines.append(tr("CRAFT_READY"))
	elif _board.has_ingredients(_selected):
		lines.append(tr("CRAFT_RESULT_BLOCKED"))
	else:
		lines.append(tr("CRAFT_NOT_READY"))
	return "\n".join(lines)


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item: String in cost:
		parts.append("%s %d (%d)" % [tr(_loot.name_key(item)), int(cost[item]), _loot.count(item)])
	return ", ".join(parts)


# --- Drawing --------------------------------------------------------------------------------

# Looking into the hollow: bark rim all round, darkness deepening toward the middle, the
# pentagram faintly glowing on the old wood. Code-drawn (art to be painted: see the sprint plan).
func _draw_hollow(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SCREEN), Palette.SB_WALNUT_DARK.darkened(0.45))
	for ring: int in 6:
		var k: float = float(ring) / 5.0
		var pts := PackedVector2Array()
		for i: int in 48:
			var a: float = TAU * float(i) / 48.0
			var wobble: float = 1.0 + 0.06 * sin(a * 5.0 + float(ring)) + 0.04 * sin(a * 11.0)
			pts.append(CENTRE + Vector2(cos(a) * 470.0, sin(a) * 360.0) * lerpf(1.0, 0.62, k) * wobble)
		var tone: Color = Palette.SB_WALNUT.darkened(0.35).lerp(Palette.SB_CHARCOAL.darkened(0.55), k)
		c.draw_colored_polygon(pts, tone)
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		c.draw_polyline(closed, Color(Palette.SB_CONTOUR, 0.5), 2.0, true)
	for i: int in 26:
		var a: float = TAU * float(i) / 26.0 + 0.1
		var from: Vector2 = CENTRE + Vector2(cos(a) * 470.0, sin(a) * 360.0) * 0.98
		var to: Vector2 = CENTRE + Vector2(cos(a) * 470.0, sin(a) * 360.0) * 0.72
		c.draw_line(from, to, Color(Palette.SB_CONTOUR, 0.35), 1.5, true)
	var glow := Color(Palette.SB_CANDLELIGHT, 0.55)
	c.draw_arc(CENTRE, STAR_RADIUS + 8.0, 0, TAU, 64, Color(Palette.SB_CANDLELIGHT, 0.3), 2.0, true)
	for i: int in 5:
		c.draw_line(star_point(i), star_point((i + 2) % 5), glow, 2.5, true)


func _draw_slot_frame(c: Control, lit: bool) -> void:
	var r: float = c.size.x * 0.5
	c.draw_circle(c.size * 0.5, r, Color(0.06, 0.04, 0.05, 0.92))
	c.draw_arc(c.size * 0.5, r - 1.0, 0, TAU, 32, Color(Palette.SB_CANDLELIGHT, 0.95) if lit else Color(Palette.SB_GOLD, 0.6), 3.0 if lit else 2.0, true)


func _draw_count(c: Control, count: int) -> void:
	if count <= 0:
		return
	var font: Font = ThemeDB.fallback_font
	var text: String = str(count)
	var at := Vector2(c.size.x - 6.0 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, c.size.y - 4.0)
	c.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0, 0, 0, 0.9))
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.SB_CREAM)


func _draw_point(c: Control, index: int) -> void:
	var s: Dictionary = _board.slot(index)
	var needed: bool = false
	var r: Dictionary = _board.recipe(_selected)
	if not r.is_empty() and int(s["count"]) > 0:
		needed = (r["ingredients"] as Dictionary).has(String(s["item"]))
	_draw_slot_frame(c, needed)
	if int(s["count"]) > 0:
		ItemArt.draw(c, _loot.icon(String(s["item"])), c.size * 0.5, c.size.x * 0.72)
		_draw_count(c, int(s["count"]))


func _draw_centre(c: Control) -> void:
	var res: Dictionary = _board.result()
	_draw_slot_frame(c, int(res["count"]) > 0 or _board.is_ready(_selected))
	if int(res["count"]) > 0:
		ItemArt.draw(c, _loot.icon(String(res["item"])), c.size * 0.5, c.size.x * 0.72)
		_draw_count(c, int(res["count"]))


func _draw_bar_slot(c: Control, index: int) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.12, 0.1, 0.13, 0.92))
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(Palette.SB_GOLD, 0.55), false, 1.5)
	if index < _bar_items.size():
		var id: String = _bar_items[index]
		ItemArt.draw(c, _loot.icon(id), c.size * 0.5 - Vector2(0, 2), c.size.x * 0.78)
		_draw_count(c, _loot.count(id))
		c.tooltip_text = tr(_loot.name_key(id))
	else:
		c.tooltip_text = ""


# --- Drag and drop --------------------------------------------------------------------------

func _preview(icon: String, size: float) -> Control:
	var p := Control.new()
	p.draw.connect(func() -> void: ItemArt.draw(p, icon, Vector2.ZERO, size))
	return p


func _drag_bar(_at: Vector2, c: Control, index: int) -> Variant:
	if index >= _bar_items.size():
		return null
	var id: String = _bar_items[index]
	c.set_drag_preview(_preview(_loot.icon(id), BAR_SLOT.x * 0.78))
	return GameHud.unit_drag_data([[_loot.icon(id), _loot.count(id), "", id]], 0)


func _can_drop_bar(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and String(data.get("type", "")) in [DRAG_BOARD_UNIT, DRAG_RESULT]


func _drop_bar(_at: Vector2, data: Variant) -> void:
	if String(data["type"]) == DRAG_RESULT:
		take_result()
	else:
		take_back(int(data["slot"]))


func _drag_point(_at: Vector2, c: Control, index: int) -> Variant:
	var s: Dictionary = _board.slot(index)
	if int(s["count"]) <= 0:
		return null
	c.set_drag_preview(_preview(_loot.icon(String(s["item"])), POINT_SLOT.x * 0.72))
	return {"type": DRAG_BOARD_UNIT, "slot": index}


func _can_drop_point(_at: Vector2, data: Variant, index: int) -> bool:
	if not (data is Dictionary) or String(data.get("type", "")) != GameHud.DRAG_UNIT:
		return false
	var held: String = String(_board.slot(index)["item"])
	return held.is_empty() or held == String(data["item"])


func _drop_point(_at: Vector2, data: Variant, index: int) -> void:
	place(index, String(data["item"]))


func _drag_centre(_at: Vector2, c: Control) -> Variant:
	var res: Dictionary = _board.result()
	if int(res["count"]) <= 0:
		return null
	c.set_drag_preview(_preview(_loot.icon(String(res["item"])), RESULT_SLOT.x * 0.72))
	return {"type": DRAG_RESULT}

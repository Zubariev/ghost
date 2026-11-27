## The roots of the old tree (sprint 002, P5, task S2-06; UX spec design/ux/roots-progression.md,
## approved 2026-11-27; reference art/references/sprint-002/reference_b_root_progression.png).
## Opened from the hollow (the "Коріння" button or R): a cross-section under the back yard where
## the roots are the progression paths and the nodes are plain coloured circles.
##
## Layout (1280 × 720): above ground 0–150 (back arrow, title, the tree and its hollow); soil
## 150–560 (roots and nodes; the long rooms root runs down-left to the coffin); node panel 560–720.
## Every action goes through [CraftingProgression]; the screen keeps only the selection.
## [br]- Click a node or move with arrows / Tab; Enter, A or "Розкрити" unlocks with one press.
## [br]- Esc, E, right-click or the arrow button step back to the hollow.
## [br]- [member _reduced_motion] ("Менше руху"): no slide, no pulse, no light running along a root.
class_name RootsScreen
extends CanvasLayer

## The screen stepped back to the hollow.
signal closed()
## A node was unlocked (its id).
signal node_unlocked(id: String)
## Something to tell the player.
signal message(text: String)

const SCREEN := Vector2(1280, 720)
const GROUND_Y: float = 150.0
const PANEL_Y: float = 560.0
const SLIDE_SECONDS: float = 0.35
const LIGHT_SECONDS: float = 0.4
const PULSE_SECONDS: float = 2.0
const ROOT_WIDTH: float = 9.0
## Where the trunk meets the soil (the trunk's first node hangs below it).
const TRUNK_FOOT := Vector2(640, GROUND_Y)
const INK := Palette.SB_CONTOUR
## Painted soil and bark (S2-12, generated 2026-11-27); drawn shapes when missing.
const SOIL_PATH: String = "res://assets/art/surfaces/roots_soil.png"
const BARK_PATH: String = "res://assets/art/surfaces/roots_bark.png"
const SOIL_TILE: float = 256.0
## The painted coffin at the long rooms root's end (generated 2026-11-27); drawn shapes when missing.
## Drawn [constant COFFIN_WIDTH] px wide, centred on the layout's coffin point.
const COFFIN_PATH: String = "res://assets/art/props/roots/coffin.png"
const COFFIN_WIDTH: float = 140.0
const MISSING := Palette.SB_EMBER

var _prog: CraftingProgression
var _loot: GhostLoot
var _layout: RootsLayout
var _reduced_motion: bool = false
var _open: bool = false
var _selected: String = ""
var _hover: String = ""
var _time: float = 0.0
## The root lighting up after an unlock: {id, t (0..1)}; empty when none.
var _light: Dictionary = {}
var _tween: Tween
var _root: Control
var _canvas: Control
var _name: Label
var _text: Label
var _cost: RichTextLabel
var _needs: RichTextLabel
var _note: Label
var _unlock: Button


func _ready() -> void:
	layer = 5
	visible = false


## True while the roots screen is shown (from [method open] until [method close]).
func is_open() -> bool:
	return _open


## True while the slide or an unlock's light is running.
func is_animating() -> bool:
	return (_tween != null and _tween.is_running()) or not _light.is_empty()


## Opens on [param progression], paying with [param loot].
func open(progression: CraftingProgression, loot: GhostLoot, reduced_motion: bool) -> void:
	if _open:
		return
	_prog = progression
	_loot = loot
	_reduced_motion = reduced_motion
	_layout = RootsLayout.new({"branches": _prog.branches(), "nodes": _prog.nodes()})
	_build()
	_open = true
	visible = true
	if is_inside_tree():   # a hollow plaque the mouse hovered held keyboard focus and took Tab/arrows/Enter
		get_viewport().gui_release_focus()
	_prog.changed.connect(_refresh)
	_loot.inventory_changed.connect(_refresh)
	_selected = _first_available()
	_refresh()
	if not _reduced_motion:
		_root.position.y = SCREEN.y   # the view sinks from the hollow into the soil
		_tween = create_tween()
		_tween.tween_property(_root, "position:y", 0.0, SLIDE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Steps back to the hollow.
func close() -> void:
	if not _open:
		return
	_open = false
	if _prog.changed.is_connected(_refresh):
		_prog.changed.disconnect(_refresh)
	if _loot.inventory_changed.is_connected(_refresh):
		_loot.inventory_changed.disconnect(_refresh)
	_light = {}
	closed.emit()
	if _reduced_motion or _root == null:
		_finish_close()
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "position:y", SCREEN.y, SLIDE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.finished.connect(_finish_close)


## The id of the selected node.
func selected() -> String:
	return _selected


## Selects node [param id] and shows it in the panel; an unknown id changes nothing.
func select(id: String) -> void:
	if _prog.node(id).is_empty():
		return
	_selected = id
	_refresh()


## Moves the selection to the nearest node in [param direction].
func move_focus(direction: Vector2) -> void:
	select(_layout.neighbour(_selected, direction))


## Moves the selection [param step] places in Tab order.
func step_focus(step: int) -> void:
	select(_layout.next_in_order(_selected, step))


## True when the selected node can be unlocked now (parents owned, enough materials).
func unlock_enabled() -> bool:
	return _prog.can_unlock(_selected)


## Unlocks the selected node (one press); false, and nothing paid, when it cannot.
func unlock_selected() -> bool:
	var id: String = _selected
	if not _prog.unlock(id):
		return false
	if not _reduced_motion:
		_light = {"id": id, "t": 0.0}
	message.emit(tr("ROOTS_UNLOCKED") % tr(String(_prog.node(id).get("name", id))))
	node_unlocked.emit(id)
	_refresh()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause") \
			or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT):
		_handled()
		close()
	elif event.is_action_pressed(&"ui_left"):
		_handled()
		move_focus(Vector2.LEFT)
	elif event.is_action_pressed(&"ui_right"):
		_handled()
		move_focus(Vector2.RIGHT)
	elif event.is_action_pressed(&"ui_up"):
		_handled()
		move_focus(Vector2.UP)
	elif event.is_action_pressed(&"ui_down"):
		_handled()
		move_focus(Vector2.DOWN)
	elif event.is_action_pressed(&"ui_focus_next"):
		_handled()
		step_focus(1)
	elif event.is_action_pressed(&"ui_focus_prev"):
		_handled()
		step_focus(-1)
	elif event.is_action_pressed(&"ui_accept"):
		_handled()
		unlock_selected()


func _process(delta: float) -> void:
	if not _open or _canvas == null:
		return
	_time += delta
	var animating: bool = not _light.is_empty() or not _reduced_motion   # the light, or pulsing nodes
	if not _light.is_empty():
		_light["t"] = float(_light["t"]) + delta / LIGHT_SECONDS
		if float(_light["t"]) >= 1.0:
			_light = {}
	if animating:   # with "Менше руху" and no light, redraw only on changes (_refresh, hover)
		_canvas.queue_redraw()


func _handled() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _finish_close() -> void:
	if _open:
		return
	visible = false
	if _root != null:
		_root.queue_free()
		_root = null
		_canvas = null


func _first_available() -> String:
	var order: Array[String] = _layout.tab_order()
	for id: String in order:
		if _prog.state(id) == CraftingProgression.NodeState.AVAILABLE:
			return id
	return order[0] if not order.is_empty() else ""


# --- Building -------------------------------------------------------------------------------

func _build() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.size = SCREEN
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_canvas = Control.new()
	_canvas.size = Vector2(SCREEN.x, PANEL_Y)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # the painted bark tiles along the trunk
	_canvas.draw.connect(_draw_scene)
	_canvas.gui_input.connect(_on_canvas_input)
	_canvas.mouse_exited.connect(_on_canvas_exited)
	_root.add_child(_canvas)
	var back := PlaqueButton.create("←", 64.0, 24)
	back.focus_mode = Control.FOCUS_NONE   # the node selection is this screen's keyboard focus (see _unhandled_input)
	back.position = Vector2(18, 14)
	back.pressed.connect(close)
	_root.add_child(back)
	var title := _label(Vector2(96, 22), 520, 26, Palette.SB_CREAM, true)
	title.text = tr("ROOTS_TITLE")
	UiFonts.use(title, "title")
	# the node panel: parchment strip along the bottom
	var panel := Control.new()
	panel.position = Vector2(0, PANEL_Y)
	panel.size = Vector2(SCREEN.x, SCREEN.y - PANEL_Y)
	panel.draw.connect(_draw_panel.bind(panel))
	_root.add_child(panel)
	_name = _label(Vector2(40, PANEL_Y + 16), 720, 22, INK, false)
	UiFonts.use(_name, "title")
	_text = _label(Vector2(40, PANEL_Y + 52), 760, 16, INK, false)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost = _rich(Vector2(40, PANEL_Y + 104), 520)
	_needs = _rich(Vector2(580, PANEL_Y + 104), 300)
	_note = _label(Vector2(900, PANEL_Y + 96), 340, 14, Color(INK, 0.8), false)
	_note.text = tr("ROOTS_FINAL")
	_unlock = PlaqueButton.create(tr("ROOTS_UNLOCK"), 180.0, 20)
	_unlock.focus_mode = Control.FOCUS_NONE   # else a hover took focus and Tab/arrows moved it between plaques
	_unlock.position = Vector2(1060, PANEL_Y + 24)
	_unlock.pressed.connect(func() -> void: unlock_selected())
	_root.add_child(_unlock)
	var hint := _label(Vector2(640, SCREEN.y - 22), 620, 13, Color(INK, 0.75), false)
	hint.text = tr("ROOTS_HINT")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _label(at: Vector2, width: float, font_size: int, color: Color, outline: bool) -> Label:
	var l := Label.new()
	l.position = at
	l.size = Vector2(width, 0)
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	if outline:
		l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override(&"outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _rich(at: Vector2, width: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.position = at
	r.size = Vector2(width, 40)
	r.add_theme_font_size_override(&"normal_font_size", 16)
	r.add_theme_color_override(&"default_color", INK)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(r)
	return r


# Leaving the soil (e.g. down onto the panel) un-hovers the node, else it stayed enlarged.
func _on_canvas_exited() -> void:
	if not _hover.is_empty():
		_hover = ""
		_canvas.mouse_default_cursor_shape = Control.CURSOR_ARROW
		_canvas.queue_redraw()


func _on_canvas_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var over: String = _layout.node_at(motion.position)
		if over != _hover:
			_hover = over
			_canvas.queue_redraw()
			_canvas.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not over.is_empty() else Control.CURSOR_ARROW
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var hit: String = _layout.node_at(click.position)
		if not hit.is_empty():
			select(hit)


# --- Refreshing the panel -------------------------------------------------------------------

func _refresh() -> void:
	if _root == null or _selected.is_empty():
		return
	var node: Dictionary = _prog.node(_selected)
	var state: CraftingProgression.NodeState = _prog.state(_selected)
	_name.text = tr(String(node.get("name", _selected)))
	_text.text = tr(String(node.get("name", _selected)) + "_TEXT")
	var parts: Array[String] = []
	var price: Dictionary = _prog.cost(_selected)
	for item: String in price:
		var have: int = _loot.count(item)
		var need: int = int(price[item])
		var part: String = "%s %d/%d" % [tr(_loot.name_key(item)), mini(have, need), need]
		parts.append(part if have >= need or state == CraftingProgression.NodeState.OWNED
			else "[color=#%s]%s ✗[/color]" % [MISSING.to_html(false), part])
	_cost.text = "" if state == CraftingProgression.NodeState.OWNED or price.is_empty() \
		else tr("ROOTS_COST") + " " + " · ".join(parts)
	var needs: Array[String] = []
	for parent: Variant in node.get("parents", []):
		var owned: bool = _prog.state(String(parent)) == CraftingProgression.NodeState.OWNED
		var name: String = tr(String(_prog.node(String(parent)).get("name", parent)))
		needs.append(name + (" ✓" if owned else " [color=#%s]✗[/color]" % MISSING.to_html(false)))
	_needs.text = "" if needs.is_empty() else tr("ROOTS_NEEDS") + " " + ", ".join(needs)
	var owned_now: bool = state == CraftingProgression.NodeState.OWNED
	_unlock.text = tr("ROOTS_OWNED") if owned_now else tr("ROOTS_UNLOCK")
	_unlock.disabled = not _prog.can_unlock(_selected)
	_note.visible = not owned_now
	if _canvas != null:
		_canvas.queue_redraw()


# --- Drawing --------------------------------------------------------------------------------

func _draw_scene() -> void:
	_draw_above_ground()
	_draw_soil()
	_draw_roots()
	_draw_coffin()
	_draw_nodes()


func _draw_above_ground() -> void:
	var c := _canvas
	c.draw_rect(Rect2(0, 0, SCREEN.x, GROUND_Y), Palette.SB_SKY_NIGHT)
	c.draw_rect(Rect2(0, GROUND_Y * 0.45, SCREEN.x, GROUND_Y * 0.55), Color(Palette.SB_DUSK_BLUE, 0.35))
	# the back yard's fence and shed, as dark shapes behind the tree
	for i: int in 64:
		var x: float = float(i) * 20.0 + 4.0
		var top: float = GROUND_Y - 46.0 - float(hash(i) % 7)
		c.draw_rect(Rect2(x, top, 15, GROUND_Y - top), Palette.SB_WALNUT_DARK.darkened(0.35))
	c.draw_colored_polygon(PackedVector2Array([Vector2(150, GROUND_Y), Vector2(150, 70), Vector2(215, 42),
		Vector2(280, 70), Vector2(280, GROUND_Y)]), Palette.SB_WALNUT_DARK.darkened(0.2))
	# the old tree: a wide trunk with the hollow, its foot on the grass line
	var trunk := PackedVector2Array([Vector2(560, GROUND_Y + 6), Vector2(588, 60), Vector2(600, 0), Vector2(684, 0),
		Vector2(694, 60), Vector2(722, GROUND_Y + 6)])
	var bark: Texture2D = _texture(BARK_PATH)
	if bark != null:
		var uvs := PackedVector2Array()
		for p: Vector2 in trunk:
			uvs.append(p / 256.0)
		c.draw_polygon(trunk, PackedColorArray([Color(0.85, 0.85, 0.85)]), uvs, bark)
	else:
		c.draw_colored_polygon(trunk, Palette.SB_WALNUT)
	c.draw_polyline(trunk, INK, 3.0, true)
	c.draw_colored_polygon(Ink.ellipse(Vector2(642, 70), 22, 34, 18), Palette.SB_CHARCOAL.darkened(0.5))
	# the grass line
	var grass := PackedVector2Array()
	for i: int in 65:
		grass.append(Vector2(float(i) * 20.0, GROUND_Y + sin(float(i) * 1.7) * 2.5))
	c.draw_polyline(grass, Palette.SB_OLIVE, 7.0, true)


func _draw_soil() -> void:
	var c := _canvas
	var soil: Texture2D = _texture(SOIL_PATH)
	if soil != null:   # the painted soil, darkening with depth
		c.draw_texture_rect(soil, Rect2(0, GROUND_Y + 4.0, SCREEN.x, PANEL_Y - GROUND_Y - 4.0), true, Color(0.8, 0.8, 0.8))
		# one smooth shade, deeper toward the bottom (stepped bands showed as lines across the soil)
		var top: float = GROUND_Y + 4.0
		c.draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(SCREEN.x, top), Vector2(SCREEN.x, PANEL_Y), Vector2(0, PANEL_Y)]),
			PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.36), Color(0, 0, 0, 0.36)]))
		return
	var bands: int = 6
	for i: int in bands:
		var y0: float = GROUND_Y + 4.0 + (PANEL_Y - GROUND_Y) * float(i) / bands
		c.draw_rect(Rect2(0, y0, SCREEN.x, (PANEL_Y - GROUND_Y) / bands + 1.0),
			Palette.SB_WALNUT_DARK.darkened(0.25 + 0.06 * float(i)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261127
	for i: int in 26:   # a few buried stones
		var at := Vector2(rng.randf_range(20, SCREEN.x - 20), rng.randf_range(GROUND_Y + 30, PANEL_Y - 16))
		c.draw_colored_polygon(Ink.ellipse(at, rng.randf_range(5, 11), rng.randf_range(3, 7), 10), Color(Palette.SB_BROWN_GREY, 0.55))


func _draw_roots() -> void:
	var c := _canvas
	var trunk_node: String = _layout.tab_order()[0] if not _layout.tab_order().is_empty() else ""
	if not trunk_node.is_empty():   # the trunk goes down into the soil to the first node
		_draw_root(PackedVector2Array([TRUNK_FOOT, _layout.position(trunk_node)]), ROOT_WIDTH * 2.0, true)
	for id: String in _layout.tab_order():
		var owned: bool = _prog.state(id) == CraftingProgression.NodeState.OWNED
		for parent: String in _layout.parents(id):
			var points: PackedVector2Array = _layout.root_points(parent, id)
			var width: float = ROOT_WIDTH * (1.4 if _prog.is_trunk(id) else 1.0)
			_draw_root(points, width, owned)
			_draw_rootlets(points, id)
			if not _light.is_empty() and String(_light["id"]) == id:
				var upto: int = maxi(2, int(float(points.size()) * clampf(float(_light["t"]), 0.0, 1.0)))
				c.draw_polyline(points.slice(0, upto), Color(Palette.SB_FIRE_CORE, 0.9), width * 0.6, true)


func _draw_root(points: PackedVector2Array, width: float, lit: bool) -> void:
	_canvas.draw_polyline(points, INK, width + 3.0, true)
	_canvas.draw_polyline(points, Palette.SB_CANDLELIGHT.darkened(0.15) if lit else Palette.SB_WALNUT, width, true)


func _draw_rootlets(points: PackedVector2Array, id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for k: int in 2:
		var from: Vector2 = points[rng.randi_range(2, points.size() - 3)]
		var to: Vector2 = from + Vector2(rng.randf_range(-26, 26), rng.randf_range(10, 30))
		_canvas.draw_line(from, to, Color(Palette.SB_WALNUT, 0.7), 2.0, true)


func _draw_coffin() -> void:
	var at: Vector2 = _layout.coffin_position()
	if at == Vector2.ZERO:
		return
	var from: String = _layout.coffin_root_node()
	if not from.is_empty():
		_draw_root(RootsLayout.curve(_layout.position(from), at + Vector2(46, -8), hash("coffin")), ROOT_WIDTH * 0.8, false)
	# a plain old coffin lying on its side under the long root (no state, no interaction)
	var painted: Texture2D = _texture(COFFIN_PATH)
	if painted != null:
		var size: Vector2 = painted.get_size() * (COFFIN_WIDTH / painted.get_size().x)
		_canvas.draw_texture_rect(painted, Rect2(at - size * 0.5, size), false)
		return
	var box := PackedVector2Array([at + Vector2(-58, -6), at + Vector2(-40, -22), at + Vector2(52, -20), at + Vector2(62, -4),
		at + Vector2(52, 14), at + Vector2(-40, 16)])
	_canvas.draw_colored_polygon(box, Palette.SB_WALNUT_DARK)
	_canvas.draw_polyline(box + PackedVector2Array([box[0]]), INK, 3.0, true)
	_canvas.draw_line(at + Vector2(-40, -3), at + Vector2(52, -2), Color(INK, 0.8), 2.0, true)


func _draw_nodes() -> void:
	var c := _canvas
	var branch_colour: Dictionary = {}
	for b: Dictionary in _prog.branches():
		branch_colour[String(b["id"])] = RootsStyle.branch_colour(String(b.get("colour", "")))
	for id: String in _layout.tab_order():
		var node: Dictionary = _prog.node(id)
		var state: CraftingProgression.NodeState = _prog.state(id)
		var look: Dictionary = RootsStyle.node_look(state, _prog.can_unlock(id), id == _selected,
			branch_colour.get(String(node.get("branch", "")), Palette.SB_CREAM))
		var at: Vector2 = _layout.position(id)
		var r: float = float(look["radius"]) * (1.12 if id == _hover else 1.0)
		var glow: float = float(look["glow"])
		if bool(look["pulse"]):
			glow = 0.5 if _reduced_motion else 0.3 + 0.25 * sin(_time * TAU / PULSE_SECONDS)
		if glow > 0.0:
			var halo: float = float(look["halo"])
			c.draw_circle(at, r * halo, Color(Color(look["fill"]), glow * 0.3))
			c.draw_circle(at, r * lerpf(1.0, halo, 0.55), Color(Color(look["fill"]), glow * 0.4))
		c.draw_circle(at, r, look["fill"])
		c.draw_arc(at, r, 0.0, TAU, 28, look["rim"], 2.5, true)
		if bool(look["ring"]):
			var width: float = float(look["ring_width"])
			c.draw_arc(at, r + width * 0.5 + 1.0, 0.0, TAU, 28, Palette.SB_GOLD, width, true)
		if bool(look["selected"]):
			c.draw_arc(at, r + RootsStyle.SELECTED_RING, 0.0, TAU, 32, Palette.SB_CANDLELIGHT, 3.0, true)
			c.draw_arc(at, r + RootsStyle.SELECTED_RING + 2.5, 0.0, TAU, 32, INK, 1.5, true)


func _draw_panel(panel: Control) -> void:
	var rect := Rect2(Vector2.ZERO, panel.size)
	panel.draw_rect(rect, Palette.SB_PARCHMENT.lightened(0.25))
	panel.draw_rect(Rect2(0, 0, rect.size.x, 6), Palette.SB_WALNUT_DARK)
	panel.draw_rect(rect.grow(-6), Color(Palette.SB_GOLD, 0.8), false, 2.0)


static var _textures: Dictionary = {}


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path]

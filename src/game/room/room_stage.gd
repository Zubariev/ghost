## Draws the room the ghost is in, Hamlet-style (stage 5a, GDD §13.2): walls, floor, doors
## where the family's doors are, furniture from `assets/data/house/furniture.json`, the
## family members who are in the room, and the ghost — all sorted by depth. A wall the ghost
## is inside fades. Presentation only: it reads the simulation and never changes it.
class_name RoomStage
extends Node2D

const WALL_FADE_ALPHA: float = 0.45
const WALL_FADE_SPEED: float = 6.0

var sim: HouseSim
var navigator: GhostNavigator
## Where everything is inside rooms (shared with the stealth system).
var layout: RoomLayout
## Object id the ghost targets (highlighted), or "".
var target_object: String = ""
## Detection and hiding (stage 5b); may be null before it is set up.
var stealth: StealthSystem
## Sight zones are drawn on the floor (Q, after the monocle is found).
var show_cones: bool = false
## The monocle has been taken from the dresser.
var monocle_taken: bool = false
## Sight zone sizes from stealth.json (for drawing the cones).
var sight_config: Dictionary = {}

var _time: float = 0.0
var _walk_phase: float = 0.0
var _wall_alpha: Dictionary = {"left": 1.0, "right": 1.0, "back": 1.0}


func _process(delta: float) -> void:
	_time += delta
	_walk_phase += delta * 9.0
	var inside: String = navigator.wall()
	for wall: String in _wall_alpha:
		var target: float = WALL_FADE_ALPHA if wall == inside else 1.0
		_wall_alpha[wall] = move_toward(float(_wall_alpha[wall]), target, WALL_FADE_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	var room_id: String = navigator.room_id
	var room: RoomState = sim.house.rooms[room_id]
	draw_rect(Rect2(-200, -200, 1680, 1120), Palette.BACKGROUND)
	_draw_floor()
	_draw_back_wall(float(_wall_alpha["back"]))
	_draw_side_wall(true, float(_wall_alpha["left"]))
	_draw_side_wall(false, float(_wall_alpha["right"]))
	_draw_doors(room_id)
	_draw_lamp_glow(room_id)
	# Depth-sorted content: [screen y, callable]
	var items: Array = []
	for piece: Dictionary in layout.pieces(room_id):
		var kind: String = String(piece["kind"])
		var uv := Vector2(float(piece["u"]), float(piece["v"]))
		var object_id: String = String(piece.get("object", ""))
		var state: StringName = sim.house.get_object_state(object_id) if not object_id.is_empty() else &""
		if piece.has("pickup") and monocle_taken:
			state = &"taken"
		var y: float = RoomGeometry.to_screen(uv).y
		if FurnitureArt.is_flat(kind):
			y = -10000.0
		elif FurnitureArt.is_wall(kind):
			y = -5000.0
		var target_key: String = object_id if not object_id.is_empty() else String(piece.get("pickup", piece.get("hide_id", "")))
		items.append([y, FurnitureArt.draw.bind(self, kind, uv, state, target_key == target_object and not target_key.is_empty(), sim.house.is_day)])
	var markers: Array = []
	for i: int in sim.routines.size():
		var routine: NpcRoutine = sim.routines[i]
		var placed: Dictionary = _placed(routine, i, room_id)
		if placed.is_empty():
			continue
		var uv: Vector2 = placed["uv"]
		var facing_left: bool = Vector2(placed["facing"]).x < 0.0
		items.append([RoomGeometry.to_screen(uv).y, FamilyArt.draw_person.bind(self, routine.schedule.npc_id,
			RoomGeometry.to_screen(uv), RoomGeometry.scale_at(uv.y), String(placed["pose"]), _walk_phase, facing_left)])
		if placed.has("marker"):
			markers.append([RoomGeometry.to_screen(uv) + Vector2(-6, -150 * RoomGeometry.scale_at(uv.y)), String(placed["marker"])])
	var ghost_uv: Vector2 = navigator.uv
	var hidden: bool = stealth != null and not stealth.hidden_in.is_empty()
	var over_floor: bool = ghost_uv.x >= 0.0 and ghost_uv.x <= 1.0 and ghost_uv.y >= 0.0 and ghost_uv.y <= 1.0
	if not hidden:
		items.append([RoomGeometry.to_screen(ghost_uv).y if over_floor else 100000.0, FamilyArt.draw_ghost.bind(self,
			RoomGeometry.to_screen(ghost_uv), RoomGeometry.scale_at(ghost_uv.y), _time, over_floor)])
	if show_cones:
		_draw_cones(room_id)
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for item: Array in items:
		(item[1] as Callable).call()
	if hidden:
		_draw_hidden_glint(ghost_uv)
	for marker: Array in markers:
		draw_string(ThemeDB.fallback_font, marker[0], marker[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			Color("e0735f") if marker[1] == "!" else Color("f0c36a"))
	if room.temperature == RoomState.Temperature.COLD:
		draw_rect(Rect2(0, 0, 1280, 720), Palette.COLD_OVERLAY)


## Where a person is drawn, with stealth incidents applied: inspecting people look at the
## sighting ("?"), searchers stand at the spot they search ("?"), a fright shows "!".
func _placed(routine: NpcRoutine, index: int, room_id: String) -> Dictionary:
	var placed: Dictionary = layout.person(routine, index, room_id, sim.routines, _time)
	if placed.is_empty() or stealth == null:
		return placed
	var npc_id: String = routine.schedule.npc_id
	var phase: StealthSystem.Phase = stealth.phase_of(npc_id)
	if phase == StealthSystem.Phase.NONE:
		return placed
	var focus: Vector2 = stealth.incident_focus(npc_id)
	if phase == StealthSystem.Phase.SEARCH_WALK or phase == StealthSystem.Phase.SEARCH_CHECK:
		placed["uv"] = Vector2(clampf(focus.x, 0.05, 0.95), clampf(focus.y + 0.10, 0.05, 0.95))
	placed["pose"] = "stand"
	var look: Vector2 = focus - Vector2(placed["uv"])
	if look.length() > 0.0001:
		placed["facing"] = look.normalized()
	placed["marker"] = "!" if phase == StealthSystem.Phase.FRIGHT else "?"
	return placed


## Peripheral (wide, faint) and deep (narrow, strong) sight zones on the floor for everyone
## in the room who could notice the ghost; clipped to the floor.
func _draw_cones(room_id: String) -> void:
	for i: int in sim.routines.size():
		var routine: NpcRoutine = sim.routines[i]
		if stealth != null and not stealth.can_notice(routine):
			continue
		var placed: Dictionary = layout.person(routine, i, room_id, sim.routines, _time)
		if placed.is_empty():
			continue
		_draw_fan(placed["uv"], placed["facing"], float(sight_config.get("peripheral_angle_deg", 120)),
			float(sight_config.get("peripheral_range", 0.5)), Color(1.0, 0.9, 0.4, 0.16))
		_draw_fan(placed["uv"], placed["facing"], float(sight_config.get("deep_angle_deg", 40)),
			float(sight_config.get("deep_range", 0.33)), Color(1.0, 0.45, 0.25, 0.30))


func _draw_fan(origin: Vector2, look: Vector2, angle_deg: float, reach: float, color: Color) -> void:
	var points := PackedVector2Array([RoomGeometry.to_screen(origin)])
	var half: float = deg_to_rad(angle_deg) * 0.5
	for step: int in 19:
		var direction: Vector2 = look.normalized().rotated(-half + 2.0 * half * float(step) / 18.0)
		points.append(RoomGeometry.to_screen(origin + direction * reach))
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(points, RoomGeometry.floor_polygon()):
		draw_colored_polygon(piece, color)
		_outline(piece, Color(color, minf(color.a * 2.5, 0.8)), 2.0)


## The hidden ghost: only a faint pair of eyes glinting at its hiding spot.
func _draw_hidden_glint(uv: Vector2) -> void:
	var at: Vector2 = RoomGeometry.to_screen(uv) + Vector2(0, -40)
	var glow: float = 0.55 + 0.35 * sin(_time * 2.5)
	for side: float in [-7.0, 7.0]:
		draw_colored_polygon(FurnitureArt._ellipse(at + Vector2(side, 0), 3.5, 5.0, 10), Color(0.75, 0.95, 1.0, glow))


# --- Room shell ------------------------------------------------------------------

func _draw_floor() -> void:
	var edge := Vector2(0, RoomGeometry.FLOOR_EDGE)
	draw_colored_polygon(PackedVector2Array([RoomGeometry.FRONT_LEFT, RoomGeometry.FRONT_RIGHT, RoomGeometry.FRONT_RIGHT + edge, RoomGeometry.FRONT_LEFT + edge]), Palette.FLOOR_EDGE)
	draw_colored_polygon(RoomGeometry.floor_polygon(), Palette.FLOOR)
	for i: int in range(1, 14):
		var t: float = float(i) / 14.0
		draw_line(RoomGeometry.to_screen(Vector2(t, 0)), RoomGeometry.to_screen(Vector2(t, 1)), Palette.FLOOR_LINE, 2.0, true)
	for v: float in [0.1, 0.23, 0.38, 0.56, 0.77]:
		draw_line(RoomGeometry.to_screen(Vector2(0, v)), RoomGeometry.to_screen(Vector2(1, v)), Palette.FLOOR_LINE, 1.5, true)
	_outline(RoomGeometry.floor_polygon(), Palette.INK, 3.0)


func _draw_back_wall(alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.back_wall_polygon()
	draw_colored_polygon(poly, _a(Palette.WALL_BACK, alpha))
	var wainscot_y: float = RoomGeometry.BACK_LEFT.y - RoomGeometry.BACK_WALL_HEIGHT * 0.38
	var x: float = RoomGeometry.BACK_LEFT.x + 14.0
	while x < RoomGeometry.BACK_RIGHT.x:
		draw_line(Vector2(x, poly[0].y), Vector2(x, wainscot_y), _a(Palette.WALL_STRIPE, alpha), 6.0)
		x += 28.0
	draw_colored_polygon(FurnitureArt._rect(RoomGeometry.BACK_LEFT.x, wainscot_y, RoomGeometry.BACK_RIGHT.x, RoomGeometry.BACK_LEFT.y), _a(Palette.WAINSCOT, alpha))
	_outline(poly, _a(Palette.INK, alpha), 3.0)
	draw_line(poly[0], poly[1], _a(Palette.WALL_CAP, alpha), 7.0)


func _draw_side_wall(left: bool, alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.left_wall_polygon() if left else RoomGeometry.right_wall_polygon()
	draw_colored_polygon(poly, _a(Palette.WALL_SIDE, alpha))
	var band := PackedVector2Array([
		RoomGeometry.side_wall_point(left, 1.0, 0.38), RoomGeometry.side_wall_point(left, 0.0, 0.38),
		RoomGeometry.side_wall_point(left, 0.0, 0.0), RoomGeometry.side_wall_point(left, 1.0, 0.0)])
	draw_colored_polygon(band, _a(Palette.WAINSCOT_SIDE, alpha))
	_outline(poly, _a(Palette.INK, alpha), 3.0)
	draw_line(poly[0], poly[1], _a(Palette.WALL_CAP, alpha), 7.0)


func _draw_doors(room_id: String) -> void:
	for other: String in sim.house.rooms:
		if sim.house.walk_minutes(room_id, other) <= 0:
			continue
		var here: RoomState = sim.house.rooms[room_id]
		var there: RoomState = sim.house.rooms[other]
		if here.floor_level != there.floor_level:
			continue   # stairs are furniture
		var step: Vector2i = there.grid - here.grid
		if step.x != 0:
			var left: bool = step.x < 0
			var alpha: float = float(_wall_alpha["left" if left else "right"])
			var frame := PackedVector2Array([
				RoomGeometry.side_wall_point(left, 0.40, 0.62), RoomGeometry.side_wall_point(left, 0.60, 0.62),
				RoomGeometry.side_wall_point(left, 0.60, 0.0), RoomGeometry.side_wall_point(left, 0.40, 0.0)])
			var inner := PackedVector2Array([
				RoomGeometry.side_wall_point(left, 0.43, 0.56), RoomGeometry.side_wall_point(left, 0.57, 0.56),
				RoomGeometry.side_wall_point(left, 0.57, 0.0), RoomGeometry.side_wall_point(left, 0.43, 0.0)])
			draw_colored_polygon(frame, _a(Palette.WOOD_DARK, alpha))
			draw_colored_polygon(inner, _a(Palette.DOORWAY, alpha))
			_outline(frame, _a(Palette.INK, alpha), 2.5)
		elif step.y < 0:
			var alpha_back: float = float(_wall_alpha["back"])
			var frame_back: PackedVector2Array = FurnitureArt._rect(
				RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U - 0.07, 0.0).x, RoomGeometry.back_wall_point(0, 0.8).y,
				RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U + 0.07, 0.0).x, RoomGeometry.BACK_LEFT.y)
			var inner_back: PackedVector2Array = FurnitureArt._rect(frame_back[0].x + 10, frame_back[0].y + 10, frame_back[1].x - 10, RoomGeometry.BACK_LEFT.y)
			draw_colored_polygon(frame_back, _a(Palette.WOOD_DARK, alpha_back))
			draw_colored_polygon(inner_back, _a(Palette.DOORWAY, alpha_back))
			_outline(frame_back, _a(Palette.INK, alpha_back), 2.5)
		else:
			var a: Vector2 = RoomGeometry.to_screen(Vector2(0.44, 1.0))
			var b: Vector2 = RoomGeometry.to_screen(Vector2(0.56, 1.0))
			draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, RoomGeometry.FLOOR_EDGE), a + Vector2(0, RoomGeometry.FLOOR_EDGE)]), Palette.DOORWAY)


func _draw_lamp_glow(room_id: String) -> void:
	for piece: Dictionary in layout.pieces(room_id):
		if String(piece["kind"]) != "floor_lamp":
			continue
		if sim.house.get_object_state(String(piece.get("object", ""))) != &"lit":
			continue
		var at: Vector2 = RoomGeometry.to_screen(Vector2(float(piece["u"]), float(piece["v"])))
		for ring: int in 4:
			var glow: PackedVector2Array = FurnitureArt._ellipse(at, 260.0 - ring * 55.0, 80.0 - ring * 17.0, 32)
			# Light falls on the floor only, never past the room's edge.
			for clipped: PackedVector2Array in Geometry2D.intersect_polygons(glow, RoomGeometry.floor_polygon()):
				draw_colored_polygon(clipped, Color(1.0, 0.85, 0.5, 0.05))


func _outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, color, width, true)


static func _a(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)

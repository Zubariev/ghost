## Draws the room the ghost is in, Hamlet-style (stage 5a, GDD §13.2): walls, floor, doors
## where the family's doors are, furniture from `assets/data/house/furniture.json`, the
## family members who are in the room, and the ghost — all sorted by depth. A wall the ghost
## is inside fades. Presentation only: it reads the simulation and never changes it.
class_name RoomStage
extends Node2D

const WALL_FADE_ALPHA: float = 0.45
const WALL_FADE_SPEED: float = 6.0
const BACK_DOOR_U: float = 0.62

var sim: HouseSim
var navigator: GhostNavigator
## room id -> Array of furniture dictionaries {kind, u, v, object?}
var furniture: Dictionary = {}
## Object id the ghost targets (highlighted), or "".
var target_object: String = ""

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


## Floor position of a sim object in the current room, or (-1, -1) when not placed here.
func object_uv(room_id: String, object_id: String) -> Vector2:
	for piece: Dictionary in furniture.get(room_id, []):
		if String(piece.get("object", "")) == object_id:
			return Vector2(float(piece["u"]), float(piece["v"]))
	return Vector2(-1, -1)


## Where a door toward [param other] is on this room's floor, from the floor grid.
func door_uv(room_id: String, other: String) -> Vector2:
	var here: RoomState = sim.house.rooms[room_id]
	var there: RoomState = sim.house.rooms[other]
	if here.floor_level != there.floor_level:
		var stairs: Vector2 = _kind_uv(room_id, "stairs")
		return stairs if stairs.x >= 0.0 else Vector2(0.5, 0.1)
	var step: Vector2i = there.grid - here.grid
	if step.x < 0:
		return Vector2(0.0, 0.5)
	if step.x > 0:
		return Vector2(1.0, 0.5)
	if step.y < 0:
		return Vector2(BACK_DOOR_U, 0.0)
	return Vector2(0.5, 1.0)


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
	for piece: Dictionary in furniture.get(room_id, []):
		var kind: String = String(piece["kind"])
		var uv := Vector2(float(piece["u"]), float(piece["v"]))
		var object_id: String = String(piece.get("object", ""))
		var state: StringName = sim.house.get_object_state(object_id) if not object_id.is_empty() else &""
		var y: float = RoomGeometry.to_screen(uv).y
		if FurnitureArt.is_flat(kind):
			y = -10000.0
		elif FurnitureArt.is_wall(kind):
			y = -5000.0
		items.append([y, FurnitureArt.draw.bind(self, kind, uv, state, object_id == target_object and not object_id.is_empty(), sim.house.is_day)])
	for i: int in sim.routines.size():
		var placed: Dictionary = _person_here(sim.routines[i], i, room_id)
		if not placed.is_empty():
			var uv: Vector2 = placed["uv"]
			items.append([RoomGeometry.to_screen(uv).y, FamilyArt.draw_person.bind(self, sim.routines[i].schedule.npc_id,
				RoomGeometry.to_screen(uv), RoomGeometry.scale_at(uv.y), String(placed["pose"]), _walk_phase, bool(placed["left"]))])
	var ghost_uv: Vector2 = navigator.uv
	var over_floor: bool = ghost_uv.x >= 0.0 and ghost_uv.x <= 1.0 and ghost_uv.y >= 0.0 and ghost_uv.y <= 1.0
	items.append([RoomGeometry.to_screen(ghost_uv).y if over_floor else 100000.0, FamilyArt.draw_ghost.bind(self,
		RoomGeometry.to_screen(ghost_uv), RoomGeometry.scale_at(ghost_uv.y), _time, over_floor)])
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for item: Array in items:
		(item[1] as Callable).call()
	if room.temperature == RoomState.Temperature.COLD:
		draw_rect(Rect2(0, 0, 1280, 720), Palette.COLD_OVERLAY)


## Where (and how) a family member appears in this room, or {} when not here.
func _person_here(routine: NpcRoutine, index: int, room_id: String) -> Dictionary:
	var walk: Dictionary = routine.get_walk_progress()
	if not walk.is_empty():
		var t: float = float(walk["t"])
		var from_room: String = String(walk["from"])
		var to_room: String = String(walk["to"])
		if from_room == room_id and t < 0.5:
			var door: Vector2 = door_uv(room_id, to_room)
			var start: Vector2 = _spot(routine, index, room_id)
			return {"uv": start.lerp(door, t * 2.0), "pose": "walk", "left": door.x < start.x}
		if to_room == room_id and t >= 0.5:
			var door_in: Vector2 = door_uv(room_id, from_room)
			var middle := Vector2(0.5, 0.6)
			return {"uv": door_in.lerp(middle, (t - 0.5) * 2.0), "pose": "walk", "left": middle.x < door_in.x}
		return {}
	if routine.room_id != room_id:
		return {}
	var pose: String = "stand"
	var activity: Activity = routine.current
	if routine.is_broken():
		pose = "broken"
	elif routine.state == NpcRoutine.State.PERFORMING and activity != null and routine.current_task == null:
		match activity.animation:
			"sleep":
				pose = "sleep"
			"eat", "rest", "read", "computer", "draw", "dolls":
				pose = "sit"
			"tricycle":
				pose = "tricycle"
	if pose == "sleep":
		var bed: Vector2 = _bed_spot(routine, room_id)
		if bed.x >= 0.0:
			return {"uv": bed, "pose": "sleep", "left": false}
	var spot: Vector2 = _spot(routine, index, room_id)
	if pose == "tricycle":
		spot.x = 0.5 + 0.3 * sin(_time * 0.6)
	return {"uv": spot, "pose": pose, "left": spot.x > 0.5}


## The spot for this person: their task's object, their activity's object, else a slot.
func _spot(routine: NpcRoutine, index: int, room_id: String) -> Vector2:
	var object_id: String = ""
	if routine.current_task != null and routine.current_task.type == HouseTask.Type.REPAIR:
		object_id = routine.current_task.target_id
	elif routine.current != null:
		object_id = routine.current.target_object_id
	var at: Vector2 = object_uv(room_id, object_id) if not object_id.is_empty() else Vector2(-1, -1)
	if at.x >= 0.0:
		var spread: float = (float(index) - 2.5) * 0.06
		return Vector2(clampf(at.x + spread, 0.08, 0.92), clampf(at.y + 0.12, 0.1, 0.95))
	return Vector2(0.18 + 0.13 * float(index), 0.62 + 0.08 * float(index % 2))


## A place in one of the room's beds for this sleeper: sleepers are shared out over the
## beds in data order, two to a double bed. (-1, -1) when the room has no free bed.
func _bed_spot(routine: NpcRoutine, room_id: String) -> Vector2:
	var sleepers: Array[NpcRoutine] = []
	for other: NpcRoutine in sim.routines:
		if other.room_id == room_id and other.state == NpcRoutine.State.PERFORMING and other.current != null \
				and other.current.animation == "sleep" and other.get_walk_progress().is_empty():
			sleepers.append(other)
	var place: int = sleepers.find(routine)
	for piece: Dictionary in furniture.get(room_id, []):
		var kind: String = String(piece["kind"])
		if kind != "bed" and kind != "double_bed":
			continue
		var capacity: int = 2 if kind == "double_bed" else 1
		if place < capacity:
			var offset: float = 0.0 if capacity == 1 else (-0.045 if place == 0 else 0.045)
			# Sorted just after the bed so the sleeper lies on top of it.
			return Vector2(float(piece["u"]) + offset, float(piece["v"]) + 0.001)
		place -= capacity
	return Vector2(-1, -1)


func _kind_uv(room_id: String, kind: String) -> Vector2:
	for piece: Dictionary in furniture.get(room_id, []):
		if String(piece["kind"]) == kind:
			return Vector2(float(piece["u"]), float(piece["v"]))
	return Vector2(-1, -1)


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
				RoomGeometry.back_wall_point(BACK_DOOR_U - 0.07, 0.0).x, RoomGeometry.back_wall_point(0, 0.8).y,
				RoomGeometry.back_wall_point(BACK_DOOR_U + 0.07, 0.0).x, RoomGeometry.BACK_LEFT.y)
			var inner_back: PackedVector2Array = FurnitureArt._rect(frame_back[0].x + 10, frame_back[0].y + 10, frame_back[1].x - 10, RoomGeometry.BACK_LEFT.y)
			draw_colored_polygon(frame_back, _a(Palette.WOOD_DARK, alpha_back))
			draw_colored_polygon(inner_back, _a(Palette.DOORWAY, alpha_back))
			_outline(frame_back, _a(Palette.INK, alpha_back), 2.5)
		else:
			var a: Vector2 = RoomGeometry.to_screen(Vector2(0.44, 1.0))
			var b: Vector2 = RoomGeometry.to_screen(Vector2(0.56, 1.0))
			draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, RoomGeometry.FLOOR_EDGE), a + Vector2(0, RoomGeometry.FLOOR_EDGE)]), Palette.DOORWAY)


func _draw_lamp_glow(room_id: String) -> void:
	for piece: Dictionary in furniture.get(room_id, []):
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

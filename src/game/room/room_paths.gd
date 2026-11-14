## Walking paths inside a room (stage 5c, roadmap step 1): a grid over the floor with every
## furniture footprint from `assets/data/house/movement.json` blocked, A* between two floor
## points, and the result straightened wherever the way is clear. A start or end inside
## furniture (a bed, the stairs, a door point on the wall) is joined to the nearest free floor
## by one straight step. Pure logic: [FamilyMotion] walks the family along these paths.
##
## [codeblock]
## var paths := RoomPaths.new(layout, JsonData.read(RoomPaths.MOVEMENT_PATH))
## var points: PackedVector2Array = paths.find("kitchen", Vector2(0.1, 0.5), Vector2(0.82, 0.44))
## [/codeblock]
class_name RoomPaths
extends RefCounted

const MOVEMENT_PATH: String = "res://assets/data/house/movement.json"

var _layout: RoomLayout
var _cells: Vector2i
var _clearance: float
## kind -> half size (u, v)
var _footprints: Dictionary[String, Vector2] = {}
## room id -> Array[Rect2]
var _blocked: Dictionary = {}
## room id -> AStarGrid2D
var _grids: Dictionary = {}


func _init(layout: RoomLayout, config: Dictionary) -> void:
	_layout = layout
	var cells: Array = config.get("grid_cells", [40, 24])
	_cells = Vector2i(int(cells[0]), int(cells[1]))
	_clearance = float(config.get("clearance", 0.025))
	var footprints: Dictionary = config.get("footprints", {})
	for kind: String in footprints:
		var half: Array = footprints[kind]
		_footprints[kind] = Vector2(float(half[0]), float(half[1]))


## Floor rectangles nobody walks through in [param room_id]: footprints grown by the clearance.
## Decor pieces ("decor": true) are drawn only and never block.
func blocked(room_id: String) -> Array[Rect2]:
	if not _blocked.has(room_id):
		var rects: Array[Rect2] = []
		for piece: Dictionary in _layout.pieces(room_id):
			var kind: String = String(piece["kind"])
			if not _footprints.has(kind) or bool(piece.get("decor", false)):
				continue   # decor (art test, 2026-11-15) is drawn only, never an obstacle
			var half: Vector2 = _footprints[kind] + Vector2(_clearance, _clearance)
			rects.append(Rect2(Vector2(float(piece["u"]), float(piece["v"])) - half, half * 2.0))
		_blocked[room_id] = rects
	return _blocked[room_id]


## True when [param uv] is on the floor and outside every footprint.
func is_free(room_id: String, uv: Vector2) -> bool:
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return false
	for rect: Rect2 in blocked(room_id):
		if rect.has_point(uv):
			return false
	return true


## True when walking straight from [param a] to [param b] crosses no footprint.
func is_clear(room_id: String, a: Vector2, b: Vector2) -> bool:
	if not is_free(room_id, a) or not is_free(room_id, b):
		return false
	for rect: Rect2 in blocked(room_id):
		if _segment_hits_rect(a, b, rect):
			return false
	return true


## A walk from [param from_uv] to [param to_uv] in [param room_id]: points in order, the
## first exactly [param from_uv], the last exactly [param to_uv].
func find(room_id: String, from_uv: Vector2, to_uv: Vector2) -> PackedVector2Array:
	if from_uv.distance_to(to_uv) < 0.0001:
		return PackedVector2Array([from_uv, to_uv])
	if is_clear(room_id, from_uv, to_uv):
		return PackedVector2Array([from_uv, to_uv])
	var start: Vector2 = from_uv if is_free(room_id, from_uv) else nearest_free(room_id, from_uv)
	var finish: Vector2 = to_uv if is_free(room_id, to_uv) else nearest_free(room_id, to_uv)
	var middle: Array[Vector2] = [start]
	if not is_clear(room_id, start, finish):
		var grid: AStarGrid2D = _grid(room_id)
		var ids: Array[Vector2i] = grid.get_id_path(_cell_of(start), _cell_of(finish))
		for i: int in range(1, ids.size() - 1):
			middle.append(_centre(ids[i]))
	middle.append(finish)
	var out := PackedVector2Array([from_uv])
	for point: Vector2 in _straighten(room_id, middle):
		if out[out.size() - 1].distance_to(point) > 0.0001:
			out.append(point)
	if out[out.size() - 1].distance_to(to_uv) > 0.0001:
		out.append(to_uv)
	return out


## The free grid cell centre closest to [param uv] (for points inside furniture or walls).
func nearest_free(room_id: String, uv: Vector2) -> Vector2:
	var best := Vector2(0.5, 0.5)
	var best_distance: float = INF
	for x: int in _cells.x:
		for y: int in _cells.y:
			var centre: Vector2 = _centre(Vector2i(x, y))
			var distance: float = centre.distance_squared_to(uv)
			if distance < best_distance and is_free(room_id, centre):
				best = centre
				best_distance = distance
	return best


## Total length of a path.
static func length(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


# Keeps only the corners that are needed: from each point, jump to the farthest later point
# that can be reached in a straight line.
func _straighten(room_id: String, points: Array[Vector2]) -> Array[Vector2]:
	var kept: Array[Vector2] = [points[0]]
	var i: int = 0
	while i < points.size() - 1:
		var j: int = points.size() - 1
		while j > i + 1 and not is_clear(room_id, points[i], points[j]):
			j -= 1
		kept.append(points[j])
		i = j
	return kept


func _grid(room_id: String) -> AStarGrid2D:
	if not _grids.has(room_id):
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(Vector2i.ZERO, _cells)
		grid.cell_size = Vector2.ONE
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for x: int in _cells.x:
			for y: int in _cells.y:
				if not is_free(room_id, _centre(Vector2i(x, y))):
					grid.set_point_solid(Vector2i(x, y), true)
		_grids[room_id] = grid
	return _grids[room_id]


func _centre(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / float(_cells.x), (float(cell.y) + 0.5) / float(_cells.y))


func _cell_of(uv: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(uv.x * float(_cells.x)), 0, _cells.x - 1), clampi(floori(uv.y * float(_cells.y)), 0, _cells.y - 1))


static func _segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i: int in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false

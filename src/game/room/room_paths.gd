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
## Grid cells across and deep when the config gives no cell size (old configs, tests).
var _cells: Vector2i
## Grid cell size in metres (2026-11-20): each room gets as many cells as fit its real size.
var _cell_m: float = 0.0
## A person's half width in metres, added around every footprint.
var _clearance: float
## kind -> half size in metres (width, depth)
var _footprints: Dictionary[String, Vector2] = {}
## room id -> cells across and deep
var _room_cells: Dictionary = {}
## room id -> Array[Rect2]
var _blocked: Dictionary = {}
## room id -> AStarGrid2D
var _grids: Dictionary = {}


func _init(layout: RoomLayout, config: Dictionary) -> void:
	_layout = layout
	var cells: Array = config.get("grid_cells", [40, 24])
	_cells = Vector2i(int(cells[0]), int(cells[1]))
	_cell_m = float(config.get("cell_m", 0.0))
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
			var half: Vector2 = _layout.to_uv(room_id, _footprints[kind] + Vector2(_clearance, _clearance))
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
		var ids: Array[Vector2i] = grid.get_id_path(_cell_of(room_id, start), _cell_of(room_id, finish))
		for i: int in range(1, ids.size() - 1):
			middle.append(_centre(room_id, ids[i]))
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
	var cells: Vector2i = _cells_of(room_id)
	for x: int in cells.x:
		for y: int in cells.y:
			var centre: Vector2 = _centre(room_id, Vector2i(x, y))
			var distance: float = _layout.distance(room_id, centre, uv)
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
		var cells: Vector2i = _cells_of(room_id)
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(Vector2i.ZERO, cells)
		grid.cell_size = _layout.size(room_id) / Vector2(cells)   # metres, so A* weighs real distance
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for x: int in cells.x:
			for y: int in cells.y:
				if not is_free(room_id, _centre(room_id, Vector2i(x, y))):
					grid.set_point_solid(Vector2i(x, y), true)
		_grids[room_id] = grid
	return _grids[room_id]


## Grid cells across and deep in [param room_id]: from its real size and the cell size in
## metres, else the config's fixed count.
func _cells_of(room_id: String) -> Vector2i:
	if _cell_m <= 0.0:
		return _cells
	if not _room_cells.has(room_id):
		var s: Vector2 = _layout.size(room_id)
		_room_cells[room_id] = Vector2i(maxi(4, ceili(s.x / _cell_m)), maxi(4, ceili(s.y / _cell_m)))
	return _room_cells[room_id]


func _centre(room_id: String, cell: Vector2i) -> Vector2:
	var cells: Vector2i = _cells_of(room_id)
	return Vector2((float(cell.x) + 0.5) / float(cells.x), (float(cell.y) + 0.5) / float(cells.y))


func _cell_of(room_id: String, uv: Vector2) -> Vector2i:
	var cells: Vector2i = _cells_of(room_id)
	return Vector2i(clampi(floori(uv.x * float(cells.x)), 0, cells.x - 1), clampi(floori(uv.y * float(cells.y)), 0, cells.y - 1))


static func _segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i: int in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[i], corners[(i + 1) % 4]) != null:
			return true
	return false

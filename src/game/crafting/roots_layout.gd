## Where the roots screen puts every node, and how focus moves between them (sprint 002, P5, task
## S2-06; design/ux/roots-progression.md, approved 2026-11-27). Pure geometry from
## [code]progression.json[/code]; no drawing.
##
## [br]- A node's [code]layout: {x, y}[/code] is its place in screen pixels (1280 × 720). A node
##   without one is placed [constant STEP] px past its first parent along its branch's
##   [code]direction[/code], so a new node or room works with data alone.
## [br]- Tab order: branches in data order, nodes in data order within each.
## [br]- Arrows: the nearest node within 60° of the direction; staying put when there is none.
## [br]- A branch may name a [code]coffin: {x, y}[/code]: the landmark at its end (no node, no state).
class_name RootsLayout
extends RefCounted

## Distance of an automatically placed node from its parent (px).
const STEP: float = 80.0
## Click radius round a node centre (px): larger than the drawn circle (UX spec: 36 px targets).
const HIT_RADIUS: float = 18.0
## How far a root may bend sideways, as a share of its length.
const WOBBLE: float = 0.18
## Points per root curve.
const ROOT_POINTS: int = 14
## Widest angle from an arrow's direction that still counts as "that way".
const ARROW_CONE: float = deg_to_rad(60.0)

var _nodes: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _branches: Array[Dictionary] = []
var _positions: Dictionary = {}


func _init(config: Dictionary) -> void:
	for b: Dictionary in config.get("branches", []):
		_branches.append(b)
	for n: Dictionary in config.get("nodes", []):
		_nodes.append(n)
		_by_id[String(n["id"])] = n
	for n: Dictionary in _nodes:
		_place(String(n["id"]), 0)


## The node's centre on screen.
func position(id: String) -> Vector2:
	return _positions.get(id, Vector2.ZERO)


## Node ids in Tab order: branch by branch (data order), nodes in data order.
func tab_order() -> Array[String]:
	var order: Array[String] = []
	for b: Dictionary in _branches:
		for n: Dictionary in _nodes:
			if String(n["branch"]) == String(b["id"]):
				order.append(String(n["id"]))
	return order


## The node [param step] places after [param from] in Tab order, wrapping round.
func next_in_order(from: String, step: int) -> String:
	var order: Array[String] = tab_order()
	if order.is_empty():
		return from
	var at: int = order.find(from)
	return order[posmod((at if at >= 0 else 0) + step, order.size())]


## The nearest node from [param from] in [param direction], or [param from] when there is none.
func neighbour(from: String, direction: Vector2) -> String:
	var origin: Vector2 = position(from)
	var best: String = from
	var best_score: float = INF
	for id: String in _positions:
		if id == from:
			continue
		var offset: Vector2 = position(id) - origin
		var angle: float = absf(offset.angle_to(direction))
		if offset.length() < 0.001 or angle > ARROW_CONE:
			continue
		var score: float = offset.length() * (1.0 + angle)   # straight ahead beats off to the side
		if score < best_score:
			best_score = score
			best = id
	return best


## The node under [param point], or "" for empty soil.
func node_at(point: Vector2) -> String:
	var best: String = ""
	var best_distance: float = HIT_RADIUS
	for id: String in _positions:
		var d: float = point.distance_to(position(id))
		if d <= best_distance:
			best_distance = d
			best = id
	return best


## A gently bent root from [param parent] to [param child]; the same curve every time.
func root_points(parent: String, child: String) -> PackedVector2Array:
	return curve(position(parent), position(child), hash(parent + ">" + child))


## A bent curve from [param a] to [param b], its bend picked by [param seed].
static func curve(a: Vector2, b: Vector2, seed: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var normal: Vector2 = (b - a).orthogonal().normalized()
	var length: float = a.distance_to(b)
	var bend_1: Vector2 = a.lerp(b, 0.33) + normal * rng.randf_range(-WOBBLE, WOBBLE) * length
	var bend_2: Vector2 = a.lerp(b, 0.66) + normal * rng.randf_range(-WOBBLE, WOBBLE) * length
	var points := PackedVector2Array()
	for i: int in ROOT_POINTS:
		var t: float = float(i) / float(ROOT_POINTS - 1)
		points.append(a.bezier_interpolate(bend_1, bend_2, b, t))
	return points


## The parents of [param id] that have a place (for drawing its roots).
func parents(id: String) -> Array[String]:
	var out: Array[String] = []
	for p: Variant in _by_id.get(id, {}).get("parents", []):
		if _positions.has(String(p)):
			out.append(String(p))
	return out


## Where the coffin lies (the end of the branch that names it); Vector2.ZERO when none does.
func coffin_position() -> Vector2:
	for b: Dictionary in _branches:
		if b.has("coffin"):
			return Vector2(float(b["coffin"]["x"]), float(b["coffin"]["y"]))
	return Vector2.ZERO


## The branch the coffin ends, or "".
func coffin_branch() -> String:
	for b: Dictionary in _branches:
		if b.has("coffin"):
			return String(b["id"])
	return ""


## The node of [param branch] that the coffin's root grows from: the one farthest from the trunk.
func coffin_root_node() -> String:
	var branch: String = coffin_branch()
	var best: String = ""
	var best_d: float = -1.0
	for n: Dictionary in _nodes:
		if String(n["branch"]) == branch:
			var d: float = position(String(n["id"])).distance_to(coffin_position())
			if best_d < 0.0 or d < best_d:
				best_d = d
				best = String(n["id"])
	return best


func _place(id: String, depth: int) -> Vector2:
	if _positions.has(id):
		return _positions[id]
	var n: Dictionary = _by_id.get(id, {})
	var at := Vector2.ZERO
	if n.has("layout"):
		at = Vector2(float(n["layout"]["x"]), float(n["layout"]["y"]))
	elif depth < 64:
		var parent_ids: Array = n.get("parents", [])
		var from: Vector2 = _place(String(parent_ids[0]), depth + 1) if not parent_ids.is_empty() and _by_id.has(String(parent_ids[0])) else Vector2(640, 200)
		at = from + _direction(String(n.get("branch", ""))) * STEP
	_positions[id] = at
	return at


func _direction(branch: String) -> Vector2:
	for b: Dictionary in _branches:
		if String(b["id"]) == branch:
			var d: Array = b.get("direction", [0, 1])
			return Vector2(float(d[0]), float(d[1])).normalized()
	return Vector2.DOWN

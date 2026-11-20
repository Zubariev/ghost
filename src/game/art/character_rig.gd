## A family member's painted cutout rig (character pipeline pilot, 2026-11-20; docs/art/characters/
## CHARACTER_PIPELINE.md). Loaded from `assets/art/characters/<id>/rig.json` (built by
## tools/art/rig_build.py): per view ("front", "side" facing right, "back", "sit") a set of painted
## parts — texture, origin and pivot in the rig canvas, parent, draw order — the foot point and the
## art's px per metre; and keyframed clips. Drawn immediately on the room canvas so people stay in
## the room's one depth-sorted pass with the furniture (no scene nodes).
##
## A pose is {part: [rotation_deg, dx, dy, scale_y]}; "root" moves the whole figure. Clips are
## {view, length, loop, tracks: {part: [[t, rot, dx, dy, sy?], ...]}}, eased between keys.
##
## [codeblock]
## var rig := CharacterRig.load_for("grandma")
## var pose: Dictionary = rig.sample("walk_side", 0.4)
## rig.draw(canvas, "side", pose, foot, RoomGeometry.scale_at(v), facing_left)
## [/codeblock]
class_name CharacterRig
extends RefCounted

const DIR: String = "res://assets/art/characters"

var id: String = ""
var height_m: float = 1.6
## Metres covered by one walk cycle (two steps): the walk clip advances by the distance walked.
var stride_m: float = 1.1
var views: Dictionary = {}
var clips: Dictionary = {}
var _textures: Dictionary = {}
## view -> part names in draw order
var _order: Dictionary = {}


## The rig of family member [param npc_id], or null when it has none (drawn in code instead).
static func load_for(npc_id: String) -> CharacterRig:
	var path: String = "%s/%s/rig.json" % [DIR, npc_id]
	if not FileAccess.file_exists(path):
		return null
	return CharacterRig.new(JsonData.read(path))


func _init(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	height_m = float(data.get("height_m", 1.6))
	stride_m = float(data.get("stride_m", 1.1))
	views = data.get("views", {})
	clips = data.get("clips", {})
	for view: String in views:
		var parts: Dictionary = views[view]["parts"]
		var names: Array = parts.keys()
		names.sort_custom(func(a: String, b: String) -> bool: return int(parts[a]["z"]) < int(parts[b]["z"]))
		_order[view] = names


func has_clip(name: String) -> bool:
	return clips.has(name)


## The view a clip is drawn in.
func clip_view(name: String) -> String:
	return String(clips.get(name, {}).get("view", "front"))


func clip_length(name: String) -> float:
	return float(clips.get(name, {}).get("length", 1.0))


## The pose of clip [param name] at [param t] seconds (looping clips wrap; others hold the end).
func sample(name: String, t: float) -> Dictionary:
	var clip: Dictionary = clips.get(name, {})
	var length: float = maxf(0.001, float(clip.get("length", 1.0)))
	var time: float = fposmod(t, length) if bool(clip.get("loop", true)) else clampf(t, 0.0, length)
	var pose: Dictionary = {}
	var tracks: Dictionary = clip.get("tracks", {})
	for part: String in tracks:
		pose[part] = _sample_track(tracks[part], time)
	return pose


## [param a] blended toward [param b] by [param t] (0..1); parts missing on one side are at rest.
static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = {}
	var rest := [0.0, 0.0, 0.0, 1.0]
	for part: String in a.keys() + b.keys():
		if out.has(part):
			continue
		var pa: Array = a.get(part, rest)
		var pb: Array = b.get(part, rest)
		out[part] = [lerpf(pa[0], pb[0], t), lerpf(pa[1], pb[1], t), lerpf(pa[2], pb[2], t), lerpf(pa[3], pb[3], t)]
	return out


## Screen px per rig canvas px for a figure drawn at room scale [param s] in [param view].
func screen_scale(view: String, s: float) -> float:
	return RoomGeometry.ART_PX_PER_M * s / float(views[view].get("px_per_m", 227.0))


## Draws the figure in [param view] with [param pose], its foot on [param foot] at room scale
## [param s]; [param flip] mirrors it (facing left in the side view). [param squeeze] (0..1)
## narrows it for a turn between views. [param tint] modulates every part.
func draw(canvas: CanvasItem, view: String, pose: Dictionary, foot: Vector2, s: float, flip: bool,
		squeeze: float = 1.0, tint: Color = Color.WHITE) -> void:
	if not views.has(view):
		return
	var v: Dictionary = views[view]
	var k: float = screen_scale(view, s)
	var foot_art := Vector2(float(v["foot"][0]), float(v["foot"][1]))
	var to_screen := Transform2D(Vector2(k * squeeze * (-1.0 if flip else 1.0), 0), Vector2(0, k), foot) * Transform2D(0.0, -foot_art)
	var world: Dictionary = {}
	for name: String in _order[view]:
		world[name] = _world(v["parts"], name, pose, world)
	for name: String in _order[view]:
		var part: Dictionary = v["parts"][name]
		var tex: Texture2D = _texture(String(part["texture"]))
		if tex == null:
			continue
		canvas.draw_set_transform_matrix(to_screen * world[name])
		canvas.draw_texture(tex, Vector2(float(part["origin"][0]), float(part["origin"][1])), tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## Screen point of a part's pivot (e.g. "head" for a float or a breath cloud).
func part_point(view: String, pose: Dictionary, part: String, foot: Vector2, s: float, flip: bool) -> Vector2:
	var v: Dictionary = views.get(view, {})
	if v.is_empty() or not v["parts"].has(part):
		return foot
	var k: float = screen_scale(view, s)
	var foot_art := Vector2(float(v["foot"][0]), float(v["foot"][1]))
	var world: Dictionary = {}
	var t: Transform2D = _world(v["parts"], part, pose, world)
	var p: Vector2 = t * Vector2(float(v["parts"][part]["pivot"][0]), float(v["parts"][part]["pivot"][1]))
	return foot + Vector2((p.x - foot_art.x) * (-1.0 if flip else 1.0), p.y - foot_art.y) * k


# A part's transform in the rig canvas: its parent's, then its own rotation and stretch about its
# pivot and its offset; parts without a parent follow "root".
func _world(parts: Dictionary, name: String, pose: Dictionary, cache: Dictionary) -> Transform2D:
	if cache.has(name):
		return cache[name]
	var part: Dictionary = parts[name]
	var parent: String = String(part.get("parent", ""))
	var base: Transform2D = _local(Vector2.ZERO, pose.get("root", [0.0, 0.0, 0.0, 1.0]))
	if not parent.is_empty() and parts.has(parent):
		base = _world(parts, parent, pose, cache)
	var pivot := Vector2(float(part["pivot"][0]), float(part["pivot"][1]))
	var t: Transform2D = base * _local(pivot, pose.get(name, [0.0, 0.0, 0.0, 1.0]))
	cache[name] = t
	return t


static func _local(pivot: Vector2, p: Array) -> Transform2D:
	var rot: float = deg_to_rad(float(p[0]))
	var sy: float = float(p[3]) if p.size() > 3 else 1.0
	return Transform2D(0.0, Vector2(float(p[1]), float(p[2])) + pivot) * Transform2D(rot, Vector2(1.0, sy), 0.0, Vector2.ZERO) * Transform2D(0.0, -pivot)


# A track's value at [param t]: eased (smoothstep) between the keys around it.
static func _sample_track(keys: Array, t: float) -> Array:
	if keys.is_empty():
		return [0.0, 0.0, 0.0, 1.0]
	var prev: Array = keys[0]
	for key: Array in keys:
		if float(key[0]) >= t:
			var span: float = float(key[0]) - float(prev[0])
			var f: float = 0.0 if span <= 0.0 else smoothstep(0.0, 1.0, (t - float(prev[0])) / span)
			return [lerpf(_v(prev, 1, 0.0), _v(key, 1, 0.0), f), lerpf(_v(prev, 2, 0.0), _v(key, 2, 0.0), f),
				lerpf(_v(prev, 3, 0.0), _v(key, 3, 0.0), f), lerpf(_v(prev, 4, 1.0), _v(key, 4, 1.0), f)]
		prev = key
	var last: Array = keys[keys.size() - 1]
	return [_v(last, 1, 0.0), _v(last, 2, 0.0), _v(last, 3, 0.0), _v(last, 4, 1.0)]


static func _v(key: Array, i: int, fallback: float) -> float:
	return float(key[i]) if key.size() > i else fallback


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path]

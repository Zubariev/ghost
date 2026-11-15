## Which look each room and prop uses, so code-drawn placeholders can be swapped for painted
## sprites without touching gameplay (Whimsical Gothic Storybook art direction, 2026-11-15).
## Config: `assets/art/visual_style.json`.
##
## [br]- [code]storybook_rooms[/code]: rooms drawn in the storybook style (the rest keep the
##   original placeholder look until they are restyled).
## [br]- [code]sprites[/code]: per furniture kind (or [code]kind:variant[/code]), a painted
##   image to draw instead of the code-drawn shape, optionally one per visual state, with its
##   anchor (the point that sits on the piece's floor position) and scale. An empty or
##   missing file falls back to the code drawing.
##
## Gameplay never reads this: walking footprints, sight blockers, hiding spots and
## interaction ranges stay in `assets/data/` and do not depend on any image's size.
##
## [codeblock]
## var visuals := PropVisuals.new(JsonData.read(PropVisuals.STYLE_PATH))
## var tex: Texture2D = visuals.texture_for("armchair", "", &"free")   # null = draw in code
## [/codeblock]
class_name PropVisuals
extends RefCounted

const STYLE_PATH: String = "res://assets/art/visual_style.json"

var _storybook_rooms: Array = []
var _sprites: Dictionary = {}
## Room wear numbers (art Phase 2): see visual_style.json "_wear".
var _wear: Dictionary = {}
## room id -> side-wall portraits (art Phase 1): [{wall, v: [from, to], h: [from, to], variant}]
var _wall_portraits: Dictionary = {}
## Loads a texture by path; injectable for tests. Default: ResourceLoader when the file exists.
var _loader: Callable
var _cache: Dictionary = {}


func _init(config: Dictionary, loader: Callable = Callable()) -> void:
	_storybook_rooms = config.get("storybook_rooms", [])
	_sprites = config.get("sprites", {})
	_wall_portraits = config.get("wall_portraits", {})
	_wear = config.get("wear", {})
	_loader = loader if loader.is_valid() else _load_texture


## True when [param room_id] is drawn in the storybook style.
func is_storybook(room_id: String) -> bool:
	return _storybook_rooms.has(room_id)


## The room-wear numbers ([RoomWear] and the room view), from visual_style.json "wear".
func wear_config() -> Dictionary:
	return _wear


## Framed portraits hung on the side walls of [param room_id] (art config only: never furniture,
## never an obstacle). Each: wall "left"/"right", v [from, to] along the wall (0 back .. 1 front),
## h [from, to] up the wall (0 floor .. 1 top), variant.
func wall_portraits(room_id: String) -> Array:
	return _wall_portraits.get(room_id, [])


## The image path for a prop: the state's own image if given, else the prop's image; "" when
## it is drawn in code. [param variant] picks "kind:variant" entries first.
func sprite_path(kind: String, variant: String, state: StringName) -> String:
	var entry: Dictionary = _entry(kind, variant)
	if entry.is_empty():
		return ""
	var by_state: Dictionary = entry.get("states", {})
	var path: String = String(by_state.get(String(state), ""))
	return path if not path.is_empty() else String(entry.get("sprite", ""))


## The painted image for a prop, or null when it is drawn in code (no entry, or the file is
## missing).
func texture_for(kind: String, variant: String, state: StringName) -> Texture2D:
	var path: String = sprite_path(kind, variant, state)
	if path.is_empty():
		return null
	if not _cache.has(path):
		_cache[path] = _loader.call(path)
	return _cache[path]


## Anchor of the prop's image (0..1 of its size) that sits on the floor position; default
## bottom centre.
func anchor(kind: String, variant: String) -> Vector2:
	var a: Array = _entry(kind, variant).get("anchor", [0.5, 1.0])
	return Vector2(float(a[0]), float(a[1]))


## Where the code-drawn animation of a painted prop sits (art Phase 3): the offset in screen
## px at depth 1 from the prop's floor point; e.g. the fire inside a painted fireplace's firebox.
func effects_offset(kind: String, variant: String) -> Vector2:
	var o: Array = (_entry(kind, variant).get("effects", {}) as Dictionary).get("offset", [0, 0])
	return Vector2(float(o[0]), float(o[1]))


## Scale of the code-drawn animation of a painted prop (1 = as in the code drawing).
func effects_scale(kind: String, variant: String) -> float:
	return float((_entry(kind, variant).get("effects", {}) as Dictionary).get("scale", 1.0))


## Image scale at the front of the room (depth scaling is applied on top).
func scale(kind: String, variant: String) -> float:
	return float(_entry(kind, variant).get("scale", 1.0))


## Draws the painted image of a prop with its foot at [param foot] and depth scale
## [param depth]; [param highlighted] adds the interaction halo. False when there is no image.
func draw_sprite(canvas: CanvasItem, kind: String, variant: String, state: StringName, foot: Vector2, depth: float, highlighted: bool) -> bool:
	var tex: Texture2D = texture_for(kind, variant, state)
	if tex == null:
		return false
	var size: Vector2 = tex.get_size() * scale(kind, variant) * depth
	var rect := Rect2(foot - anchor(kind, variant) * size, size)
	if highlighted:
		Ink.glow(canvas, rect.get_center(), rect.size * 0.62, Color(Palette.SB_HIGHLIGHT, 0.5))
	canvas.draw_texture_rect(tex, rect, false)
	return true


func _entry(kind: String, variant: String) -> Dictionary:
	if not variant.is_empty() and _sprites.has(kind + ":" + variant):
		return _sprites[kind + ":" + variant]
	return _sprites.get(kind, {})


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("PropVisuals: missing sprite %s; drawing in code" % path)
		return null
	return load(path) as Texture2D

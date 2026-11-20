## Painted walls, floors and rugs (user review 2026-11-20: textures from the user's references,
## generated in the storybook style). A room's surfaces come from `assets/art/visual_style.json`
## → `surfaces` (room id, or "default"): a wall texture, an optional wainscot texture up to
## `wainscot_m`, a floor texture, each with its real tile size in metres. Everything is laid in
## the room camera's perspective ([RoomGeometry]): the floor in thin depth rows and the side walls
## in thin strips, so boards and tiles shrink correctly toward the back. Textures repeat mirrored
## (seamless) — the canvas drawing them sets [code]texture_repeat[/code] to mirror.
##
## [codeblock]
## var surfaces := RoomSurfaces.new(JsonData.read(PropVisuals.STYLE_PATH).get("surfaces", {}))
## if surfaces.has_room("kitchen"): surfaces.draw_room(canvas, "kitchen", wall_alpha)
## [/codeblock]
class_name RoomSurfaces
extends RefCounted

## Thin rows / strips used to approximate perspective with flat-shaded triangles.
const ROWS: int = 24
const STRIPS: int = 16
## Darker at the back wall and toward the top of a wall (the room's light is low and in front).
const BACK_SHADE: float = 0.72
const TOP_SHADE: float = 0.8

var _config: Dictionary = {}
var _cache: Dictionary = {}


func _init(config: Dictionary) -> void:
	_config = config


## True when [param room_id] (or the "default" entry) has painted surfaces.
func has_room(room_id: String) -> bool:
	return not _room(room_id).is_empty() and texture(String(_room(room_id).get("wall", ""))) != null


## The rug texture, or null.
func rug_texture() -> Texture2D:
	return texture(String(_config.get("rug", "")))


## The corner cobweb texture (white on transparent, a top-left corner), or null.
func web_texture() -> Texture2D:
	return texture(String(_config.get("web", "")))


## Draws the floor (with its front edge), the back wall and both side walls of [param room_id].
## [param wall_alpha]: {back, left, right} fading a wall the ghost is inside.
func draw_room(canvas: CanvasItem, room_id: String, wall_alpha: Dictionary) -> void:
	var cfg: Dictionary = _room(room_id)
	draw_floor(canvas, cfg)
	draw_back_wall(canvas, cfg, float(wall_alpha.get("back", 1.0)))
	draw_side_wall(canvas, cfg, true, float(wall_alpha.get("left", 1.0)))
	draw_side_wall(canvas, cfg, false, float(wall_alpha.get("right", 1.0)))


func draw_floor(canvas: CanvasItem, cfg: Dictionary) -> void:
	var size: Vector2 = RoomGeometry.ROOM_SIZE_M
	var edge := Vector2(0, RoomGeometry.FLOOR_EDGE)
	canvas.draw_colored_polygon(PackedVector2Array([RoomGeometry.FRONT_LEFT, RoomGeometry.FRONT_RIGHT,
		RoomGeometry.FRONT_RIGHT + edge, RoomGeometry.FRONT_LEFT + edge]), Palette.SB_WALNUT_DARK)
	var tex: Texture2D = texture(String(cfg.get("floor", "")))
	if tex == null:
		canvas.draw_colored_polygon(RoomGeometry.floor_polygon(), Palette.SB_FLOOR)
		return
	var tile: Vector2 = _tile(cfg, "floor_tile_m", Vector2(2.0, 2.0))
	for i: int in ROWS:
		var v0: float = float(i) / float(ROWS)
		var v1: float = float(i + 1) / float(ROWS)
		var c0 := Color.WHITE.darkened(1.0 - lerpf(BACK_SHADE, 1.0, v0))
		var c1 := Color.WHITE.darkened(1.0 - lerpf(BACK_SHADE, 1.0, v1))
		var points := PackedVector2Array([RoomGeometry.to_screen(Vector2(0, v0)), RoomGeometry.to_screen(Vector2(1, v0)),
			RoomGeometry.to_screen(Vector2(1, v1)), RoomGeometry.to_screen(Vector2(0, v1))])
		var uvs := PackedVector2Array([Vector2(0, v0 * size.y) / tile, Vector2(size.x, v0 * size.y) / tile,
			Vector2(size.x, v1 * size.y) / tile, Vector2(0, v1 * size.y) / tile])
		canvas.draw_polygon(points, PackedColorArray([c0, c0, c1, c1]), uvs, tex)
	Ink.outline(canvas, RoomGeometry.floor_polygon(), Ink.Tier.FURNITURE, 3.0)


func draw_back_wall(canvas: CanvasItem, cfg: Dictionary, alpha: float) -> void:
	var w: float = RoomGeometry.ROOM_SIZE_M.x
	for band: Array in _bands(cfg):
		var h0: float = band[1]
		var h1: float = band[2]
		var tex: Texture2D = band[0]
		var tile: Vector2 = band[3]
		var points := PackedVector2Array([RoomGeometry.back_wall_point(0.0, h1), RoomGeometry.back_wall_point(1.0, h1),
			RoomGeometry.back_wall_point(1.0, h0), RoomGeometry.back_wall_point(0.0, h0)])
		var top := Color(Color.WHITE.darkened(1.0 - lerpf(1.0, TOP_SHADE, h1)), alpha)
		var bottom := Color(Color.WHITE.darkened(1.0 - lerpf(1.0, TOP_SHADE, h0)), alpha)
		var hm0: float = (1.0 - h0) * RoomGeometry.WALL_HEIGHT_M
		var hm1: float = (1.0 - h1) * RoomGeometry.WALL_HEIGHT_M
		var uvs := PackedVector2Array([Vector2(0, hm1) / tile, Vector2(w, hm1) / tile, Vector2(w, hm0) / tile, Vector2(0, hm0) / tile])
		if tex == null:
			top *= Palette.SB_WALL
			bottom *= Palette.SB_WALL
		canvas.draw_polygon(points, PackedColorArray([top, top, bottom, bottom]), uvs, tex)
	var poly: PackedVector2Array = RoomGeometry.back_wall_polygon()
	_rail(canvas, cfg, PackedVector2Array([RoomGeometry.back_wall_point(0.0, _wainscot(cfg)), RoomGeometry.back_wall_point(1.0, _wainscot(cfg))]), alpha)
	Ink.outline(canvas, poly, Ink.Tier.FURNITURE, 1.0, Color(Palette.SB_CONTOUR, alpha))
	Ink.line(canvas, PackedVector2Array([poly[0], poly[1]]), Ink.Tier.FURNITURE, 2.0, Color(Palette.SB_WALNUT_DARK, alpha), 3.0)


func draw_side_wall(canvas: CanvasItem, cfg: Dictionary, left: bool, alpha: float) -> void:
	var d: float = RoomGeometry.ROOM_SIZE_M.y
	for band: Array in _bands(cfg):
		var tex: Texture2D = band[0]
		var h0: float = band[1]
		var h1: float = band[2]
		var tile: Vector2 = band[3]
		var hm0: float = (1.0 - h0) * RoomGeometry.WALL_HEIGHT_M
		var hm1: float = (1.0 - h1) * RoomGeometry.WALL_HEIGHT_M
		for i: int in STRIPS:
			var v0: float = float(i) / float(STRIPS)
			var v1: float = float(i + 1) / float(STRIPS)
			var points := PackedVector2Array([RoomGeometry.side_wall_point(left, v0, h1), RoomGeometry.side_wall_point(left, v1, h1),
				RoomGeometry.side_wall_point(left, v1, h0), RoomGeometry.side_wall_point(left, v0, h0)])
			# Side walls a little darker than the back wall, darker still toward the front corner.
			var k0: float = 0.86 - 0.12 * v0
			var k1: float = 0.86 - 0.12 * v1
			var top0 := Color(Color.WHITE.darkened(1.0 - k0 * lerpf(1.0, TOP_SHADE, h1)), alpha)
			var top1 := Color(Color.WHITE.darkened(1.0 - k1 * lerpf(1.0, TOP_SHADE, h1)), alpha)
			var bot0 := Color(Color.WHITE.darkened(1.0 - k0 * lerpf(1.0, TOP_SHADE, h0)), alpha)
			var bot1 := Color(Color.WHITE.darkened(1.0 - k1 * lerpf(1.0, TOP_SHADE, h0)), alpha)
			var a: float = (v0 * d if left else (1.0 - v0) * d)
			var b: float = (v1 * d if left else (1.0 - v1) * d)
			var uvs := PackedVector2Array([Vector2(a, hm1) / tile, Vector2(b, hm1) / tile, Vector2(b, hm0) / tile, Vector2(a, hm0) / tile])
			canvas.draw_polygon(points, PackedColorArray([top0, top1, bot1, bot0]), uvs, tex)
	var poly: PackedVector2Array = RoomGeometry.left_wall_polygon() if left else RoomGeometry.right_wall_polygon()
	_rail(canvas, cfg, PackedVector2Array([RoomGeometry.side_wall_point(left, 1.0, _wainscot(cfg)), RoomGeometry.side_wall_point(left, 0.0, _wainscot(cfg))]), alpha)
	Ink.outline(canvas, poly, Ink.Tier.FURNITURE, 4.0 if left else 6.0, Color(Palette.SB_CONTOUR, alpha))
	Ink.line(canvas, PackedVector2Array([poly[0], poly[1]]), Ink.Tier.FURNITURE, 7.0, Color(Palette.SB_WALNUT_DARK, alpha), 3.0)


## A rug of [param size_m] metres (width, depth) centred on floor position [param uv], laid in
## perspective. Draws nothing without a rug texture.
func draw_rug(canvas: CanvasItem, uv: Vector2, size_m: Vector2) -> bool:
	var tex: Texture2D = rug_texture()
	if tex == null:
		return false
	var half: Vector2 = size_m / RoomGeometry.ROOM_SIZE_M / 2.0
	var rows: int = 8
	for i: int in rows:
		var t0: float = float(i) / float(rows)
		var t1: float = float(i + 1) / float(rows)
		var v0: float = uv.y - half.y + 2.0 * half.y * t0
		var v1: float = uv.y - half.y + 2.0 * half.y * t1
		var points := PackedVector2Array([RoomGeometry.to_screen(Vector2(uv.x - half.x, v0)), RoomGeometry.to_screen(Vector2(uv.x + half.x, v0)),
			RoomGeometry.to_screen(Vector2(uv.x + half.x, v1)), RoomGeometry.to_screen(Vector2(uv.x - half.x, v1))])
		var shade0 := Color.WHITE.darkened(1.0 - lerpf(BACK_SHADE, 1.0, clampf(v0, 0.0, 1.0)))
		var shade1 := Color.WHITE.darkened(1.0 - lerpf(BACK_SHADE, 1.0, clampf(v1, 0.0, 1.0)))
		canvas.draw_polygon(points, PackedColorArray([shade0, shade0, shade1, shade1]),
			PackedVector2Array([Vector2(0, t0), Vector2(1, t0), Vector2(1, t1), Vector2(0, t1)]), tex)
	return true


## A texture by path, loaded once; null when the path is empty or missing.
func texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _cache.has(path):
		_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[path]


func _room(room_id: String) -> Dictionary:
	var rooms: Dictionary = _config.get("rooms", {})
	return rooms.get(room_id, rooms.get("default", {}))


# Wall bands: [texture, low, high (0..1 of the wall's height, 0 = floor), tile in metres]. A
# wainscot (when given) up to wainscot_m, the wallpaper above. Texture rows run down from the
# ceiling, so a pattern lines up along the top of every wall.
func _bands(cfg: Dictionary) -> Array:
	var wall: Texture2D = texture(String(cfg.get("wall", "")))
	var tile: Vector2 = _tile(cfg, "wall_tile_m", Vector2(1.0, 1.0))
	var wainscot: Texture2D = texture(String(cfg.get("wainscot", "")))
	if wainscot == null:
		return [[wall, 0.0, 1.0, tile]]
	var split: float = _wainscot(cfg)
	return [[wainscot, 0.0, split, _tile(cfg, "wainscot_tile_m", Vector2(1.2, 1.2))], [wall, split, 1.0, tile]]


## Height of the wainscot rail as a fraction of the wall (0 when there is none).
func _wainscot(cfg: Dictionary) -> float:
	if texture(String(cfg.get("wainscot", ""))) == null:
		return 0.0
	return clampf(float(cfg.get("wainscot_m", 0.9)) / RoomGeometry.WALL_HEIGHT_M, 0.0, 1.0)


func _rail(canvas: CanvasItem, cfg: Dictionary, line: PackedVector2Array, alpha: float) -> void:
	if _wainscot(cfg) <= 0.0:
		return
	Ink.line(canvas, line, Ink.Tier.FURNITURE, 5.0, Color(Palette.SB_WALNUT_DARK, alpha), 2.5)


static func _tile(cfg: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var t: Array = cfg.get(key, [])
	return Vector2(float(t[0]), float(t[1])) if t.size() == 2 else fallback

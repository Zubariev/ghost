## Rooms of different sizes on one scale (user decision 2026-11-20, "zoomed"): each room's floor
## is its real width × depth (rooms.json size_m) within the full box
## ([code]assets/data/house/room_view.json[/code]), and the whole house shares one zoom so the
## largest room fills the view; a smaller room sits centred. People and props keep one size in
## every room.
##
## [codeblock]
## var view := RoomView.new(JsonData.read(RoomView.CONFIG_PATH), {"kitchen": Vector2(4.5, 4.0)})
## view.apply("kitchen", stage)          # floor size, zoom and centring for the kitchen
## var p: Vector2 = RoomGeometry.to_display(RoomGeometry.to_screen(uv))   # for the HUD
## [/codeblock]
class_name RoomView
extends RefCounted

const CONFIG_PATH: String = "res://assets/data/house/room_view.json"

var _full := Vector2(10.6, 7.5)
var _area := Rect2(20, 60, 1240, 585)
## room id -> real size in metres (width, depth)
var _sizes: Dictionary = {}
var _zoom: float = 1.0
var _room: String = ""


## [param sizes]: room id -> real floor size in metres (Vector2 width, depth).
func _init(config: Dictionary, sizes: Dictionary) -> void:
	var f: Array = config.get("full_box_size_m", [])
	if f.size() == 2:
		_full = Vector2(float(f[0]), float(f[1]))
	var a: Array = config.get("view_area", [])
	if a.size() == 4:
		_area = Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	_sizes = sizes
	_zoom = INF
	for room_id: String in _sizes:   # the zoom at which every room fits; the largest fills the view
		var k: Vector2 = floor_scale(room_id)
		RoomGeometry.set_floor_scale(k.x, k.y)
		var box: Rect2 = RoomGeometry.bounds()
		_zoom = minf(_zoom, minf(_area.size.x / box.size.x, _area.size.y / box.size.y))
	if _zoom == INF:
		_zoom = 1.0
	RoomGeometry.set_floor_scale(1.0)


## The one zoom of the house (the widest room fills the view).
func zoom() -> float:
	return _zoom


## The floor of [param room_id] as a fraction of the full box, width and depth (1, 1 when its
## size is unknown).
func floor_scale(room_id: String) -> Vector2:
	var s: Vector2 = _sizes.get(room_id, _full)
	return s / _full


## Sets the room geometry for [param room_id] and places [param stage] (zoom, centred in the
## view); the HUD maps room points through [method RoomGeometry.to_display]. Cheap when the room
## is unchanged.
func apply(room_id: String, stage: Node2D) -> void:
	if room_id == _room:
		return
	_room = room_id
	var k: Vector2 = floor_scale(room_id)
	RoomGeometry.set_floor_scale(k.x, k.y)
	RoomGeometry.ROOM_SIZE_M = _sizes.get(room_id, _full)
	var offset: Vector2 = _area.get_center() - RoomGeometry.bounds().get_center() * _zoom
	RoomGeometry.set_view(_zoom, offset)
	if stage != null:
		stage.scale = Vector2(_zoom, _zoom)
		stage.position = offset


## Back to the full box with no zoom (leaving the game; tests).
static func reset() -> void:
	RoomGeometry.set_floor_scale(1.0)
	RoomGeometry.ROOM_SIZE_M = Vector2(10.6, 7.5)
	RoomGeometry.set_view(1.0, Vector2.ZERO)

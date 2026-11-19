## Rooms of different sizes on one scale (user decision 2026-11-20, "zoomed"): each room's floor
## is its real width ([code]assets/data/house/room_view.json[/code]) within the full box, and the
## whole house shares one zoom so the widest room fills the view; a smaller room sits centred.
## People and props keep one size in every room. Positions stay relative (u, v).
##
## [codeblock]
## var view := RoomView.new(JsonData.read(RoomView.CONFIG_PATH))
## view.apply("kitchen", stage)          # floor size, zoom and centring for the kitchen
## var p: Vector2 = RoomGeometry.to_display(RoomGeometry.to_screen(uv))   # for the HUD
## [/codeblock]
class_name RoomView
extends RefCounted

const CONFIG_PATH: String = "res://assets/data/house/room_view.json"

var _full_width: float = 10.6
var _area := Rect2(20, 60, 1240, 585)
var _widths: Dictionary = {}
var _zoom: float = 1.0
var _room: String = ""


func _init(config: Dictionary) -> void:
	_full_width = float(config.get("full_box_width_m", _full_width))
	var a: Array = config.get("view_area", [])
	if a.size() == 4:
		_area = Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	_widths = config.get("width_m", {})
	var widest: float = 0.0
	for w: Variant in _widths.values():
		widest = maxf(widest, float(w))
	if widest > 0.0:
		RoomGeometry.set_floor_scale(widest / _full_width)
		var box: Rect2 = RoomGeometry.bounds()
		_zoom = minf(_area.size.x / box.size.x, _area.size.y / box.size.y)
		RoomGeometry.set_floor_scale(1.0)


## The one zoom of the house (the widest room fills the view).
func zoom() -> float:
	return _zoom


## The floor of [param room_id] as a fraction of the full box (1.0 when its size is unknown).
func floor_scale(room_id: String) -> float:
	return float(_widths.get(room_id, _full_width)) / _full_width


## Sets the room geometry for [param room_id] and places [param stage] (zoom, centred in the
## view); the HUD maps room points through [method RoomGeometry.to_display]. Cheap when the room
## is unchanged.
func apply(room_id: String, stage: Node2D) -> void:
	if room_id == _room:
		return
	_room = room_id
	RoomGeometry.set_floor_scale(floor_scale(room_id))
	var offset: Vector2 = _area.get_center() - RoomGeometry.bounds().get_center() * _zoom
	RoomGeometry.set_view(_zoom, offset)
	if stage != null:
		stage.scale = Vector2(_zoom, _zoom)
		stage.position = offset


## Back to the full box with no zoom (leaving the game; tests).
static func reset() -> void:
	RoomGeometry.set_floor_scale(1.0)
	RoomGeometry.set_view(1.0, Vector2.ZERO)

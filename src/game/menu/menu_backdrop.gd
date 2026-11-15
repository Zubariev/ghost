## The main menu's background (2026-11-15): a dark painted wall, the user's illustrated living
## room (`assets/art/ui/menu/menu_room.png`, cut out from `art/references/Вікторіанська вітальня та
## кнопки UI.png`) on the right, and a dark shade on the left behind the menu. The room image is
## drawn once; the subtle animation sits on a separate layer that alone redraws each frame:
## firelight breathing on the stones and floor, a few embers rising, dust motes drifting in the
## window light, a candle glow, and now and then the ghost glimpsed in the window.
## Positions of the fire, window and candle are in the image's own pixels (ROOM_*).
class_name MenuBackdrop
extends Control

const ROOM_PATH: String = "res://assets/art/ui/menu/menu_room.png"
const SCREEN := Vector2(1280, 720)
## Points in the room image (px) the animation is tied to.
const ROOM_FIRE := Vector2(860, 520)
const ROOM_WINDOW := Rect2(370, 118, 130, 340)
const ROOM_CANDLE := Vector2(968, 262)
const WALL_TOP := Color("2b2119")
const WALL_BOTTOM := Color("17110d")
## The ghost shows in the window for GHOST_SECONDS every GHOST_EVERY seconds.
const GHOST_EVERY: float = 24.0
const GHOST_SECONDS: float = 4.5

var _room: Texture2D
var _room_rect := Rect2()
var _ambience: Control
var _ghost: Control
var _time: float = 0.0


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room = load(ROOM_PATH) as Texture2D if ResourceLoader.exists(ROOM_PATH) else null
	if _room != null:
		var scale_to: float = SCREEN.y / _room.get_size().y
		var room_size: Vector2 = _room.get_size() * scale_to
		_room_rect = Rect2(Vector2(SCREEN.x - room_size.x, SCREEN.y - room_size.y), room_size)
	_ghost = Control.new()
	_ghost.size = SCREEN
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.modulate.a = 0.0
	_ghost.draw.connect(_draw_ghost)
	add_child(_ghost)
	_ambience = Control.new()
	_ambience.size = SCREEN
	_ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ambience.draw.connect(_draw_ambience)
	add_child(_ambience)


func _process(delta: float) -> void:
	_time += delta
	var cycle: float = fposmod(_time, GHOST_EVERY)
	var t: float = clampf((cycle - (GHOST_EVERY - GHOST_SECONDS)) / GHOST_SECONDS, 0.0, 1.0)
	_ghost.modulate.a = 0.32 * sin(t * PI)
	if _ghost.modulate.a > 0.0:
		_ghost.queue_redraw()
	_ambience.queue_redraw()


## Seconds of animation shown (captures set it to show a moment).
func set_time(seconds: float) -> void:
	_time = seconds
	_process(0.0)


func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(SCREEN.x, 0), SCREEN, Vector2(0, SCREEN.y)]),
		PackedColorArray([WALL_TOP, WALL_TOP, WALL_BOTTOM, WALL_BOTTOM]))
	if _room != null:
		draw_texture_rect(_room, _room_rect, false)
	# Shade behind the menu, so the plaques stand clear of the painting.
	var shade := Color(0.04, 0.03, 0.02, 0.9)
	var clear := Color(shade, 0.0)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(640, 0), Vector2(640, SCREEN.y), Vector2(0, SCREEN.y)]),
		PackedColorArray([shade, clear, clear, shade]))


## A point of the room image on screen.
func _at(room_px: Vector2) -> Vector2:
	if _room == null:
		return room_px
	return _room_rect.position + room_px * (_room_rect.size.x / _room.get_size().x)


func _draw_ambience() -> void:
	if _room == null:
		return
	var s: float = _room_rect.size.x / _room.get_size().x
	var flicker: float = 0.5 + 0.3 * sin(_time * 7.1) * sin(_time * 3.3 + 1.0) + 0.2 * sin(_time * 13.7)
	var fire: Vector2 = _at(ROOM_FIRE)
	# Firelight breathing on the stones, and a pool on the floor
	Ink.glow(_ambience, fire + Vector2(0, -20) * s, Vector2(150, 95) * s, Color(Palette.SB_CANDLELIGHT, 0.10 + 0.07 * flicker), 6)
	Ink.glow(_ambience, fire + Vector2(-20, 130) * s, Vector2(260, 46) * s, Color(Palette.SB_CANDLELIGHT, 0.07 + 0.05 * flicker), 5)
	# Embers rising from the fire
	for i: int in 9:
		var life: float = fposmod(_time * 0.35 + float(i) * 0.137, 1.0)
		var x: float = sin(float(i) * 2.3 + _time * 1.7) * 18.0 + (float(i) - 4.0) * 7.0
		var p: Vector2 = fire + Vector2(x, -40.0 - 150.0 * life) * s
		_ambience.draw_circle(p, 1.6, Color(Palette.SB_CANDLELIGHT.lightened(0.2), 0.75 * (1.0 - life) * (0.6 + 0.4 * flicker)), true, -1.0, true)
	# Candle on the mantel
	var candle: Vector2 = _at(ROOM_CANDLE)
	Ink.glow(_ambience, candle, Vector2(22, 26) * s, Color(Palette.SB_CANDLELIGHT, 0.10 + 0.05 * sin(_time * 5.3)), 4)
	# Dust motes drifting in the window light
	var win := Rect2(_at(ROOM_WINDOW.position), ROOM_WINDOW.size * s)
	for i: int in 14:
		var k: float = float(i) * 1.618
		var x: float = win.position.x + win.size.x * (0.5 + 0.55 * sin(_time * 0.11 + k * 2.1))
		var y: float = win.position.y + win.size.y * (0.55 + 0.5 * sin(_time * 0.07 + k * 1.3))
		var twinkle: float = 0.5 + 0.5 * sin(_time * 1.3 + k)
		_ambience.draw_circle(Vector2(x, y + 80.0 * s), 1.3, Color(Palette.SB_CREAM, 0.28 * twinkle), true, -1.0, true)


func _draw_ghost() -> void:
	if _room == null:
		return
	var s: float = _room_rect.size.x / _room.get_size().x
	var win_centre: Vector2 = _at(ROOM_WINDOW.get_center())
	var drift: float = fposmod(_time, GHOST_EVERY) / GHOST_EVERY
	FamilyArt.draw_ghost(_ghost, win_centre + Vector2(-20.0 + 40.0 * drift, 40.0) * s, 0.55, _time, false)

## Painted doors (sprint 001, phase H, 2026-11-26; user brief item 17): the door image
## ([code]visual_style.json[/code] sprite "door", or "room/door" for one room) laid onto the
## same frames the drawn doors used, so where doors are, where people walk and how rooms connect
## do not change. Side-wall doors follow the wall's perspective (drawn in strips, like the painted
## walls); back-wall doors are flat. Without an image the drawn doors stay.
class_name DoorArt
extends RefCounted

## Along a side wall (0 back .. 1 front) and up it (0..1 of the wall): the drawn doors' frame.
const SIDE_V := Vector2(0.39, 0.61)
const SIDE_HEIGHT: float = 0.64
## Half the back door's width, in floor units across the back wall ([constant RoomLayout.BACK_DOOR_U]).
const BACK_HALF_U: float = 0.07
const STRIPS: int = 8


## The door on the left or right side wall, faded by [param alpha] (a wall the ghost is inside).
static func draw_side(canvas: CanvasItem, tex: Texture2D, left: bool, alpha: float) -> void:
	var tint := Color(0.86, 0.86, 0.86, alpha)   # side walls sit a little darker than the back wall
	for i: int in STRIPS:
		var t0: float = float(i) / float(STRIPS)
		var t1: float = float(i + 1) / float(STRIPS)
		# the image's left edge is the screen-left end of the frame: the front on the left wall,
		# the back on the right wall
		var v0: float = lerpf(SIDE_V.y, SIDE_V.x, t0) if left else lerpf(SIDE_V.x, SIDE_V.y, t0)
		var v1: float = lerpf(SIDE_V.y, SIDE_V.x, t1) if left else lerpf(SIDE_V.x, SIDE_V.y, t1)
		var points := PackedVector2Array([RoomGeometry.side_wall_point(left, v0, SIDE_HEIGHT), RoomGeometry.side_wall_point(left, v1, SIDE_HEIGHT),
			RoomGeometry.side_wall_point(left, v1, 0.0), RoomGeometry.side_wall_point(left, v0, 0.0)])
		var uvs := PackedVector2Array([Vector2(t0, 0), Vector2(t1, 0), Vector2(t1, 1), Vector2(t0, 1)])
		canvas.draw_polygon(points, PackedColorArray([tint, tint, tint, tint]), uvs, tex)


## The door on the back wall at [constant RoomLayout.BACK_DOOR_U].
static func draw_back(canvas: CanvasItem, tex: Texture2D, alpha: float) -> void:
	canvas.draw_texture_rect(tex, back_rect(), false, Color(1, 1, 1, alpha))


## Where the back door is drawn (screen px).
static func back_rect() -> Rect2:
	var bottom_left: Vector2 = RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U - BACK_HALF_U, 0.0)
	var top_right: Vector2 = RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U + BACK_HALF_U, SIDE_HEIGHT)
	return Rect2(bottom_left.x, top_right.y, top_right.x - bottom_left.x, bottom_left.y - top_right.y)

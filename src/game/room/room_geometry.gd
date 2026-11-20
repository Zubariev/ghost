## The Hamlet-style room frame (validated by the 2026-11-12 room spike): a back wall, two
## slanted side walls, no front wall, a floor that narrows toward the back. Positions on the floor
## are (u, v): u left→right 0..1, v back wall 0 → front edge 1; values outside 0..1 reach into the
## walls.
##
## A real pinhole camera (user review 2026-11-20: "objects close to the camera a little bigger —
## a clear math exercise"). The camera stands [constant CAMERA_HEIGHT] m above the floor, looks
## at the room from the front, every room's front edge [constant FRONT_DISTANCE] m away; focal
## length [constant FOCAL] px, horizon at [constant HORIZON_Y]. A floor point X m right of the
## room's centre and Z m from the camera is at
##     x = CENTRE_X + FOCAL · X / Z,   y = HORIZON_Y + FOCAL · (CAMERA_HEIGHT − h) / Z
## (h: height above the floor), and anything there is drawn FOCAL / Z / [constant ART_PX_PER_M]
## times its art size ([method scale_at]). Calibrated so the full 10.6 × 7.5 m box is exactly the
## spike's box (floor corners (330, 250), (950, 250), (1170, 625), (110, 625); back wall 170 px,
## side walls 290 px at the front; ceiling [constant WALL_HEIGHT_M] m). Each room uses its own
## real width and depth ([method set_room]): a shallow room narrows less toward the back.
class_name RoomGeometry
extends RefCounted

const CENTRE_X: float = 640.0
const HORIZON_Y: float = -279.0
const FOCAL: float = 1057.0
const CAMERA_HEIGHT: float = 9.04
## Camera to every room's front edge, metres.
const FRONT_DISTANCE: float = 10.57
## Ceiling height, metres (old house: tall rooms).
const WALL_HEIGHT_M: float = 2.9
## Painted props and people are drawn at this many px per metre at scale 1 (SPRITE_SPEC §2).
const ART_PX_PER_M: float = 75.0
## The full box (the spike's room).
const FULL_SIZE_M := Vector2(10.6, 7.5)
const FULL_BACK_LEFT := Vector2(330, 250)
const FULL_BACK_RIGHT := Vector2(950, 250)
const FULL_FRONT_LEFT := Vector2(110, 625)
const FULL_FRONT_RIGHT := Vector2(1170, 625)
const FLOOR_EDGE: float = 18.0

## The room on screen: real floor size in metres (width u, depth v).
static var ROOM_SIZE_M := FULL_SIZE_M
static var BACK_LEFT := FULL_BACK_LEFT
static var BACK_RIGHT := FULL_BACK_RIGHT
static var FRONT_LEFT := FULL_FRONT_LEFT
static var FRONT_RIGHT := FULL_FRONT_RIGHT
## Wall heights on screen: the back wall, and the side walls at the front edge (px).
static var BACK_WALL_HEIGHT: float = 170.0
static var SIDE_WALL_FRONT_HEIGHT: float = 290.0

## The room view's zoom and offset ([RoomView]): the stage is drawn scaled by VIEW_ZOOM and moved
## by VIEW_OFFSET; screen-space UI (the HUD) maps room points with [method to_display].
static var VIEW_ZOOM: float = 1.0
static var VIEW_OFFSET := Vector2.ZERO


## Sets the room on screen to a floor of [param size_m] metres (width, depth).
static func set_room(size_m: Vector2) -> void:
	ROOM_SIZE_M = size_m
	BACK_LEFT = to_screen(Vector2(0, 0))
	BACK_RIGHT = to_screen(Vector2(1, 0))
	FRONT_LEFT = to_screen(Vector2(0, 1))
	FRONT_RIGHT = to_screen(Vector2(1, 1))
	BACK_WALL_HEIGHT = FOCAL * WALL_HEIGHT_M / distance(0.0)
	SIDE_WALL_FRONT_HEIGHT = FOCAL * WALL_HEIGHT_M / distance(1.0)


## Metres from the camera to depth [param v] of the room's floor.
static func distance(v: float) -> float:
	return FRONT_DISTANCE + (1.0 - v) * ROOM_SIZE_M.y


## Screen point of a floor position (perspective: rows crowd together toward the back).
static func to_screen(uv: Vector2) -> Vector2:
	return project(uv, 0.0)


## Screen point [param height_m] metres above the floor position [param uv].
static func project(uv: Vector2, height_m: float) -> Vector2:
	var z: float = distance(uv.y)
	return Vector2(CENTRE_X + FOCAL * (uv.x - 0.5) * ROOM_SIZE_M.x / z, HORIZON_Y + FOCAL * (CAMERA_HEIGHT - height_m) / z)


## Drawing scale at depth [param v]: art px per metre times this is the screen's px per metre
## there. Points off the floor are clamped to its edges.
static func scale_at(v: float) -> float:
	return FOCAL / distance(clampf(v, 0.0, 1.0)) / ART_PX_PER_M


## Screen px per metre at depth [param v].
static func px_per_m(v: float) -> float:
	return FOCAL / distance(clampf(v, 0.0, 1.0))


static func set_view(zoom: float, offset: Vector2) -> void:
	VIEW_ZOOM = zoom
	VIEW_OFFSET = offset


## Where a point of the room drawing appears on the display (for UI drawn outside the stage).
static func to_display(point: Vector2) -> Vector2:
	return point * VIEW_ZOOM + VIEW_OFFSET


## The screen box the room occupies: walls' tops to the floor's front edge.
static func bounds() -> Rect2:
	var top: float = minf(BACK_LEFT.y - BACK_WALL_HEIGHT, FRONT_LEFT.y - SIDE_WALL_FRONT_HEIGHT)
	return Rect2(FRONT_LEFT.x, top, FRONT_RIGHT.x - FRONT_LEFT.x, FRONT_LEFT.y + FLOOR_EDGE - top)


static func floor_polygon() -> PackedVector2Array:
	return PackedVector2Array([BACK_LEFT, BACK_RIGHT, FRONT_RIGHT, FRONT_LEFT])


static func back_wall_polygon() -> PackedVector2Array:
	var up := Vector2(0, -BACK_WALL_HEIGHT)
	return PackedVector2Array([BACK_LEFT + up, BACK_RIGHT + up, BACK_RIGHT, BACK_LEFT])


static func left_wall_polygon() -> PackedVector2Array:
	return PackedVector2Array([FRONT_LEFT + Vector2(0, -SIDE_WALL_FRONT_HEIGHT), BACK_LEFT + Vector2(0, -BACK_WALL_HEIGHT), BACK_LEFT, FRONT_LEFT])


static func right_wall_polygon() -> PackedVector2Array:
	return PackedVector2Array([BACK_RIGHT + Vector2(0, -BACK_WALL_HEIGHT), FRONT_RIGHT + Vector2(0, -SIDE_WALL_FRONT_HEIGHT), FRONT_RIGHT, BACK_RIGHT])


## A point on a side wall: [param v] along it (0 back, 1 front), [param height] 0..1 up it.
static func side_wall_point(left: bool, v: float, height: float) -> Vector2:
	return project(Vector2(0.0 if left else 1.0, v), WALL_HEIGHT_M * height)


## A point on the back wall: [param u] across it, [param height] 0..1 up it.
static func back_wall_point(u: float, height: float) -> Vector2:
	return project(Vector2(u, 0.0), WALL_HEIGHT_M * height)

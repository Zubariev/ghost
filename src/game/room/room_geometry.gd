## The Hamlet-style room frame shared by every room (validated by the 2026-11-12 room spike):
## a back wall, two slanted side walls, no front wall, and a floor that narrows toward the
## back. Positions on the floor are (u, v): u left→right 0..1, v back wall 0 → front edge 1;
## values outside 0..1 reach into the walls.
class_name RoomGeometry
extends RefCounted

## The full-size box; [RoomView] shrinks the floor to each room's real width with
## [method set_floor_scale] (rooms of different sizes, user decision 2026-11-20).
const FULL_BACK_LEFT := Vector2(330, 250)
const FULL_BACK_RIGHT := Vector2(950, 250)
const FULL_FRONT_LEFT := Vector2(110, 625)
const FULL_FRONT_RIGHT := Vector2(1170, 625)
const FULL_BACK_SCALE: float = 0.78
const FULL_FRONT_SCALE: float = 1.12
static var BACK_LEFT := FULL_BACK_LEFT
static var BACK_RIGHT := FULL_BACK_RIGHT
static var FRONT_LEFT := FULL_FRONT_LEFT
static var FRONT_RIGHT := FULL_FRONT_RIGHT
const BACK_WALL_HEIGHT: float = 170.0
const SIDE_WALL_FRONT_HEIGHT: float = 290.0
const FLOOR_EDGE: float = 18.0
## Figures and furniture are drawn this much smaller at the back wall than at the front.
static var BACK_SCALE: float = FULL_BACK_SCALE
static var FRONT_SCALE: float = FULL_FRONT_SCALE


## A floor [param fw] times the full box's width and [param fd] times its depth ([param fd] < 0:
## the same as [param fw]), about the floor's centre: a smaller room at the same scale for people
## and props. Walls keep their height; the depth scale narrows with a shallower floor. 1.0
## restores the full box.
static func set_floor_scale(fw: float, fd: float = -1.0) -> void:
	if fd < 0.0:
		fd = fw
	var centre: Vector2 = (FULL_BACK_LEFT + FULL_BACK_RIGHT + FULL_FRONT_LEFT + FULL_FRONT_RIGHT) / 4.0
	var k := Vector2(fw, fd)
	BACK_LEFT = centre + (FULL_BACK_LEFT - centre) * k
	BACK_RIGHT = centre + (FULL_BACK_RIGHT - centre) * k
	FRONT_LEFT = centre + (FULL_FRONT_LEFT - centre) * k
	FRONT_RIGHT = centre + (FULL_FRONT_RIGHT - centre) * k
	var mid: float = (FULL_BACK_SCALE + FULL_FRONT_SCALE) / 2.0
	BACK_SCALE = mid + (FULL_BACK_SCALE - mid) * fd
	FRONT_SCALE = mid + (FULL_FRONT_SCALE - mid) * fd


## The real floor size in metres of the room on screen ([RoomView]); the full box by default.
## Lets drawings sized in metres (a rug) find their floor units.
static var ROOM_SIZE_M := Vector2(10.6, 7.5)


## The room view's zoom and offset ([RoomView]): the stage is drawn scaled by VIEW_ZOOM and moved
## by VIEW_OFFSET; screen-space UI (the HUD) maps room points with [method to_display].
static var VIEW_ZOOM: float = 1.0
static var VIEW_OFFSET := Vector2.ZERO


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


## Screen point of a floor position.
static func to_screen(uv: Vector2) -> Vector2:
	var left: Vector2 = BACK_LEFT.lerp(FRONT_LEFT, uv.y)
	var right: Vector2 = BACK_RIGHT.lerp(FRONT_RIGHT, uv.y)
	return left.lerp(right, uv.x)


## Drawing scale at depth [param v].
static func scale_at(v: float) -> float:
	return lerpf(BACK_SCALE, FRONT_SCALE, clampf(v, 0.0, 1.0))


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
	var base: Vector2 = BACK_LEFT.lerp(FRONT_LEFT, v) if left else BACK_RIGHT.lerp(FRONT_RIGHT, v)
	var wall_height: float = lerpf(BACK_WALL_HEIGHT, SIDE_WALL_FRONT_HEIGHT, v)
	return base - Vector2(0, wall_height * height)


## A point on the back wall: [param u] across it, [param height] 0..1 up it.
static func back_wall_point(u: float, height: float) -> Vector2:
	return BACK_LEFT.lerp(BACK_RIGHT, u) - Vector2(0, BACK_WALL_HEIGHT * height)

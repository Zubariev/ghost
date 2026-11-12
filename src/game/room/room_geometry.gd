## The Hamlet-style room frame shared by every room (validated by the 2026-11-12 room spike):
## a back wall, two slanted side walls, no front wall, and a floor that narrows toward the
## back. Positions on the floor are (u, v): u left→right 0..1, v back wall 0 → front edge 1;
## values outside 0..1 reach into the walls.
class_name RoomGeometry
extends RefCounted

const BACK_LEFT := Vector2(330, 250)
const BACK_RIGHT := Vector2(950, 250)
const FRONT_LEFT := Vector2(110, 625)
const FRONT_RIGHT := Vector2(1170, 625)
const BACK_WALL_HEIGHT: float = 170.0
const SIDE_WALL_FRONT_HEIGHT: float = 290.0
const FLOOR_EDGE: float = 18.0
## Figures and furniture are drawn this much smaller at the back wall than at the front.
const BACK_SCALE: float = 0.78
const FRONT_SCALE: float = 1.12


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

## How run-down a room is, 0 (perfect order) .. 1 (dark, cold, dirty, something broken), and
## what that does to walking (user decision 2026-11-15): people walk carefully and slower in
## a run-down room; the ghost is slowed in a room in perfect order and moves freely in a
## run-down one. Reads the simulation's room state; changes nothing.
##
## Four equal parts: light (dark 1, dim 0.5, bright 0), cold (1 when cold), dirt (dirty 1,
## normal [constant NORMAL_DIRT], clean 0), and anything in the room needing repair (1).
##
## [codeblock]
## var r: float = RoomCondition.run_down(house, "kitchen")
## speed *= RoomCondition.ghost_factor(r, ghost_slowest)
## [/codeblock]
class_name RoomCondition
extends RefCounted

## A room that is neither cleaned nor dirty counts as a little run-down.
const NORMAL_DIRT: float = 0.3
const DIM_LIGHT: float = 0.5


static func run_down(house: HouseState, room_id: String) -> float:
	var room: RoomState = house.rooms[room_id]
	var light: float = 1.0 if room.light == RoomState.Light.DARK else (DIM_LIGHT if room.light == RoomState.Light.DIM else 0.0)
	var cold: float = 1.0 if room.temperature == RoomState.Temperature.COLD else 0.0
	var dirt: float = 1.0 if room.cleanliness == RoomState.Cleanliness.DIRTY else (NORMAL_DIRT if room.cleanliness == RoomState.Cleanliness.NORMAL else 0.0)
	var broken: float = 0.0
	for obj: ObjectState in house.objects.values():
		if obj.room_id == room_id and obj.needs_repair():
			broken = 1.0
			break
	return (light + cold + dirt + broken) / 4.0


## People's pace factor: 1 in a room in perfect order, [param slowest] in a fully run-down one.
static func people_factor(run_down_amount: float, slowest: float) -> float:
	return lerpf(1.0, slowest, clampf(run_down_amount, 0.0, 1.0))


## The ghost's speed factor: [param slowest] in a room in perfect order, 1 in a fully
## run-down one.
static func ghost_factor(run_down_amount: float, slowest: float) -> float:
	return lerpf(slowest, 1.0, clampf(run_down_amount, 0.0, 1.0))

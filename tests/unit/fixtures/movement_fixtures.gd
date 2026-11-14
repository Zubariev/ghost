## Factory functions for stage 5c walking tests: the sim fixture house laid out on floors
## and a grid (bedroom upstairs; kitchen and dining side by side downstairs), its furniture,
## and movement numbers. Fixture values, not tuning.
extends RefCounted

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")

## The largest step anyone may make in one frame without it being a jump (boundary value:
## a frame here is FRAME_MINUTES, far below a teleport across a room).
const MAX_FRAME_STEP: float = 0.15
const FRAME_MINUTES: float = 0.05
## Across the straight line from the stairs to the stove spot (0.80, 0.42).
const COUNTER_UV := Vector2(0.5, 0.25)


## The sim fixture house with floors and grid cells: bedroom (floor 1) over the kitchen,
## joined by stairs; kitchen (0, 0) — dining (1, 0) by side doors.
static func house() -> HouseState:
	var data: Dictionary = Fx.house_data()
	for room: Dictionary in data["rooms"]:
		match String(room["id"]):
			"bedroom":
				room["floor"] = 1
				room["grid"] = [0, 0]
			"kitchen":
				room["grid"] = [0, 0]
			"dining":
				room["grid"] = [1, 0]
			"cellar":
				room["grid"] = [3, 3]
	return HouseState.from_dict(data)


## Stairs in the bedroom and kitchen; in the kitchen a counter between the stairs and the
## stove, so the walk to the stove must go round it.
static func furniture() -> Dictionary:
	return {
		"bedroom": [{"kind": "stairs", "u": 0.22, "v": 0.02}],
		"kitchen": [
			{"kind": "stairs", "u": 0.22, "v": 0.02},
			{"kind": "stove", "u": 0.80, "v": 0.30, "object": "stove"},
			{"kind": "counter", "u": COUNTER_UV.x, "v": COUNTER_UV.y},
		],
		"dining": [],
		"cellar": [],
	}


static func config() -> Dictionary:
	return {
		"walk_speed": 0.45, "catch_up_minutes": 1.0, "stagger_minutes": 0.15, "door_inset": 0.12, "grid_cells": [40, 24],
		"clearance": 0.02,
		"footprints": {"stairs": [0.09, 0.05], "stove": [0.07, 0.05], "counter": [0.15, 0.04]},
	}

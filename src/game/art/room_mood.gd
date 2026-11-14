## How warm or haunted a room looks (Whimsical Gothic Storybook art direction, 2026-11-15).
## Presentation only: it reads the room's simulated state and never changes it.
##
## [br]- Warmth 1 = cozy (lit, comfortable); 0 = haunted. A dark room loses most warmth, a
##   dim one some; a cold room (a window left open) loses a lot. The losses add up.
## [br]- A fireplace burns while its room is not cold; an open window puts it out.
##
## [codeblock]
## var target: float = RoomMood.warmth(house.rooms["living_room"])
## shown = RoomMood.approach(shown, target, delta)   # eases the change over about a second
## [/codeblock]
class_name RoomMood
extends RefCounted

const DARK_LOSS: float = 0.55
const DIM_LOSS: float = 0.25
const COLD_LOSS: float = 0.45
## Warmth change per real second when the room's state changes.
const EASE_PER_SECOND: float = 1.2


## Target warmth of [param room], 0 (haunted) .. 1 (cozy).
static func warmth(room: RoomState) -> float:
	var value: float = 1.0
	match room.light:
		RoomState.Light.DARK:
			value -= DARK_LOSS
		RoomState.Light.DIM:
			value -= DIM_LOSS
	if room.temperature == RoomState.Temperature.COLD:
		value -= COLD_LOSS
	return clampf(value, 0.0, 1.0)


## True while a fireplace in [param room] burns.
static func fire_burning(room: RoomState) -> bool:
	return room.temperature != RoomState.Temperature.COLD


## Moves the shown warmth toward [param target] over real time.
static func approach(shown: float, target: float, delta: float) -> float:
	return move_toward(shown, target, EASE_PER_SECOND * delta)

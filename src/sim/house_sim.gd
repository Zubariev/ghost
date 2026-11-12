## The house simulation: one clock, the house state and every NPC routine,
## stepped together one game minute at a time.
##
## [codeblock]
## var sim := HouseSim.from_data_files()
## sim.start()
## sim.advance(delta)   # from _process; honours pause and ×1/×2/×4
## [/codeblock]
class_name HouseSim
extends RefCounted

const CLOCK_PATH: String = "res://assets/data/time/clock.json"
const RULES_PATH: String = "res://assets/data/sim/rules.json"
const HOUSE_PATH: String = "res://assets/data/house/rooms.json"
const SCHEDULE_PATHS: Array[String] = ["res://assets/data/schedules/grandma.json"]

var clock: GameClock
var house: HouseState
var routines: Array[NpcRoutine] = []


func _init(game_clock: GameClock, house_state: HouseState, npc_routines: Array[NpcRoutine]) -> void:
	clock = game_clock
	house = house_state
	routines = npc_routines
	clock.minute_advanced.connect(_on_minute_advanced)


## Builds the simulation from the game's data files.
static func from_data_files() -> HouseSim:
	var game_clock: GameClock = GameClock.from_config(JsonData.read(CLOCK_PATH))
	var house_state: HouseState = HouseState.from_dict(JsonData.read(HOUSE_PATH))
	var step_minutes: int = int(JsonData.read(RULES_PATH).get("work_step_minutes", 15))
	var npc_routines: Array[NpcRoutine] = []
	for path: String in SCHEDULE_PATHS:
		npc_routines.append(NpcRoutine.new(Schedule.from_dict(JsonData.read(path)), house_state, step_minutes))
	return HouseSim.new(game_clock, house_state, npc_routines)


## Puts every NPC on the activity due at the clock's current time.
func start() -> void:
	for routine: NpcRoutine in routines:
		routine.begin(clock.minute_of_day())


## Advances real time; returns game minutes passed.
func advance(real_seconds: float) -> int:
	return clock.advance(real_seconds)


func _on_minute_advanced(total_minutes: int) -> void:
	var spent: int = posmod(total_minutes - 1, GameClock.MINUTES_PER_DAY)
	for routine: NpcRoutine in routines:
		routine.step(spent)

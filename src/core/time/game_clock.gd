## Game time, advanced in whole game minutes from real seconds.
##
## Agreed rules (Demo Specification §6): 1 game minute = 1 real second at ×1;
## speeds ×1/×2/×4 change only how fast time passes, never schedule timestamps;
## day is 06:00–22:00, night 22:00–06:00. All values come from data
## (`assets/data/time/clock.json`), never from this file.
##
## Single-thread only: call it from the main loop.
##
## [codeblock]
## var clock := GameClock.from_config(JsonData.read("res://assets/data/time/clock.json"))
## clock.minute_advanced.connect(func(total: int) -> void: print(GameClock.format_time(total)))
## clock.set_speed_index(2)   # ×4
## clock.advance(delta)       # from _process
## [/codeblock]
class_name GameClock
extends RefCounted

## Emitted once for every whole game minute that passes. [param total_minutes]
## counts from day 1, 00:00; the minute just spent is [code]total_minutes - 1[/code].
signal minute_advanced(total_minutes: int)
## Emitted when time crosses the day start or the night start.
signal phase_changed(is_day: bool)

const MINUTES_PER_DAY: int = 1440

## Whole game minutes since day 1, 00:00.
var total_minutes: int = 0
## While true, [method advance] passes no time.
var paused: bool = false

var _minutes_per_second: float
var _day_start: int
var _night_start: int
var _speeds: Array[int] = []
var _speed_index: int = 0
var _fraction: float = 0.0
var _was_day: bool


func _init(minutes_per_second: float, day_start: int, night_start: int, speeds: Array[int], start_minute: int) -> void:
	_minutes_per_second = minutes_per_second
	_day_start = day_start
	_night_start = night_start
	_speeds = speeds.duplicate()
	if _speeds.is_empty():
		_speeds = [1]
	total_minutes = start_minute
	_was_day = is_day()


## Builds a clock from the parsed `clock.json` dictionary.
static func from_config(config: Dictionary) -> GameClock:
	var speeds: Array[int] = []
	for value: Variant in config.get("speeds", [1]):
		speeds.append(int(value))
	return GameClock.new(
		float(config.get("minutes_per_real_second", 1.0)),
		parse_time(String(config.get("day_start", "06:00"))),
		parse_time(String(config.get("night_start", "22:00"))),
		speeds,
		parse_time(String(config.get("start_time", "06:00"))))


## Parses "HH:MM" into minutes since midnight; returns -1 when malformed.
static func parse_time(text: String) -> int:
	var parts: PackedStringArray = text.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	var hours: int = parts[0].to_int()
	var minutes: int = parts[1].to_int()
	if hours < 0 or hours > 23 or minutes < 0 or minutes > 59:
		return -1
	return hours * 60 + minutes


## Formats minutes since midnight (any value; wrapped to one day) as "HH:MM".
static func format_time(minute_of_day: int) -> String:
	var wrapped: int = posmod(minute_of_day, MINUTES_PER_DAY)
	return "%02d:%02d" % [wrapped / 60, wrapped % 60]


## Advances by [param real_seconds] of real time at the current speed.
## Returns how many whole game minutes passed; emits one signal per minute.
func advance(real_seconds: float) -> int:
	if paused or real_seconds <= 0.0:
		return 0
	_fraction += real_seconds * _minutes_per_second * float(get_speed())
	var whole: int = floori(_fraction)
	_fraction -= float(whole)
	for i: int in whole:
		total_minutes += 1
		minute_advanced.emit(total_minutes)
		var day_now: bool = is_day()
		if day_now != _was_day:
			_was_day = day_now
			phase_changed.emit(day_now)
	return whole


func get_speed() -> int:
	return _speeds[_speed_index]


func get_speeds() -> Array[int]:
	return _speeds.duplicate()


## Selects a speed by its index in the configured list (×1, ×2, ×4).
func set_speed_index(index: int) -> void:
	_speed_index = clampi(index, 0, _speeds.size() - 1)


func minute_of_day() -> int:
	return total_minutes % MINUTES_PER_DAY


## Day 1 is the first day.
func day_number() -> int:
	return total_minutes / MINUTES_PER_DAY + 1


func is_day() -> bool:
	var minute: int = minute_of_day()
	if _day_start < _night_start:
		return minute >= _day_start and minute < _night_start
	return minute >= _day_start or minute < _night_start

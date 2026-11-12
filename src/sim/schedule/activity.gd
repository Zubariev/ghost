## One entry of an NPC's schedule (GDD §6.2 fields).
##
## Two kinds:
## [br]- [constant WORK] takes a fixed number of minutes (cooking). It runs in steps; its
##   requirements are checked only between steps, and once running it may finish after
##   its window ends (Demo Specification §5.6).
## [br]- [constant SPAN] fills the rest of its window once started (meals, rest, sleep).
class_name Activity
extends RefCounted

enum Kind { WORK, SPAN }

var id: String = ""
var display_name: String = ""
## Window start, minutes since midnight (inclusive).
var start_minute: int = 0
## Window end, minutes since midnight (exclusive). Smaller than the start when the
## window runs past midnight (sleep 22:00–06:00).
var end_minute: int = 0
var kind: Kind = Kind.SPAN
var room_id: String = ""
var target_object_id: String = ""
var animation: String = ""
## For [constant WORK]: game minutes of work to finish.
var work_minutes: int = 0
var requirements: Array[Dictionary] = []
var on_start: Array[Dictionary] = []
var on_success: Array[Dictionary] = []


static func from_dict(data: Dictionary) -> Activity:
	var activity := Activity.new()
	activity.id = String(data.get("id", ""))
	activity.display_name = String(data.get("name", activity.id))
	activity.start_minute = GameClock.parse_time(String(data.get("start", "")))
	activity.end_minute = GameClock.parse_time(String(data.get("end", "")))
	activity.kind = Kind.WORK if String(data.get("kind", "span")) == "work" else Kind.SPAN
	activity.room_id = String(data.get("room", ""))
	activity.target_object_id = String(data.get("target", ""))
	activity.animation = String(data.get("animation", ""))
	activity.work_minutes = int(data.get("work_minutes", 0))
	activity.requirements = _dict_array(data.get("requires", []))
	activity.on_start = _dict_array(data.get("on_start", []))
	activity.on_success = _dict_array(data.get("on_success", []))
	if activity.start_minute < 0 or activity.end_minute < 0:
		push_error("Activity %s: bad start/end time" % activity.id)
	if activity.kind == Kind.WORK and activity.work_minutes <= 0:
		push_error("Activity %s: work needs work_minutes > 0" % activity.id)
	return activity


## True when [param minute_of_day] falls inside this activity's window.
func contains(minute_of_day: int) -> bool:
	if start_minute < end_minute:
		return minute_of_day >= start_minute and minute_of_day < end_minute
	return minute_of_day >= start_minute or minute_of_day < end_minute


static func _dict_array(values: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if values is Array:
		for value: Variant in values:
			if value is Dictionary:
				result.append(value)
	return result

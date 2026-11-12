## An NPC's fixed daily schedule: a list of activity windows covering the whole day.
class_name Schedule
extends RefCounted

var npc_id: String = ""
var display_name: String = ""
## The room the NPC is in when the simulation starts.
var start_room: String = ""
var activities: Array[Activity] = []
## How jumpy the person is: a longer search after a sighting (Demo Specification §8.8).
var anxiety: float = 1.0


static func from_dict(data: Dictionary) -> Schedule:
	var schedule := Schedule.new()
	schedule.npc_id = String(data.get("npc_id", ""))
	schedule.display_name = String(data.get("name", schedule.npc_id))
	schedule.start_room = String(data.get("start_room", ""))
	schedule.anxiety = float(data.get("anxiety", 1.0))
	for entry: Variant in data.get("activities", []):
		if entry is Dictionary:
			schedule.activities.append(Activity.from_dict(entry))
	return schedule


## The activity whose window contains [param minute_of_day], or null in a gap.
func activity_at(minute_of_day: int) -> Activity:
	for activity: Activity in activities:
		if activity.contains(minute_of_day):
			return activity
	return null


## Problems with the windows: minutes covered by no activity or by more than one.
## An empty result means every minute of the day belongs to exactly one window.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var gap_start: int = -1
	for minute: int in GameClock.MINUTES_PER_DAY:
		var count: int = 0
		for activity: Activity in activities:
			if activity.contains(minute):
				count += 1
		if count > 1:
			problems.append("%s: %d activities overlap at %s" % [npc_id, count, GameClock.format_time(minute)])
		if count == 0 and gap_start < 0:
			gap_start = minute
		elif count != 0 and gap_start >= 0:
			problems.append("%s: no activity %s–%s" % [npc_id, GameClock.format_time(gap_start), GameClock.format_time(minute)])
			gap_start = -1
	if gap_start >= 0:
		problems.append("%s: no activity from %s" % [npc_id, GameClock.format_time(gap_start)])
	return problems

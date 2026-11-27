## The family's bathroom routine in the shipped schedules (sprint 002, task S2-02; user approval
## 2026-11-26): one person at a time in the upper bathroom, everyone goes at least once a day, and
## every visit leaves time at the sink even after the slowest walk there (a fully run-down house).
extends GdUnitTestSuite

const BATHROOM: String = "upper_bathroom"
## Minutes at the sink a visit must keep after the worst-case walk (sprint 002 plan, P1).
const MIN_MINUTES_AT_SINK: int = 5
const RULES_PATH: String = "res://assets/data/sim/rules.json"


func _house() -> HouseState:
	return HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))


func _schedules() -> Array[Schedule]:
	var result: Array[Schedule] = []
	for path: String in HouseSim.SCHEDULE_PATHS:
		result.append(Schedule.from_dict(JsonData.read(path)))
	return result


## Bathroom windows as [npc_id, activity id, start, end] (minutes since midnight; none runs past midnight).
func _visits() -> Array[Array]:
	var result: Array[Array] = []
	for schedule: Schedule in _schedules():
		for activity: Activity in schedule.activities:
			if activity.room_id == BATHROOM:
				result.append([schedule.npc_id, activity.id, activity.start_minute, activity.end_minute])
	return result


## The activity before [param index] in [param schedule], wrapping round midnight.
func _previous_room(schedule: Schedule, index: int) -> String:
	return schedule.activities[(index - 1 + schedule.activities.size()) % schedule.activities.size()].room_id


## Walk minutes from [param from_room] to the bathroom as NpcRoutine counts them (per leg, rounded,
## at least 1), at [param pace] slowed by the worst room condition.
func _worst_walk(house: HouseState, from_room: String, pace: float) -> int:
	var slowest: float = float(JsonData.read(RULES_PATH).get("people_slowest", 1.0))
	var total: int = 0
	var room: String = from_room
	for next_room: String in house.find_path(from_room, BATHROOM):
		total += maxi(1, roundi(float(house.walk_minutes(room, next_room)) / maxf(0.05, pace * slowest)))
		room = next_room
	return total


func test_every_family_member_uses_the_bathroom_at_least_once_a_day() -> void:
	var visitors: Dictionary = {}
	for visit: Array in _visits():
		visitors[visit[0]] = true
	for schedule: Schedule in _schedules():
		assert_bool(visitors.has(schedule.npc_id)).override_failure_message(
			"%s never uses the bathroom" % schedule.npc_id).is_true()


func test_the_children_no_longer_share_one_bathroom_window() -> void:
	var children_at_21: int = 0
	for visit: Array in _visits():
		if int(visit[2]) <= 21 * 60 and int(visit[3]) > 21 * 60 + 15:
			children_at_21 += 1
	assert_int(children_at_21).is_equal(0)


func test_no_two_bathroom_windows_overlap() -> void:
	var visits: Array[Array] = _visits()
	for i: int in visits.size():
		for j: int in range(i + 1, visits.size()):
			var a: Array = visits[i]
			var b: Array = visits[j]
			var overlap: bool = int(a[2]) < int(b[3]) and int(b[2]) < int(a[3])
			assert_bool(overlap).override_failure_message(
				"%s (%s) overlaps %s (%s)" % [a[1], a[0], b[1], b[0]]).is_false()


func test_every_visit_leaves_time_at_the_sink_after_the_slowest_walk() -> void:
	var house: HouseState = _house()
	for schedule: Schedule in _schedules():
		for index: int in schedule.activities.size():
			var activity: Activity = schedule.activities[index]
			if activity.room_id != BATHROOM:
				continue
			var walk: int = _worst_walk(house, _previous_room(schedule, index), schedule.pace)
			var left: int = activity.end_minute - activity.start_minute - walk
			assert_int(left).override_failure_message("%s: %d min at the sink after a %d min walk" % [
				activity.id, left, walk]).is_greater_equal(MIN_MINUTES_AT_SINK)

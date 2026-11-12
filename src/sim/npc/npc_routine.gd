## Runs one NPC's fixed daily schedule, one game minute at a time.
##
## Agreed rules (GDD §6.2–6.5, §9.7; Demo Specification §5.3–5.6):
## [br]- An activity whose requirements are unmet waits at its place; when its window
##   ends it is skipped.
## [br]- A late activity never shifts the windows after it.
## [br]- Started work is never interrupted: requirements are checked only between
##   work steps.
## [br]- Work that is running when its window ends is finished (food is ready late).
## [br]- Work waiting mid-way keeps its progress, and is abandoned if its window ends.
## [br]- A room that cannot be reached means waiting, never a replacement room.
##
## Minutes spent walking do not count as work; the minute she arrives is spent walking.
class_name NpcRoutine
extends RefCounted

enum State { SCHEDULED, MOVING, PERFORMING, WAITING }

signal state_changed(new_state: State)
signal activity_started(activity: Activity)
signal activity_waiting(activity: Activity, unmet: Array[Dictionary])
signal activity_completed(activity: Activity)
signal activity_skipped(activity: Activity, work_done_minutes: int)
signal room_entered(room_id: String)

var schedule: Schedule
## The room the NPC is in (the last room entered while walking).
var room_id: String = ""
var state: State = State.SCHEDULED
## The activity being pursued (may be past its window while finishing work).
var current: Activity = null
## Minutes of work done on the current [constant Activity.WORK] activity.
var work_done_minutes: int = 0

var _house: HouseState
var _step_minutes: int
var _started: bool = false
var _finished: bool = false
var _step_left: int = 0
var _path: Array[String] = []
var _next_room: String = ""
var _leg_minutes: int = 0
var _leg_left: int = 0


func _init(npc_schedule: Schedule, house: HouseState, work_step_minutes: int) -> void:
	schedule = npc_schedule
	_house = house
	_step_minutes = maxi(1, work_step_minutes)
	room_id = schedule.start_room


## Sets up the activity due at [param minute_of_day] without spending a minute.
func begin(minute_of_day: int) -> void:
	_switch_to(schedule.activity_at(minute_of_day))


## Spends one game minute: [param minute_of_day] is the minute being spent.
func step(minute_of_day: int) -> void:
	var due: Activity = schedule.activity_at(minute_of_day)
	if due != current and not _is_running_work():
		_close_current()
		_switch_to(due)
	var minute_used: bool = false
	if state == State.MOVING:
		_advance_move()
		minute_used = true
	if state == State.WAITING:
		_try_start()
	if state == State.PERFORMING and not minute_used:
		_advance_work()


## While walking: the room being left, the room ahead and how far along (0..1).
## Returns an empty dictionary when not walking.
func get_walk_progress() -> Dictionary:
	if state != State.MOVING or _leg_minutes <= 0:
		return {}
	return {
		"from": room_id,
		"to": _next_room,
		"t": 1.0 - float(_leg_left) / float(_leg_minutes),
	}


func get_work_left_minutes() -> int:
	if current == null or current.kind != Activity.Kind.WORK:
		return 0
	return maxi(0, current.work_minutes - work_done_minutes)


func _is_running_work() -> bool:
	return current != null and current.kind == Activity.Kind.WORK \
		and _started and not _finished and state == State.PERFORMING


func _close_current() -> void:
	if current == null:
		return
	if current.kind == Activity.Kind.SPAN and _started:
		activity_completed.emit(current)
	elif not _finished:
		activity_skipped.emit(current, work_done_minutes)


func _switch_to(activity: Activity) -> void:
	current = activity
	_started = false
	_finished = false
	work_done_minutes = 0
	_step_left = 0
	_path.clear()
	if activity == null:
		_set_state(State.SCHEDULED)
		return
	_try_start()


## Moves toward the activity's room, or starts it when its requirements are met.
func _try_start() -> void:
	if current == null or _finished:
		return
	if room_id != current.room_id:
		_path = _house.find_path(room_id, current.room_id)
		if _path.is_empty():
			_wait([{"room": current.room_id}])
		else:
			_begin_leg()
			_set_state(State.MOVING)
		return
	var unmet: Array[Dictionary] = _house.unmet_requirements(current.requirements)
	if not unmet.is_empty():
		_wait(unmet)
		return
	if not _started:
		_started = true
		_house.apply_effects(current.on_start)
		activity_started.emit(current)
	if current.kind == Activity.Kind.WORK:
		_step_left = mini(_step_minutes, get_work_left_minutes())
	_set_state(State.PERFORMING)


func _wait(unmet: Array[Dictionary]) -> void:
	if state != State.WAITING:
		_set_state(State.WAITING)
		activity_waiting.emit(current, unmet)


func _begin_leg() -> void:
	_next_room = _path[0]
	_leg_minutes = _house.walk_minutes(room_id, _next_room)
	_leg_left = _leg_minutes


func _advance_move() -> void:
	_leg_left -= 1
	if _leg_left > 0:
		return
	room_id = _path.pop_front()
	room_entered.emit(room_id)
	if _path.is_empty():
		_set_state(State.SCHEDULED)
		_try_start()
	else:
		_begin_leg()


func _advance_work() -> void:
	if current.kind != Activity.Kind.WORK:
		return
	work_done_minutes += 1
	_step_left -= 1
	if work_done_minutes >= current.work_minutes:
		_finished = true
		_house.apply_effects(current.on_success)
		activity_completed.emit(current)
		_set_state(State.SCHEDULED)
		return
	if _step_left <= 0:
		# Between steps: the only point where a changed condition stops the work.
		var unmet: Array[Dictionary] = _house.unmet_requirements(current.requirements)
		if unmet.is_empty():
			_step_left = mini(_step_minutes, get_work_left_minutes())
		else:
			_wait(unmet)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_changed.emit(new_state)

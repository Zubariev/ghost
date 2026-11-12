## Runs one NPC's fixed daily schedule, one game minute at a time.
##
## Agreed rules (GDD §6.2–6.5, §9.7, §10.4; Demo Specification §5.3–5.6):
## [br]- An activity whose requirements are unmet waits at its place; when its window
##   ends it is skipped.
## [br]- A late activity never shifts the windows after it.
## [br]- Started work is never interrupted: requirements are checked only between
##   work steps.
## [br]- Work that is running when its window ends is finished (food is ready late).
## [br]- Work waiting mid-way keeps its progress, and is abandoned if its window ends.
## [br]- A room that cannot be reached means waiting, never a replacement room.
## [br]- In a work window ([constant Activity.Kind.TASKS]) the NPC takes the best open task
##   for its role, then the next; with none it potters in its idle room and looks again
##   at each step boundary. Priorities choose the next task, never stop the current one.
##
## [br]- An unmet need the NPC can put right alone (hidden groceries: search, approved for
##   stage 5a) is fixed first as a timed job in place, then the activity starts.
## [br]- A ghost sighting holds the NPC (Demo Specification §8.8): the activity is suspended
##   with its progress kept; on release it resumes only if its window is still open,
##   otherwise it is skipped — even work that would otherwise finish late.
## [br]- Broken (GDD §8.4) stops the schedule at once — the one thing that interrupts —
##   and releases any claimed task; on recovery the NPC joins the activity due now, and
##   missed activities are not made up.
##
## Minutes spent walking do not count as work; the minute she arrives is spent walking.
class_name NpcRoutine
extends RefCounted

enum State { SCHEDULED, MOVING, PERFORMING, WAITING, BROKEN, HELD }
## What the NPC is doing inside the current activity.
enum JobKind { SPAN, WORK, IDLE }

signal state_changed(new_state: State)
signal activity_started(activity: Activity)
signal activity_waiting(activity: Activity, unmet: Array[Dictionary])
signal activity_completed(activity: Activity)
signal activity_skipped(activity: Activity, work_done_minutes: int)
signal task_started(task: HouseTask)
signal task_completed(task: HouseTask)
signal self_fix_started(object_id: String)
signal room_entered(room_id: String)

var schedule: Schedule
## The room the NPC is in (the last room entered while walking).
var room_id: String = ""
var state: State = State.SCHEDULED
## The activity being pursued (may be past its window while finishing work).
var current: Activity = null
## The claimed task in a work window, or null (none, or pottering).
var current_task: HouseTask = null
## Minutes of work done on the current job.
var work_done_minutes: int = 0

var _house: HouseState
var _board: TaskBoard
var _step_minutes: int
var _activity_started: bool = false
var _job_kind: JobKind = JobKind.SPAN
var _job_room: String = ""
var _job_work_minutes: int = 0
var _job_requirements: Array[Dictionary] = []
var _job_on_start: Array[Dictionary] = []
var _job_on_success: Array[Dictionary] = []
var _started: bool = false
var _finished: bool = false
## Object being put right by the NPC itself before the activity (or "").
var _self_fix_object: String = ""
## The state to return to when a hold ends.
var _held_from: State = State.SCHEDULED
var _step_left: int = 0
var _path: Array[String] = []
var _next_room: String = ""
var _leg_minutes: int = 0
var _leg_left: int = 0


## [param board] is needed only by schedules with work windows.
func _init(npc_schedule: Schedule, house: HouseState, work_step_minutes: int, board: TaskBoard = null) -> void:
	schedule = npc_schedule
	_house = house
	_board = board
	_step_minutes = maxi(1, work_step_minutes)
	room_id = schedule.start_room


## Sets up the activity due at [param minute_of_day] without spending a minute.
func begin(minute_of_day: int) -> void:
	_switch_to(schedule.activity_at(minute_of_day))


## Stops everything at once (GDD §8.4). No activity is completed or skipped by it.
func enter_broken() -> void:
	_self_fix_object = ""
	if current_task != null:
		_board.release(current_task.key, schedule.npc_id)
		current_task = null
	current = null
	_path.clear()
	_set_job(JobKind.SPAN, room_id, 0, [], [], [])
	_set_state(State.BROKEN)


## Leaves Broken and joins the activity due at [param minute_of_day] (from the room she is in).
func leave_broken(minute_of_day: int) -> void:
	if state != State.BROKEN:
		return
	_set_state(State.SCHEDULED)
	_switch_to(schedule.activity_at(minute_of_day))


## Suspends the routine where it is (a ghost sighting). Returns false when it cannot be
## held (Broken, or already held).
func hold() -> bool:
	if state == State.BROKEN or state == State.HELD:
		return false
	_held_from = state
	_set_state(State.HELD)
	return true


## Ends a hold at [param minute_of_day]: the suspended activity resumes with its progress
## if its window is still open; otherwise it is closed (skipped when unfinished) and the
## activity due now begins.
func release(minute_of_day: int) -> void:
	if state != State.HELD:
		return
	_set_state(_held_from)
	var due: Activity = schedule.activity_at(minute_of_day)
	if due != current:
		_close_current()
		_switch_to(due)


func is_held() -> bool:
	return state == State.HELD


func is_broken() -> bool:
	return state == State.BROKEN


## True while actually doing the scheduled activity itself (not walking, waiting,
## pottering or working on a claimed task).
func is_doing_activity() -> bool:
	return state == State.PERFORMING and current != null and current.kind != Activity.Kind.TASKS


## Spends one game minute: [param minute_of_day] is the minute being spent.
func step(minute_of_day: int) -> void:
	if state == State.BROKEN or state == State.HELD:
		return
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
		_advance_work(minute_of_day)


## True while pottering in a work window with no task.
func is_idle() -> bool:
	return _job_kind == JobKind.IDLE


## The object being put right by the NPC itself (e.g. searching for groceries), or "".
func get_self_fix_object() -> String:
	return _self_fix_object


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
	if _job_kind != JobKind.WORK:
		return 0
	return maxi(0, _job_work_minutes - work_done_minutes)


func get_job_work_minutes() -> int:
	return _job_work_minutes if _job_kind == JobKind.WORK else 0


func _is_running_work() -> bool:
	return _job_kind == JobKind.WORK and _started and not _finished and state == State.PERFORMING


func _close_current() -> void:
	if current == null:
		return
	if current_task != null:
		_board.release(current_task.key, schedule.npc_id)
		current_task = null
	_house.apply_effects(current.on_end)
	match current.kind:
		Activity.Kind.SPAN:
			if _activity_started:
				activity_completed.emit(current)
			else:
				activity_skipped.emit(current, 0)
		Activity.Kind.WORK:
			if not _finished:
				activity_skipped.emit(current, work_done_minutes)
		Activity.Kind.TASKS:
			activity_completed.emit(current)


func _switch_to(activity: Activity) -> void:
	_self_fix_object = ""
	current = activity
	current_task = null
	_activity_started = false
	_path.clear()
	if activity == null:
		_set_job(JobKind.SPAN, room_id, 0, [], [], [])
		_set_state(State.SCHEDULED)
		return
	match activity.kind:
		Activity.Kind.WORK:
			_set_job(JobKind.WORK, activity.room_id, activity.work_minutes, activity.requirements, activity.on_start, activity.on_success)
		Activity.Kind.TASKS:
			_choose_task_job()
		_:
			_set_job(JobKind.SPAN, activity.room_id, 0, activity.requirements, activity.on_start, activity.on_success)
	_try_start()


## Claims the best task for the window's role, or falls back to pottering.
func _choose_task_job() -> void:
	var empty: Array[Dictionary] = []
	current_task = null
	if _board != null:
		current_task = _board.pick(current.role, schedule.npc_id, room_id, current.room_filter)
	if current_task != null:
		_set_job(JobKind.WORK, current_task.room_id, current_task.work_minutes, empty, empty, current_task.on_success)
	else:
		_set_job(JobKind.IDLE, current.idle_room, 0, empty, empty, empty)


func _set_job(kind: JobKind, job_room: String, minutes: int, requirements: Array[Dictionary],
		on_start: Array[Dictionary], on_success: Array[Dictionary]) -> void:
	_job_kind = kind
	_job_room = job_room
	_job_work_minutes = minutes
	_job_requirements = requirements
	_job_on_start = on_start
	_job_on_success = on_success
	_started = false
	_finished = false
	work_done_minutes = 0
	_step_left = 0


## Moves toward the job's room, or starts the job when its requirements are met.
func _try_start() -> void:
	if current == null or _finished:
		return
	if room_id != _job_room:
		_path = _house.find_path(room_id, _job_room)
		if _path.is_empty():
			_wait([{"room": _job_room}])
		else:
			_begin_leg()
			_set_state(State.MOVING)
		return
	var unmet: Array[Dictionary] = _house.unmet_requirements(_job_requirements)
	if not unmet.is_empty():
		if _start_self_fix(unmet):
			return
		_wait(unmet)
		return
	var first_start: bool = not _activity_started
	var job_start: bool = not _started
	_activity_started = true
	if job_start:
		_started = true
		_house.apply_effects(_job_on_start)
	match _job_kind:
		JobKind.WORK:
			_step_left = mini(_step_minutes, get_work_left_minutes())
		JobKind.IDLE:
			_step_left = _step_minutes
	_set_state(State.PERFORMING)
	# Signals last: a listener may hold the routine (sitting on a hidden ghost), and that
	# must not be overwritten by this method.
	if first_start:
		activity_started.emit(current)
	if job_start and current_task != null:
		task_started.emit(current_task)


## Starts fixing the first unmet need the NPC can put right alone, in this room.
func _start_self_fix(unmet: Array[Dictionary]) -> bool:
	for need: Dictionary in unmet:
		var object_id: String = String(need.get("object", ""))
		if not _house.objects.has(object_id):
			continue
		var obj: ObjectState = _house.objects[object_id]
		if not obj.can_self_fix() or obj.room_id != room_id:
			continue
		var empty: Array[Dictionary] = []
		var fix_effect: Array[Dictionary] = [{"object": object_id, "set": String(obj.self_fix.get("to", ""))}]
		_set_job(JobKind.WORK, room_id, int(obj.self_fix.get("minutes", 1)), empty, empty, fix_effect)
		_self_fix_object = object_id
		_started = true
		_step_left = mini(_step_minutes, get_work_left_minutes())
		_set_state(State.PERFORMING)
		self_fix_started.emit(object_id)
		return true
	return false


func _restore_activity_job() -> void:
	if current.kind == Activity.Kind.WORK:
		_set_job(JobKind.WORK, current.room_id, current.work_minutes, current.requirements, current.on_start, current.on_success)
	else:
		_set_job(JobKind.SPAN, current.room_id, 0, current.requirements, current.on_start, current.on_success)


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


func _advance_work(minute_of_day: int) -> void:
	match _job_kind:
		JobKind.SPAN:
			return
		JobKind.IDLE:
			_step_left -= 1
			if _step_left <= 0:
				# Step boundary while pottering: look for a task.
				_choose_task_job()
				_try_start()
			return
	work_done_minutes += 1
	_step_left -= 1
	if work_done_minutes >= _job_work_minutes:
		_finish_job(minute_of_day)
		return
	if _step_left <= 0:
		# Between steps: the only point where a changed condition stops the work.
		var unmet: Array[Dictionary] = _house.unmet_requirements(_job_requirements)
		if unmet.is_empty():
			_step_left = mini(_step_minutes, get_work_left_minutes())
		else:
			_wait(unmet)


func _finish_job(minute_of_day: int) -> void:
	_finished = true
	_house.apply_effects(_job_on_success)
	if not _self_fix_object.is_empty():
		_self_fix_object = ""
		_restore_activity_job()
		if current.contains(minute_of_day):
			_try_start()
		else:
			_set_state(State.SCHEDULED)
		return
	if current_task == null:
		activity_completed.emit(current)
		_set_state(State.SCHEDULED)
		return
	var done: HouseTask = current_task
	_board.release(done.key, schedule.npc_id)
	current_task = null
	task_completed.emit(done)
	if current.contains(minute_of_day):
		_choose_task_job()
		_try_start()
	else:
		_set_state(State.SCHEDULED)


func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_changed.emit(new_state)

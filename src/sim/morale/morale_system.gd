## Morale for every NPC: penalties, bonuses, Broken and the scenario's end.
##
## Agreed rules (GDD §8, Demo Specification §7):
## [br]- morale 0–100 per NPC; fixed values per event, no personal multipliers;
## [br]- one-off penalties when the event happens (missed meal at its window's end;
##   poor sleep on waking);
## [br]- periodic penalties only for cold and dirt, every 30 game minutes, only while the NPC
##   is doing an activity in that room that those conditions affect (never when passing);
## [br]- condition penalties within one activity stack up to a cap;
## [br]- at ≤ [code]broken_at[/code] the NPC is Broken at once: no schedule, no penalties;
##   morale recovers gradually to [code]recover_to[/code], then the NPC rejoins its schedule;
## [br]- the family leaves (win) when every NPC is at or below the threshold at the same
##   moment, checked immediately on each change; the scenario is lost when its last day ends.
## Bonuses (approved 2026-11-12): a meal +10 in good conditions, +3 in poor ones; any other
## completed activity +3 in good conditions; a finished task +3 to the worker.
##
## Call [method begin_minute] before the routines step and [method end_minute] after.
class_name MoraleSystem
extends RefCounted

signal morale_changed(npc_id: String, value: int, delta: int, reason: String)
signal npc_broke(npc_id: String)
signal npc_recovered(npc_id: String)
signal family_left(total_minutes: int)
signal scenario_lost(total_minutes: int)

const OUTCOME_WON: String = "won"
const OUTCOME_LOST: String = "lost"

## "" while the scenario runs, then [constant OUTCOME_WON] or [constant OUTCOME_LOST].
var outcome: String = ""

var _rules: Dictionary
var _penalties: Dictionary
var _bonuses: Dictionary
var _house: HouseState
var _routines: Dictionary[String, NpcRoutine] = {}
var _morale: Dictionary[String, int] = {}
var _broken: Dictionary[String, bool] = {}
var _recover_minutes: Dictionary[String, int] = {}
## Per NPC, for the activity being done: condition penalties charged, bad conditions seen,
## darkness charged, and when it started.
var _charged: Dictionary[String, int] = {}
var _bad: Dictionary[String, bool] = {}
var _dark_charged: Dictionary[String, bool] = {}
var _started_at: Dictionary[String, int] = {}
var _minute: int = 0
var _total: int = 0


func _init(rules: Dictionary, house: HouseState, routines: Array[NpcRoutine]) -> void:
	_rules = rules
	_penalties = rules.get("penalties", {})
	_bonuses = rules.get("bonuses", {})
	_house = house
	for routine: NpcRoutine in routines:
		var npc_id: String = routine.schedule.npc_id
		_routines[npc_id] = routine
		_morale[npc_id] = int(rules.get("start", 80))
		_broken[npc_id] = false
		_reset_activity(npc_id)
		routine.activity_started.connect(_on_activity_started.bind(npc_id))
		routine.activity_completed.connect(_on_activity_completed.bind(npc_id))
		routine.activity_skipped.connect(_on_activity_skipped.bind(npc_id))
		routine.task_completed.connect(_on_task_completed.bind(npc_id))


func get_morale(npc_id: String) -> int:
	return _morale.get(npc_id, 0)


func is_broken(npc_id: String) -> bool:
	return _broken.get(npc_id, false)


## Sets morale directly (debug tools and tests); Broken and the win are checked as usual.
func set_morale(npc_id: String, value: int) -> void:
	_set_value(npc_id, value, "set")


## Call before the routines spend [param minute_of_day]; [param total_minutes] counts the
## minutes spent since day 1, 00:00.
func begin_minute(minute_of_day: int, total_minutes: int) -> void:
	_minute = minute_of_day
	_total = total_minutes


## Call after the routines have spent the minute: conditions, periodic penalties,
## Broken recovery and the scenario's end.
func end_minute() -> void:
	if not outcome.is_empty():
		return
	var periodic_every: int = maxi(1, int(_penalties.get("periodic_every_minutes", 30)))
	for npc_id: String in _routines:
		if _broken[npc_id]:
			_recover(npc_id)
			continue
		var routine: NpcRoutine = _routines[npc_id]
		if not routine.is_doing_activity():
			continue
		var activity: Activity = routine.current
		var room: RoomState = _house.rooms[routine.room_id]
		var cold: bool = activity.affected_by.has("temperature") and room.temperature == RoomState.Temperature.COLD
		var dirty: bool = activity.affected_by.has("cleanliness") and room.cleanliness == RoomState.Cleanliness.DIRTY
		var dark: bool = activity.affected_by.has("light") and room.light == RoomState.Light.DARK
		if cold or dirty or dark:
			_bad[npc_id] = true
		if dark and not _dark_charged[npc_id]:
			_dark_charged[npc_id] = true
			_charge_condition(npc_id, int(_penalties.get("dark", 0)), "dark")
		if _minute % periodic_every == 0:
			if cold:
				_charge_condition(npc_id, int(_penalties.get("cold", 0)), "cold")
			if dirty:
				_charge_condition(npc_id, int(_penalties.get("dirty", 0)), "dirty")
		if not outcome.is_empty():
			return
	var last_minute: int = int(_rules.get("scenario_days", 3)) * GameClock.MINUTES_PER_DAY
	if outcome.is_empty() and _total + 1 >= last_minute:
		outcome = OUTCOME_LOST
		scenario_lost.emit(_total + 1)


func _on_activity_started(activity: Activity, npc_id: String) -> void:
	_reset_activity(npc_id)
	_started_at[npc_id] = _minute


func _on_activity_completed(activity: Activity, npc_id: String) -> void:
	if activity.kind == Activity.Kind.TASKS:
		return
	if activity.category == "sleep":
		var late_by: int = posmod(_started_at[npc_id] - activity.start_minute, GameClock.MINUTES_PER_DAY)
		if late_by > int(_penalties.get("sleep_late_after_minutes", 30)):
			_change(npc_id, -int(_penalties.get("sleep_late", 0)), "sleep_late")
	var good: bool = not _bad[npc_id]
	if activity.category == "meal":
		_change(npc_id, int(_bonuses.get("meal_good" if good else "meal_poor", 0)), "meal_good" if good else "meal_poor")
	else:
		_change(npc_id, int(_bonuses.get("activity_good" if good else "activity_poor", 0)), "activity_good" if good else "activity_poor")


func _on_activity_skipped(activity: Activity, _work_done: int, npc_id: String) -> void:
	match activity.category:
		"meal":
			_change(npc_id, -int(_penalties.get("missed_meal", 0)), "missed_meal")
		"sleep":
			_change(npc_id, -int(_penalties.get("sleep_skipped", 0)), "sleep_skipped")


func _on_task_completed(_task: HouseTask, npc_id: String) -> void:
	_change(npc_id, int(_bonuses.get("task_done", 0)), "task_done")


## A condition penalty (dark, cold, dirt), limited by the cap for the current activity.
func _charge_condition(npc_id: String, amount: int, reason: String) -> void:
	var cap: int = int(_penalties.get("cap_per_activity", 10))
	var allowed: int = mini(amount, cap - _charged[npc_id])
	if allowed <= 0:
		return
	_charged[npc_id] += allowed
	_change(npc_id, -allowed, reason)


func _recover(npc_id: String) -> void:
	_recover_minutes[npc_id] = _recover_minutes.get(npc_id, 0) + 1
	if _recover_minutes[npc_id] % maxi(1, int(_rules.get("recover_every_minutes", 10))) != 0:
		return
	_set_value(npc_id, _morale[npc_id] + int(_rules.get("recover_step", 1)), "recovery")
	if _morale[npc_id] >= int(_rules.get("recover_to", 15)):
		_broken[npc_id] = false
		_routines[npc_id].leave_broken((_minute + 1) % GameClock.MINUTES_PER_DAY)
		npc_recovered.emit(npc_id)


## A gameplay change: ignored while Broken (no penalties, no bonuses) or after the end.
func _change(npc_id: String, delta: int, reason: String) -> void:
	if delta == 0 or _broken[npc_id]:
		return
	_set_value(npc_id, _morale[npc_id] + delta, reason)


func _set_value(npc_id: String, value: int, reason: String) -> void:
	if not outcome.is_empty() or not _morale.has(npc_id):
		return
	var old: int = _morale[npc_id]
	var new_value: int = clampi(value, int(_rules.get("min", 0)), int(_rules.get("max", 100)))
	_morale[npc_id] = new_value
	if new_value != old:
		morale_changed.emit(npc_id, new_value, new_value - old, reason)
	if not _broken[npc_id] and new_value <= int(_rules.get("broken_at", 10)):
		_broken[npc_id] = true
		_recover_minutes[npc_id] = 0
		_routines[npc_id].enter_broken()
		npc_broke.emit(npc_id)
	_check_win()


func _check_win() -> void:
	var threshold: int = int(_rules.get("broken_at", 10))
	for npc_id: String in _morale:
		if _morale[npc_id] > threshold:
			return
	outcome = OUTCOME_WON
	family_left.emit(_total)


func _reset_activity(npc_id: String) -> void:
	_charged[npc_id] = 0
	_bad[npc_id] = false
	_dark_charged[npc_id] = false
	_started_at[npc_id] = _minute

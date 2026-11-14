## A ghost action in progress (stage 5d; Demo Specification §8.10). Harm takes time: each
## action runs for its configured minutes (longer for costlier harm) and lands only when the
## time is up. The room view draws a ring over the object that fills clockwise.
##
## [br]- Starting needs enough energy for the action; otherwise nothing starts.
## [br]- On completion the action is applied and its energy paid. If energy fell below the
##   cost meanwhile (the ghost was noticed), or the object was already put in that state, it
##   fails and nothing is paid.
## [br]- Floating off, hiding, changing floor or contact cancels it: nothing is paid.
##
## [codeblock]
## var casting := GhostCasting.new(house, energy)
## if casting.start("stove").is_empty():   # "" = started; else the reason it could not
##     ...
## casting.update(minutes)                  # every frame, in game minutes
## [/codeblock]
class_name GhostCasting
extends RefCounted

const NOT_ENOUGH_ENERGY: String = "energy"
const UNAVAILABLE: String = "unavailable"
const BUSY: String = "busy"

signal completed(object_id: String)
## [param reason]: [constant NOT_ENOUGH_ENERGY] or [constant UNAVAILABLE].
signal failed(object_id: String, reason: String)
signal cancelled(object_id: String)

## The object being acted on, or "".
var object_id: String = ""

var _house: HouseState
var _energy: GhostEnergy
var _key: String = ""
var _total: float = 0.0
var _elapsed: float = 0.0


func _init(house: HouseState, energy: GhostEnergy) -> void:
	_house = house
	_energy = energy


func is_casting() -> bool:
	return not object_id.is_empty()


## How far along the running action is, 0..1 (0 when none).
func progress() -> float:
	if not is_casting() or _total <= 0.0:
		return 0.0
	return clampf(_elapsed / _total, 0.0, 1.0)


## Game minutes the running action still needs.
func minutes_left() -> float:
	return maxf(0.0, _total - _elapsed) if is_casting() else 0.0


## Starts acting on [param target]. Returns "" when started, otherwise why not:
## [constant BUSY], [constant UNAVAILABLE] or [constant NOT_ENOUGH_ENERGY].
func start(target: String) -> String:
	if is_casting():
		return BUSY
	if not GhostActions.can_act(_house, target):
		return UNAVAILABLE
	var key: String = GhostEnergy.action_key(_house.objects[target])
	if not _energy.can_afford(key):
		return NOT_ENOUGH_ENERGY
	object_id = target
	_key = key
	_total = _energy.action_minutes(key)
	_elapsed = 0.0
	if _total <= 0.0:
		_finish()
	return ""


## Runs the action on by [param minutes] game minutes; it lands when its time is up.
func update(minutes: float) -> void:
	if not is_casting() or minutes <= 0.0:
		return
	_elapsed += minutes
	if _elapsed >= _total:
		_finish()


## Stops the running action; nothing is paid.
func cancel() -> void:
	if not is_casting():
		return
	var target: String = object_id
	_clear()
	cancelled.emit(target)


func _finish() -> void:
	var target: String = object_id
	var key: String = _key
	_clear()
	if not GhostActions.can_act(_house, target):
		failed.emit(target, UNAVAILABLE)
	elif not _energy.can_afford(key):
		failed.emit(target, NOT_ENOUGH_ENERGY)
	else:
		GhostActions.act(_house, target)
		_energy.spend_action(key)
		completed.emit(target)


func _clear() -> void:
	object_id = ""
	_key = ""
	_total = 0.0
	_elapsed = 0.0

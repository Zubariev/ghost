## The ghost's energy (stage 5d, roadmap step 2; Demo Specification §8.10, GDD §12.2).
## Numbers come from `assets/data/ghost/energy.json`.
##
## [br]- Refills by itself while the ghost is not acting: faster while hidden, and faster in a
##   dark or cold room (harm the ghost has done feeds it); the multipliers stack. No refill
##   while an action runs, nor for a short pause after one completes.
## [br]- Ghost actions cost energy by how much harm they do; at too little energy they cannot
##   be done. Moving and hiding never cost energy and are never blocked.
## [br]- Being noticed (peripheral) and full contact (deep) cost energy; never below 0.
##
## [codeblock]
## var energy := GhostEnergy.new(JsonData.read(GhostEnergy.ENERGY_PATH))
## energy.regenerate(minutes, hidden, room_is_dark, room_is_cold, casting.is_casting())
## if energy.can_afford("stove"): ...
## [/codeblock]
class_name GhostEnergy
extends RefCounted

const ENERGY_PATH: String = "res://assets/data/ghost/energy.json"

## [param amount] was just lost to [param reason] ("peripheral", "deep" or an action key).
signal lost(amount: float, reason: String)
## Energy has just fallen to the low-warning level or below.
signal low_warning()

## Current energy, 0..[method max_value].
var value: float = 0.0

var _max: float
var _regen: float
var _hidden: float
var _dark: float
var _cold: float
var _pause: float
var _pause_left: float = 0.0
var _low: float
## action key -> {cost, minutes}
var _actions: Dictionary = {}
var _penalties: Dictionary = {}


func _init(config: Dictionary) -> void:
	_max = float(config.get("max", 100))
	value = clampf(float(config.get("start", _max)), 0.0, _max)
	_regen = float(config.get("regen_per_minute", 0.5))
	_hidden = float(config.get("hidden_multiplier", 1.0))
	_dark = float(config.get("dark_multiplier", 1.0))
	_cold = float(config.get("cold_multiplier", 1.0))
	_pause = float(config.get("pause_after_action_minutes", 0))
	_low = float(config.get("low_warning", 0))
	_actions = config.get("actions", {})
	_penalties = config.get("detection_penalty", {})


func max_value() -> float:
	return _max


## True at or below the low-warning level.
func is_low() -> bool:
	return value <= _low


## Energy per game minute right now, for a ghost that is not acting.
func rate(hidden: bool, dark: bool, cold: bool) -> float:
	var per_minute: float = _regen
	if hidden:
		per_minute *= _hidden
	if dark:
		per_minute *= _dark
	if cold:
		per_minute *= _cold
	return per_minute


## Refills for [param minutes] game minutes. [param acting]: an action is running (no refill).
func regenerate(minutes: float, hidden: bool, dark: bool, cold: bool, acting: bool) -> void:
	if minutes <= 0.0 or acting:
		return
	if _pause_left > 0.0:
		var paused: float = minf(_pause_left, minutes)
		_pause_left -= paused
		minutes -= paused
	value = minf(_max, value + rate(hidden, dark, cold) * minutes)


## Game minutes of the no-refill pause still to run.
func pause_left() -> float:
	return _pause_left


## The key an object's ghost action is costed under: its kind (lamp, window), else its id.
static func action_key(obj: ObjectState) -> String:
	return obj.kind if not obj.kind.is_empty() else obj.id


func has_action(key: String) -> bool:
	return _actions.has(key)


func action_cost(key: String) -> float:
	return float(_actions.get(key, {}).get("cost", 0))


## How long the action takes, in game minutes.
func action_minutes(key: String) -> float:
	return float(_actions.get(key, {}).get("minutes", 0))


func can_afford(key: String) -> bool:
	return value >= action_cost(key)


## Pays for a completed action and starts the no-refill pause; false (nothing spent) when
## there is not enough energy.
func spend_action(key: String) -> bool:
	if not can_afford(key):
		return false
	_take(action_cost(key), key)
	_pause_left = _pause
	return true


## Takes the penalty for being noticed ([param zone] "peripheral") or full contact ("deep");
## returns how much was actually lost (never more than is left).
func penalize(zone: String) -> float:
	return _take(float(_penalties.get(zone, 0)), zone)


## The penalty for [param zone] as configured.
func penalty(zone: String) -> float:
	return float(_penalties.get(zone, 0))


func _take(amount: float, reason: String) -> float:
	var was_low: bool = is_low()
	var taken: float = minf(maxf(amount, 0.0), value)
	value -= taken
	if taken > 0.0:
		lost.emit(taken, reason)
	if not was_low and is_low():
		low_warning.emit()
	return taken

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
## Value changes from the crafting tree's owned nodes (sprint 002, P3); null: configured values.
var modifiers: GhostModifiers = null
## The room the ghost is in (set by the game each frame): room bonds apply only there.
var room_id: String = ""

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
	return _mod("energy.max", _max)


## True at or below the low-warning level.
func is_low() -> bool:
	return value <= _low


## Energy per game minute right now, for a ghost that is not acting.
func rate(hidden: bool, dark: bool, cold: bool) -> float:
	var per_minute: float = _mod("energy.regen", _regen, {"room": room_id})
	if hidden:
		per_minute *= _mod("energy.hidden_multiplier", _hidden)
	if dark:
		per_minute *= _mod("energy.dark_multiplier", _dark)
	if cold:
		per_minute *= _mod("energy.cold_multiplier", _cold)
	return per_minute


## Refills for [param minutes] game minutes. [param acting]: an action is running (no refill).
func regenerate(minutes: float, hidden: bool, dark: bool, cold: bool, acting: bool) -> void:
	if minutes <= 0.0 or acting:
		return
	if _pause_left > 0.0:
		var paused: float = minf(_pause_left, minutes)
		_pause_left -= paused
		minutes -= paused
	value = minf(max_value(), value + rate(hidden, dark, cold) * minutes)


## Game minutes of the no-refill pause still to run.
func pause_left() -> float:
	return _pause_left


## The key an object's ghost action is costed under: its kind (lamp, window), else its id.
static func action_key(obj: ObjectState) -> String:
	return obj.kind if not obj.kind.is_empty() else obj.id


func has_action(key: String) -> bool:
	return _actions.has(key)


## Energy the action costs, after owned nodes (in the ghost's room, for this action).
func action_cost(key: String) -> float:
	return _mod("energy.action_cost", float(_actions.get(key, {}).get("cost", 0)), {"room": room_id, "action": key})


## How long the action takes, in game minutes.
func action_minutes(key: String) -> float:
	return _mod("energy.action_minutes", float(_actions.get(key, {}).get("minutes", 0)), {"room": room_id, "action": key})


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


## Adds [param amount] (the energy elixir, sprint 001, phase E), never above the maximum. Refused
## (false, nothing changes) for a non-positive amount or when energy is already full, so an
## elixir is not used up for nothing.
func restore(amount: float) -> bool:
	if amount <= 0.0 or value >= max_value():
		return false
	value = minf(max_value(), value + amount)
	return true


## Energy taken by something in the world, such as the hostile spider's web (sprint 002, P2):
## never below zero, nothing for a negative [param amount]; emits [signal lost] with
## [param reason]. Returns what was actually taken.
func drain(amount: float, reason: String) -> float:
	if amount <= 0.0:
		return 0.0
	return _take(amount, reason)


func _take(amount: float, reason: String) -> float:
	var was_low: bool = is_low()
	var taken: float = minf(maxf(amount, 0.0), value)
	value -= taken
	if taken > 0.0:
		lost.emit(taken, reason)
	if not was_low and is_low():
		low_warning.emit()
	return taken


# --- Save (2026-11-16) ------------------------------------------------------------------

## Energy and the no-refill pause left.
func save_state() -> Dictionary:
	return {"value": value, "pause_left": _pause_left}


## Restores [method save_state]'s data, without emitting signals.
func load_state(data: Dictionary) -> void:
	value = clampf(float(data["value"]), 0.0, max_value())
	_pause_left = float(data["pause_left"])


## [param base] after the owned nodes' changes (unchanged without [member modifiers]).
func _mod(key: String, base: float, context: Dictionary = {}) -> float:
	return base if modifiers == null else modifiers.value(key, base, context)

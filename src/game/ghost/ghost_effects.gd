## Timed effects on the ghost (sprint 001, phase E, 2026-11-26): the speed elixir, and the
## monocle in phase G. Each effect has an id, game minutes left and its parameters from the
## item's data ([code]assets/data/ghost/loot.json[/code] "use").
##
## [br]- Time is game minutes ([method update]), so effects pause with the clock (pause menu,
##   crafting) and run faster at higher game speeds, like everything else in the house.
## [br]- Starting an effect that is already running restarts its time (the longer of what is left
##   and the new dose) and replaces its parameters: doses never stack.
## [br]- [method speed_multiplier] is exactly 1 when no speed effect runs and never below 1, so
##   the ghost's normal speed always comes back and an effect never slows or stops it.
##
## [codeblock]
## effects.start("speed", 60.0, {"multiplier": 1.5})
## effects.update(minutes)
## var speed: float = base_speed * effects.speed_multiplier()
## [/codeblock]
class_name GhostEffects
extends RefCounted

## [param effect_id] ran out.
signal ended(effect_id: String)
## [param effect_id] started or was restarted.
signal started(effect_id: String)

## effect id -> {minutes: float, params: Dictionary}
var _running: Dictionary[String, Dictionary] = {}


## Starts [param effect_id] for [param minutes] game minutes with [param params]; restarts it when
## it already runs. Nothing happens for a non-positive duration.
func start(effect_id: String, minutes: float, params: Dictionary = {}) -> void:
	if minutes <= 0.0:
		return
	var left: float = remaining(effect_id)
	_running[effect_id] = {"minutes": maxf(left, minutes), "params": params.duplicate()}
	started.emit(effect_id)


## Runs every effect on by [param minutes]; those that run out end ([signal ended]).
func update(minutes: float) -> void:
	if minutes <= 0.0:
		return
	var done: Array[String] = []
	for id: String in _running:
		_running[id]["minutes"] = float(_running[id]["minutes"]) - minutes
		if float(_running[id]["minutes"]) <= 0.0:
			done.append(id)
	for id: String in done:
		_running.erase(id)
		ended.emit(id)


## Ends [param effect_id] now (e.g. the game ends); emits [signal ended] when it was running.
func stop(effect_id: String) -> void:
	if _running.erase(effect_id):
		ended.emit(effect_id)


func is_active(effect_id: String) -> bool:
	return _running.has(effect_id)


## Game minutes left of [param effect_id], 0 when it does not run.
func remaining(effect_id: String) -> float:
	return maxf(0.0, float(_running.get(effect_id, {}).get("minutes", 0.0)))


## The running effects' ids.
func active() -> Array[String]:
	var out: Array[String] = []
	out.assign(_running.keys())
	return out


## The factor on the ghost's speed: the speed effect's multiplier, never below 1; 1 without it.
func speed_multiplier() -> float:
	if not _running.has("speed"):
		return 1.0
	return maxf(1.0, float(_running["speed"]["params"].get("multiplier", 1.0)))


# --- Save -----------------------------------------------------------------------------------

func save_state() -> Dictionary:
	var out: Dictionary = {}
	for id: String in _running:
		out[id] = {"minutes": float(_running[id]["minutes"]), "params": (_running[id]["params"] as Dictionary).duplicate()}
	return out


func load_state(data: Dictionary) -> void:
	_running.clear()
	for id: String in data:
		_running[id] = {"minutes": float(data[id]["minutes"]), "params": data[id].get("params", {})}

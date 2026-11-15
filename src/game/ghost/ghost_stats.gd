## What the ghost did during one run, for the end summary (stage 6, Demo Spec §10.4):
## actions by kind, times noticed and caught, finds, energy spent on actions and energy lost
## to being seen. Fed by the game from existing signals (GhostCasting.completed,
## GhostEnergy.lost, StealthSystem.noticed / contact, GhostLoot.taken); reads nothing itself.
class_name GhostStats
extends RefCounted

## Energy-loss reasons that are penalties for being seen (energy.json detection_penalty),
## not the cost of an action.
const SEEN_REASONS: Array[String] = ["peripheral", "deep"]

var noticed: int = 0
var caught: int = 0
var items_found: int = 0
var notes_found: int = 0
var energy_spent: float = 0.0
var energy_lost: float = 0.0
## action key (GhostEnergy.action_key) -> times done
var _actions: Dictionary[String, int] = {}


## A finished ghost action of [param key] (lamp, window, stove, grocery_basket, computer).
func record_action(key: String) -> void:
	_actions[key] = _actions.get(key, 0) + 1


## Energy taken for [param reason]: a detection zone counts as lost, anything else as spent.
func record_energy(amount: float, reason: String) -> void:
	if SEEN_REASONS.has(reason):
		energy_lost += amount
	else:
		energy_spent += amount


## A found item of [param kind] ("lore" is a note; anything else an item).
func record_find(kind: String) -> void:
	if kind == "lore":
		notes_found += 1
	else:
		items_found += 1


func record_noticed() -> void:
	noticed += 1


func record_caught() -> void:
	caught += 1


func actions_of(key: String) -> int:
	return _actions.get(key, 0)


func total_actions() -> int:
	var total: int = 0
	for key: String in _actions:
		total += _actions[key]
	return total


## Action keys done at least once, in the order first done.
func action_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(_actions.keys())
	return keys

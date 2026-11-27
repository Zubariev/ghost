## Value changes from the crafting tree's owned nodes (sprint 002, P3, task S2-04; catalog
## design/crafting-progression-catalog.md, approved 2026-11-26). One shared list; each system asks
## it for its value instead of reading the base number alone:
## [codeblock]
## var cost: float = mods.value("energy.action_cost", base_cost, {"room": room_id, "action": "lamp"})
## [/codeblock]
## An effect is {key, op ("add" or "mul"), value} with optional filters: [code]room[/code] (only
## while the ghost is in that room), [code]npcs[/code] (only for these family members) and
## [code]action[/code] (only for that ghost action key). Adds apply first, then multipliers;
## the result is never below zero. Only the keys in [constant KEYS] exist: data naming any other
## is rejected when it loads ([method check]).
class_name GhostModifiers
extends RefCounted

## Every value a node may change, and the system that reads it.
const KEYS: Array[String] = [
	"energy.max",                            # GhostEnergy
	"energy.regen",                          # GhostEnergy, per room
	"energy.hidden_multiplier",              # GhostEnergy
	"energy.dark_multiplier",                # GhostEnergy
	"energy.cold_multiplier",                # GhostEnergy
	"energy.action_cost",                    # GhostEnergy, per room / action
	"energy.action_minutes",                 # GhostEnergy, per room / action
	"energy.detection_penalty.peripheral",   # GhostEnergy, per family member
	"ghost.slowest_in_order",                # ghost speed (house_game)
	"loot.search_minutes",                   # GhostLoot
	"loot.inventory_slots",                  # GhostLoot
	"monocle.minutes",                       # Monocle
	"stealth.contact_morale_penalty",        # StealthSystem, per family member
]
const OPS: Array[String] = ["add", "mul"]
const FIELDS: Array[String] = ["key", "op", "value", "room", "npcs", "action"]

## The effects changed.
signal changed()

var _effects: Array[Dictionary] = []


## Replaces the effects (all owned nodes' effects together).
func set_effects(effects: Array[Dictionary]) -> void:
	_effects = effects.duplicate(true)
	changed.emit()


## [param base] changed by every effect on [param key] that applies in [param context]
## ({room, npc, action}; a missing entry matches only unfiltered effects).
func value(key: String, base: float, context: Dictionary = {}) -> float:
	var add: float = 0.0
	var mul: float = 1.0
	for e: Dictionary in _effects:
		if String(e.get("key", "")) != key or not _applies(e, context):
			continue
		if String(e["op"]) == "add":
			add += float(e["value"])
		else:
			mul *= float(e["value"])
	return maxf(0.0, (base + add) * mul)


## What is wrong with effect [param effect], or "" when it is valid.
static func check(effect: Dictionary) -> String:
	if not KEYS.has(String(effect.get("key", ""))):
		return "unknown key '%s'" % effect.get("key", "")
	if not OPS.has(String(effect.get("op", ""))):
		return "unknown op '%s'" % effect.get("op", "")
	if not effect.has("value") or not (effect["value"] is float or effect["value"] is int):
		return "no number value"
	for field: String in effect:
		if not FIELDS.has(field):
			return "unknown field '%s'" % field
	return ""


static func _applies(e: Dictionary, context: Dictionary) -> bool:
	if e.has("room") and String(e["room"]) != String(context.get("room", "")):
		return false
	if e.has("action") and String(e["action"]) != String(context.get("action", "")):
		return false
	if e.has("npcs") and not (e["npcs"] as Array).has(String(context.get("npc", ""))):
		return false
	return true

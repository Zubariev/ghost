## Using an item from the slot bar by dragging it onto the ghost (sprint 001, phase C, 2026-11-26).
##
## An item's data names its effect ([code]"use": {"effect": "restore_energy", "amount": 40}[/code]
## in [code]assets/data/ghost/loot.json[/code]). Systems register a handler per effect name; the
## handler applies the effect and returns whether it worked. One unit is used up only when it
## worked; a refused, unknown or unheld use changes nothing, so a dropped item is never lost or
## duplicated. [code]"keep": true[/code] leaves the unit in the inventory: that effect takes it
## out itself (the monocle, phase G).
##
## [codeblock]
## var use := GhostItemUse.new(loot)
## use.register("restore_energy", func(item: String, params: Dictionary) -> bool:
##     return energy.restore(float(params["amount"])))
## if not use.use("elixir_energy"): hud.add_log(tr("LOG_CANNOT_USE"))
## [/codeblock]
class_name GhostItemUse
extends RefCounted

## [param item_id] was used ([param effect] worked).
signal used(item_id: String, effect: String)

var _loot: GhostLoot
## effect name -> Callable(item_id: String, params: Dictionary) -> bool
var _handlers: Dictionary[String, Callable] = {}


func _init(loot: GhostLoot) -> void:
	_loot = loot


## Sets the handler for [param effect] (replaces any earlier one).
func register(effect: String, handler: Callable) -> void:
	_handlers[effect] = handler


## True when the item has a use with a registered handler (it may still refuse right now).
func can_use(item_id: String) -> bool:
	var effect: String = String(_loot.use_of(item_id).get("effect", ""))
	return not effect.is_empty() and _handlers.has(effect)


## Uses one unit of [param item_id]; returns true when its effect worked.
func use(item_id: String) -> bool:
	if _loot.count(item_id) <= 0 or not can_use(item_id):
		return false
	var params: Dictionary = _loot.use_of(item_id)
	var effect: String = String(params["effect"])
	if not bool(_handlers[effect].call(item_id, params)):
		return false
	if not bool(params.get("keep", false)):
		_loot.remove(item_id, 1)
	used.emit(item_id, effect)
	return true

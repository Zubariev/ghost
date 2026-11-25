## The crafting tree's board (sprint 001, phase D, 2026-11-26; user brief items 3 to 7): five
## ingredient slots round an inverted pentagram and one result slot in the middle. Data:
## `assets/data/crafting/recipes.json`.
##
## [br]- Units move between the ghost's inventory ([GhostLoot]) and the board one at a time
##   ([method place_unit], [method return_unit]). A slot holds one kind, any number of units.
## [br]- A recipe is ready when it is unlocked, the board holds at least what it needs (the same
##   kind in two slots counts together), and the middle is empty or holds the same result.
## [br]- [method craft] uses up exactly the recipe's ingredients and adds its result to the
##   middle; [method take_result] moves the whole result to the inventory, or leaves it.
## [br]- The tree has a level ([member tier]); each upgrade is paid from the inventory and unlocks
##   the recipes of its level. New recipes and upgrades are data only.
## [br]- Nothing is lost: a unit that no longer fits the inventory stays on the board, and the
##   board, the result and the level are saved ([method save_state]).
##
## [codeblock]
## var board := CraftingBoard.new(JsonData.read(CraftingBoard.RECIPES_PATH), loot)
## board.place_unit(0, "dust")
## if board.is_ready("energy_elixir"): board.craft("energy_elixir")
## board.take_result()
## [/codeblock]
class_name CraftingBoard
extends RefCounted

const RECIPES_PATH: String = "res://assets/data/crafting/recipes.json"

## The board, the result or the tree's level changed.
signal changed()

## The tree's level: recipes of this tier and below are unlocked.
var tier: int = 0

var _loot: GhostLoot
var _slots: Array[Dictionary] = []
var _result: Dictionary = {"item": "", "count": 0}
var _recipes: Array[Dictionary] = []
var _upgrades: Array[Dictionary] = []


func _init(config: Dictionary, loot: GhostLoot) -> void:
	_loot = loot
	tier = int(config.get("start_tier", 0))
	for i: int in int(config.get("slots", 5)):
		_slots.append({"item": "", "count": 0})
	for recipe: Dictionary in config.get("recipes", []):
		_recipes.append(recipe)
	for upgrade: Dictionary in config.get("upgrades", []):
		_upgrades.append(upgrade)
	_upgrades.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["tier"]) < int(b["tier"]))


func slot_count() -> int:
	return _slots.size()


## Slot [param index]: {item, count}; item "" when empty.
func slot(index: int) -> Dictionary:
	return _slots[index].duplicate() if index >= 0 and index < _slots.size() else {"item": "", "count": 0}


## The middle slot: {item, count}; item "" when empty.
func result() -> Dictionary:
	return _result.duplicate()


func is_empty() -> bool:
	for s: Dictionary in _slots:
		if int(s["count"]) > 0:
			return false
	return int(_result["count"]) == 0


## Units on the board by item id (all slots together).
func totals() -> Dictionary:
	var out: Dictionary = {}
	for s: Dictionary in _slots:
		if int(s["count"]) > 0:
			out[s["item"]] = int(out.get(s["item"], 0)) + int(s["count"])
	return out


## Moves one unit of [param item_id] from the inventory to slot [param index]. Refused (nothing
## moves) for a missing slot, an item not held, or a slot holding another kind.
func place_unit(index: int, item_id: String) -> bool:
	if index < 0 or index >= _slots.size() or item_id.is_empty() or _loot.count(item_id) <= 0:
		return false
	var s: Dictionary = _slots[index]
	if int(s["count"]) > 0 and String(s["item"]) != item_id:
		return false
	if not _loot.remove(item_id, 1):
		return false
	s["item"] = item_id
	s["count"] = int(s["count"]) + 1
	changed.emit()
	return true


## Moves one unit from slot [param index] back to the inventory; false (the unit stays) when the
## slot is empty or the inventory has no room for its kind.
func return_unit(index: int) -> bool:
	if index < 0 or index >= _slots.size() or int(_slots[index]["count"]) <= 0:
		return false
	var s: Dictionary = _slots[index]
	if _loot.add(String(s["item"]), 1) == 0:
		return false
	s["count"] = int(s["count"]) - 1
	if int(s["count"]) == 0:
		s["item"] = ""
	changed.emit()
	return true


## Moves every unit on the board back to the inventory (the crafting screen closes); true when
## the slots are empty afterwards. What does not fit stays on the board.
func return_all() -> bool:
	var all_back: bool = true
	for i: int in _slots.size():
		while int(_slots[i]["count"]) > 0:
			if not return_unit(i):
				all_back = false
				break
	return all_back


func recipes() -> Array[Dictionary]:
	return _recipes.duplicate()


func recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in _recipes:
		if String(r["id"]) == recipe_id:
			return r
	return {}


func is_unlocked(recipe_id: String) -> bool:
	var r: Dictionary = recipe(recipe_id)
	return not r.is_empty() and int(r.get("tier", 0)) <= tier


## True when the board holds at least what the recipe needs, of each ingredient.
func has_ingredients(recipe_id: String) -> bool:
	var r: Dictionary = recipe(recipe_id)
	if r.is_empty():
		return false
	var have: Dictionary = totals()
	for item: String in r.get("ingredients", {}):
		if int(have.get(item, 0)) < int(r["ingredients"][item]):
			return false
	return true


## True when [param recipe_id] can be crafted now: unlocked, ingredients on the board, and the
## middle is empty or already holds the same result.
func is_ready(recipe_id: String) -> bool:
	if not is_unlocked(recipe_id) or not has_ingredients(recipe_id):
		return false
	return int(_result["count"]) == 0 or String(_result["item"]) == String(recipe(recipe_id)["result"])


## The unlocked recipes that are ready now, in data order.
func ready_recipes() -> Array[String]:
	var out: Array[String] = []
	for r: Dictionary in _recipes:
		if is_ready(String(r["id"])):
			out.append(String(r["id"]))
	return out


## Crafts [param recipe_id]: uses up exactly its ingredients (from the first slots that hold
## them) and adds the result to the middle. False, and nothing changes, when it is not ready.
func craft(recipe_id: String) -> bool:
	if not is_ready(recipe_id):
		return false
	var r: Dictionary = recipe(recipe_id)
	for item: String in r.get("ingredients", {}):
		var need: int = int(r["ingredients"][item])
		for s: Dictionary in _slots:
			if need == 0:
				break
			if String(s["item"]) == item:
				var used: int = mini(need, int(s["count"]))
				s["count"] = int(s["count"]) - used
				need -= used
				if int(s["count"]) == 0:
					s["item"] = ""
	_result["item"] = String(r["result"])
	_result["count"] = int(_result["count"]) + int(r.get("amount", 1))
	changed.emit()
	return true


## Moves the whole result to the inventory; false (it stays in the middle) when there is none
## or the inventory has no room for its kind.
func take_result() -> bool:
	if int(_result["count"]) <= 0:
		return false
	if _loot.add(String(_result["item"]), int(_result["count"])) == 0:
		return false
	_result = {"item": "", "count": 0}
	changed.emit()
	return true


## The next upgrade ({tier, cost}), or {} when the tree is at its top level.
func next_upgrade() -> Dictionary:
	for u: Dictionary in _upgrades:
		if int(u["tier"]) > tier:
			return u
	return {}


## True when there is a next upgrade and the inventory holds its whole cost.
func can_upgrade() -> bool:
	var u: Dictionary = next_upgrade()
	if u.is_empty():
		return false
	for item: String in u.get("cost", {}):
		if _loot.count(item) < int(u["cost"][item]):
			return false
	return true


## Pays the next upgrade from the inventory and raises the tree's level; false (nothing paid)
## when it cannot be afforded or there is none.
func upgrade() -> bool:
	if not can_upgrade():
		return false
	var u: Dictionary = next_upgrade()
	for item: String in u.get("cost", {}):
		_loot.remove(item, int(u["cost"][item]))
	tier = int(u["tier"])
	changed.emit()
	return true


# --- Save -----------------------------------------------------------------------------------

func save_state() -> Dictionary:
	var slots: Array = []
	for s: Dictionary in _slots:
		slots.append([String(s["item"]), int(s["count"])])
	return {"tier": tier, "slots": slots, "result": [String(_result["item"]), int(_result["count"])]}


func load_state(data: Dictionary) -> void:
	tier = int(data.get("tier", tier))
	var slots: Array = data.get("slots", [])
	for i: int in mini(slots.size(), _slots.size()):
		_slots[i] = {"item": String(slots[i][0]), "count": int(slots[i][1])}
	var r: Array = data.get("result", ["", 0])
	_result = {"item": String(r[0]), "count": int(r[1])}
	changed.emit()

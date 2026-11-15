## Searching hiding spots for things to collect (user decision 2026-11-15; collect + inventory
## + lore now, crafting later). Numbers and contents: `assets/data/ghost/loot.json`.
##
## [br]- While hidden, hold E for [code]search_minutes[/code] to search the spot; letting go
##   stops the search ([method hold]).
## [br]- A finished search opens the spot's grid: 4 slots (small spot) or 9 (large) showing
##   what is there now. Items are taken one by one ([method take]).
## [br]- Unique items are in their spot until taken, then gone for good. Renewable materials
##   come back [code]respawn_minutes[/code] after being taken. Untaken items stay.
## [br]- Leaving the spot closes the grid ([method close]); hiding again needs a new search.
## [br]- Taken items go to [member inventory]; lore items are also listed in [member lore_found].
## [br]- HUD slot bar (user decision 2026-11-15): materials fill [code]inventory_slots[/code]
##   slots, one per kind, stacking; when every slot holds a kind, a new kind cannot be taken
##   ([method can_take]). Lore notes and the house map never use a slot.
## [br]- The house map is an item (kind [code]map[/code]); the HUD map shows once it is
##   taken ([method has_map]).
##
## [codeblock]
## loot.start_search("hide_hall_chest_5")
## loot.hold(Input.is_action_pressed(&"interact"))
## loot.update(minutes, clock.total_minutes)
## var item: String = loot.take(slot, clock.total_minutes)
## [/codeblock]
class_name GhostLoot
extends RefCounted

const LOOT_PATH: String = "res://assets/data/ghost/loot.json"

## A search finished: [param slots] are the grid's item ids ("" = empty slot).
signal searched(spot_id: String, slots: Array[String])
## [param item_id] was taken into the inventory.
signal taken(item_id: String)

## item id -> how many the ghost has.
var inventory: Dictionary[String, int] = {}
## Lore items found, in the order found.
var lore_found: Array[String] = []

var _search_minutes: float
var _slots: int
var _grid_sizes: Dictionary
var _spots: Dictionary
var _items: Dictionary
## Unique items already taken (never come back).
var _collected: Dictionary[String, bool] = {}
## "spot|item" -> total game minute it was taken (renewables).
var _taken_at: Dictionary[String, int] = {}
var _searching_spot: String = ""
var _progress: float = 0.0
var _open_spot: String = ""
var _grid: Array[String] = []


func _init(config: Dictionary) -> void:
	_search_minutes = maxf(0.0, float(config.get("search_minutes", 3)))
	_slots = int(config.get("inventory_slots", 10))
	_grid_sizes = config.get("grid", {"small": 4, "large": 9})
	_spots = config.get("spots", {})
	_items = config.get("items", {})


## Starts searching [param spot_id] (call while hidden in it). No effect while that spot's grid
## is already open.
func start_search(spot_id: String) -> void:
	if _open_spot == spot_id:
		return
	close()
	_searching_spot = spot_id
	_progress = 0.0


func is_searching() -> bool:
	return not _searching_spot.is_empty()


## How far the running search is, 0..1.
func search_progress() -> float:
	if not is_searching() or _search_minutes <= 0.0:
		return 0.0
	return clampf(_progress / _search_minutes, 0.0, 1.0)


## The spot being searched, or "".
func searching_spot() -> String:
	return _searching_spot


## Reports whether E is held this frame; letting go stops the search.
func hold(held: bool) -> void:
	if not held:
		_searching_spot = ""
		_progress = 0.0


## Runs the search on by [param minutes]; [param now] is the total game minute (for respawns).
func update(minutes: float, now: int) -> void:
	if not is_searching() or minutes <= 0.0:
		return
	_progress += minutes
	if _progress >= _search_minutes:
		var spot: String = _searching_spot
		_searching_spot = ""
		_progress = 0.0
		_open(spot, now)


func is_open() -> bool:
	return not _open_spot.is_empty()


## The spot whose grid is open, or "".
func open_spot() -> String:
	return _open_spot


## The open grid: one item id per slot ("" = empty); empty when closed.
func grid() -> Array[String]:
	return _grid.duplicate()


## True when the item in grid [param slot] can be taken now: there is one, and it is not a
## new material kind while every inventory slot is in use.
func can_take(slot: int) -> bool:
	if not is_open() or slot < 0 or slot >= _grid.size() or _grid[slot].is_empty():
		return false
	var item: String = _grid[slot]
	return kind_of(item) != "material" or inventory.has(item) or slot_items().size() < _slots


## Takes the item in [param slot] at total game minute [param now]; returns its id, or ""
## (nothing there, or the inventory slots are full: [method can_take]).
func take(slot: int, now: int) -> String:
	if not can_take(slot):
		return ""
	var item: String = _grid[slot]
	_grid[slot] = ""
	inventory[item] = int(inventory.get(item, 0)) + 1
	var spot: Dictionary = _spots.get(_open_spot, {})
	if (spot.get("unique", []) as Array).has(item):
		_collected[item] = true
		if kind_of(item) == "lore":
			lore_found.append(item)
	else:
		_taken_at[_open_spot + "|" + item] = now
	taken.emit(item)
	return item


## Closes the grid and stops any search (the ghost left the spot, or was caught).
func close() -> void:
	_open_spot = ""
	_grid = []
	_searching_spot = ""
	_progress = 0.0


## How many inventory slots there are.
func slot_count() -> int:
	return _slots


## The materials held, one per slot, in the order first taken.
func slot_items() -> Array[String]:
	var out: Array[String] = []
	for id: String in inventory:
		if kind_of(id) == "material":
			out.append(id)
	return out


## True once the house map has been taken.
func has_map() -> bool:
	for id: String in inventory:
		if kind_of(id) == "map":
			return true
	return false


func count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func kind_of(item_id: String) -> String:
	return String(_items.get(item_id, {}).get("kind", "material"))


## The string key of an item's name.
func name_key(item_id: String) -> String:
	return String(_items.get(item_id, {}).get("name", item_id))


## The string key of a lore item's text, or "".
func text_key(item_id: String) -> String:
	return String(_items.get(item_id, {}).get("text", ""))


func icon(item_id: String) -> String:
	return String(_items.get(item_id, {}).get("icon", ""))


# Fills the grid with what is in the spot now: unique items not yet taken, then renewables
# that are back; in data order, so the same contents always give the same grid.
func _open(spot_id: String, now: int) -> void:
	var spot: Dictionary = _spots.get(spot_id, {})
	var size: int = int(_grid_sizes.get(String(spot.get("size", "small")), 4))
	var present: Array[String] = []
	for item: String in spot.get("unique", []):
		if not _collected.has(item):
			present.append(item)
	for item: String in spot.get("renewable", []):
		var key: String = spot_id + "|" + item
		var back_at: int = int(_taken_at.get(key, -1)) + int(_items.get(item, {}).get("respawn_minutes", 0))
		if not _taken_at.has(key) or now >= back_at:
			present.append(item)
	_grid = []
	for i: int in size:
		_grid.append(present[i] if i < present.size() else "")
	_open_spot = spot_id
	searched.emit(spot_id, grid())

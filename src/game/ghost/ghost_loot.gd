## Searching hiding spots for things to collect (user decision 2026-11-15; collect + inventory
## + lore now, crafting later). Numbers and contents: `assets/data/ghost/loot.json`.
##
## [br]- While hidden, hold E for [code]search_minutes[/code] to search the spot; letting go
##   stops the search ([method hold]).
## [br]- A finished search opens the spot's grid: 4 slots (small spot) or 9 (large) showing
##   what is there now. Items are taken one by one ([method take]).
## [br]- Unique items are in their spot until taken, then gone for good. Renewable materials
##   come back [code]respawn_minutes[/code] after being taken. Untaken items stay.
## [br]- Leaving the spot, or pressing E again while the grid is open (2026-11-15), closes the
##   grid ([method close]); seeing it again needs a new search.
## [br]- Taken items go to [member inventory]; lore items are also listed in [member lore_found].
## [br]- HUD slot bar (user decision 2026-11-15): materials (and since sprint 001 consumables and
##   tools) fill [code]inventory_slots[/code] slots, one per kind, stacking; when every slot holds a kind, a new kind cannot be taken
##   ([method can_take]). Lore notes and the house map never use a slot.
## [br]- The house map is an item (kind [code]map[/code]); the HUD map shows once it is
##   taken ([method has_map]).
##
## [codeblock]
## loot.start_search("hide_hall_chest_5")
## loot.hold(Input.is_action_pressed(&"interact"))
## loot.update(minutes, clock.total_minutes)
## var item: String = loot.take(slot, clock.total_minutes)
## loot.remove("fly", 6); loot.add("spider_nest", 1)   # other systems move units (sprint 001)
## [/codeblock]
class_name GhostLoot
extends RefCounted

const LOOT_PATH: String = "res://assets/data/ghost/loot.json"

## A search finished: [param slots] are the grid's item ids ("" = empty slot).
signal searched(spot_id: String, slots: Array[String])
## [param item_id] was taken into the inventory.
signal taken(item_id: String)
## The inventory changed (taken, added, removed): the slot bar redraws.
signal inventory_changed()

## Item kinds that take a slot of the bar, one slot per kind, stacking (sprint 001, 2026-11-26:
## consumables such as elixirs and spider nests, and tools such as the monocle, join materials).
const SLOT_KINDS: Array[String] = ["material", "consumable", "tool"]

## item id -> how many the ghost has.
var inventory: Dictionary[String, int] = {}
## Lore items found, in the order found.
var lore_found: Array[String] = []

var _search_minutes: float
var _slots: int
## Value changes from the crafting tree's owned nodes (sprint 002, P3): search time and slots;
## null: configured values.
var modifiers: GhostModifiers = null
var _grid_sizes: Dictionary
var _spots: Dictionary
var _items: Dictionary
## Unique items already taken (never come back).
var _collected: Dictionary[String, bool] = {}
## "spot|item" -> total game minute it was taken (renewables).
var _taken_at: Dictionary[String, int] = {}
## Single items put into a spot at run time (the monocle after use, sprint 001): item -> spot id.
var _placed: Dictionary[String, String] = {}
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
	if not is_searching() or search_minutes() <= 0.0:
		return 0.0
	return clampf(_progress / search_minutes(), 0.0, 1.0)


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
	if _progress >= search_minutes():
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
	return can_add(_grid[slot])


## Takes the item in [param slot] at total game minute [param now]; returns its id, or ""
## (nothing there, or the inventory slots are full: [method can_take]).
func take(slot: int, now: int) -> String:
	if not can_take(slot):
		return ""
	var item: String = _grid[slot]
	_grid[slot] = ""
	inventory[item] = int(inventory.get(item, 0)) + 1
	var spot: Dictionary = _spots.get(_open_spot, {})
	if _placed.get(item, "") == _open_spot:
		_placed.erase(item)   # a placed item leaves its spot for good
	elif (spot.get("unique", []) as Array).has(item):
		_collected[item] = true
		if kind_of(item) == "lore":
			lore_found.append(item)
	else:
		_taken_at[_open_spot + "|" + item] = now
	taken.emit(item)
	inventory_changed.emit()
	return item


# --- Moving units in and out (sprint 001, phase C, 2026-11-26) -----------------------------
# Crafting, the spider's trade and using items move single units through these; counts never go
# below zero and an emptied kind is removed, which frees its slot.

## True when the item takes a slot of the bar (see [constant SLOT_KINDS]).
func uses_slot(item_id: String) -> bool:
	return SLOT_KINDS.has(kind_of(item_id))


## True when at least one unit of [param item_id] fits: a kind already held, an item that takes
## no slot, or a free slot.
func can_add(item_id: String) -> bool:
	return not uses_slot(item_id) or inventory.has(item_id) or slot_items().size() < slot_count()


## Adds [param amount] units; returns how many were added (all, or 0 when the kind does not fit).
func add(item_id: String, amount: int = 1) -> int:
	if amount <= 0 or not can_add(item_id):
		return 0
	inventory[item_id] = count(item_id) + amount
	inventory_changed.emit()
	return amount


## Removes [param amount] units; all or nothing. Returns false (and changes nothing) when fewer
## are held.
func remove(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(item_id) < amount:
		return false
	var left: int = count(item_id) - amount
	if left == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = left
	inventory_changed.emit()
	return true


## Closes the grid and stops any search (the ghost left the spot, or was caught).
func close() -> void:
	_open_spot = ""
	_grid = []
	_searching_spot = ""
	_progress = 0.0


## How many inventory slots there are.
func slot_count() -> int:
	return _slots if modifiers == null else roundi(modifiers.value("loot.inventory_slots", float(_slots)))


## Game minutes E must be held to search a spot (after owned nodes).
func search_minutes() -> float:
	return _search_minutes if modifiers == null else modifiers.value("loot.search_minutes", _search_minutes)


## The items held that take a slot, one per slot, in the order first taken.
func slot_items() -> Array[String]:
	var out: Array[String] = []
	for id: String in inventory:
		if uses_slot(id) and count(id) > 0:
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


## What using the item does (data "use": {"effect": ..., parameters}), or {} for items that
## cannot be used (sprint 001, 2026-11-26).
func use_of(item_id: String) -> Dictionary:
	return _items.get(item_id, {}).get("use", {})


# Fills the grid with what is in the spot now: unique items not yet taken, then renewables
# that are back; in data order, so the same contents always give the same grid.
func _open(spot_id: String, now: int) -> void:
	var spot: Dictionary = _spots.get(spot_id, {})
	var size: int = int(_grid_sizes.get(String(spot.get("size", "small")), 4))
	var present: Array[String] = []
	for item: String in _placed:
		if _placed[item] == spot_id:
			present.append(item)   # placed items first, so a full spot still shows them
	for item: String in spot.get("unique", []):
		if not _collected.has(item):
			present.append(item)
	for item: String in spot.get("renewable", []):
		var key: String = spot_id + "|" + item
		# a spot may bring an item back sooner or later than usual (sprint 001: flies in the kitchen)
		var respawn: int = int(spot.get("respawn", {}).get(item, _items.get(item, {}).get("respawn_minutes", 0)))
		var back_at: int = int(_taken_at.get(key, -1)) + respawn
		if not _taken_at.has(key) or now >= back_at:
			present.append(item)
	_grid = []
	for i: int in size:
		_grid.append(present[i] if i < present.size() else "")
	_open_spot = spot_id
	searched.emit(spot_id, grid())


# --- Placing single items (sprint 001, phase G, 2026-11-26) --------------------------------

## Puts [param item_id] into hiding spot [param spot_id], where the next search finds it (first in
## the grid). Refused for an unknown spot, an item already placed somewhere, or one the ghost holds:
## a single item is never in two places.
func place(item_id: String, spot_id: String) -> bool:
	if not _spots.has(spot_id) or _placed.has(item_id) or count(item_id) > 0:
		return false
	_placed[item_id] = spot_id
	return true


## Places [param item_id] in a hiding spot picked by [param rng] from every searchable spot; returns
## the spot, or "" when it could not be placed.
func place_randomly(item_id: String, rng: RandomNumberGenerator) -> String:
	var ids: Array = _spots.keys()
	if ids.is_empty():
		return ""
	ids.sort()   # data order is not guaranteed; sorted, a seed always gives the same spot
	var spot_id: String = String(ids[rng.randi_range(0, ids.size() - 1)])
	return spot_id if place(item_id, spot_id) else ""


## The spot [param item_id] was placed in, or "".
func placed_spot(item_id: String) -> String:
	return String(_placed.get(item_id, ""))


# --- Save (2026-11-16) ------------------------------------------------------------------

## What the ghost has, what it found, and when renewables were taken. A search under way or an
## open grid is not kept: a loaded game starts with the grid closed (search again).
func save_state() -> Dictionary:
	return {"inventory": inventory.duplicate(), "lore": lore_found.duplicate(), "collected": _collected.duplicate(),
		"taken_at": _taken_at.duplicate(), "placed": _placed.duplicate()}


func load_state(data: Dictionary) -> void:
	close()
	inventory.assign(data["inventory"])
	lore_found.assign(data["lore"])
	_collected.assign(data["collected"])
	_taken_at.assign(data["taken_at"])
	_placed.assign(data.get("placed", {}))   # saves from before sprint 001 have none

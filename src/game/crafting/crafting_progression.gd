## The crafting tree's roots (sprint 002, P3, task S2-04): branches of nodes the ghost opens with
## materials. Content: design/crafting-progression-catalog.md (approved 2026-11-26); data:
## [code]assets/data/crafting/progression.json[/code]. Logic only; the roots screen draws it.
##
## [br]- A node is OWNED, AVAILABLE (every parent owned) or LOCKED.
## [br]- Trunk nodes carry a [code]tier[/code]: they are the tree's existing levels
##   ([CraftingBoard]). Owned when the board's tier has reached theirs; unlocking one is the
##   board's own upgrade (its cost in recipes.json). So a level bought on the hollow screen, or
##   loaded from a sprint 001 save, owns its trunk node, and nothing is stored twice.
## [br]- Every other node has its own [code]cost[/code] (paid from [GhostLoot], all or nothing) and
##   [code]effects[/code] ([GhostModifiers] entries). Owned branch nodes are saved by id.
## [br]- Adding a branch, node or room bond is data only.
class_name CraftingProgression
extends RefCounted

const PROGRESSION_PATH: String = "res://assets/data/crafting/progression.json"

enum NodeState { LOCKED, AVAILABLE, OWNED }

## A node was unlocked (or the owned set was loaded).
signal changed()

var _board: CraftingBoard
var _loot: GhostLoot
var _branches: Array[Dictionary] = []
var _nodes: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _owned: Dictionary = {}   # branch node id -> true


func _init(config: Dictionary, board: CraftingBoard, loot: GhostLoot) -> void:
	_board = board
	_loot = loot
	for b: Dictionary in config.get("branches", []):
		_branches.append(b)
	for n: Dictionary in config.get("nodes", []):
		_nodes.append(n)
		_by_id[String(n["id"])] = n
	# the signal's own emit, not a lambda: a lambda here holds this object, and the board holding it
	# made a cycle that was never freed (leak at exit, 2026-11-27)
	_board.changed.connect(changed.emit)


## The branches as in the data (id, colour, direction, coffin); a copy.
func branches() -> Array[Dictionary]:
	return _branches.duplicate()


## Every node as in the data, in catalogue order; a copy.
func nodes() -> Array[Dictionary]:
	return _nodes.duplicate()


## The node [param id] as in the data, or {} when there is none.
func node(id: String) -> Dictionary:
	return _by_id.get(id, {})


## True for a trunk node: one of the tree's levels (it has a tier) rather than a branch node.
func is_trunk(id: String) -> bool:
	return node(id).has("tier")


## LOCKED, AVAILABLE (every parent owned) or OWNED; an unknown id is LOCKED.
func state(id: String) -> NodeState:
	if _is_owned(id):
		return NodeState.OWNED
	for parent: Variant in node(id).get("parents", []):
		if not _is_owned(String(parent)):
			return NodeState.LOCKED
	return NodeState.AVAILABLE if not node(id).is_empty() else NodeState.LOCKED


## What unlocking [param id] costs: item -> units ({} for an owned or unknown node).
func cost(id: String) -> Dictionary:
	var n: Dictionary = node(id)
	if n.is_empty():
		return {}
	if is_trunk(id):
		for u: Dictionary in _board_upgrades():
			if int(u["tier"]) == int(n["tier"]):
				return (u.get("cost", {}) as Dictionary).duplicate()
		return {}
	return (n.get("cost", {}) as Dictionary).duplicate()


## True when [param id] is available and the inventory holds its whole cost.
func can_unlock(id: String) -> bool:
	if state(id) != NodeState.AVAILABLE:
		return false
	if is_trunk(id):
		return int(node(id)["tier"]) == int(_board.next_upgrade().get("tier", -1)) and _board.can_upgrade()
	var price: Dictionary = cost(id)
	for item: String in price:
		if _loot.count(item) < int(price[item]):
			return false
	return true


## Pays for and owns [param id]; false, and nothing is paid, when it cannot.
func unlock(id: String) -> bool:
	if not can_unlock(id):
		return false
	if is_trunk(id):
		return _board.upgrade()   # emits the board's changed, forwarded as ours
	var price: Dictionary = cost(id)
	for item: String in price:
		_loot.remove(item, int(price[item]))
	_owned[id] = true
	changed.emit()
	return true


## The effects of every owned node, in data order.
func active_effects() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n: Dictionary in _nodes:
		if _is_owned(String(n["id"])):
			for e: Dictionary in n.get("effects", []):
				out.append(e)
	return out


# --- Save -----------------------------------------------------------------------------------

## The owned branch nodes (trunk ownership is the board's tier, saved with the board).
func save_state() -> Dictionary:
	var owned: Array = []
	for n: Dictionary in _nodes:
		if _owned.has(String(n["id"])):
			owned.append(String(n["id"]))
	return {"owned": owned}


## Restores [method save_state]'s data; ids no longer in the data are dropped; an empty
## dictionary (a save from before sprint 002) owns no branch node.
func load_state(data: Dictionary) -> void:
	_owned.clear()
	for id: Variant in data.get("owned", []):
		if _by_id.has(String(id)) and not is_trunk(String(id)):
			_owned[String(id)] = true
	changed.emit()


# --- Data check -------------------------------------------------------------------------------

## Problems in progression data [param config] (with the board's recipes data
## [param board_config]): unknown branches or parents, cycles, trunk tiers without an upgrade,
## branch nodes without a cost or an effect, invalid effects. Empty when the data is sound.
static func check(config: Dictionary, board_config: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var branch_ids: Array = (config.get("branches", []) as Array).map(func(b: Dictionary) -> String: return String(b["id"]))
	var tiers: Array = [int(board_config.get("start_tier", 0))]
	for u: Dictionary in board_config.get("upgrades", []):
		tiers.append(int(u["tier"]))
	var by_id: Dictionary = {}
	for n: Dictionary in config.get("nodes", []):
		if by_id.has(String(n["id"])):
			problems.append("%s: duplicate id" % n["id"])
		by_id[String(n["id"])] = n
	for n: Dictionary in config.get("nodes", []):
		var id: String = String(n["id"])
		if not branch_ids.has(String(n.get("branch", ""))):
			problems.append("%s: unknown branch '%s'" % [id, n.get("branch", "")])
		for parent: Variant in n.get("parents", []):
			if not by_id.has(String(parent)):
				problems.append("%s: unknown parent '%s'" % [id, parent])
		if n.has("tier"):
			if not tiers.has(int(n["tier"])):
				problems.append("%s: no tree level %d" % [id, int(n["tier"])])
			continue
		if (n.get("cost", {}) as Dictionary).is_empty():
			problems.append("%s: no cost" % id)
		if (n.get("effects", []) as Array).is_empty():
			problems.append("%s: no effect" % id)
		for e: Dictionary in n.get("effects", []):
			var bad: String = GhostModifiers.check(e)
			if not bad.is_empty():
				problems.append("%s: %s" % [id, bad])
	for id: String in by_id:
		if _in_cycle(id, by_id):
			problems.append("%s: cycle in parents" % id)
	return problems


static func _in_cycle(start: String, by_id: Dictionary) -> bool:
	var stack: Array = (by_id[start].get("parents", []) as Array).duplicate()
	var seen: Dictionary = {}
	while not stack.is_empty():
		var id: String = String(stack.pop_back())
		if id == start:
			return true
		if seen.has(id) or not by_id.has(id):
			continue
		seen[id] = true
		stack.append_array(by_id[id].get("parents", []))
	return false


func _is_owned(id: String) -> bool:
	var n: Dictionary = node(id)
	if n.is_empty():
		return false
	if n.has("tier"):
		return _board.tier >= int(n["tier"])
	return _owned.has(id)


func _board_upgrades() -> Array[Dictionary]:
	return _board.upgrades()

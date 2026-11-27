## The crafting tree's roots (sprint 002, P3, task S2-04; catalog
## design/crafting-progression-catalog.md): nodes on branches, each opened when its parents are
## owned and paid for from the inventory, all or nothing; trunk nodes are the tree's existing
## levels, so older saves keep what they had.
extends GdUnitTestSuite

var _loot: GhostLoot
var _board: CraftingBoard
var _prog: CraftingProgression


func _loot_config() -> Dictionary:
	var items: Dictionary = {}
	for id: String in ["dust", "bone", "ink", "feather"]:
		items[id] = {"name": "ITEM_" + id, "kind": "material"}
	return {"inventory_slots": 10, "spots": {}, "items": items}


func _board_config() -> Dictionary:
	return {"slots": 5, "start_tier": 0,
		"upgrades": [{"tier": 1, "cost": {"bone": 2}}, {"tier": 2, "cost": {"ink": 2}}],
		"recipes": [{"id": "tonic", "result": "dust", "amount": 1, "tier": 1, "ingredients": {"bone": 1}}]}


func _prog_config() -> Dictionary:
	return {
		"branches": [
			{"id": "trunk", "colour": "amber"},
			{"id": "ghost", "colour": "green"},
		],
		"nodes": [
			{"id": "T0", "branch": "trunk", "parents": [], "tier": 0},
			{"id": "T1", "branch": "trunk", "parents": ["T0"], "tier": 1},
			{"id": "T2", "branch": "trunk", "parents": ["T1"], "tier": 2},
			{"id": "G1", "branch": "ghost", "parents": ["T1"], "cost": {"dust": 3},
				"effects": [{"key": "energy.max", "op": "add", "value": 20}]},
			{"id": "G2", "branch": "ghost", "parents": ["G1"], "cost": {"feather": 1, "dust": 1},
				"effects": [{"key": "energy.hidden_multiplier", "op": "add", "value": 1}]},
		],
	}


func before_test() -> void:
	_loot = GhostLoot.new(_loot_config())
	_board = CraftingBoard.new(_board_config(), _loot)
	_prog = CraftingProgression.new(_prog_config(), _board, _loot)


func test_at_the_start_only_the_tree_is_owned_and_the_first_level_is_open() -> void:
	assert_int(_prog.state("T0")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_int(_prog.state("T1")).is_equal(CraftingProgression.NodeState.AVAILABLE)
	assert_int(_prog.state("T2")).is_equal(CraftingProgression.NodeState.LOCKED)
	assert_int(_prog.state("G1")).is_equal(CraftingProgression.NodeState.LOCKED)


func test_a_trunk_node_is_the_trees_level_and_costs_its_upgrade() -> void:
	assert_dict(_prog.cost("T1")).is_equal({"bone": 2})
	_loot.add("bone", 2)
	assert_bool(_prog.unlock("T1")).is_true()
	assert_int(_board.tier).is_equal(1)
	assert_bool(_board.is_unlocked("tonic")).is_true()
	assert_int(_loot.count("bone")).is_equal(0)
	assert_int(_prog.state("T1")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_int(_prog.state("G1")).is_equal(CraftingProgression.NodeState.AVAILABLE)


func test_an_upgrade_bought_on_the_hollow_screen_owns_the_trunk_node() -> void:
	_loot.add("bone", 2)
	_board.upgrade()
	assert_int(_prog.state("T1")).is_equal(CraftingProgression.NodeState.OWNED)


func test_a_node_cannot_be_unlocked_before_its_parents() -> void:
	_loot.add("dust", 5)
	assert_bool(_prog.can_unlock("G1")).is_false()
	assert_bool(_prog.unlock("G1")).is_false()
	assert_int(_loot.count("dust")).is_equal(5)


func test_unlocking_pays_the_whole_cost_or_nothing() -> void:
	_loot.add("bone", 2)
	_prog.unlock("T1")
	_loot.add("dust", 2)
	assert_bool(_prog.unlock("G1")).is_false()
	assert_int(_loot.count("dust")).is_equal(2)
	_loot.add("dust", 1)
	assert_bool(_prog.unlock("G1")).is_true()
	assert_int(_loot.count("dust")).is_equal(0)
	assert_int(_prog.state("G1")).is_equal(CraftingProgression.NodeState.OWNED)


func test_an_owned_node_cannot_be_bought_twice() -> void:
	_loot.add("bone", 2)
	_prog.unlock("T1")
	_loot.add("dust", 6)
	_prog.unlock("G1")
	assert_bool(_prog.unlock("G1")).is_false()
	assert_int(_loot.count("dust")).is_equal(3)


func test_owned_nodes_give_their_effects_and_signal() -> void:
	var changed: Array[int] = [0]
	_prog.changed.connect(func() -> void: changed[0] += 1)
	_loot.add("bone", 2)
	_prog.unlock("T1")
	_loot.add("dust", 3)
	_prog.unlock("G1")
	assert_array(_prog.active_effects()).is_equal([{"key": "energy.max", "op": "add", "value": 20}])
	assert_int(changed[0]).is_equal(2)


func test_owned_nodes_survive_save_and_load_and_unknown_ids_are_dropped() -> void:
	_loot.add("bone", 2)
	_prog.unlock("T1")
	_loot.add("dust", 3)
	_prog.unlock("G1")
	var data: Dictionary = _prog.save_state()
	data["owned"].append("removed_node")
	var board2 := CraftingBoard.new(_board_config(), _loot)
	board2.load_state(_board.save_state())
	var copy := CraftingProgression.new(_prog_config(), board2, _loot)
	copy.load_state(data)
	assert_int(copy.state("G1")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_array(copy.save_state()["owned"]).is_equal(["G1"])


func test_a_save_from_before_the_roots_keeps_its_tree_level() -> void:
	# sprint 001 saves: the board's tier only, no progression data
	_board.load_state({"tier": 2, "slots": [], "result": ["", 0]})
	_prog.load_state({})
	assert_int(_prog.state("T1")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_int(_prog.state("T2")).is_equal(CraftingProgression.NodeState.OWNED)
	assert_int(_prog.state("G1")).is_equal(CraftingProgression.NodeState.AVAILABLE)


func test_the_checker_finds_broken_graphs() -> void:
	assert_array(Array(CraftingProgression.check(_prog_config(), _board_config()))).is_empty()
	var bad: Dictionary = _prog_config()
	bad["nodes"].append({"id": "X", "branch": "nowhere", "parents": ["missing"], "cost": {"dust": 1}})
	bad["nodes"].append({"id": "Y", "branch": "ghost", "parents": ["Z"], "cost": {"dust": 1}})
	bad["nodes"].append({"id": "Z", "branch": "ghost", "parents": ["Y"], "cost": {"dust": 1}})
	bad["nodes"].append({"id": "W", "branch": "ghost", "parents": ["T1"], "cost": {"dust": 1},
		"effects": [{"key": "ghost.fly", "op": "add", "value": 1}]})
	bad["nodes"].append({"id": "V", "branch": "ghost", "parents": ["T1"]})
	var problems: String = "\n".join(CraftingProgression.check(bad, _board_config()))
	for expected: String in ["unknown branch", "unknown parent", "cycle", "ghost.fly", "V: no cost", "V: no effect"]:
		assert_str(problems).contains(expected)


func test_the_progression_is_freed_when_nobody_holds_it() -> void:
	# a lambda inside a RefCounted keeps its self alive: connected to the board's signal it made a
	# board <-> progression cycle that leaked both (and the loot) at exit (2026-11-27)
	var loot := GhostLoot.new(_loot_config())
	var board := CraftingBoard.new(_board_config(), loot)
	var prog := CraftingProgression.new(_prog_config(), board, loot)
	var prog_ref: WeakRef = weakref(prog)
	var board_ref: WeakRef = weakref(board)
	prog = null
	board = null
	loot = null
	assert_object(prog_ref.get_ref()).is_null()
	assert_object(board_ref.get_ref()).is_null()


func test_a_board_change_is_still_passed_on_as_a_progression_change() -> void:
	var seen: Array[int] = [0]
	_prog.changed.connect(func() -> void: seen[0] += 1)
	_board.changed.emit()
	assert_int(seen[0]).is_equal(1)

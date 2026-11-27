## How a node looks in each state (sprint 002, P5; design/ux/roots-progression.md, States &
## Variants): the states differ by size, ring and glow, not by colour alone.
extends GdUnitTestSuite

const COLOUR := Color(0.7, 0.55, 0.3)


func _look(state: CraftingProgression.NodeState, affordable: bool = false, selected: bool = false) -> Dictionary:
	return RootsStyle.node_look(state, affordable, selected, COLOUR)


func test_locked_nodes_are_small_dark_and_have_no_glow() -> void:
	var look: Dictionary = _look(CraftingProgression.NodeState.LOCKED)
	assert_float(look["radius"]).is_less(_look(CraftingProgression.NodeState.AVAILABLE)["radius"])
	assert_float(look["glow"]).is_equal(0.0)
	assert_bool(look["ring"]).is_false()


func test_only_an_affordable_available_node_pulses() -> void:
	assert_bool(_look(CraftingProgression.NodeState.AVAILABLE, true)["pulse"]).is_true()
	assert_bool(_look(CraftingProgression.NodeState.AVAILABLE, false)["pulse"]).is_false()
	assert_bool(_look(CraftingProgression.NodeState.OWNED, true)["pulse"]).is_false()


func test_an_owned_node_has_a_gold_ring_and_a_steady_glow() -> void:
	var look: Dictionary = _look(CraftingProgression.NodeState.OWNED)
	assert_bool(look["ring"]).is_true()
	assert_float(look["glow"]).is_greater(0.0)


func test_the_four_states_differ_without_colour() -> void:
	var keys: Array = []
	for args: Array in [[CraftingProgression.NodeState.LOCKED, false], [CraftingProgression.NodeState.AVAILABLE, false],
			[CraftingProgression.NodeState.AVAILABLE, true], [CraftingProgression.NodeState.OWNED, false]]:
		var look: Dictionary = _look(args[0], args[1])
		keys.append([look["radius"], look["ring"], look["glow"] > 0.0, look["pulse"]])
	for i: int in keys.size():
		for j: int in range(i + 1, keys.size()):
			assert_array(keys[i]).is_not_equal(keys[j])


func test_selection_adds_an_outer_ring_without_changing_the_state_look() -> void:
	var plain: Dictionary = _look(CraftingProgression.NodeState.OWNED)
	var chosen: Dictionary = _look(CraftingProgression.NodeState.OWNED, false, true)
	assert_bool(chosen["selected"]).is_true()
	assert_float(chosen["radius"]).is_equal(plain["radius"])


func test_branch_colours_come_from_the_existing_palette() -> void:
	assert_object(RootsStyle.branch_colour("amber")).is_equal(Palette.SB_CANDLELIGHT)
	assert_object(RootsStyle.branch_colour("gold")).is_equal(Palette.SB_GOLD)
	assert_object(RootsStyle.branch_colour("green")).is_equal(Palette.SB_OLIVE)
	assert_object(RootsStyle.branch_colour("mauve")).is_equal(Palette.SB_ROSE)


# --- Review of the first screenshots (user, 2026-11-27) ---

func test_a_locked_node_keeps_a_clear_tint_of_its_branch_colour() -> void:
	var look: Dictionary = _look(CraftingProgression.NodeState.LOCKED)
	var fill: Color = look["fill"]
	# at least 40% of the way from charcoal to the branch colour, so branches read on a first visit
	var share: float = (fill.r - Palette.SB_CHARCOAL.r) / (COLOUR.r - Palette.SB_CHARCOAL.r)
	assert_float(share).is_greater_equal(0.4)


func test_owned_has_a_small_steady_halo_and_a_thick_ring_available_a_wide_pulsing_one() -> void:
	var owned: Dictionary = _look(CraftingProgression.NodeState.OWNED)
	var ready: Dictionary = _look(CraftingProgression.NodeState.AVAILABLE, true)
	assert_float(owned["halo"]).is_less(ready["halo"])
	assert_float(owned["ring_width"]).is_greater_equal(4.0)

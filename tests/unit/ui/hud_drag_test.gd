## Dragging from the slot bar (sprint 001, phase C, 2026-11-26): a drag always carries one unit of
## one item, never a stack; an empty slot gives nothing to drag; a drop counts as "on the ghost"
## only near the ghost and only for an inventory unit.
extends GdUnitTestSuite

const RADIUS: float = 72.0

var _entries: Array = [["thread", 5, "Thread", "old_thread"], ["elixir_energy", 1, "Elixir", "elixir_energy"]]


func test_a_drag_from_a_stack_carries_one_unit_of_that_item() -> void:
	var data: Variant = GameHud.unit_drag_data(_entries, 0)
	assert_dict(data).is_equal({"type": GameHud.DRAG_UNIT, "item": "old_thread", "from_slot": 0})
	assert_bool((data as Dictionary).has("count")).is_false()


func test_an_empty_or_missing_slot_gives_nothing_to_drag() -> void:
	assert_object(GameHud.unit_drag_data(_entries, 2)).is_null()
	assert_object(GameHud.unit_drag_data(_entries, -1)).is_null()
	assert_object(GameHud.unit_drag_data([["dust", 0, "Dust", "dust"]], 0)).is_null()


func test_a_unit_let_go_near_the_ghost_is_a_drop_on_it() -> void:
	var data: Variant = GameHud.unit_drag_data(_entries, 1)
	var ghost := Vector2(600, 400)
	assert_bool(GameHud.accepts_ghost_drop(data, ghost + Vector2(30, -40), ghost, RADIUS)).is_true()
	assert_bool(GameHud.accepts_ghost_drop(data, ghost + Vector2(RADIUS + 1.0, 0), ghost, RADIUS)).is_false()


func test_anything_but_an_inventory_unit_is_not_accepted_on_the_ghost() -> void:
	var ghost := Vector2(600, 400)
	assert_bool(GameHud.accepts_ghost_drop({"type": "something_else", "item": "x"}, ghost, ghost, RADIUS)).is_false()
	assert_bool(GameHud.accepts_ghost_drop("old_thread", ghost, ghost, RADIUS)).is_false()
	assert_bool(GameHud.accepts_ghost_drop(null, ghost, ghost, RADIUS)).is_false()

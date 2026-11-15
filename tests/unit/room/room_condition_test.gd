## How run-down a room is, and what that does to walking (user decision 2026-11-15): people
## slow down in dark, cold, dirty rooms with broken things; the ghost slows down in rooms in
## perfect order.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")
const PEOPLE_SLOWEST: float = 0.75
const GHOST_SLOWEST: float = 0.7


func _perfect(house: HouseState, room_id: String) -> void:
	house.set_room_cleanliness(room_id, RoomState.Cleanliness.CLEAN)
	house.rooms[room_id].light = RoomState.Light.BRIGHT
	house.rooms[room_id].temperature = RoomState.Temperature.COMFORTABLE


func test_a_room_in_perfect_order_scores_zero() -> void:
	var house: HouseState = Fx.house()
	_perfect(house, "dining")
	assert_float(RoomCondition.run_down(house, "dining")).is_equal(0.0)


func test_a_dark_cold_dirty_room_with_something_broken_scores_one() -> void:
	# Arrange
	var house: HouseState = Fx.house()
	house.set_room_cleanliness("kitchen", RoomState.Cleanliness.DIRTY)
	house.rooms["kitchen"].light = RoomState.Light.DARK
	house.rooms["kitchen"].temperature = RoomState.Temperature.COLD
	house.set_object_state("stove", &"broken")
	# Act / Assert
	assert_float(RoomCondition.run_down(house, "kitchen")).is_equal(1.0)


func test_each_problem_adds_a_part() -> void:
	# Arrange: perfect, then only dirty
	var house: HouseState = Fx.house()
	_perfect(house, "dining")
	house.set_room_cleanliness("dining", RoomState.Cleanliness.DIRTY)
	var dirty_only: float = RoomCondition.run_down(house, "dining")
	house.rooms["dining"].temperature = RoomState.Temperature.COLD
	var dirty_and_cold: float = RoomCondition.run_down(house, "dining")
	# Assert
	assert_float(dirty_only).is_greater(0.0)
	assert_float(dirty_and_cold).is_greater(dirty_only)
	assert_float(dirty_and_cold).is_less(1.0)


func test_people_walk_slower_and_the_ghost_faster_as_a_room_runs_down() -> void:
	assert_float(RoomCondition.people_factor(0.0, PEOPLE_SLOWEST)).is_equal(1.0)
	assert_float(RoomCondition.people_factor(1.0, PEOPLE_SLOWEST)).is_equal(PEOPLE_SLOWEST)
	assert_float(RoomCondition.ghost_factor(0.0, GHOST_SLOWEST)).is_equal(GHOST_SLOWEST)
	assert_float(RoomCondition.ghost_factor(1.0, GHOST_SLOWEST)).is_equal(1.0)
	assert_float(RoomCondition.people_factor(0.5, PEOPLE_SLOWEST)).is_between(PEOPLE_SLOWEST, 1.0)

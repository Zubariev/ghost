## The shipped house has the sprint 001 locations (phase B, 2026-11-25): a basement under the hall,
## an attic over the upper corridor, a back yard behind the library and a front yard in front of
## the hall; each reachable by the ghost, each with at least two searchable hiding spots, none
## entered by the family.
extends GdUnitTestSuite

const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
const NEW_AREAS: Array[String] = ["basement", "attic", "back_yard", "front_yard"]


func _house() -> HouseState:
	return HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))


func test_new_areas_sit_where_the_house_plan_puts_them() -> void:
	var house := _house()
	var hall: RoomState = house.rooms["hall"]
	assert_int(house.rooms["basement"].floor_level).is_equal(hall.floor_level - 1)
	assert_that(house.rooms["basement"].grid).is_equal(hall.grid)
	assert_int(house.rooms["attic"].floor_level).is_equal(house.rooms["upper_corridor"].floor_level + 1)
	assert_that(house.rooms["attic"].grid).is_equal(house.rooms["upper_corridor"].grid)
	assert_that(house.rooms["back_yard"].grid).is_equal(house.rooms["library"].grid + Vector2i(0, -1))
	assert_that(house.rooms["front_yard"].grid).is_equal(hall.grid + Vector2i(0, 1))
	assert_bool(house.rooms["back_yard"].outdoor and house.rooms["front_yard"].outdoor).is_true()


func test_the_ghost_reaches_every_new_area_from_the_hall() -> void:
	# Arrange
	var nav := GhostNavigator.new(_house())
	# Act / Assert: down to the basement and back
	nav.place("hall", Vector2(0.5, 0.5))
	assert_bool(nav.change_floor(-1)).is_true()
	assert_str(nav.room_id).is_equal("basement")
	assert_bool(nav.change_floor(1)).is_true()
	# up twice to the attic
	assert_bool(nav.change_floor(1)).is_true()
	assert_bool(nav.change_floor(1)).is_true()
	assert_str(nav.room_id).is_equal("attic")
	# out through the hall's open front into the front yard
	nav.place("hall", Vector2(0.5, 0.95))
	nav.move(Vector2(0.0, 0.3))
	assert_str(nav.room_id).is_equal("front_yard")
	# through the library's back wall into the back yard
	nav.place("library", Vector2(0.5, 0.05))
	nav.move(Vector2(0.0, -0.3))
	assert_str(nav.room_id).is_equal("back_yard")


func test_the_family_never_enters_the_new_areas() -> void:
	var data: Dictionary = JsonData.read(HouseSim.HOUSE_PATH)
	var house := _house()
	for id: String in NEW_AREAS:
		assert_bool(house.rooms[id].family_access).override_failure_message(id + " open to the family").is_false()
		for door: Dictionary in data["doors"]:
			assert_bool(door["a"] == id or door["b"] == id).override_failure_message("door to " + id).is_false()


func test_every_new_area_has_two_searchable_hiding_spots() -> void:
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	var spots: Dictionary = JsonData.read(GhostLoot.LOOT_PATH)["spots"]
	for id: String in NEW_AREAS:
		var hides: int = 0
		for piece: Dictionary in rooms.get(id, []):
			if piece.has("hide_id") and spots.has(String(piece["hide_id"])):
				hides += 1
		assert_int(hides).override_failure_message(id + " hiding spots").is_greater_equal(2)

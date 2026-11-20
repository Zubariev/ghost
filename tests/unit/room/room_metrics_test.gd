## Distances in metres on rooms of real sizes (user decision 2026-11-20): the layout converts
## between floor units and metres per room; sight, sight blockers and walking footprints are
## measured in metres, so the same reach covers more of a small room than of a big one.
extends GdUnitTestSuite


func _house() -> HouseState:
	return HouseState.from_dict({"rooms": [
		{"id": "small", "size_m": [4.0, 2.0]},
		{"id": "big", "size_m": [10.0, 8.0]},
		{"id": "plain"},
	]})


func _layout() -> RoomLayout:
	return RoomLayout.new({
		"small": [{"kind": "wardrobe", "u": 0.5, "v": 0.5, "blocks_sight": [1.0, 0.5]}],
		"big": [{"kind": "wardrobe", "u": 0.5, "v": 0.5}],
	}, _house())


func test_the_layout_measures_each_room_in_its_own_metres() -> void:
	var layout: RoomLayout = _layout()
	# Assert: across the small room is 4 m, down it 2 m; a room without a size measures floor units
	assert_vector(layout.size("small")).is_equal(Vector2(4.0, 2.0))
	assert_float(layout.distance("small", Vector2(0, 0), Vector2(1, 0))).is_equal_approx(4.0, 0.0001)
	assert_float(layout.distance("small", Vector2(0, 0), Vector2(0, 1))).is_equal_approx(2.0, 0.0001)
	assert_float(layout.distance("plain", Vector2(0, 0), Vector2(1, 0))).is_equal_approx(1.0, 0.0001)
	assert_vector(layout.to_uv("big", Vector2(5.0, 2.0))).is_equal(Vector2(0.5, 0.25))


func test_a_sight_blocker_is_its_size_in_metres() -> void:
	# A wardrobe blocking 2 m × 1 m in a 4 × 2 m room covers half its width and half its depth
	var rect: Rect2 = _layout().occluders("small")[0]
	assert_vector(rect.size).is_equal_approx(Vector2(0.5, 0.5), Vector2(0.0001, 0.0001))


func test_the_same_sight_range_reaches_across_a_small_room_but_not_a_big_one() -> void:
	# Arrange: someone at the left wall looking right; the ghost at the right wall; seen up to 5 m
	var cfg: Dictionary = {"peripheral_angle_deg": 120, "peripheral_range": 5.0, "deep_angle_deg": 40, "deep_range": 3.0}
	var none: Array[Rect2] = []
	var from := Vector2(0.05, 0.5)
	var ghost := Vector2(0.95, 0.5)
	# Act
	var in_small: RoomLayout.Zone = RoomLayout.sight_zone(from, Vector2.RIGHT, ghost, cfg, none, Vector2(4.0, 2.0))
	var in_big: RoomLayout.Zone = RoomLayout.sight_zone(from, Vector2.RIGHT, ghost, cfg, none, Vector2(10.0, 8.0))
	# Assert: 3.6 m away in the small room, past the 3 m deep zone but inside 5 m; 9 m away in the big one
	assert_int(in_small).is_equal(RoomLayout.Zone.PERIPHERAL)
	assert_int(in_big).is_equal(RoomLayout.Zone.NONE)


func test_a_cone_angle_is_measured_in_metres_not_floor_units() -> void:
	# In a room 10 m wide and 1 m deep, a point 0.5 across and 0.5 down from someone looking right
	# is 5 m right and 0.5 m down: about 6 degrees off, inside a 40-degree deep cone.
	var cfg: Dictionary = {"peripheral_angle_deg": 120, "peripheral_range": 10.0, "deep_angle_deg": 40, "deep_range": 10.0}
	var none: Array[Rect2] = []
	var zone: RoomLayout.Zone = RoomLayout.sight_zone(Vector2(0.1, 0.2), Vector2.RIGHT, Vector2(0.6, 0.7), cfg, none, Vector2(10.0, 1.0))
	assert_int(zone).is_equal(RoomLayout.Zone.DEEP)


func test_walking_footprints_and_grid_follow_the_room_size() -> void:
	# Arrange: a wardrobe 1 m × 0.5 m half size, no clearance, 0.5 m grid cells
	var layout: RoomLayout = _layout()
	var paths := RoomPaths.new(layout, {"cell_m": 0.5, "clearance": 0.0, "footprints": {"wardrobe": [1.0, 0.5]}})
	# Act
	var small: Rect2 = paths.blocked("small")[0]
	var big: Rect2 = paths.blocked("big")[0]
	# Assert: 2 m × 1 m is half the small room and a fifth by an eighth of the big one
	assert_vector(small.size).is_equal_approx(Vector2(0.5, 0.5), Vector2(0.0001, 0.0001))
	assert_vector(big.size).is_equal_approx(Vector2(0.2, 0.125), Vector2(0.0001, 0.0001))
	assert_vector(paths._cells_of("small")).is_equal(Vector2i(8, 4))
	assert_vector(paths._cells_of("big")).is_equal(Vector2i(20, 16))


func test_a_family_member_without_an_object_goes_to_their_seat_in_metres() -> void:
	# Arrange: the small room (4 × 2 m) seats father at 1 m across, 0.5 m deep; nobody else
	var layout := RoomLayout.new({"small": []}, _house(), {"small": [[1.0, 0.5]]})
	# Act / Assert: father's seat in floor units; mother (no seat) falls back to the row of slots
	assert_vector(layout.slot("small", 0)).is_equal(Vector2(0.25, 0.25))
	assert_vector(layout.slot("small", 1)).is_equal(Vector2(0.31, 0.70))
	assert_vector(layout.slot("big", 0)).is_equal(Vector2(0.18, 0.62))


func test_people_take_their_own_place_at_an_object_in_metres() -> void:
	# Arrange: around a "table" object in the small room (4 × 2 m), father's place 1 m across, 1 m deep
	var layout := RoomLayout.new({"small": [{"kind": "dining_table", "u": 0.5, "v": 0.5, "object": "table"}]}, _house(),
		{}, {"table": [[1.0, 1.0]]})
	var house: HouseState = _house()
	var schedule := Schedule.from_dict({"npc_id": "father", "start_room": "small", "activities": [
		{"id": "eat", "start": "00:00", "end": "23:59", "room": "small", "target": "table", "animation": "eat"}]})
	var routine := NpcRoutine.new(schedule, house, 15)
	routine.current = schedule.activities[0]
	# Act / Assert: father (0) at his place; mother (1, no place) in front of the table
	assert_vector(layout.spot(routine, 0, "small")).is_equal(Vector2(0.25, 0.5))
	assert_vector(layout.spot(routine, 1, "small")).is_equal(Vector2(0.41, 0.62))

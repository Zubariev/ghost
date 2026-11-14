## The shipped house and family walk properly (stage 5c, roadmap step 1; reads assets/data/):
## every door and stairway can be walked to from every other one without crossing furniture,
## and through a whole simulated day nobody jumps inside a room, rooms change only at a
## matching door pair, and the simulation's timings are the same as with nobody drawn.
extends GdUnitTestSuite

const MOVEMENT_PATH: String = "res://assets/data/house/movement.json"
const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
## Boundary value: the largest step in one frame that is still walking, not a jump.
const MAX_FRAME_STEP: float = 0.15
## Boundary value: how close to a door point a crossing must be.
const DOOR_TOLERANCE: float = 0.001
const FRAME_SECONDS: float = 0.05


func _layout(house: HouseState) -> RoomLayout:
	return RoomLayout.new(JsonData.read(FURNITURE_PATH).get("rooms", {}), house)


## Door points (and stairs) of [param room_id] toward each neighbour.
func _doors(layout: RoomLayout, house: HouseState, room_id: String) -> Array[Vector2]:
	var doors: Array[Vector2] = []
	for other: String in house.rooms:
		if other != room_id and house.walk_minutes(room_id, other) > 0:
			doors.append(layout.door_uv(room_id, other))
	return doors


func test_every_door_reaches_every_other_door_round_the_furniture() -> void:
	# Arrange
	var house := HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))
	var layout: RoomLayout = _layout(house)
	var paths := RoomPaths.new(layout, JsonData.read(MOVEMENT_PATH))
	for room_id: String in house.rooms:
		var doors: Array[Vector2] = _doors(layout, house, room_id)
		for a: Vector2 in doors:
			for b: Vector2 in doors:
				if a == b:
					continue
				# Act
				var points: PackedVector2Array = paths.find(room_id, a, b)
				# Assert: every step is clear of furniture, except a step from or to a point
				# that is itself not free floor (the stairs), which must reach free floor
				for i: int in range(points.size() - 1):
					var from_free: bool = paths.is_free(room_id, points[i])
					var to_free: bool = paths.is_free(room_id, points[i + 1])
					if from_free and to_free:
						assert_bool(paths.is_clear(room_id, points[i], points[i + 1])).override_failure_message(
							"%s: %s → %s crosses furniture at %s" % [room_id, a, b, points[i]]).is_true()
					else:
						assert_bool(from_free or to_free).override_failure_message(
							"%s: %s → %s steps between two blocked points" % [room_id, a, b]).is_true()
				assert_float(RoomPaths.length(points)).override_failure_message(
					"%s: %s → %s detours %.2f" % [room_id, a, b, RoomPaths.length(points)]).is_less(3.0)


func test_every_door_has_free_floor_just_inside_it() -> void:
	# Arrange
	var house := HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))
	var layout: RoomLayout = _layout(house)
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var paths := RoomPaths.new(layout, config)
	var motion := FamilyMotion.new([], house, layout, paths, config)
	for room_id: String in house.rooms:
		for other: String in house.rooms:
			if other == room_id or house.walk_minutes(room_id, other) <= 0:
				continue
			# Act
			var entry: Vector2 = motion.entry_uv(room_id, other)
			# Assert: free, and close to its door
			assert_bool(paths.is_free(room_id, entry)).override_failure_message("%s from %s: %s" % [room_id, other, entry]).is_true()
			assert_float(entry.distance_to(layout.door_uv(room_id, other))).is_less(0.3)


func test_a_whole_day_has_no_jumps_and_rooms_change_only_at_doors() -> void:
	# Arrange
	var sim: HouseSim = HouseSim.from_data_files()
	sim.start()
	var layout: RoomLayout = _layout(sim.house)
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var motion := FamilyMotion.new(sim.routines, sim.house, layout, RoomPaths.new(layout, config), config)
	var crossings: Array = []
	motion.door_crossed.connect(func(i: int, from_room: String, to_room: String, exit_uv: Vector2, entry_uv: Vector2) -> void:
		crossings.append([i, from_room, to_room, exit_uv, entry_uv]))
	var last: Array = []
	for i: int in sim.routines.size():
		last.append([motion.room_of(i), Vector2(motion.person(i, motion.room_of(i))["uv"])])
	var jumps: Array[String] = []
	var frames: int = int(float(GameClock.MINUTES_PER_DAY) / sim.clock.minutes_for(FRAME_SECONDS))
	# Act
	for frame: int in frames:
		var minutes: float = sim.clock.minutes_for(FRAME_SECONDS)
		sim.advance(FRAME_SECONDS)
		motion.update(minutes)
		for i: int in sim.routines.size():
			var room: String = motion.room_of(i)
			var uv: Vector2 = motion.person(i, room)["uv"]
			if room == String(last[i][0]) and uv.distance_to(last[i][1]) > MAX_FRAME_STEP and jumps.size() < 10:
				jumps.append("%s %s jumped %.3f in %s" % [GameClock.format_time(sim.clock.minute_of_day()),
					sim.routines[i].schedule.npc_id, uv.distance_to(last[i][1]), room])
			last[i] = [room, uv]
	# Assert
	assert_array(jumps).is_empty()
	assert_int(crossings.size()).is_greater(20)
	for crossing: Array in crossings:
		var from_room: String = crossing[1]
		var to_room: String = crossing[2]
		assert_int(sim.house.walk_minutes(from_room, to_room)).override_failure_message("%s → %s has no door" % [from_room, to_room]).is_greater(0)
		assert_float(Vector2(crossing[3]).distance_to(layout.door_uv(from_room, to_room))).is_less(DOOR_TOLERANCE)
		assert_float(Vector2(crossing[4]).distance_to(layout.door_uv(to_room, from_room))).is_less(DOOR_TOLERANCE)


func test_drawing_the_walks_leaves_the_day_unchanged() -> void:
	# Arrange: two identical simulations; only one has the family walking on screen
	var drawn: HouseSim = HouseSim.from_data_files()
	var bare: HouseSim = HouseSim.from_data_files()
	drawn.start()
	bare.start()
	var layout: RoomLayout = _layout(drawn.house)
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var motion := FamilyMotion.new(drawn.routines, drawn.house, layout, RoomPaths.new(layout, config), config)
	var drawn_log: Array[String] = []
	var bare_log: Array[String] = []
	for i: int in drawn.routines.size():
		var who: String = drawn.routines[i].schedule.npc_id
		drawn.routines[i].room_entered.connect(func(room: String) -> void:
			drawn_log.append("%d %s %s" % [drawn.clock.total_minutes, who, room]))
		bare.routines[i].room_entered.connect(func(room: String) -> void:
			bare_log.append("%d %s %s" % [bare.clock.total_minutes, who, room]))
	# Act: one day
	for frame: int in int(float(GameClock.MINUTES_PER_DAY) / drawn.clock.minutes_for(FRAME_SECONDS)):
		var minutes: float = drawn.clock.minutes_for(FRAME_SECONDS)
		drawn.advance(FRAME_SECONDS)
		bare.advance(FRAME_SECONDS)
		motion.update(minutes)
	# Assert
	assert_array(drawn_log).is_not_empty()
	assert_array(drawn_log).is_equal(bare_log)
	for i: int in drawn.routines.size():
		var who: String = drawn.routines[i].schedule.npc_id
		assert_int(drawn.morale.get_morale(who)).is_equal(bare.morale.get_morale(who))

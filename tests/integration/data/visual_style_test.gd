## The living room art test (Whimsical Gothic Storybook, 2026-11-15) leaves gameplay alone
## (reads assets/): decor pieces are drawn only, no family route ever crosses one, the
## walking obstacles are exactly those of the gameplay furniture, and the style config is
## consistent with the house.
extends GdUnitTestSuite

const FURNITURE_PATH: String = "res://assets/data/house/furniture.json"
const MOVEMENT_PATH: String = "res://assets/data/house/movement.json"
const ROOM: String = "living_room"
const GAMEPLAY_KEYS: Array[String] = ["object", "hide_id", "blocks_sight", "pickup"]


func _house() -> HouseState:
	return HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))


func _decor(rooms: Dictionary, room_id: String) -> Array[Dictionary]:
	var decor: Array[Dictionary] = []
	for piece: Dictionary in rooms.get(room_id, []):
		if bool(piece.get("decor", false)):
			decor.append(piece)
	return decor


func test_decor_pieces_carry_no_gameplay_keys() -> void:
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		for piece: Dictionary in _decor(rooms, room_id):
			for key: String in GAMEPLAY_KEYS:
				assert_bool(piece.has(key)).override_failure_message("%s decor %s has %s" % [room_id, piece["kind"], key]).is_false()


func test_the_living_room_has_the_art_test_props() -> void:
	var kinds: Array[String] = []
	for piece: Dictionary in JsonData.read(FURNITURE_PATH)["rooms"][ROOM]:
		kinds.append(String(piece["kind"]))
	for kind: String in ["fireplace", "armchair", "sofa", "side_table", "tea_table", "rug", "bookshelf", "floor_lamp", "window", "painting", "wall_clock"]:
		assert_bool(kinds.has(kind)).override_failure_message("missing " + kind).is_true()
	assert_int(kinds.count("armchair")).is_equal(2)


func test_walking_obstacles_are_only_the_gameplay_furniture() -> void:
	# Arrange: the same room with and without its decor
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	var without: Dictionary = rooms.duplicate(true)
	var kept: Array = []
	for piece: Dictionary in without[ROOM]:
		if not bool(piece.get("decor", false)):
			kept.append(piece)
	without[ROOM] = kept
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var house: HouseState = _house()
	# Act
	var with_decor: Array[Rect2] = RoomPaths.new(RoomLayout.new(rooms, house), config).blocked(ROOM)
	var gameplay_only: Array[Rect2] = RoomPaths.new(RoomLayout.new(without, house), config).blocked(ROOM)
	# Assert
	assert_array(with_decor).is_equal(gameplay_only)


func test_no_family_route_in_the_living_room_crosses_decor() -> void:
	# Arrange: every place someone can start or stop in the room — doors, the points just
	# inside them, every object's work spot and every free-standing slot.
	var house: HouseState = _house()
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	var layout := RoomLayout.new(rooms, house)
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var paths := RoomPaths.new(layout, config)
	var motion := FamilyMotion.new([], house, layout, paths, config)
	var places: Array[Vector2] = []
	for other: String in house.rooms:
		if other != ROOM and house.walk_minutes(ROOM, other) > 0:
			places.append(layout.door_uv(ROOM, other))
			places.append(motion.entry_uv(ROOM, other))
	for piece: Dictionary in rooms[ROOM]:
		if piece.has("object"):
			var at := Vector2(float(piece["u"]), float(piece["v"]))
			for index: int in 6:
				var spread: float = (float(index) - 2.5) * 0.06
				places.append(Vector2(clampf(at.x + spread, 0.08, 0.92), clampf(at.y + 0.12, 0.1, 0.95)))
	for index: int in 6:
		places.append(Vector2(0.18 + 0.13 * float(index), 0.62 + 0.08 * float(index % 2)))
	var footprints: Dictionary = config["footprints"]
	var clearance: float = float(config["clearance"])
	var decor_rects: Array[Rect2] = []
	for piece: Dictionary in _decor(rooms, ROOM):
		if footprints.has(String(piece["kind"])):
			var half: Array = footprints[String(piece["kind"])]
			var size := Vector2(float(half[0]), float(half[1])) + Vector2(clearance, clearance)
			decor_rects.append(Rect2(Vector2(float(piece["u"]), float(piece["v"])) - size, size * 2.0))
	assert_int(decor_rects.size()).is_greater(0)
	# Act / Assert
	for a: Vector2 in places:
		for b: Vector2 in places:
			var points: PackedVector2Array = paths.find(ROOM, a, b)
			for i: int in points.size() - 1:
				for rect: Rect2 in decor_rects:
					var crosses: bool = rect.has_point(points[i]) or rect.has_point(points[i + 1]) \
						or RoomPaths._segment_hits_rect(points[i], points[i + 1], rect)
					assert_bool(crosses).override_failure_message("route %s → %s crosses decor %s" % [a, b, rect]).is_false()


func test_storybook_rooms_exist_and_sprite_files_exist() -> void:
	var style: Dictionary = JsonData.read(PropVisuals.STYLE_PATH)
	var house: HouseState = _house()
	for room_id: String in style.get("storybook_rooms", []):
		assert_bool(house.rooms.has(room_id)).override_failure_message(room_id).is_true()
	var sprites: Dictionary = style.get("sprites", {})
	for key: String in sprites:
		var entry: Dictionary = sprites[key]
		var all: Array = [String(entry.get("sprite", ""))]
		all.append_array((entry.get("states", {}) as Dictionary).values())
		for path: String in all:
			if not path.is_empty():
				assert_bool(ResourceLoader.exists(path)).override_failure_message("missing sprite " + path).is_true()


func test_every_placeholder_shape_can_be_filled_in_every_state() -> void:
	# Regression: the broken computer's crack crossed itself ("triangulation failed"); it
	# showed once the house started run-down with the computer broken (2026-11-15).
	var house: HouseState = _house()
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		for piece: Dictionary in rooms[room_id]:
			if bool(piece.get("decor", false)):
				continue
			var kind: String = String(piece["kind"])
			var states: Array = [""]
			var object_id: String = String(piece.get("object", ""))
			if not object_id.is_empty():
				states = Array(house.objects[object_id].allowed_states)
			if piece.has("pickup"):
				states = ["", "taken"]
			for state: Variant in states:
				for day: bool in [true, false]:
					var parts: Array = FurnitureArt._parts(kind, Vector2(float(piece["u"]), float(piece["v"])), StringName(state), day)
					for i: int in parts.size():
						var poly: PackedVector2Array = FurnitureArt._place(parts[i][0], Vector2(600, 400), 0.9, kind == "window")
						assert_bool(Geometry2D.triangulate_polygon(poly).is_empty()).override_failure_message(
							"%s %s (%s) part %d cannot be filled" % [room_id, kind, state, i]).is_false()


func test_every_storybook_shape_can_be_filled_in_every_state() -> void:
	# Guard for the storybook drawings (art Phase 1, 2026-11-15): stones, arches and the
	# perspective rug must stay valid polygons in every state, day and night.
	var house: HouseState = _house()
	var style: Dictionary = JsonData.read(PropVisuals.STYLE_PATH)
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in style.get("storybook_rooms", []):
		for piece: Dictionary in rooms[room_id]:
			var kind: String = String(piece["kind"])
			var uv := Vector2(float(piece["u"]), float(piece["v"]))
			var states: Array = [""]
			var object_id: String = String(piece.get("object", ""))
			if not object_id.is_empty():
				states = Array(house.objects[object_id].allowed_states)
			if kind == "fireplace":
				states = ["burning", "out"]
			for state: Variant in states:
				for day: bool in [true, false]:
					var parts: Array = StorybookArt._parts(kind, String(piece.get("variant", "")), StringName(state), day, 0.0, Ink.Tier.FURNITURE, uv)
					assert_bool(parts.is_empty()).override_failure_message("%s %s has no drawing" % [room_id, kind]).is_false()
					for i: int in parts.size():
						var poly: PackedVector2Array = StorybookArt._place(parts[i][0], Vector2(600, 400), 0.9)
						assert_bool(Geometry2D.triangulate_polygon(poly).is_empty()).override_failure_message(
							"%s %s (%s, day %s) part %d cannot be filled" % [room_id, kind, state, day, i]).is_false()


func test_every_room_has_at_least_two_hiding_spots() -> void:
	# User decision 2026-11-15: with one spot, a searcher checks it first and a glimpsed
	# ghost that hid there was always caught.
	var rooms: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
	for room_id: String in rooms:
		var spots: int = 0
		for piece: Dictionary in rooms[room_id]:
			if piece.has("hide_id"):
				spots += 1
		assert_int(spots).override_failure_message("%s has %d hiding spot(s)" % [room_id, spots]).is_greater_equal(2)

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


func test_no_family_route_in_any_room_crosses_decor() -> void:
	# Every room (Phase B, 2026-11-20: all re-laid in metres with decor): every place someone can
	# start or stop — doors, the points just inside them, every object's place (object_seats or
	# in front of it) and every seat — joined by family routes that never cross a decor piece.
	var house: HouseState = _house()
	var furniture: Dictionary = JsonData.read(FURNITURE_PATH)
	var rooms: Dictionary = furniture["rooms"]
	var object_seats: Dictionary = furniture.get("object_seats", {})
	var layout := RoomLayout.new(rooms, house, furniture.get("seats", {}), object_seats)
	var config: Dictionary = JsonData.read(MOVEMENT_PATH)
	var paths := RoomPaths.new(layout, config)
	var motion := FamilyMotion.new([], house, layout, paths, config)
	var footprints: Dictionary = config["footprints"]
	var clearance: float = float(config["clearance"])
	var checked: int = 0
	for room_id: String in rooms:
		var decor_rects: Array[Rect2] = []
		for piece: Dictionary in _decor(rooms, room_id):
			if footprints.has(String(piece["kind"])) and not StorybookArt.is_wall(String(piece["kind"])):
				var half: Array = footprints[String(piece["kind"])]
				var size: Vector2 = layout.to_uv(room_id, Vector2(float(half[0]), float(half[1])) + Vector2(clearance, clearance))
				decor_rects.append(Rect2(Vector2(float(piece["u"]), float(piece["v"])) - size, size * 2.0))
		if decor_rects.is_empty():
			continue
		var places: Array[Vector2] = []
		for other: String in house.rooms:
			if other != room_id and house.walk_minutes(room_id, other) > 0:
				places.append(layout.door_uv(room_id, other))
				places.append(motion.entry_uv(room_id, other))
		for piece: Dictionary in rooms[room_id]:
			if piece.has("object"):
				var at := Vector2(float(piece["u"]), float(piece["v"]))
				var seats: Array = object_seats.get(String(piece["object"]), [])
				for index: int in 6:
					if index < seats.size():
						places.append(layout.to_uv(room_id, Vector2(float(seats[index][0]), float(seats[index][1]))))
					else:
						var spread: float = (float(index) - 2.5) * 0.06
						places.append(Vector2(clampf(at.x + spread, 0.08, 0.92), clampf(at.y + 0.12, 0.1, 0.95)))
		for index: int in 6:
			places.append(layout.slot(room_id, index))
		# Act / Assert
		for a: Vector2 in places:
			for b: Vector2 in places:
				var points: PackedVector2Array = paths.find(room_id, a, b)
				for i: int in points.size() - 1:
					for rect: Rect2 in decor_rects:
						var crosses: bool = rect.has_point(points[i]) or rect.has_point(points[i + 1]) \
							or RoomPaths._segment_hits_rect(points[i], points[i + 1], rect)
						assert_bool(crosses).override_failure_message("%s: route %s → %s crosses decor %s" % [room_id, a, b, rect]).is_false()
		checked += 1
	assert_int(checked).is_greater_equal(8)


func test_nothing_stands_in_front_of_a_door() -> void:
	# User request 2026-11-20 ("don't forget about doors when adding decor"): in every room the
	# 1.2 m wide, 1 m deep zone inside each side, back or front door holds no piece's footprint.
	var house: HouseState = _house()
	var furniture: Dictionary = JsonData.read(FURNITURE_PATH)
	var rooms: Dictionary = furniture["rooms"]
	var layout := RoomLayout.new(rooms, house)
	var footprints: Dictionary = JsonData.read(MOVEMENT_PATH)["footprints"]
	var zones: int = 0
	for room_id: String in rooms:
		var size: Vector2 = layout.size(room_id)
		for other: String in house.rooms:
			if other == room_id or house.walk_minutes(room_id, other) <= 0 or house.rooms[other].floor_level != house.rooms[room_id].floor_level:
				continue   # stairs are a door themselves
			var door: Vector2 = layout.door_uv(room_id, other) * size   # metres
			var zone: Rect2
			if door.x <= 0.001:
				zone = Rect2(0.0, door.y - 0.6, 1.0, 1.2)
			elif door.x >= size.x - 0.001:
				zone = Rect2(size.x - 1.0, door.y - 0.6, 1.0, 1.2)
			elif door.y <= 0.001:
				zone = Rect2(door.x - 0.6, 0.0, 1.2, 1.0)
			else:
				zone = Rect2(door.x - 0.6, size.y - 1.0, 1.2, 1.0)
			zones += 1
			for piece: Dictionary in rooms[room_id]:
				var kind: String = String(piece["kind"])
				if not footprints.has(kind) or StorybookArt.is_wall(kind):
					continue
				var half := Vector2(float(footprints[kind][0]), float(footprints[kind][1]))
				var rect := Rect2(Vector2(float(piece["u"]), float(piece["v"])) * size - half, half * 2.0)
				assert_bool(rect.intersects(zone)).override_failure_message("%s: %s stands in front of the door to %s" % [room_id, kind, other]).is_false()
	assert_int(zones).is_greater_equal(14)


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


func test_wall_portraits_hang_clear_of_doors_and_above_the_wainscot() -> void:
	# Art Phase 1 (2026-11-15): side-wall portraits are art config, not furniture; they must
	# stay on the wall, above the wainscot and away from the side doors (v 0.39-0.61).
	var style: Dictionary = JsonData.read(PropVisuals.STYLE_PATH)
	var portraits: Dictionary = style.get("wall_portraits", {})
	assert_bool(portraits.is_empty()).is_false()
	for room_id: String in portraits:
		assert_bool((style.get("storybook_rooms", []) as Array).has(room_id)).override_failure_message(room_id + " is not a storybook room").is_true()
		for entry: Dictionary in portraits[room_id]:
			var v: Array = entry["v"]
			var h: Array = entry["h"]
			assert_bool(["left", "right"].has(String(entry["wall"]))).is_true()
			assert_bool(float(v[0]) >= 0.04 and float(v[1]) <= 0.96 and float(v[0]) < float(v[1])).override_failure_message("%s portrait off the wall" % room_id).is_true()
			assert_bool(float(v[1]) <= 0.36 or float(v[0]) >= 0.64).override_failure_message("%s portrait over a side door" % room_id).is_true()
			assert_bool(float(h[0]) >= StorybookShell.WAINSCOT_HEIGHT and float(h[1]) <= 0.95 and float(h[0]) < float(h[1])).override_failure_message("%s portrait height" % room_id).is_true()
			for part: PackedVector2Array in StorybookShell.portrait_parts(String(entry["wall"]) == "left", Vector2(float(v[0]), float(v[1])), Vector2(float(h[0]), float(h[1])), String(entry.get("variant", ""))).map(func(p: Array) -> PackedVector2Array: return p[0]):
				assert_bool(Geometry2D.triangulate_polygon(part).is_empty()).override_failure_message("%s portrait part cannot be filled" % room_id).is_false()


func test_room_wear_config_is_complete_and_names_real_furniture() -> void:
	# Art Phase 2 (2026-11-15): every wear number is configured; cobwebs sit only on furniture
	# kinds the house has.
	var wear: Dictionary = JsonData.read(PropVisuals.STYLE_PATH).get("wear", {})
	for key: String in ["fade_per_second", "dull_alpha", "dust_patches", "dust_alpha", "door_clear", "floor_margin",
			"web_alpha", "web_radius", "web_tops", "motes", "mote_alpha", "polish_alpha", "breath_period", "breath_alpha",
			"cold_corner_alpha", "ember_seconds"]:
		assert_bool(wear.has(key)).override_failure_message("wear." + key + " missing").is_true()
	var kinds: Dictionary = {}
	for pieces: Array in (JsonData.read(FURNITURE_PATH)["rooms"] as Dictionary).values():
		for piece: Dictionary in pieces:
			kinds[String(piece["kind"])] = true
	for kind: String in wear.get("web_tops", {}):
		assert_bool(kinds.has(kind)).override_failure_message("web_tops: no furniture kind " + kind).is_true()


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


func test_every_shipped_sprite_loads_and_wall_sprites_fit_the_back_wall() -> void:
	# Art Phase 3 (2026-11-15): the painted fireplace. Every configured image must load (else the
	# room silently falls back to code); a wall piece must not rise above the ceiling line, and
	# its code-drawn animation point must lie on the image.
	var style: Dictionary = JsonData.read(PropVisuals.STYLE_PATH)
	var visuals := PropVisuals.new(style)
	for key: String in style.get("sprites", {}):
		# Room-scoped keys "room/kind[:variant]" (2026-11-15) name a real room holding that kind.
		var room: String = key.get_slice("/", 0) if key.contains("/") else ""
		var bare: String = key.get_slice("/", 1) if key.contains("/") else key
		var kind: String = bare.get_slice(":", 0)
		var variant: String = bare.get_slice(":", 1) if bare.contains(":") else ""
		if not room.is_empty():
			var furniture: Dictionary = JsonData.read(FURNITURE_PATH)["rooms"]
			assert_bool(furniture.has(room)).override_failure_message(key + ": no room " + room).is_true()
			var kinds: Array = (furniture.get(room, []) as Array).map(func(p: Dictionary) -> String: return String(p["kind"]))
			assert_bool(kinds.has(kind)).override_failure_message(key + ": no " + kind + " in " + room).is_true()
		var entry: Dictionary = style["sprites"][key]
		var paths: Array = [String(entry.get("sprite", ""))] + (entry.get("states", {}) as Dictionary).values()
		for layer: Dictionary in ((entry.get("effects", {}) as Dictionary).get("states", {}) as Dictionary).values():
			paths.append(String(layer.get("sprite", "")))
		for path: String in paths:
			if not path.is_empty():
				assert_bool(ResourceLoader.exists(path)).override_failure_message("missing sprite " + path).is_true()
		var tex: Texture2D = visuals.texture_for(kind, variant, &"", room)
		assert_object(tex).override_failure_message(key + " does not load").is_not_null()
		var size: Vector2 = tex.get_size() * visuals.scale(kind, variant, room)
		var rect := Rect2(-visuals.anchor(kind, variant, room) * size, size)
		if StorybookArt.is_wall(kind):
			assert_float(-rect.position.y).override_failure_message(key + " rises above the ceiling").is_less_equal(RoomGeometry.BACK_WALL_HEIGHT + 2.0)
		if entry.has("effects"):
			assert_bool(rect.has_point(visuals.effects_offset(kind, variant, room))).override_failure_message(key + " effects point off the image").is_true()
		# Moving parts drawn by the code (2026-11-20) sit on the image too
		for name: String in visuals.effect_points(kind, variant, room):
			assert_bool(rect.grow(1.0).has_point(visuals.effect_points(kind, variant, room)[name])).override_failure_message(key + " point " + name + " off the image").is_true()
		# A window's glass mask (2026-11-20) matches its state's image in size
		for state: String in (entry.get("glass", {}) as Dictionary):
			var mask: Texture2D = visuals.glass_mask(kind, variant, StringName(state), room)
			assert_object(mask).override_failure_message(key + " glass mask " + state + " does not load").is_not_null()
			if mask != null:
				assert_vector(mask.get_size()).override_failure_message(key + " glass mask size").is_equal(visuals.texture_for(kind, variant, StringName(state), room).get_size())


func test_every_room_has_painted_walls_and_floor_and_every_texture_loads() -> void:
	# Painted surfaces (user review 2026-11-20): a wall and a floor for every room, the rug and the
	# cobweb; every path in the config is a texture that loads.
	var surfaces: Dictionary = JsonData.read(PropVisuals.STYLE_PATH).get("surfaces", {})
	var rooms: Dictionary = surfaces.get("rooms", {})
	var paths: Array[String] = [String(surfaces.get("rug", "")), String(surfaces.get("web", ""))]
	for room_id: String in _house().rooms:
		assert_bool(rooms.has(room_id)).override_failure_message("no surfaces for " + room_id).is_true()
		var cfg: Dictionary = rooms.get(room_id, {})
		for key: String in ["wall", "floor", "wainscot"]:
			if cfg.has(key) or key != "wainscot":
				paths.append(String(cfg.get(key, "")))
	for path: String in paths:
		assert_bool(ResourceLoader.exists(path) and load(path) is Texture2D).override_failure_message("texture does not load: " + path).is_true()

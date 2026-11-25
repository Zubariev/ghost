## Painted cutout characters (character pipeline pilot, 2026-11-20): clips are sampled and eased,
## the rest pose rebuilds the painting in place, the animator's state table follows the game's own
## states, and the walk advances by the metres walked. Grandma's real rig data is checked too.
extends GdUnitTestSuite


func _rig() -> CharacterRig:
	return CharacterRig.new({
		"id": "test", "height_m": 1.6, "stride_m": 1.0,
		"views": {
			"front": {"foot": [50, 100], "px_per_m": 75.0, "parts": {
				"body": {"texture": "", "origin": [30, 20], "pivot": [50, 60], "parent": "", "z": 0},
				"head": {"texture": "", "origin": [40, 0], "pivot": [50, 20], "parent": "body", "z": 1}}},
			"side": {"foot": [50, 100], "px_per_m": 75.0, "parts": {
				"body": {"texture": "", "origin": [30, 20], "pivot": [60, 60], "parent": "", "z": 0}}},
		},
		"clips": {
			"idle_front": {"view": "front", "length": 2.0, "loop": true, "tracks": {"head": [[0, 0], [1, 10], [2, 0]]}},
			"walk_side": {"view": "side", "length": 1.0, "loop": true, "tracks": {"body": [[0, 0], [1, 4]]}},
			"walk_front": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"walk_back": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"anxious": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"fright": {"view": "front", "length": 1.0, "loop": false, "tracks": {"head": [[0, 0], [1, 6]]}},
			"cook": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"sit": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"sit_side": {"view": "side", "length": 1.0, "loop": true, "tracks": {}},
			"sit_back": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"dolls": {"view": "front", "length": 1.0, "loop": true, "tracks": {}},
			"tricycle": {"view": "side", "length": 1.0, "loop": true, "tracks": {}},
			"stride": {"view": "side", "length": 1.0, "loop": true, "ease": "linear", "tracks": {"body": [[0, 0], [1, 10]]}},
		},
	})


func test_a_clip_is_eased_between_keys_and_loops_or_holds() -> void:
	var rig: CharacterRig = _rig()
	assert_float(rig.sample("idle_front", 1.0)["head"][0]).is_equal_approx(10.0, 0.001)
	assert_float(rig.sample("idle_front", 0.5)["head"][0]).is_equal_approx(5.0, 0.001)    # smoothstep half way
	assert_float(rig.sample("idle_front", 0.25)["head"][0]).is_less(2.5)                 # eased in: slower at first
	assert_float(rig.sample("idle_front", 3.0)["head"][0]).is_equal_approx(10.0, 0.001)  # looped
	assert_float(rig.sample("fright", 5.0)["head"][0]).is_equal_approx(6.0, 0.001)       # held at the end
	assert_float(rig.sample("stride", 0.25)["body"][0]).is_equal_approx(2.5, 0.001)      # linear: constant speed


func test_the_rest_pose_puts_every_part_where_it_was_painted() -> void:
	# At room scale 1 a 75 px-per-metre rig draws 1:1: the head's pivot is 80 px above the foot
	var rig: CharacterRig = _rig()
	var head: Vector2 = rig.part_point("front", {}, "head", Vector2(300, 400), 1.0, false)
	assert_vector(head).is_equal_approx(Vector2(300, 320), Vector2(0.01, 0.01))
	# a child follows its parent: the body turned 90° about its pivot swings the head round
	var turned: Vector2 = rig.part_point("front", {"body": [90.0, 0.0, 0.0, 1.0]}, "head", Vector2(300, 400), 1.0, false)
	assert_vector(turned).is_equal_approx(Vector2(340, 360), Vector2(0.01, 0.01))


func test_the_animator_follows_the_games_states() -> void:
	var anim := CharacterAnimator.new(_rig(), 1.0)
	var size := Vector2(4, 4)
	assert_array(anim.choose({"pose": "walk", "facing": Vector2(1, 0), "room_size": size})).is_equal(["walk_side", false])
	assert_array(anim.choose({"pose": "walk", "facing": Vector2(-1, 0), "room_size": size})).is_equal(["walk_side", true])
	assert_array(anim.choose({"pose": "walk", "facing": Vector2(0, 1), "room_size": size})).is_equal(["walk_front", false])
	assert_array(anim.choose({"pose": "walk", "facing": Vector2(0, -1), "room_size": size})).is_equal(["walk_back", false])
	assert_array(anim.choose({"pose": "stand", "activity": "cook", "facing": Vector2(0, -1), "room_size": size})).is_equal(["cook", false])
	assert_array(anim.choose({"pose": "stand", "marker": "?", "room_size": size})).is_equal(["anxious", false])
	assert_array(anim.choose({"pose": "walk", "marker": "!", "room_size": size})).is_equal(["fright", false])
	assert_array(anim.choose({"pose": "sit", "room_size": size})).is_equal(["sit", false])
	# a seated activity with its own painted pose; the tricycle mirrored by its direction
	assert_array(anim.choose({"pose": "sit", "activity": "dolls", "room_size": size})).is_equal(["dolls", false])
	# a side-on activity faces the way its seat does (drawing at the easel to her left)
	assert_array(anim.choose({"pose": "sit", "activity": "tricycle", "seat_facing": Vector2(-1, 0), "room_size": size})).is_equal(["tricycle", true])
	assert_array(anim.choose({"pose": "tricycle", "activity": "tricycle", "facing": Vector2(1, 0), "room_size": size})).is_equal(["tricycle", false])
	assert_array(anim.choose({"pose": "tricycle", "activity": "tricycle", "facing": Vector2(-1, 0), "room_size": size})).is_equal(["tricycle", true])
	# seated with the seat facing away from the camera (a desk, the near side of the table)
	assert_array(anim.choose({"pose": "sit", "activity": "computer", "seat_facing": Vector2(0, -1), "room_size": size})).is_equal(["sit_back", false])
	# off to one side of the desk (up and to the left): still from behind, not the front pose
	assert_array(anim.choose({"pose": "sit", "activity": "computer", "seat_facing": Vector2(-0.64, -0.77), "room_size": size})).is_equal(["sit_back", false])
	# eating at a table end: turned by the seat, not by a glance; resting while glancing sideways: front
	assert_array(anim.choose({"pose": "sit", "activity": "eat", "facing": Vector2(0, 1), "seat_facing": Vector2(-1, 0), "room_size": size})).is_equal(["sit_side", true])
	assert_array(anim.choose({"pose": "sit", "activity": "eat", "facing": Vector2(-1, 0), "seat_facing": Vector2(1, 0), "room_size": size})).is_equal(["sit_side", false])
	assert_array(anim.choose({"pose": "sit", "activity": "rest", "facing": Vector2(1, 0), "seat_facing": Vector2(0, -1), "room_size": size})).is_equal(["sit", false])
	assert_array(anim.choose({"pose": "sit", "activity": "eat", "seat_facing": Vector2(0, 1), "room_size": size})).is_equal(["sit", false])
	# behind the table, off to one side (the table's centre is down and to the right): facing the camera
	assert_array(anim.choose({"pose": "sit", "activity": "eat", "seat_facing": Vector2(0.5, 0.55), "room_size": size})).is_equal(["sit", false])
	assert_array(anim.choose({"pose": "stand", "activity": "knit", "facing": Vector2(0, 1), "room_size": size})).is_equal(["idle_front", false])


func test_the_walk_advances_by_the_metres_walked() -> void:
	# Stride 1 m: walking 0.5 m (an eighth of a 4 m room) is half a cycle, however long it took
	var anim := CharacterAnimator.new(_rig(), 1.0)
	var size := Vector2(4, 4)
	anim.update(0.1, {"pose": "walk", "uv": Vector2(0.25, 0.5), "facing": Vector2(1, 0), "room_size": size})
	anim.update(3.0, {"pose": "walk", "uv": Vector2(0.375, 0.5), "facing": Vector2(1, 0), "room_size": size})
	assert_float(anim.current_pose()["body"][0]).is_equal_approx(2.0, 0.01)   # half way through 0 → 4


func test_the_tricycle_faces_the_way_it_rolls() -> void:
	# The game sways the tricycle back and forth with a fixed facing: the painting follows the motion
	var anim := CharacterAnimator.new(_rig(), 1.0)
	var size := Vector2(4, 4)
	anim.update(0.1, {"pose": "tricycle", "activity": "tricycle", "uv": Vector2(0.4, 0.5), "facing": Vector2(0, 1), "room_size": size})
	anim.update(0.1, {"pose": "tricycle", "activity": "tricycle", "uv": Vector2(0.45, 0.5), "facing": Vector2(0, 1), "room_size": size})
	var flip_riding_right: bool = anim.flip
	anim.update(0.1, {"pose": "tricycle", "activity": "tricycle", "uv": Vector2(0.42, 0.5), "facing": Vector2(0, 1), "room_size": size})
	# flip = facing left; the rig un-mirrors the left-painted tricycle, so riding right is not flipped
	assert_bool(flip_riding_right).is_false()
	assert_bool(anim.flip).is_true()


func test_grandmas_rig_is_complete() -> void:
	_check_rig("grandma", ["idle_front", "walk_side", "walk_front", "walk_back", "cook", "anxious", "fright", "sit", "sit_side", "slump"])


func test_fathers_rig_is_complete() -> void:
	_check_rig("father", ["idle_front", "idle_side", "idle_back", "walk_side", "walk_front", "walk_back", "repair", "tools", "anxious", "fright", "sit", "sit_side", "slump"])


func test_mothers_rig_is_complete() -> void:
	_check_rig("mother", ["idle_front", "idle_side", "idle_back", "walk_side", "walk_front", "walk_back", "clean", "anxious", "fright", "sit", "sit_side", "slump"])


func test_grandpas_rig_is_complete() -> void:
	_check_rig("grandpa", ["idle_front", "idle_side", "idle_back", "walk_side", "walk_front", "walk_back", "read", "anxious", "fright", "sit", "sit_side", "slump"])


func test_sons_rig_is_complete() -> void:
	_check_rig("son", ["idle_front", "idle_side", "idle_back", "walk_side", "walk_front", "walk_back", "read", "sit_back", "clean", "anxious", "fright", "slump"])


func test_daughters_rig_is_complete() -> void:
	_check_rig("daughter", ["idle_front", "idle_side", "idle_back", "walk_side", "walk_front", "walk_back", "dolls", "draw", "tricycle", "sit_back", "anxious", "fright", "slump"])


func _check_rig(npc_id: String, required: Array) -> void:
	var rig: CharacterRig = CharacterRig.load_for(npc_id)
	assert_object(rig).is_not_null()
	for view: String in rig.views:
		for part: String in rig.views[view]["parts"]:
			var path: String = String(rig.views[view]["parts"][part]["texture"])
			assert_bool(ResourceLoader.exists(path)).override_failure_message("missing " + path).is_true()
	for clip: String in rig.clips:
		var view: String = rig.clip_view(clip)
		assert_bool(rig.views.has(view)).override_failure_message(clip + ": no view " + view).is_true()
		for part: String in rig.clips[clip]["tracks"]:
			assert_bool(part == "root" or rig.views[view]["parts"].has(part)).override_failure_message(clip + ": no part " + part).is_true()
	for clip: String in required:
		assert_bool(rig.has_clip(clip)).override_failure_message("no clip " + clip).is_true()


func test_a_view_painted_facing_left_is_mirrored_the_other_way() -> void:
	# The side seated pose is painted facing left: drawn unflipped it must face left (its parts
	# where painted), and flipped (facing right) mirrored about the foot.
	var rig: CharacterRig = _rig()
	rig.views["side"]["faces_left"] = true
	var plain: Vector2 = rig.part_point("side", {}, "body", Vector2(300, 400), 1.0, false)
	var flipped: Vector2 = rig.part_point("side", {}, "body", Vector2(300, 400), 1.0, true)
	rig.views["side"]["faces_left"] = false
	var normal: Vector2 = rig.part_point("side", {}, "body", Vector2(300, 400), 1.0, false)
	assert_float(plain.x - 300.0).is_equal_approx(-(normal.x - 300.0), 0.01)
	assert_float(flipped.x).is_equal_approx(normal.x, 0.01)

## The painted ghost (Phase 3, 2026-11-21; docs/art/characters/GHOST.md §7): his rig is complete and
## always floating, the animator's state table follows only what the game already decides (drift,
## casting, hiding, being caught), view changes and stops are eased, and he stays in the room's
## depth order.
extends GdUnitTestSuite


func _rig() -> CharacterRig:
	return CharacterRig.load_for("ghost")


## Runs [param anim] for [param seconds] at a steady floor velocity (m/s).
func _run(anim: GhostAnimator, seconds: float, velocity: Vector2, extra: Dictionary = {}) -> void:
	var state: Dictionary = {"velocity": velocity}
	state.merge(extra, true)
	var t: float = 0.0
	while t < seconds:
		anim.update(1.0 / 60.0, state)
		t += 1.0 / 60.0


func test_the_ghost_rig_is_complete() -> void:
	var rig: CharacterRig = _rig()
	assert_object(rig).is_not_null()
	for view: String in ["front", "side", "back"]:
		assert_bool(rig.views.has(view)).is_true()
		for part: String in rig.views[view]["parts"]:
			var tex: String = String(rig.views[view]["parts"][part]["texture"])
			assert_bool(ResourceLoader.exists(tex)).override_failure_message("missing " + tex).is_true()
	for part: String in ["head", "body", "arm_l", "arm_r", "leg_l", "leg_r"]:
		assert_bool(rig.views["front"]["parts"].has(part)).is_true()
		assert_bool(rig.views["back"]["parts"].has(part)).is_true()
	for part: String in ["head", "body", "arm", "legs"]:
		assert_bool(rig.views["side"]["parts"].has(part)).is_true()
	for clip: String in ["float_front", "float_side", "float_back", "glide_front", "glide_side", "glide_back",
			"reach_front", "reach_side", "reach_back", "fright"]:
		assert_bool(rig.has_clip(clip)).override_failure_message("missing clip " + clip).is_true()
	for key: String in ["opacity", "tint", "glow_color", "glow_alpha", "glow_px", "hover_m"]:
		assert_bool(rig.look.has(key)).override_failure_message("missing look " + key).is_true()


func test_he_is_drawn_on_the_familys_scale() -> void:
	# The family is drawn at the storybook scale (father 1.85 m → ~1.4 m figure): the ghost, a 1.78 m
	# man, must not come out bigger than the father (user review 2026-11-21).
	var ghost: CharacterRig = _rig()
	var father: CharacterRig = CharacterRig.load_for("father")
	assert_float(_figure_m(ghost)).is_less(_figure_m(father))
	assert_float(_figure_m(ghost)).is_greater(_figure_m(father) * 0.85)


## Painted figure height in metres in the front view (top of the highest part to the lowest).
func _figure_m(rig: CharacterRig) -> float:
	var v: Dictionary = rig.views["front"]
	var top: float = INF
	var bottom: float = -INF
	for part: String in v["parts"]:
		var p: Dictionary = v["parts"][part]
		var tex: Texture2D = load(String(p["texture"]))
		top = minf(top, float(p["origin"][1]))
		bottom = maxf(bottom, float(p["origin"][1]) + float(tex.get_height()))
	return (bottom - top) / float(v["px_per_m"])


func test_he_always_floats_above_the_floor() -> void:
	# No standing pose: he hangs above his floor point, and no clip has a walk or a planted foot.
	var rig: CharacterRig = _rig()
	assert_float(float(rig.look["hover_m"])).is_greater(0.1)
	for name: String in rig.clips:
		assert_bool(name.begins_with("walk") or name.begins_with("idle") or name.begins_with("stand")).is_false()
	# the painted toes are above the view's foot point (the floor under him), in every view
	for view: String in ["front", "side", "back"]:
		var foot_y: float = float(rig.views[view]["foot"][1])
		for part: String in rig.views[view]["parts"]:
			var p: Dictionary = rig.views[view]["parts"][part]
			var tex: Texture2D = load(String(p["texture"]))
			assert_float(float(p["origin"][1]) + float(tex.get_height())).is_less_equal(foot_y + 2.0)
	# the rest bob only lifts him (dy <= 0): he never dips down onto the floor
	for clip: String in ["float_front", "float_side", "float_back"]:
		for key: Array in rig.clips[clip]["tracks"]["root"]:
			assert_float(float(key[3])).is_less_equal(0.0)


func test_the_state_table_follows_the_game() -> void:
	var anim := GhostAnimator.new(_rig())
	assert_array(anim.choose({"drift": Vector2(1.5, 0)})).is_equal(["glide_side", false])
	assert_array(anim.choose({"drift": Vector2(-1.5, 0)})).is_equal(["glide_side", true])
	assert_array(anim.choose({"drift": Vector2(0, 1.5)})).is_equal(["glide_front", false])
	assert_array(anim.choose({"drift": Vector2(0, -1.5)})).is_equal(["glide_back", false])
	# hovering keeps the last view, then turns to face the room
	assert_array(anim.choose({"drift": Vector2.ZERO, "last_dir": "left", "still": 0.5})).is_equal(["float_side", true])
	assert_array(anim.choose({"drift": Vector2.ZERO, "last_dir": "away", "still": 0.5})).is_equal(["float_back", false])
	assert_array(anim.choose({"drift": Vector2.ZERO, "last_dir": "left", "still": GhostAnimator.FACE_FRONT_AFTER})).is_equal(["float_front", false])
	# casting faces the object; a fright wins over everything
	assert_array(anim.choose({"casting": true, "target": Vector2(-2, 0.3)})).is_equal(["reach_side", true])
	assert_array(anim.choose({"casting": true, "target": Vector2(0.2, 2)})).is_equal(["reach_front", false])
	assert_array(anim.choose({"casting": true, "target": Vector2(0.1, -2)})).is_equal(["reach_back", false])
	assert_array(anim.choose({"frightened": true, "casting": true, "drift": Vector2(2, 0)})).is_equal(["fright", false])


func test_gliding_leans_into_the_drift_and_the_legs_trail() -> void:
	var anim := GhostAnimator.new(_rig())
	_run(anim, 1.5, Vector2(1.75, 0))
	assert_str(anim.clip).is_equal("glide_side")
	var pose: Dictionary = anim.current_pose()
	var clip_pose: Dictionary = anim.rig.sample("glide_side", 0.0)
	assert_float(anim.lean).is_greater(4.0)
	assert_float(anim.trail).is_greater(8.0)
	# legs swing back (+ in the side view facing right) past what the clip alone holds
	assert_float(float(pose["legs"][0])).is_greater(float(clip_pose["legs"][0]) + 6.0)
	# mirrored when drifting left: the same look, opposite rig sign
	var left := GhostAnimator.new(_rig())
	_run(left, 1.5, Vector2(-1.75, 0))
	assert_bool(left.flip).is_true()
	assert_float(float(left.current_pose()["legs"][0])).is_greater(float(clip_pose["legs"][0]) + 6.0)


func test_a_stop_settles_with_a_swing_instead_of_freezing() -> void:
	var anim := GhostAnimator.new(_rig())
	_run(anim, 1.5, Vector2(1.75, 0))
	var overshoot: float = 0.0
	var t: float = 0.0
	while t < 2.0:   # under FACE_FRONT_AFTER of stillness: still facing the way he went
		anim.update(1.0 / 60.0, {"velocity": Vector2.ZERO})
		overshoot = minf(overshoot, anim.trail)
		t += 1.0 / 60.0
	assert_float(overshoot).is_less(-0.3)            # the legs swung on past rest
	assert_float(absf(anim.trail)).is_less(0.5)      # and settled
	assert_str(anim.clip).is_equal("float_side")     # hovering, still facing the way he went


func test_view_changes_turn_and_clip_changes_blend() -> void:
	var anim := GhostAnimator.new(_rig())
	_run(anim, 1.0, Vector2(1.75, 0))
	anim.update(1.0 / 60.0, {"velocity": Vector2(0, 1.75)})
	_run(anim, 0.4, Vector2(0, 1.75))
	assert_str(anim.view).is_equal("front")
	# the switch narrowed the figure for a moment, then widened it again
	var turning := GhostAnimator.new(_rig())
	_run(turning, 1.0, Vector2(1.75, 0))
	_run(turning, 0.25, Vector2(0, 1.75))
	var narrowest: float = 1.0
	for i: int in 20:
		turning.update(1.0 / 60.0, {"velocity": Vector2(0, 1.75)})
		narrowest = minf(narrowest, turning.squeeze())
	assert_float(narrowest).is_less(1.0)
	_run(turning, 0.5, Vector2(0, 1.75))
	assert_float(turning.squeeze()).is_equal(1.0)
	# same view, new clip: no snap — the first frame still shows the old pose
	var still := GhostAnimator.new(_rig())
	_run(still, 3.0, Vector2.ZERO)
	var before: Dictionary = still.current_pose()
	still.update(1.0 / 60.0, {"velocity": Vector2.ZERO, "casting": true, "target": Vector2(0, 2)})
	assert_str(still.clip).is_equal("reach_front")
	assert_float(absf(float(still.current_pose()["arm_r"][0]) - float(before["arm_r"][0]))).is_less(5.0)


func test_hiding_fades_him_out_and_emerging_brings_him_back() -> void:
	var anim := GhostAnimator.new(_rig())
	_run(anim, 0.5, Vector2.ZERO)
	assert_float(anim.presence()).is_equal(1.0)
	_run(anim, 0.15, Vector2.ZERO, {"hidden": true})
	assert_float(anim.presence()).is_between(0.05, 0.95)   # on the way: not a pop
	_run(anim, 0.5, Vector2.ZERO, {"hidden": true})
	assert_float(anim.presence()).is_equal(0.0)
	_run(anim, 0.2, Vector2.ZERO)
	assert_float(anim.presence()).is_between(0.05, 0.95)
	_run(anim, 0.5, Vector2.ZERO)
	assert_float(anim.presence()).is_equal(1.0)


func test_a_fright_plays_then_he_floats_again() -> void:
	var anim := GhostAnimator.new(_rig())
	_run(anim, 0.5, Vector2.ZERO)
	anim.startle(true)
	_run(anim, 0.1, Vector2.ZERO)
	assert_str(anim.clip).is_equal("fright")
	_run(anim, GhostAnimator.FRIGHT_CAUGHT, Vector2.ZERO)
	assert_str(anim.clip).starts_with("float_")


func test_a_teleport_is_not_motion() -> void:
	# respawn after contact, or a jump across the room in one frame: no glide, no lean
	var anim := GhostAnimator.new(_rig())
	_run(anim, 0.5, Vector2.ZERO)
	anim.update(1.0 / 60.0, {"velocity": Vector2(400, 0)})
	assert_float(anim.drift.length()).is_equal(0.0)
	assert_str(anim.clip).starts_with("float_")


func test_he_is_depth_sorted_by_his_floor_point() -> void:
	# behind a sofa at v 0.5 when further back, in front of it when nearer the camera
	var sofa_y: float = RoomGeometry.to_screen(Vector2(0.5, 0.5)).y
	assert_float(RoomStage.ghost_sort_y(Vector2(0.5, 0.3))).is_less(sofa_y)
	assert_float(RoomStage.ghost_sort_y(Vector2(0.5, 0.8))).is_greater(sofa_y)
	# inside a wall he is drawn over the room (as before the painted ghost)
	assert_float(RoomStage.ghost_sort_y(Vector2(-0.1, 0.5))).is_equal(100000.0)


func test_the_visual_composites_body_and_halo_offscreen() -> void:
	var rig: CharacterRig = _rig()
	var anim := GhostAnimator.new(rig)
	var visual: GhostVisual = auto_free(GhostVisual.new(rig, anim))
	add_child(visual)
	assert_object(visual.body_texture()).is_not_null()
	assert_object(visual.halo_texture()).is_not_null()
	assert_float(visual.setting("opacity", 0.0)).is_between(0.5, 1.0)
	# he hangs above his foot point; hidden, he shrinks toward it
	anim.update(1.0 / 60.0, {"velocity": Vector2.ZERO})
	var shown: Rect2 = visual.figure_rect(Vector2(600, 500), 1.0)
	assert_float(shown.end.y).is_less(500.0 + GhostVisual.CANVAS.y)
	_run(anim, 1.0, Vector2.ZERO, {"hidden": true})
	var hidden: Rect2 = visual.figure_rect(Vector2(600, 500), 1.0)
	assert_float(hidden.size.y).is_less(shown.size.y)

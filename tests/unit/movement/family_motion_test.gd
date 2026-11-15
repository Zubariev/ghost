## The family walks (stage 5c, roadmap step 1; decided 2026-11-13: walking is shown only and
## costs no simulation time). Fixture timeline (sim fixtures): "tester" sleeps in the bedroom
## upstairs until 09:00, walks down the stairs to the kitchen (2 min), cooks at the stove
## until 10:00, then walks through the side door to the dining room (2 min).
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")
const Mx := preload("res://tests/unit/fixtures/movement_fixtures.gd")
const FRAMES_PER_MINUTE: int = 20

var _house: HouseState
var _routine: NpcRoutine
var _routines: Array[NpcRoutine] = []
var _layout: RoomLayout
var _paths: RoomPaths
var _motion: FamilyMotion
## Every frame: [room, uv]
var _trace: Array = []
## Every door crossing: [from_room, to_room, exit_uv, entry_uv]
var _crossings: Array = []


func before_test() -> void:
	_house = Mx.house()
	_routine = Fx.routine(_house)
	_routines = [_routine]
	_layout = RoomLayout.new(Mx.furniture(), _house)
	_paths = RoomPaths.new(_layout, Mx.config())
	_routine.begin(Fx.COOK_START - 1)
	_motion = FamilyMotion.new(_routines, _house, _layout, _paths, Mx.config())
	_trace = []
	_crossings = []
	_motion.door_crossed.connect(func(_i: int, from_room: String, to_room: String, exit_uv: Vector2, entry_uv: Vector2) -> void:
		_crossings.append([from_room, to_room, exit_uv, entry_uv]))


## Spends minutes like the game: the simulation's minute, then frames of walking.
func _run(from_minute: int, to_minute: int) -> void:
	for minute: int in range(from_minute, to_minute):
		_routine.step(minute)
		for frame: int in FRAMES_PER_MINUTE:
			_motion.update(Mx.FRAME_MINUTES)
			var placed: Dictionary = _motion.person(0, _motion.room_of(0))
			_trace.append([_motion.room_of(0), placed["uv"]])


## The exit and entry points of the first crossing from [param room] into [param next].
func _crossing(room: String, next: String) -> Array:
	for crossing: Array in _crossings:
		if crossing[0] == room and crossing[1] == next:
			return [crossing[2], crossing[3]]
	return []


func test_start_shows_the_person_at_their_spot_without_walking() -> void:
	# Assert: settled at their bedroom slot
	var placed: Dictionary = _motion.person(0, "bedroom")
	assert_dict(placed).is_not_empty()
	assert_vector(Vector2(placed["uv"])).is_equal(_layout.spot(_routine, 0, "bedroom"))
	assert_bool(_motion.is_walking(0)).is_false()


func test_between_floors_they_leave_and_arrive_by_the_stairs() -> void:
	# Act
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 2)
	# Assert
	var crossing: Array = _crossing("bedroom", "kitchen")
	assert_array(crossing).is_not_empty()
	assert_vector(Vector2(crossing[0])).is_equal(_layout.door_uv("bedroom", "kitchen"))
	assert_vector(Vector2(crossing[1])).is_equal(_layout.door_uv("kitchen", "bedroom"))
	assert_vector(Vector2(crossing[1])).is_equal(_layout.kind_uv("kitchen", "stairs"))


func test_between_rooms_on_a_floor_they_use_the_matching_doors() -> void:
	# Act: cooking ends at 10:00, then the walk to the dining room
	_run(Fx.COOK_START - 1, Fx.MEAL_START + Fx.WALK + 2)
	# Assert: out by the kitchen's right door, in by the dining room's left door
	var crossing: Array = _crossing("kitchen", "dining")
	assert_array(crossing).is_not_empty()
	assert_vector(Vector2(crossing[0])).is_equal(Vector2(1.0, 0.5))
	assert_vector(Vector2(crossing[1])).is_equal(Vector2(0.0, 0.5))


func test_nobody_jumps_inside_a_room() -> void:
	# Act
	_run(Fx.COOK_START - 1, Fx.MEAL_START + Fx.WALK + 5)
	# Assert
	for i: int in range(1, _trace.size()):
		if _trace[i - 1][0] != _trace[i][0]:
			continue
		var step: float = Vector2(_trace[i - 1][1]).distance_to(_trace[i][1])
		assert_float(step).override_failure_message("frame %d jumped %.3f in %s" % [i, step, _trace[i][0]]).is_less_equal(Mx.MAX_FRAME_STEP)


func test_the_walk_to_the_stove_goes_round_the_counter() -> void:
	# Act
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 4)
	# Assert: the straight way is blocked, and the walk is never inside the counter
	var counter: Rect2 = _paths.blocked("kitchen")[2]
	var entry_point: Vector2 = _motion.entry_uv("kitchen", "bedroom")
	assert_bool(_paths.is_clear("kitchen", entry_point, _layout.spot(_routine, 0, "kitchen"))).is_false()
	var kitchen_frames: int = 0
	for entry: Array in _trace:
		if entry[0] == "kitchen":
			kitchen_frames += 1
			assert_bool(counter.has_point(entry[1])).override_failure_message("inside the counter at %s" % entry[1]).is_false()
	assert_int(kitchen_frames).is_greater(0)


func test_after_arriving_they_stand_at_the_stove_and_face_it() -> void:
	# Act: well into cooking
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 5)
	# Assert
	var placed: Dictionary = _motion.person(0, "kitchen")
	var spot: Vector2 = _layout.spot(_routine, 0, "kitchen")
	assert_vector(Vector2(placed["uv"])).is_equal_approx(spot, Vector2(0.001, 0.001))
	assert_str(String(placed["pose"])).is_not_equal("walk")
	assert_float(Vector2(placed["facing"]).dot((_layout.object_uv("kitchen", "stove") - spot).normalized())).is_greater(0.99)


func test_while_walking_they_face_the_way_they_go() -> void:
	# Act: half a minute into the walk down
	_run(Fx.COOK_START - 1, Fx.COOK_START)
	_routine.step(Fx.COOK_START)
	var before: Vector2 = _motion.person(0, _motion.room_of(0))["uv"]
	_motion.update(Mx.FRAME_MINUTES)
	var placed: Dictionary = _motion.person(0, _motion.room_of(0))
	# Assert
	assert_str(String(placed["pose"])).is_equal("walk")
	assert_float(Vector2(placed["facing"]).dot((Vector2(placed["uv"]) - before).normalized())).is_greater(0.99)


func test_long_routes_speed_up_to_catch_up_with_the_simulation() -> void:
	# Act: the simulation has them in the kitchen by 09:02; the view follows within a minute
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 1)
	# Assert
	assert_str(_motion.room_of(0)).is_equal("kitchen")


func test_walking_never_changes_simulation_timings() -> void:
	# Arrange: a second, identical house and routine that nobody draws
	var bare_house: HouseState = Mx.house()
	var bare: NpcRoutine = Fx.routine(bare_house)
	bare.begin(Fx.COOK_START - 1)
	var with_view: Array[String] = []
	var without_view: Array[String] = []
	_routine.activity_started.connect(func(a: Activity) -> void: with_view.append(a.id))
	bare.activity_started.connect(func(a: Activity) -> void: without_view.append(a.id))
	var rooms_with: Array[String] = []
	var rooms_without: Array[String] = []
	# Act
	for minute: int in range(Fx.COOK_START - 1, Fx.MEAL_END + 5):
		_routine.step(minute)
		bare.step(minute)
		for frame: int in FRAMES_PER_MINUTE:
			_motion.update(Mx.FRAME_MINUTES)
		rooms_with.append("%d:%s:%d" % [minute, _routine.room_id, _routine.state])
		rooms_without.append("%d:%s:%d" % [minute, bare.room_id, bare.state])
	# Assert
	assert_array(rooms_with).is_equal(rooms_without)
	assert_array(with_view).is_equal(without_view)
	assert_int(_routine.work_done_minutes).is_equal(bare.work_done_minutes)


func test_sight_looks_from_the_walking_position() -> void:
	# Arrange: the cook is shown mid-walk; the ghost stands right in front of that point
	var morale := MoraleSystem.new(Fx.morale_rules(), _house, _routines)
	var nav := GhostNavigator.new(_house)
	var stealth := StealthSystem.new(Fx.stealth_config(), _house, _routines, morale, _layout, nav, "cellar", Vector2(0.5, 0.5))
	stealth.person_source = _motion.person
	_motion.stealth = stealth
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK)
	var placed: Dictionary = _motion.person(0, "kitchen")
	assert_bool(_motion.is_walking(0)).is_true()
	var contacts: Array[String] = []
	stealth.contact.connect(func(npc: String, _how: String) -> void: contacts.append(npc))
	nav.place("kitchen", Vector2(placed["uv"]) + Vector2(placed["facing"]) * 0.1)
	# Act
	stealth.observe()
	# Assert: seen up close from where they are walking, not from the stove
	assert_array(contacts).contains_exactly(["tester"])


func test_people_leaving_together_walk_one_after_another_not_stacked() -> void:
	# Arrange: a second tester with the same schedule; both leave the bedroom at 09:00
	var second: NpcRoutine = Fx.routine(_house)
	second.begin(Fx.COOK_START - 1)
	_routines.append(second)
	_motion = FamilyMotion.new(_routines, _house, _layout, _paths, Mx.config())
	var closest: float = INF
	var both_walking: int = 0
	# Act
	for minute: int in range(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 2):
		_routine.step(minute)
		second.step(minute)
		for frame: int in FRAMES_PER_MINUTE:
			_motion.update(Mx.FRAME_MINUTES)
			if _motion.is_walking(0) and _motion.is_walking(1) and _motion.room_of(0) == _motion.room_of(1):
				both_walking += 1
				closest = minf(closest, Vector2(_motion.person(0, _motion.room_of(0))["uv"]).distance_to(_motion.person(1, _motion.room_of(1))["uv"]))
	# Assert: whenever both are on their way in the same room, they are apart
	assert_int(both_walking).is_greater(0)
	assert_float(closest).is_greater(0.03)


# Speeds (user decision 2026-11-15): each person has their own pace, and run-down rooms slow
# everyone; a person's whole walk (pace and how far they may trail) scales with it.

func test_a_slow_person_covers_proportionally_less_ground() -> void:
	# Arrange: the same walk at full and at half pace
	_routine.schedule.pace = 0.5
	var slow := FamilyMotion.new(_routines, _house, _layout, _paths, Mx.config())
	var fast_house: HouseState = Mx.house()
	var fast_routine: NpcRoutine = Fx.routine(fast_house)
	fast_routine.begin(Fx.COOK_START - 1)
	var fast_layout := RoomLayout.new(Mx.furniture(), fast_house)
	var fast := FamilyMotion.new([fast_routine] as Array[NpcRoutine], fast_house, fast_layout, RoomPaths.new(fast_layout, Mx.config()), Mx.config())
	_routine.step(Fx.COOK_START - 1)
	fast_routine.step(Fx.COOK_START - 1)
	_routine.step(Fx.COOK_START)
	fast_routine.step(Fx.COOK_START)
	# A tiny step plans the routes (planning happens on update).
	slow.update(0.000001)
	fast.update(0.000001)
	var slow_start: float = slow.remaining(0)
	var fast_start: float = fast.remaining(0)
	# Act: one frame
	slow.update(Mx.FRAME_MINUTES)
	fast.update(Mx.FRAME_MINUTES)
	# Assert: the same route, half the ground covered
	assert_float(slow_start).is_equal_approx(fast_start, 0.0001)
	assert_float(slow_start - slow.remaining(0)).is_equal_approx((fast_start - fast.remaining(0)) * 0.5, 0.0005)


func test_a_run_down_room_slows_walking() -> void:
	# Arrange: the bedroom in perfect order, then fully run down
	_routine.people_slowest = 0.75
	var motion := FamilyMotion.new(_routines, _house, _layout, _paths, Mx.config())
	_house.set_room_cleanliness("bedroom", RoomState.Cleanliness.CLEAN)
	var tidy: float = motion.pace(0)
	_house.set_room_cleanliness("bedroom", RoomState.Cleanliness.DIRTY)
	_house.rooms["bedroom"].light = RoomState.Light.DARK
	_house.rooms["bedroom"].temperature = RoomState.Temperature.COLD
	_house.set_object_state("lamp", &"broken")
	# Act
	var ruined: float = motion.pace(0)
	# Assert
	assert_float(ruined).is_equal_approx(tidy * 0.75, 0.0001)


# Head turns (user decision 2026-11-15): resting people glance around now and then, so a
# single room is no longer safe to cross behind someone's back.

func _glances(every: Array = [3.0, 7.0], focused: Array = []) -> Dictionary:
	return {"every_minutes": every, "duration_minutes": [1.0, 2.0], "max_angle_deg": 110.0,
		"focused_activities": focused, "focused_factor": 0.4, "seed": 11}


## Runs the cook at the stove for [param minutes] and returns how many frames their gaze was
## away from the stove.
func _frames_looking_away(minutes: int) -> int:
	_run(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 6)   # arrive and settle at the stove
	var spot: Vector2 = _layout.spot(_routine, 0, "kitchen")
	var at_stove: Vector2 = (_layout.object_uv("kitchen", "stove") - spot).normalized()
	var away: int = 0
	for minute: int in range(Fx.COOK_START + Fx.WALK + 6, Fx.COOK_START + Fx.WALK + 6 + minutes):
		_routine.step(minute)
		for frame: int in FRAMES_PER_MINUTE:
			_motion.update(Mx.FRAME_MINUTES)
			if Vector2(_motion.person(0, "kitchen")["facing"]).dot(at_stove) < 0.97:
				away += 1
	return away


func test_a_resting_person_glances_away_and_back() -> void:
	# Arrange
	_motion.set_glances(_glances())
	# Act: 20 minutes at the stove
	var away: int = _frames_looking_away(20)
	# Assert: sometimes away, mostly at work
	assert_int(away).is_greater(0)
	assert_int(away).is_less(20 * FRAMES_PER_MINUTE / 2)


func test_without_glances_the_gaze_stays_on_the_work() -> void:
	assert_int(_frames_looking_away(20)).is_equal(0)


func test_focused_work_means_fewer_glances() -> void:
	# Arrange: the same cook, once with cooking counted as focused work
	_motion.set_glances(_glances())
	var normal: int = _frames_looking_away(30)
	before_test()
	_motion.set_glances(_glances([3.0, 7.0], ["cook"]))   # the fixture cook has no animation: its id counts
	# Act
	var focused: int = _frames_looking_away(30)
	# Assert
	assert_int(focused).is_less(normal)


func test_more_anxious_people_glance_more_often() -> void:
	# Arrange: calm (anxiety 0.5) vs anxious (anxiety 1.5), same seed
	_routine.schedule.anxiety = 0.5
	_motion.set_glances(_glances())
	var calm: int = _frames_looking_away(40)
	before_test()
	_routine.schedule.anxiety = 1.5
	_motion.set_glances(_glances())
	# Act
	var anxious: int = _frames_looking_away(40)
	# Assert
	assert_int(anxious).is_greater(calm)


func test_glances_are_the_same_every_run() -> void:
	_motion.set_glances(_glances())
	var first: int = _frames_looking_away(20)
	before_test()
	_motion.set_glances(_glances())
	assert_int(_frames_looking_away(20)).is_equal(first)


func test_nobody_rushes_faster_than_the_cap_even_far_behind() -> void:
	# Arrange: a cap of 1.5x pace; the walk down to the stove is long
	var config: Dictionary = Mx.config()
	config["max_rush"] = 1.5
	_motion = FamilyMotion.new(_routines, _house, _layout, _paths, config)
	var fastest: float = 0.0
	var last: Vector2 = _motion.person(0, _motion.room_of(0))["uv"]
	var last_room: String = _motion.room_of(0)
	# Act
	for minute: int in range(Fx.COOK_START - 1, Fx.COOK_START + Fx.WALK + 6):
		_routine.step(minute)
		for frame: int in FRAMES_PER_MINUTE:
			_motion.update(Mx.FRAME_MINUTES)
			var room: String = _motion.room_of(0)
			var uv: Vector2 = _motion.person(0, room)["uv"]
			if room == last_room:
				fastest = maxf(fastest, uv.distance_to(last) / Mx.FRAME_MINUTES)
			last = uv
			last_room = room
	# Assert
	assert_float(fastest).is_less_equal(float(config["walk_speed"]) * 1.5 + 0.0001)

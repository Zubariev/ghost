## Being seen, inspecting, searching and contact (GDD §6.7, §12.1a; Demo Specification §8.5,
## §8.8, approved 2026-11-13). Fixture: "tester" walks to the kitchen 09:00–09:01 and cooks
## from 09:02 (30 min) facing the stove; the cooking window ends at 10:00.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")
const START_ROOM: String = "bedroom"
const START_UV := Vector2(0.5, 0.9)

var _house: HouseState
var _routine: NpcRoutine
var _routines: Array[NpcRoutine] = []
var _morale: MoraleSystem
var _layout: RoomLayout
var _nav: GhostNavigator
var _stealth: StealthSystem
var _energy: Array[String] = []
var _contacts: Array[String] = []
var _skipped: Array[String] = []


func _setup(config: Dictionary = Fx.stealth_config(), extra: Array[NpcRoutine] = []) -> void:
	_house = Fx.house() if _house == null else _house
	_routine = Fx.routine(_house)
	_routines = [_routine]
	_routines.append_array(extra)
	_morale = MoraleSystem.new(Fx.morale_rules(), _house, _routines)
	_layout = RoomLayout.new(Fx.furniture_data(), _house)
	_nav = GhostNavigator.new(_house)
	_nav.place(START_ROOM, START_UV)
	_stealth = StealthSystem.new(config, _house, _routines, _morale, _layout, _nav, START_ROOM, START_UV)
	_energy = []
	_contacts = []
	_skipped = []
	_stealth.ghost_energy_penalty.connect(func(zone: String, _amount: int) -> void: _energy.append(zone))
	_stealth.contact.connect(func(npc: String, _how: String) -> void: _contacts.append(npc))
	_routine.activity_skipped.connect(func(a: Activity, _d: int) -> void: _skipped.append(a.id))
	for routine: NpcRoutine in _routines:
		routine.begin(Fx.COOK_START)


func before_test() -> void:
	_house = null


## Spends minutes like the game: morale, routines, then a frame of sight, then stealth's minute.
func _run(from_minute: int, to_minute: int) -> void:
	for minute: int in range(from_minute, to_minute):
		_morale.begin_minute(minute, minute)
		for routine: NpcRoutine in _routines:
			routine.step(minute)
		_morale.end_minute()
		_stealth.observe()
		_stealth.on_minute(minute)


## Puts the ghost at an angle (degrees) from the cook's line of sight, at a distance.
func _ghost_near_cook(angle_deg: float, distance: float) -> void:
	var where: Dictionary = _layout.person(_routine, 0, "kitchen", _routines)
	var direction: Vector2 = Vector2(where["facing"]).rotated(deg_to_rad(angle_deg))
	_nav.place("kitchen", Vector2(where["uv"]) + direction * distance)


func _cook_ten_minutes() -> void:
	_run(Fx.COOK_START, Fx.COOK_START + Fx.WALK + 10)
	assert_int(_routine.work_done_minutes).is_equal(10)


func test_deep_zone_contact_costs_morale_and_returns_the_ghost() -> void:
	_setup()
	_cook_ten_minutes()
	# Act: the ghost floats straight into her view, close
	_ghost_near_cook(0.0, 0.15)
	_stealth.observe()
	# Assert: −10 morale, deep energy penalty, ghost back at the start, fright hold
	assert_int(_morale.get_morale("tester")).is_equal(70)
	assert_array(_energy).contains_exactly(["deep"])
	assert_array(_contacts).contains_exactly(["tester"])
	assert_str(_nav.room_id).is_equal(START_ROOM)
	assert_bool(_routine.is_held()).is_true()


func test_peripheral_detection_differs_from_deep_contact() -> void:
	_setup()
	_cook_ten_minutes()
	# Act: glimpsed at the edge of her view
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	# Assert: registered at once — energy only; no morale loss, no respawn, no contact
	assert_array(_energy).contains_exactly(["peripheral"])
	assert_int(_morale.get_morale("tester")).is_equal(80)
	assert_str(_nav.room_id).is_equal("kitchen")
	assert_array(_contacts).is_empty()


func test_peripheral_detection_during_cooking_suspends_after_the_current_minute() -> void:
	_setup()
	_cook_ten_minutes()
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	# The current minute still finishes (atomic segment), then she is held to inspect
	assert_bool(_routine.is_held()).is_false()
	_run(Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 11)
	assert_bool(_routine.is_held()).is_true()
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.INSPECTING)
	assert_int(_routine.work_done_minutes).is_equal(11)


func test_cooking_resumes_with_progress_when_the_ghost_is_gone() -> void:
	_setup()
	_cook_ten_minutes()
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_run(Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 11)
	# Act: the ghost leaves the room during the inspection
	_nav.place("cellar", Vector2(0.5, 0.5))   # somewhere nobody goes
	_run(Fx.COOK_START + Fx.WALK + 11, Fx.COOK_START + Fx.WALK + 12)
	# Assert: the inspection minute is over — released, cooking again, nothing redone
	assert_bool(_routine.is_held()).is_false()
	assert_int(_routine.state).is_equal(NpcRoutine.State.PERFORMING)
	var done_before: int = _routine.work_done_minutes
	assert_int(done_before).is_equal(11)
	_run(Fx.COOK_START + Fx.WALK + 12, Fx.COOK_START + Fx.WALK + 12 + (Fx.COOK_MINUTES - done_before))
	assert_str(String(_house.get_object_state("food"))).is_equal("ready")


func test_activity_window_expiring_during_inspection_skips_cooking() -> void:
	# Arrange: groceries hidden until 09:40, so cooking is still running at 09:58
	_house = Fx.house()
	_house.set_object_state("basket", &"hidden")
	_setup()
	_run(Fx.COOK_START, Fx.COOK_START + 40)
	_house.set_object_state("basket", &"available")
	_run(Fx.COOK_START + 40, Fx.MEAL_START - 1)
	# Act: glimpsed at 09:59; she inspects across 10:00
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_nav.place("cellar", Vector2(0.5, 0.5))   # somewhere nobody goes
	_run(Fx.MEAL_START - 1, Fx.MEAL_START + 2)
	# Assert
	assert_bool(_routine.is_held()).is_false()
	assert_array(_skipped).contains(["cook"])
	assert_str(_routine.current.id).is_equal("meal")


func test_hidden_ghost_starts_a_search_and_window_expiry_during_search_skips_cooking() -> void:
	# Arrange: groceries hidden until 09:40, so cooking is still running at 09:50
	_house = Fx.house()
	_house.set_object_state("basket", &"hidden")
	_setup()
	_run(Fx.COOK_START, Fx.COOK_START + 40)
	_house.set_object_state("basket", &"available")
	_run(Fx.COOK_START + 40, Fx.COOK_START + 50)
	# Act: glimpsed at 09:50; the ghost hides in the counter while she inspects
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_run(Fx.COOK_START + 50, Fx.COOK_START + 51)
	assert_bool(_stealth.hide("hide_counter")).is_true()
	_run(Fx.COOK_START + 51, Fx.COOK_START + 52)
	# Assert: the inspection found a hidden ghost, so she searches
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.SEARCH_WALK)
	# Act: the ghost slips out before she reaches the counter; the 12-minute search runs past 10:00
	_stealth.unhide()
	_nav.place("cellar", Vector2(0.5, 0.5))   # somewhere nobody goes
	_run(Fx.COOK_START + 52, Fx.MEAL_START + 20)
	# Assert: the search ended, the incident is forgotten, cooking was skipped
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.NONE)
	assert_array(_skipped).contains(["cook"])
	assert_str(_routine.current.id).is_equal("meal")


func test_checking_the_occupied_spot_causes_fright_then_contact() -> void:
	# Every spot counts as "near the sighting", so the nearest one — the armchair — is checked first
	var config: Dictionary = Fx.stealth_config()
	config["nearby_spot_radius"] = 1.5
	_setup(config)
	_cook_ten_minutes()
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_run(Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 11)
	assert_bool(_stealth.hide("kitchen_armchair")).is_true()
	# Act: she checks the armchair first
	_run(Fx.COOK_START + Fx.WALK + 11, Fx.COOK_START + Fx.WALK + 20)
	# Assert
	assert_array(_contacts).contains_exactly(["tester"])
	assert_int(_morale.get_morale("tester")).is_equal(70)
	assert_str(_nav.room_id).is_equal(START_ROOM)
	assert_str(_stealth.hidden_in).is_equal("")


func test_search_timeout_during_a_check_finishes_the_check_first() -> void:
	# Search time 2 min (anxiety at morale 80 adds a little): walk 1 + check 2 runs past it
	_setup(Fx.stealth_config(2))
	_cook_ten_minutes()
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_run(Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 11)
	_stealth.hide("hide_counter")
	_run(Fx.COOK_START + Fx.WALK + 11, Fx.COOK_START + Fx.WALK + 12)   # inspection over → search
	_stealth.unhide()
	_nav.place("cellar", Vector2(0.5, 0.5))   # somewhere nobody goes
	var search_minutes: int = _stealth.search_minutes_for("tester")
	# Act: past the limit, but mid-check
	_run(Fx.COOK_START + Fx.WALK + 12, Fx.COOK_START + Fx.WALK + 12 + 2)
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.SEARCH_CHECK)
	assert_int(search_minutes).is_less(3)
	# Act: the check completes, then the search ends
	_run(Fx.COOK_START + Fx.WALK + 14, Fx.COOK_START + Fx.WALK + 16)
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.NONE)
	assert_bool(_routine.is_held()).is_false()


func test_sitting_in_the_armchair_the_ghost_hides_in_causes_contact() -> void:
	# Arrange: someone who walks in from the dining room to rest in the kitchen armchair
	# (a window from 09:00 to 09:00 covers the whole day)
	var sitter_data: Dictionary = {
		"npc_id": "sitter", "name": "Sitter", "start_room": "dining",
		"activities": [
			{"id": "rest", "start": "09:00", "end": "09:00", "kind": "span", "room": "kitchen", "target": "kitchen_armchair"},
		],
	}
	_house = Fx.house()
	var sitter := NpcRoutine.new(Schedule.from_dict(sitter_data), _house, Fx.STEP)
	var extra: Array[NpcRoutine] = [sitter]
	_house.set_object_state("stove", &"broken")   # the cook only waits in the kitchen
	_setup(Fx.stealth_config(), extra)
	_nav.place("kitchen", Vector2(0.5, 0.8))
	assert_bool(_stealth.hide("kitchen_armchair")).is_true()
	# Act: she arrives (2-minute walk) and sits down in it
	_run(Fx.COOK_START, Fx.COOK_START + Fx.WALK + 1)
	# Assert
	assert_array(_contacts).contains(["sitter"])
	assert_str(_nav.room_id).is_equal(START_ROOM)


func test_walls_block_sight() -> void:
	_setup()
	_cook_ten_minutes()
	# Right in her line of sight, but inside the wall behind the stove
	var where: Dictionary = _layout.person(_routine, 0, "kitchen", _routines)
	var through_wall: Vector2 = Vector2(where["uv"]) + Vector2(where["facing"]) * 0.30
	through_wall.y = -0.05
	_nav.place("kitchen", through_wall)
	_stealth.observe()
	assert_array(_energy).is_empty()
	assert_array(_contacts).is_empty()


func test_sleeping_broken_and_searching_people_ignore_new_detection() -> void:
	# Sleeping: a sleeper in the bedroom, ghost right in front of her
	var sleeper_data: Dictionary = {
		"npc_id": "sleeper", "name": "Sleeper", "start_room": "kitchen",
		"activities": [{"id": "night", "start": "09:00", "end": "09:00", "kind": "span", "room": "kitchen", "animation": "sleep"}],
	}
	_house = Fx.house()
	var sleeper := NpcRoutine.new(Schedule.from_dict(sleeper_data), _house, Fx.STEP)
	var extra: Array[NpcRoutine] = [sleeper]
	_setup(Fx.stealth_config(), extra)
	_cook_ten_minutes()
	assert_int(sleeper.state).is_equal(NpcRoutine.State.PERFORMING)
	assert_bool(_stealth.can_notice(sleeper)).is_false()
	assert_bool(_stealth.can_notice(_routine)).is_true()
	# Broken
	_morale.set_morale("tester", 10)
	assert_bool(_stealth.can_notice(_routine)).is_false()
	# Already searching: a fresh setup, tester mid-search, then the ghost in deep view
	_house = Fx.house()
	_setup()
	_cook_ten_minutes()
	_ghost_near_cook(50.0, 0.3)
	_stealth.observe()
	_run(Fx.COOK_START + Fx.WALK + 10, Fx.COOK_START + Fx.WALK + 11)
	_stealth.hide("hide_counter")
	_run(Fx.COOK_START + Fx.WALK + 11, Fx.COOK_START + Fx.WALK + 12)
	_stealth.unhide()
	_energy.clear()
	_ghost_near_cook(0.0, 0.1)
	_stealth.observe()
	assert_array(_energy).is_empty()
	assert_array(_contacts).is_empty()


func test_search_time_grows_with_low_morale_and_anxiety() -> void:
	_setup(Fx.stealth_config(10))
	# 10 × (1 + anxiety 1.0 × (100 − 80) / 100) = 12
	assert_int(_stealth.search_minutes_for("tester")).is_equal(12)
	_morale.set_morale("tester", 30)
	# 10 × (1 + 1.0 × 0.7) = 17
	assert_int(_stealth.search_minutes_for("tester")).is_equal(17)


func test_no_hiding_spots_ends_the_search_at_once() -> void:
	_setup()
	_routine.hold()
	_stealth.begin_search("tester", "dining", Vector2(0.5, 0.5))
	assert_int(_stealth.phase_of("tester")).is_equal(StealthSystem.Phase.NONE)
	assert_bool(_routine.is_held()).is_false()

## The shipped data files load and agree with each other (reads assets/data/).
extends GdUnitTestSuite

const SCHEDULE_COUNT: int = 6


func _house() -> HouseState:
	return HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))


func _schedules() -> Array[Schedule]:
	var result: Array[Schedule] = []
	for path: String in HouseSim.SCHEDULE_PATHS:
		result.append(Schedule.from_dict(JsonData.read(path)))
	return result


func test_all_six_family_schedules_load() -> void:
	assert_int(_schedules().size()).is_equal(SCHEDULE_COUNT)


func test_every_schedule_covers_the_whole_day() -> void:
	for schedule: Schedule in _schedules():
		assert_array(Array(schedule.validate())).is_empty()


func test_grandma_keeps_her_agreed_ten_activities() -> void:
	var grandma: Schedule = Schedule.from_dict(JsonData.read("res://assets/data/schedules/grandma.json"))
	assert_int(grandma.activities.size()).is_equal(10)


func test_every_scheduled_room_is_reachable_from_the_start_room() -> void:
	var house: HouseState = _house()
	for schedule: Schedule in _schedules():
		for activity: Activity in schedule.activities:
			assert_int(house.path_cost(schedule.start_room, activity.room_id)).is_greater_equal(0)


func test_every_requirement_and_effect_names_a_known_object_and_state() -> void:
	var house: HouseState = _house()
	for schedule: Schedule in _schedules():
		for activity: Activity in schedule.activities:
			for entry: Dictionary in activity.requirements + activity.on_start + activity.on_success + activity.on_end:
				var object_id: String = String(entry["object"])
				assert_bool(house.objects.has(object_id)).is_true()
				var state := StringName(entry.get("state", entry.get("set", "")))
				assert_bool(house.objects[object_id].allows(state)).is_true()


func test_every_work_window_has_a_role_and_known_idle_room() -> void:
	var house: HouseState = _house()
	for schedule: Schedule in _schedules():
		for activity: Activity in schedule.activities:
			if activity.kind == Activity.Kind.TASKS:
				assert_array(["repair", "clean"]).contains([activity.role])
				assert_bool(house.rooms.has(activity.idle_room)).is_true()


func test_undisturbed_day_nobody_skips_an_activity() -> void:
	# Arrange
	var sim: HouseSim = HouseSim.from_data_files()
	var skipped: Array[String] = []
	for routine: NpcRoutine in sim.routines:
		routine.activity_skipped.connect(func(a: Activity, _d: int) -> void: skipped.append(a.id))
	sim.start()
	# Act: one full day at ×1
	for i: int in GameClock.MINUTES_PER_DAY:
		sim.advance(1.0)
	# Assert
	assert_array(skipped).is_empty()
	assert_int(sim.clock.day_number()).is_equal(2)


func test_father_repairs_the_stove_before_the_lamp() -> void:
	# Arrange: both broken at 08:30, before his 09:00 repair window
	var sim: HouseSim = HouseSim.from_data_files()
	var repaired: Array[String] = []
	sim.routines[0].task_completed.connect(func(t: HouseTask) -> void: repaired.append(t.target_id))
	sim.start()
	for i: int in 150:
		sim.advance(1.0)
	sim.house.set_object_state("living_room_lamp", &"broken")
	sim.house.set_object_state("stove", &"broken")
	# Act: to 12:00
	for i: int in 210:
		sim.advance(1.0)
	# Assert
	assert_array(repaired).contains_exactly(["stove", "living_room_lamp"])


func test_morale_data_has_every_rule_value() -> void:
	var rules: Dictionary = JsonData.read(HouseSim.MORALE_PATH)
	for key: String in ["start", "min", "max", "broken_at", "recover_to", "recover_step", "recover_every_minutes", "scenario_days"]:
		assert_bool(rules.has(key)).is_true()
	for key: String in ["missed_meal", "sleep_skipped", "sleep_late", "sleep_late_after_minutes", "dark", "cold", "dirty", "periodic_every_minutes", "cap_per_activity"]:
		assert_bool(rules["penalties"].has(key)).is_true()
	for key: String in ["meal_good", "meal_poor", "activity_good", "activity_poor", "task_done"]:
		assert_bool(rules["bonuses"].has(key)).is_true()


func test_undisturbed_first_day_nobody_goes_broken() -> void:
	# The balance target (decision 5): no one Broken before the first evening.
	var sim: HouseSim = HouseSim.from_data_files()
	var broke: Array[String] = []
	sim.morale.npc_broke.connect(func(npc: String) -> void: broke.append(npc))
	sim.start()
	for i: int in GameClock.MINUTES_PER_DAY:
		sim.advance(1.0)
	assert_array(broke).is_empty()
	var broken_at: int = int(JsonData.read(HouseSim.MORALE_PATH)["broken_at"])
	for routine: NpcRoutine in sim.routines:
		assert_int(sim.morale.get_morale(routine.schedule.npc_id)).is_greater(broken_at)


func test_simulation_stops_when_the_family_leaves() -> void:
	var sim: HouseSim = HouseSim.from_data_files()
	sim.start()
	for routine: NpcRoutine in sim.routines:
		sim.morale.set_morale(routine.schedule.npc_id, 10)
	assert_bool(sim.is_over()).is_true()
	assert_str(sim.morale.outcome).is_equal(MoraleSystem.OUTCOME_WON)
	var minute_before: int = sim.clock.total_minutes
	assert_int(sim.advance(60.0)).is_equal(0)
	assert_int(sim.clock.total_minutes).is_equal(minute_before)

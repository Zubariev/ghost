## The shipped data files load and agree with each other (reads assets/data/).
extends GdUnitTestSuite


func test_grandma_schedule_covers_the_whole_day() -> void:
	var schedule: Schedule = Schedule.from_dict(JsonData.read("res://assets/data/schedules/grandma.json"))
	assert_int(schedule.activities.size()).is_equal(10)
	assert_array(Array(schedule.validate())).is_empty()


func test_every_scheduled_room_is_reachable_from_the_start_room() -> void:
	var house: HouseState = HouseState.from_dict(JsonData.read("res://assets/data/house/rooms.json"))
	var schedule: Schedule = Schedule.from_dict(JsonData.read("res://assets/data/schedules/grandma.json"))
	for activity: Activity in schedule.activities:
		if activity.room_id != schedule.start_room:
			assert_array(house.find_path(schedule.start_room, activity.room_id)).is_not_empty()


func test_every_requirement_names_a_known_object_and_state() -> void:
	var house: HouseState = HouseState.from_dict(JsonData.read("res://assets/data/house/rooms.json"))
	var schedule: Schedule = Schedule.from_dict(JsonData.read("res://assets/data/schedules/grandma.json"))
	for activity: Activity in schedule.activities:
		for requirement: Dictionary in activity.requirements + activity.on_start + activity.on_success:
			var object_id: String = String(requirement["object"])
			assert_bool(house.objects.has(object_id)).is_true()
			var state := StringName(requirement.get("state", requirement.get("set", "")))
			assert_bool(house.objects[object_id].allows(state)).is_true()


func test_undisturbed_day_has_grandma_complete_every_activity() -> void:
	# Arrange
	var sim: HouseSim = HouseSim.from_data_files()
	var skipped: Array[String] = []
	sim.routines[0].activity_skipped.connect(func(a: Activity, _d: int) -> void: skipped.append(a.id))
	sim.start()
	# Act: one full day at ×1, one real second at a time
	for i: int in GameClock.MINUTES_PER_DAY:
		sim.advance(1.0)
	# Assert
	assert_array(skipped).is_empty()
	assert_int(sim.clock.day_number()).is_equal(2)

## Schedule window lookup and validation.
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")


func test_activity_at_returns_window_containing_minute() -> void:
	var schedule: Schedule = Schedule.from_dict(Fx.schedule_data())
	assert_str(schedule.activity_at(Fx.COOK_START).id).is_equal("cook")
	assert_str(schedule.activity_at(Fx.MEAL_START - 1).id).is_equal("cook")
	assert_str(schedule.activity_at(Fx.MEAL_START).id).is_equal("meal")


func test_window_ending_at_midnight_wraps() -> void:
	var schedule: Schedule = Schedule.from_dict(Fx.schedule_data())
	assert_str(schedule.activity_at(23 * 60 + 59).id).is_equal("rest")
	assert_str(schedule.activity_at(0).id).is_equal("sleep")


func test_fixture_schedule_covers_the_whole_day() -> void:
	var schedule: Schedule = Schedule.from_dict(Fx.schedule_data())
	assert_array(Array(schedule.validate())).is_empty()


func test_validate_reports_a_gap() -> void:
	var data: Dictionary = Fx.schedule_data()
	data["activities"].remove_at(2)   # drop the 10:00–11:00 meal
	var problems: PackedStringArray = Schedule.from_dict(data).validate()
	assert_int(problems.size()).is_equal(1)
	assert_str(problems[0]).contains("10:00")


func test_work_activity_reads_work_minutes() -> void:
	var cook: Activity = Schedule.from_dict(Fx.schedule_data()).activities[1]
	assert_int(cook.kind).is_equal(Activity.Kind.WORK)
	assert_int(cook.work_minutes).is_equal(Fx.COOK_MINUTES)

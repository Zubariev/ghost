## The full 3-day demo scenario through the real simulation and data (stage 6, Demo Spec
## §10.3): it can be won without developer help, it is lost when nothing is done, and a new
## run starts fresh (restart).
extends GdUnitTestSuite

const LAST_MINUTE: int = 3 * GameClock.MINUTES_PER_DAY


## Runs the scenario with a scripted ghost: every [param gap] game minutes it spoils
## something in the busiest room (lamp at night, then the window), else the stove, groceries
## or computer — paying for it from GhostEnergy with the real costs and the normal refill.
## No stealth: an upper bound, like the 2026-11-15 probe.
func _run(gap: int) -> HouseSim:
	var sim := HouseSim.from_data_files(true)
	var energy := GhostEnergy.new(JsonData.read("res://assets/data/ghost/energy.json"))
	sim.start()
	var last_act: int = -gap
	while not sim.is_over() and sim.clock.total_minutes < LAST_MINUTE + 1:
		energy.regenerate(1.0, false, false, false, false)
		if gap > 0 and sim.clock.total_minutes - last_act >= gap:
			var target: String = _pick(sim)
			if not target.is_empty():
				var key: String = GhostEnergy.action_key(sim.house.objects[target])
				if energy.spend_action(key):
					GhostActions.act(sim.house, target)
					last_act = sim.clock.total_minutes
		sim.advance(1.0)
	return sim


func _pick(sim: HouseSim) -> String:
	var count: Dictionary = {}
	for routine: NpcRoutine in sim.routines:
		if routine.is_doing_activity():
			count[routine.room_id] = int(count.get(routine.room_id, 0)) + 1
	var busiest: String = ""
	for room_id: String in count:
		if busiest.is_empty() or count[room_id] > count[busiest]:
			busiest = room_id
	var order: Array[String] = []
	if not sim.clock.is_day():
		order.append("lamp_" + busiest)
	order.append_array(["window_" + busiest, "stove", "grocery_basket", "computer"])
	for object_id: String in order:
		if GhostActions.can_act(sim.house, object_id):
			return object_id
	return ""


func test_scenario_can_be_won_before_the_third_day_ends() -> void:
	# Arrange / Act: a ghost acting every 30 game minutes
	var sim: HouseSim = _run(30)
	# Assert
	assert_str(sim.morale.outcome).is_equal(MoraleSystem.OUTCOME_WON)
	assert_int(sim.clock.total_minutes).is_less(LAST_MINUTE)
	assert_float(sim.morale.family_average()).is_less_equal(float(sim.morale.leave_threshold()))


func test_scenario_is_lost_when_the_ghost_does_nothing() -> void:
	# Arrange / Act
	var sim: HouseSim = _run(0)
	# Assert
	assert_str(sim.morale.outcome).is_equal(MoraleSystem.OUTCOME_LOST)
	assert_int(sim.clock.total_minutes).is_equal(LAST_MINUTE)


func test_a_new_run_starts_fresh_after_a_finished_one() -> void:
	# Arrange: a finished, won run
	var first: HouseSim = _run(30)
	# Act: restart
	var second := HouseSim.from_data_files(true)
	second.start()
	# Assert: clock, morale and the house are back at the scenario start
	assert_str(first.morale.outcome).is_equal(MoraleSystem.OUTCOME_WON)
	assert_str(second.morale.outcome).is_equal("")
	assert_int(second.clock.day_number()).is_equal(1)
	var start: int = int(JsonData.read(HouseSim.MORALE_PATH)["start"])
	for routine: NpcRoutine in second.routines:
		assert_int(second.morale.get_morale(routine.schedule.npc_id)).is_equal(start)
	assert_str(String(second.house.get_object_state("stove"))).is_equal("working")
	assert_str(String(second.house.get_object_state("grocery_basket"))).is_equal("available")

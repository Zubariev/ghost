## The shipped energy numbers fit the house (stage 5d; Demo Specification §8.10; reads
## assets/data/): every ghost action has a cost and a duration, costlier harm takes at least
## as long, contact costs more than being noticed, and the warning sits inside the pool.
extends GdUnitTestSuite


func _energy() -> GhostEnergy:
	return GhostEnergy.new(JsonData.read(GhostEnergy.ENERGY_PATH))


func _action_keys() -> Array[String]:
	var house := HouseState.from_dict(JsonData.read(HouseSim.HOUSE_PATH))
	var keys: Array[String] = []
	for obj: ObjectState in house.objects.values():
		if not obj.ghost.is_empty() and not keys.has(GhostEnergy.action_key(obj)):
			keys.append(GhostEnergy.action_key(obj))
	return keys


func test_every_ghost_action_has_a_cost_and_a_duration() -> void:
	var energy: GhostEnergy = _energy()
	var keys: Array[String] = _action_keys()
	assert_int(keys.size()).is_greater(0)
	for key: String in keys:
		assert_bool(energy.has_action(key)).override_failure_message("no energy entry for " + key).is_true()
		assert_float(energy.action_cost(key)).override_failure_message(key).is_greater(0.0)
		assert_float(energy.action_minutes(key)).override_failure_message(key).is_greater(0.0)


func test_costlier_harm_never_takes_less_time() -> void:
	var energy: GhostEnergy = _energy()
	var keys: Array[String] = _action_keys()
	for a: String in keys:
		for b: String in keys:
			if energy.action_cost(a) > energy.action_cost(b):
				assert_float(energy.action_minutes(a)).override_failure_message("%s costs more than %s but is quicker" % [a, b]) \
					.is_greater_equal(energy.action_minutes(b))


func test_contact_costs_more_than_being_noticed() -> void:
	var energy: GhostEnergy = _energy()
	assert_float(energy.penalty("peripheral")).is_greater(0.0)
	assert_float(energy.penalty("deep")).is_greater(energy.penalty("peripheral"))


func test_the_ghost_starts_able_to_act_and_the_warning_is_inside_the_pool() -> void:
	var energy: GhostEnergy = _energy()
	assert_bool(energy.is_low()).is_false()
	for key: String in _action_keys():
		assert_bool(energy.can_afford(key)).override_failure_message(key).is_true()

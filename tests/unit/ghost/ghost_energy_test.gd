## The ghost's energy (stage 5d; Demo Specification §8.10, design approved 2026-11-14):
## passive refill, faster hidden and in dark or cold rooms, none while acting or just after,
## action costs, empty energy and detection penalties.
extends GdUnitTestSuite

const Ex := preload("res://tests/unit/fixtures/energy_fixtures.gd")


func test_energy_refills_by_itself_when_not_acting() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(50.0))
	# Act: 10 game minutes in plain view, lit, warm
	energy.regenerate(10.0, false, false, false, false)
	# Assert
	assert_float(energy.value).is_equal_approx(50.0 + Ex.REGEN * 10.0, 0.001)


func test_hiding_refills_faster() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(50.0))
	# Act
	energy.regenerate(10.0, true, false, false, false)
	# Assert
	assert_float(energy.value).is_equal_approx(50.0 + Ex.REGEN * Ex.HIDDEN * 10.0, 0.001)


func test_dark_and_cold_rooms_feed_the_ghost_and_stack() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(0.0))
	# Act / Assert
	assert_float(energy.rate(false, true, false)).is_equal_approx(Ex.REGEN * Ex.DARK, 0.0001)
	assert_float(energy.rate(false, false, true)).is_equal_approx(Ex.REGEN * Ex.COLD, 0.0001)
	assert_float(energy.rate(true, true, true)).is_equal_approx(Ex.REGEN * Ex.HIDDEN * Ex.DARK * Ex.COLD, 0.0001)


func test_energy_never_refills_past_the_maximum() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(Ex.MAX - 1.0))
	# Act
	energy.regenerate(100.0, true, true, true, false)
	# Assert
	assert_float(energy.value).is_equal(Ex.MAX)


func test_no_refill_while_an_action_runs() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(50.0))
	# Act
	energy.regenerate(10.0, true, true, true, true)
	# Assert
	assert_float(energy.value).is_equal(50.0)


func test_no_refill_for_the_pause_after_an_action() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(50.0))
	energy.spend_action("lamp")
	var after: float = 50.0 - Ex.CHEAP_COST
	# Act: the pause, then 2 more minutes
	energy.regenerate(Ex.PAUSE, false, false, false, false)
	var during_pause: float = energy.value
	energy.regenerate(2.0, false, false, false, false)
	# Assert
	assert_float(during_pause).is_equal(after)
	assert_float(energy.value).is_equal_approx(after + Ex.REGEN * 2.0, 0.001)


func test_pause_ends_part_way_through_a_long_frame() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(50.0))
	energy.spend_action("lamp")
	# Act: one step longer than the pause
	energy.regenerate(Ex.PAUSE + 4.0, false, false, false, false)
	# Assert: only the 4 minutes after the pause refill
	assert_float(energy.value).is_equal_approx(50.0 - Ex.CHEAP_COST + Ex.REGEN * 4.0, 0.001)


func test_actions_cost_their_configured_energy() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config())
	# Act
	var paid_lamp: bool = energy.spend_action("lamp")
	var paid_stove: bool = energy.spend_action("basket")
	# Assert: cheap and dear harm differ
	assert_bool(paid_lamp and paid_stove).is_true()
	assert_float(energy.value).is_equal(Ex.MAX - Ex.CHEAP_COST - Ex.DEAR_COST)
	assert_float(energy.action_cost("basket")).is_greater(energy.action_cost("lamp"))
	assert_float(energy.action_minutes("basket")).is_greater(energy.action_minutes("lamp"))


func test_too_little_energy_blocks_an_action_and_spends_nothing() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(Ex.DEAR_COST - 1.0))
	# Act
	var paid: bool = energy.spend_action("basket")
	# Assert
	assert_bool(energy.can_afford("basket")).is_false()
	assert_bool(paid).is_false()
	assert_float(energy.value).is_equal(Ex.DEAR_COST - 1.0)
	assert_float(energy.pause_left()).is_equal(0.0)


func test_at_zero_energy_it_still_refills() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(0.0))
	# Act
	energy.regenerate(4.0, false, false, false, false)
	# Assert
	assert_bool(energy.can_afford("lamp")).is_false()
	assert_float(energy.value).is_greater(0.0)


func test_being_noticed_and_contact_cost_energy_and_contact_costs_more() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config())
	var lost: Array = []
	energy.lost.connect(func(amount: float, reason: String) -> void: lost.append([amount, reason]))
	# Act
	energy.penalize("peripheral")
	energy.penalize("deep")
	# Assert
	assert_float(energy.value).is_equal(Ex.MAX - Ex.PERIPHERAL - Ex.DEEP)
	assert_array(lost).is_equal([[Ex.PERIPHERAL, "peripheral"], [Ex.DEEP, "deep"]])
	assert_float(energy.penalty("deep")).is_greater(energy.penalty("peripheral"))


func test_penalties_never_take_energy_below_zero() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(3.0))
	# Act
	var taken: float = energy.penalize("deep")
	# Assert
	assert_float(taken).is_equal(3.0)
	assert_float(energy.value).is_equal(0.0)


func test_low_warning_fires_once_when_energy_drops_to_the_level() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(Ex.LOW + Ex.CHEAP_COST + 1.0))
	var warnings: Array[int] = [0]
	energy.low_warning.connect(func() -> void: warnings[0] += 1)
	# Act
	energy.spend_action("lamp")   # still above the level
	var after_first: int = warnings[0]
	energy.penalize("peripheral")   # crosses it
	energy.penalize("peripheral")   # already low
	# Assert
	assert_int(after_first).is_equal(0)
	assert_int(warnings[0]).is_equal(1)
	assert_bool(energy.is_low()).is_true()


# --- The energy elixir (sprint 001, phase E, 2026-11-26) ------------------------------------

func test_restoring_adds_energy_up_to_the_maximum() -> void:
	# Arrange
	var energy := GhostEnergy.new(Ex.config(Ex.MAX - 30.0))
	# Act
	var ok: bool = energy.restore(40.0)
	# Assert: clamped, never above the pool
	assert_bool(ok).is_true()
	assert_float(energy.value).is_equal(Ex.MAX)


func test_restoring_when_already_full_is_refused_so_the_elixir_is_not_wasted() -> void:
	var energy := GhostEnergy.new(Ex.config(Ex.MAX))
	assert_bool(energy.restore(40.0)).is_false()
	assert_float(energy.value).is_equal(Ex.MAX)


func test_restoring_nothing_or_a_negative_amount_is_refused() -> void:
	var energy := GhostEnergy.new(Ex.config(10.0))
	assert_bool(energy.restore(0.0)).is_false()
	assert_bool(energy.restore(-5.0)).is_false()
	assert_float(energy.value).is_equal(10.0)


func test_restoring_above_the_low_level_lifts_the_warning() -> void:
	var energy := GhostEnergy.new(Ex.config(1.0))
	assert_bool(energy.is_low()).is_true()
	energy.restore(40.0)
	assert_bool(energy.is_low()).is_false()

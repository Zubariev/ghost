## Ghost stats for the end summary (stage 6, Demo Spec §10.4).
extends GdUnitTestSuite


func test_new_stats_are_all_zero() -> void:
	# Arrange / Act
	var stats := GhostStats.new()
	# Assert
	assert_int(stats.total_actions()).is_equal(0)
	assert_int(stats.noticed).is_equal(0)
	assert_int(stats.caught).is_equal(0)
	assert_int(stats.items_found).is_equal(0)
	assert_int(stats.notes_found).is_equal(0)
	assert_float(stats.energy_spent).is_equal(0.0)


func test_actions_are_counted_by_kind() -> void:
	# Arrange
	var stats := GhostStats.new()
	# Act
	stats.record_action("lamp")
	stats.record_action("lamp")
	stats.record_action("stove")
	# Assert
	assert_int(stats.total_actions()).is_equal(3)
	assert_int(stats.actions_of("lamp")).is_equal(2)
	assert_int(stats.actions_of("stove")).is_equal(1)
	assert_int(stats.actions_of("window")).is_equal(0)


func test_energy_spent_counts_actions_and_energy_lost_counts_being_seen() -> void:
	# Arrange
	var stats := GhostStats.new()
	# Act: an action's cost, then penalties for being noticed and for contact
	stats.record_energy(25.0, "stove")
	stats.record_energy(5.0, "peripheral")
	stats.record_energy(15.0, "deep")
	# Assert
	assert_float(stats.energy_spent).is_equal(25.0)
	assert_float(stats.energy_lost).is_equal(20.0)


func test_finds_split_into_notes_and_items() -> void:
	# Arrange
	var stats := GhostStats.new()
	# Act
	stats.record_find("lore")
	stats.record_find("material")
	stats.record_find("material")
	# Assert
	assert_int(stats.notes_found).is_equal(1)
	assert_int(stats.items_found).is_equal(2)


func test_noticed_and_caught_are_counted_separately() -> void:
	# Arrange
	var stats := GhostStats.new()
	# Act
	stats.record_noticed()
	stats.record_noticed()
	stats.record_caught()
	# Assert
	assert_int(stats.noticed).is_equal(2)
	assert_int(stats.caught).is_equal(1)

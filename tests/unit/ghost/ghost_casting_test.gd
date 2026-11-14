## Harm takes time (stage 5d; Demo Specification §8.10): an action runs for its configured
## minutes, lands only then and is paid only then; cancelling pays nothing; too little
## energy cannot start it. Fixture house objects: a lamp (kind "lamp") and the grocery basket (costed as dear harm).
extends GdUnitTestSuite

const Fx := preload("res://tests/unit/fixtures/sim_fixtures.gd")
const Ex := preload("res://tests/unit/fixtures/energy_fixtures.gd")

var _house: HouseState
var _energy: GhostEnergy
var _casting: GhostCasting
var _events: Array[String] = []


func _setup(start: float = Ex.MAX) -> void:
	_house = Fx.house()
	_energy = GhostEnergy.new(Ex.config(start))
	_casting = GhostCasting.new(_house, _energy)
	_events = []
	_casting.completed.connect(func(id: String) -> void: _events.append("done " + id))
	_casting.failed.connect(func(id: String, why: String) -> void: _events.append("failed %s %s" % [id, why]))
	_casting.cancelled.connect(func(id: String) -> void: _events.append("cancelled " + id))


func test_harm_lands_only_when_its_time_is_up() -> void:
	# Arrange
	_setup()
	# Act
	var why: String = _casting.start("basket")
	_casting.update(Ex.DEAR_MINUTES - 0.5)
	var half_state: StringName = _house.get_object_state("basket")
	var energy_during: float = _energy.value
	_casting.update(0.5)
	# Assert: still working (and nothing paid) until the time is up
	assert_str(why).is_empty()
	assert_str(String(half_state)).is_equal("available")
	assert_float(energy_during).is_equal(Ex.MAX)
	assert_str(String(_house.get_object_state("basket"))).is_equal("hidden")
	assert_float(_energy.value).is_equal(Ex.MAX - Ex.DEAR_COST)
	assert_array(_events).contains_exactly(["done basket"])


func test_costlier_harm_takes_longer() -> void:
	# Arrange
	_setup()
	# Act: the same time on a cheap and a dear action
	_casting.start("bedroom_lamp")
	_casting.update(Ex.CHEAP_MINUTES)
	var lamp_done: bool = _house.get_object_state("bedroom_lamp") == &"out"
	_casting.start("basket")
	_casting.update(Ex.CHEAP_MINUTES)
	# Assert
	assert_bool(lamp_done).is_true()
	assert_bool(_casting.is_casting()).is_true()
	assert_float(_casting.progress()).is_equal_approx(Ex.CHEAP_MINUTES / Ex.DEAR_MINUTES, 0.001)


func test_progress_fills_from_zero_to_one() -> void:
	# Arrange
	_setup()
	_casting.start("basket")
	# Act
	var at_start: float = _casting.progress()
	_casting.update(Ex.DEAR_MINUTES * 0.5)
	# Assert
	assert_float(at_start).is_equal(0.0)
	assert_float(_casting.progress()).is_equal_approx(0.5, 0.001)
	assert_float(_casting.minutes_left()).is_equal_approx(Ex.DEAR_MINUTES * 0.5, 0.001)


func test_cancelling_pays_nothing_and_leaves_the_object() -> void:
	# Arrange
	_setup()
	_casting.start("basket")
	_casting.update(Ex.DEAR_MINUTES - 0.1)
	# Act
	_casting.cancel()
	_casting.update(1.0)
	# Assert
	assert_str(String(_house.get_object_state("basket"))).is_equal("available")
	assert_float(_energy.value).is_equal(Ex.MAX)
	assert_bool(_casting.is_casting()).is_false()
	assert_array(_events).contains_exactly(["cancelled basket"])


func test_too_little_energy_cannot_start_harm() -> void:
	# Arrange
	_setup(Ex.DEAR_COST - 1.0)
	# Act
	var why: String = _casting.start("basket")
	# Assert: cheap harm still possible
	assert_str(why).is_equal(GhostCasting.NOT_ENOUGH_ENERGY)
	assert_bool(_casting.is_casting()).is_false()
	assert_str(_casting.start("bedroom_lamp")).is_empty()


func test_energy_lost_meanwhile_makes_the_harm_fail_unpaid() -> void:
	# Arrange: just enough for the stove, then noticed while acting
	_setup(Ex.DEAR_COST)
	_casting.start("basket")
	_energy.penalize("peripheral")
	# Act
	_casting.update(Ex.DEAR_MINUTES)
	# Assert
	assert_str(String(_house.get_object_state("basket"))).is_equal("available")
	assert_float(_energy.value).is_equal(Ex.DEAR_COST - Ex.PERIPHERAL)
	assert_array(_events).contains_exactly(["failed basket " + GhostCasting.NOT_ENOUGH_ENERGY])


func test_harm_already_done_cannot_start() -> void:
	# Arrange
	_setup()
	GhostActions.act(_house, "basket")
	# Act / Assert
	assert_str(_casting.start("basket")).is_equal(GhostCasting.UNAVAILABLE)


func test_one_action_at_a_time() -> void:
	# Arrange
	_setup()
	_casting.start("basket")
	# Act / Assert
	assert_str(_casting.start("bedroom_lamp")).is_equal(GhostCasting.BUSY)

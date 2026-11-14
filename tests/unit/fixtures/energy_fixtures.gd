## Factory for stage 5d energy tests: energy numbers with the shipped structure. Fixture
## values (round numbers so expected results are easy to read), not tuning.
extends RefCounted

const MAX: float = 100.0
const REGEN: float = 0.5
const HIDDEN: float = 3.0
const DARK: float = 1.5
const COLD: float = 1.25
const PAUSE: float = 5.0
const LOW: float = 20.0
const CHEAP_COST: float = 10.0
const CHEAP_MINUTES: float = 2.0
const DEAR_COST: float = 25.0
const DEAR_MINUTES: float = 5.0
const PERIPHERAL: float = 5.0
const DEEP: float = 15.0


static func config(start: float = MAX) -> Dictionary:
	return {
		"max": MAX, "start": start, "regen_per_minute": REGEN, "hidden_multiplier": HIDDEN,
		"dark_multiplier": DARK, "cold_multiplier": COLD, "pause_after_action_minutes": PAUSE,
		"low_warning": LOW,
		"actions": {
			"lamp": {"cost": CHEAP_COST, "minutes": CHEAP_MINUTES},
			"basket": {"cost": DEAR_COST, "minutes": DEAR_MINUTES},
		},
		"detection_penalty": {"peripheral": PERIPHERAL, "deep": DEEP},
	}

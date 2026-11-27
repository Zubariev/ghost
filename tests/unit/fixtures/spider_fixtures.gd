## Test values for the spider's ecology and web (sprint 002, P2). Independent of the shipped
## spider.json so balance changes do not break the rule tests.
extends RefCounted

const CAL_PER_FLY: float = 10.0
const DECAY_PER_DAY: float = 30.0
const GROWN_AT: float = 100.0
const HOSTILE_AT: float = 180.0
const HOSTILE_DAYS: float = 3.0
const RECOVER_PER_DAY: float = 60.0
const CALM_AT: float = 40.0
const SIZE_MIN: float = 1.0
const SIZE_MAX: float = 1.6

const RANGE_M: float = 5.0
const COOLDOWN_S: float = 6.0
const TELEGRAPH_S: float = 1.2
const SPEED_MPS: float = 4.0
const HIT_RADIUS_M: float = 0.45
const DAMAGE_PCT: float = 10.0
const MAX_HITS_PER_DAY: int = 4


static func ecology() -> Dictionary:
	return {"calories_per_fly": CAL_PER_FLY, "decay_per_day": DECAY_PER_DAY, "grown_at": GROWN_AT,
		"hostile_at": HOSTILE_AT, "hostile_days": HOSTILE_DAYS, "recover_per_day": RECOVER_PER_DAY,
		"calm_at": CALM_AT, "size_min": SIZE_MIN, "size_max": SIZE_MAX}


static func web() -> Dictionary:
	return {"range_m": RANGE_M, "cooldown_seconds": COOLDOWN_S, "telegraph_seconds": TELEGRAPH_S,
		"speed_mps": SPEED_MPS, "hit_radius_m": HIT_RADIUS_M, "damage_pct": DAMAGE_PCT,
		"max_hits_per_day": MAX_HITS_PER_DAY}

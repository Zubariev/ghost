## The hostile attic spider's web attack (sprint 002, P2, task S2-03; user brief C3, C4).
## Logic only: the game draws [member phase], [member target] and [method web_position], and
## drains energy on a hit. Values from [code]spider.json[/code] [code]web[/code].
##
## Fair by construction:
## [br]- READY: after [code]cooldown_seconds[/code], a hostile spider starts an attack on a ghost
##   that is exposed (in the attic, not hidden) within [code]range_m[/code], at most
##   [code]max_hits_per_day[/code] hits per game day.
## [br]- TELEGRAPH: the spot is marked where the ghost is at that moment ([member target]) and the
##   spider winds up for [code]telegraph_seconds[/code]; hiding or the spider calming cancels it.
## [br]- FLIGHT: the web flies to the marked spot at [code]speed_mps[/code]; when it lands it hits
##   only an exposed ghost within [code]hit_radius_m[/code] of it. One web, at most one hit.
## Timing is in real seconds (frames), stopped while the game is paused; positions in metres on
## the attic floor.
class_name SpiderWeb
extends RefCounted

enum Phase { READY, TELEGRAPH, FLIGHT }

var phase: Phase = Phase.READY
## The marked spot (metres) of the current attack.
var target: Vector2 = Vector2.ZERO

var _range: float
var _cooldown_seconds: float
var _telegraph_seconds: float
var _speed: float
var _hit_radius: float
var _damage_pct: float
var _max_hits: int
var _cooldown: float = 0.0
var _timer: float = 0.0
var _from: Vector2 = Vector2.ZERO
var _flown: float = 0.0
var _day: int = -1
var _hits_today: int = 0


func _init(config: Dictionary) -> void:
	_range = float(config.get("range_m", 0.0))
	_cooldown_seconds = float(config.get("cooldown_seconds", 0.0))
	_telegraph_seconds = float(config.get("telegraph_seconds", 0.0))
	_speed = maxf(0.01, float(config.get("speed_mps", 1.0)))
	_hit_radius = float(config.get("hit_radius_m", 0.0))
	_damage_pct = float(config.get("damage_pct", 0.0))
	_max_hits = int(config.get("max_hits_per_day", 0))


## One frame of [param delta] real seconds. [param exposed]: the ghost is in the attic and not
## hidden. Returns true on the frame a web hits the ghost.
func update(delta: float, hostile: bool, exposed: bool, ghost: Vector2, spider: Vector2, day: int) -> bool:
	if day != _day:
		_day = day
		_hits_today = 0
	match phase:
		Phase.READY:
			_cooldown = maxf(0.0, _cooldown - delta)
			if hostile and exposed and _cooldown <= 0.0 and _hits_today < _max_hits \
					and ghost.distance_to(spider) <= _range:
				phase = Phase.TELEGRAPH
				target = ghost
				_from = spider
				_timer = _telegraph_seconds
		Phase.TELEGRAPH:
			if not hostile or not exposed:
				phase = Phase.READY
				return false
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.FLIGHT
				_flown = 0.0
		Phase.FLIGHT:
			_flown += _speed * delta
			if _flown >= _from.distance_to(target):
				phase = Phase.READY
				_cooldown = _cooldown_seconds
				if exposed and ghost.distance_to(target) <= _hit_radius:
					_hits_today += 1
					return true
	return false


## Where the web is in flight (metres); the spider's mouth before it flies.
func web_position() -> Vector2:
	if phase != Phase.FLIGHT:
		return _from
	var length: float = _from.distance_to(target)
	return _from.lerp(target, 1.0 if length <= 0.0 else clampf(_flown / length, 0.0, 1.0))


## How far the web in flight has gone, 0..1 (0 when no web is flying).
func flight_progress() -> float:
	if phase != Phase.FLIGHT:
		return 0.0
	var length: float = _from.distance_to(target)
	return 1.0 if length <= 0.0 else clampf(_flown / length, 0.0, 1.0)


## Energy one hit takes from a ghost with [param max_energy].
func damage_for(max_energy: float) -> float:
	return max_energy * _damage_pct / 100.0


## Hits taken this game day.
func hits_today() -> int:
	return _hits_today

## How the attic spider moves (sprint 002, P4, task S2-05; user brief B3). Logic only, in real
## seconds; [SpiderPose] turns it into a pose and [SpiderArt] draws it. Values from
## [code]spider.json[/code] [code]behaviour[/code].
##
## [br]- Drop (0 = high on its thread, 1 = down near the floor): when the ghost is within
##   [code]react_m[/code] it lowers itself over [code]descend_seconds[/code]; it climbs back the
##   same way once the ghost has been away (or out of sight) for [code]return_delay_seconds[/code].
## [br]- Animation, highest first: "telegraph" (the web's wind-up), "feed" (for
##   [code]feed_seconds[/code] after a trade), "hostile", "idle".
class_name SpiderBehaviour
extends RefCounted

## 0 = at the top of its thread, 1 = lowered as far as it goes.
var drop: float = 0.0

var _react_m: float
var _descend_seconds: float
var _return_delay: float
var _feed_seconds: float
var _wanted: float = 0.0
var _away: float = 0.0
var _feed_left: float = 0.0
var _hostile: bool = false
var _telegraph: bool = false


func _init(config: Dictionary) -> void:
	_react_m = float(config.get("react_m", 0.0))
	_descend_seconds = maxf(0.01, float(config.get("descend_seconds", 1.0)))
	_return_delay = float(config.get("return_delay_seconds", 0.0))
	_feed_seconds = float(config.get("feed_seconds", 0.0))


## One frame: [param distance_m] to the ghost (INF when it is hidden or elsewhere).
func update(delta: float, distance_m: float, hostile: bool, telegraph: bool) -> void:
	_hostile = hostile
	_telegraph = telegraph
	_feed_left = maxf(0.0, _feed_left - delta)
	if distance_m <= _react_m:
		_away = 0.0
		_wanted = 1.0
	else:
		_away += delta
		if _away >= _return_delay:
			_wanted = 0.0
	drop = move_toward(drop, _wanted, delta / _descend_seconds)


## The spider was just fed: it eats for a while.
func feed() -> void:
	_feed_left = _feed_seconds


## True while the spider is still eating after a trade (for [code]feed_seconds[/code]).
func is_feeding() -> bool:
	return _feed_left > 0.0


## "telegraph", "feed", "hostile" or "idle".
func anim() -> String:
	if _telegraph:
		return "telegraph"
	if _feed_left > 0.0:
		return "feed"
	return "hostile" if _hostile else "idle"

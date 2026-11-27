## The attic spider's appetite and mood (sprint 002, P2, task S2-03; user brief track C).
## Flies fed to it in the trade become calories; it burns them slowly by game time and grows with
## them. Overfed, it turns hostile for some game days, then calms and shrinks back to friendly.
## All values come from [code]spider.json[/code] [code]ecology[/code]; logic only, no drawing.
##
## [br]- FRIENDLY and GROWN: burns [code]decay_per_day[/code]; GROWN (from [code]grown_at[/code])
##   is the visible warning; both still take food.
## [br]- HOSTILE: reached at [code]hostile_at[/code] (calories capped there); refuses food, burns
##   nothing, lasts [code]hostile_days[/code].
## [br]- RECOVERING: burns [code]recover_per_day[/code], refuses food, ends as FRIENDLY at or below
##   [code]calm_at[/code].
## [br]- Size: from [code]size_min[/code] at 0 calories to [code]size_max[/code] at
##   [code]hostile_at[/code], linear.
##
## [codeblock]
## var spider := SpiderEcology.new(JsonData.read(SpiderTrade.SPIDER_PATH)["ecology"])
## if spider.accepts_food() and trade.trade(): spider.feed(6)
## spider.advance(game_minutes)
## [/codeblock]
class_name SpiderEcology
extends RefCounted

enum Mood { FRIENDLY, GROWN, HOSTILE, RECOVERING }

## Calories this close to [code]calm_at[/code] count as calm (float rounding over long steps).
const CALM_EPSILON: float = 0.0001

## The mood changed (a [enum Mood] value).
signal mood_changed(mood: int)

var mood: Mood = Mood.FRIENDLY
var calories: float = 0.0

var _per_fly: float
var _decay_per_minute: float
var _grown_at: float
var _hostile_at: float
var _hostile_minutes: float
var _recover_per_minute: float
var _calm_at: float
var _size_min: float
var _size_max: float
var _hostile_left: float = 0.0


func _init(config: Dictionary) -> void:
	var day: float = float(GameClock.MINUTES_PER_DAY)
	_per_fly = float(config.get("calories_per_fly", 0.0))
	_decay_per_minute = float(config.get("decay_per_day", 0.0)) / day
	_grown_at = float(config.get("grown_at", 0.0))
	_hostile_at = maxf(0.001, float(config.get("hostile_at", 1.0)))
	_hostile_minutes = float(config.get("hostile_days", 0.0)) * day
	_recover_per_minute = float(config.get("recover_per_day", 0.0)) / day
	_calm_at = float(config.get("calm_at", 0.0))
	_size_min = float(config.get("size_min", 1.0))
	_size_max = float(config.get("size_max", 1.0))


## True when the spider takes flies (friendly or grown).
func accepts_food() -> bool:
	return mood == Mood.FRIENDLY or mood == Mood.GROWN


## [param flies] eaten; false, and nothing changes, when it refuses food.
func feed(flies: int) -> bool:
	if not accepts_food() or flies <= 0:
		return false
	calories = minf(_hostile_at, calories + float(flies) * _per_fly)
	if calories >= _hostile_at:
		_hostile_left = _hostile_minutes
		_set_mood(Mood.HOSTILE)
	else:
		_set_mood(Mood.GROWN if calories >= _grown_at else Mood.FRIENDLY)
	return true


## Runs [param minutes] of game time (any length: a long step crosses moods exactly).
func advance(minutes: float) -> void:
	var left: float = maxf(0.0, minutes)
	while left > 0.0:
		match mood:
			Mood.HOSTILE:
				var step: float = minf(left, _hostile_left)
				_hostile_left -= step
				left -= step
				if _hostile_left <= 0.0:
					_set_mood(Mood.RECOVERING)
			Mood.RECOVERING:
				if _recover_per_minute <= 0.0:
					return
				var to_calm: float = maxf(0.0, (calories - _calm_at) / _recover_per_minute)
				var step: float = minf(left, to_calm)
				calories = maxf(0.0, calories - step * _recover_per_minute)
				left -= step
				if step >= to_calm or calories <= _calm_at + CALM_EPSILON:
					calories = minf(calories, _calm_at)
					_set_mood(Mood.FRIENDLY)
			_:
				calories = maxf(0.0, calories - left * _decay_per_minute)
				left = 0.0
				_set_mood(Mood.GROWN if calories >= _grown_at else Mood.FRIENDLY)


## Scale of the spider's drawing: [code]size_min[/code] to [code]size_max[/code].
func size() -> float:
	return lerpf(_size_min, _size_max, clampf(calories / _hostile_at, 0.0, 1.0))


## Game minutes of hostility left (0 unless hostile).
func hostile_minutes_left() -> float:
	return _hostile_left if mood == Mood.HOSTILE else 0.0


## The ecology for a save: mood, calories and hostile time left ([method load_state] reads it).
func save_state() -> Dictionary:
	return {"mood": int(mood), "calories": calories, "hostile_left": _hostile_left}


## Restores [method save_state]'s data without emitting signals; an empty dictionary (a save
## from before sprint 002) gives a friendly, hungry spider.
func load_state(data: Dictionary) -> void:
	mood = int(data.get("mood", Mood.FRIENDLY)) as Mood
	calories = clampf(float(data.get("calories", 0.0)), 0.0, _hostile_at)
	_hostile_left = maxf(0.0, float(data.get("hostile_left", 0.0)))


func _set_mood(new_mood: Mood) -> void:
	if new_mood != mood:
		mood = new_mood
		mood_changed.emit(int(mood))

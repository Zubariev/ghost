## Grandpa's monocle (sprint 001, phase G, 2026-11-26; user brief items 12 to 14). Its effect is
## unchanged since stage 5b: while it works, Q shows the family's sight zones. What changed is
## how it is held and used:
##
## [br]- Found once on the grandparents' dresser ([method take_from_dresser]); the first find
##   shows Grandpa's message and the drag hint.
## [br]- Kept in the inventory like any item (kind tool); dragged onto the ghost it is activated
##   ([method activate]) for the data's minutes ([code]loot.json[/code] monocle "use": minutes).
## [br]- When the time is up ([GhostEffects] "monocle" ends) it turns up in a random hiding spot,
##   found again by searching ([method GhostLoot.place_randomly]).
## [br]- There is always exactly one: on the dresser, in the inventory, active, or in one spot.
class_name Monocle
extends RefCounted

const ITEM: String = "monocle"
const EFFECT: String = "monocle"

## It turned up in hiding spot [param spot_id] after its time ran out.
signal hidden_again(spot_id: String)

## Taken from the dresser (the dresser shows it gone; the first-find message has been shown).
var found: bool = false
## True once the first find happened (the message is for that find only).
var first_find_message: bool = false

var _loot: GhostLoot
var _effects: GhostEffects
var _rng: RandomNumberGenerator


func _init(loot: GhostLoot, effects: GhostEffects, rng: RandomNumberGenerator) -> void:
	_loot = loot
	_effects = effects
	_rng = rng
	_effects.ended.connect(_on_effect_ended)


## Takes the monocle off the dresser into the inventory; true only for that first find (false when
## it is already found or the inventory has no slot for it, which leaves it on the dresser).
func take_from_dresser() -> bool:
	if found or _loot.add(ITEM, 1) == 0:
		return false
	found = true
	first_find_message = true
	return true


## Activates the held monocle for [code]params.minutes[/code] game minutes: it leaves the
## inventory while it works. False when it is not held, already working, or has no time.
func activate(params: Dictionary) -> bool:
	var minutes: float = float(params.get("minutes", 0.0))
	if _loot.count(ITEM) <= 0 or _effects.is_active(EFFECT) or minutes <= 0.0:
		return false
	_loot.remove(ITEM, 1)
	_effects.start(EFFECT, minutes)
	return true


func is_active() -> bool:
	return _effects.is_active(EFFECT)


func _on_effect_ended(effect_id: String) -> void:
	if effect_id != EFFECT:
		return
	var spot: String = _loot.place_randomly(ITEM, _rng)
	if not spot.is_empty():
		hidden_again.emit(spot)


func save_state() -> Dictionary:
	return {"found": found}


func load_state(data: Dictionary) -> void:
	found = bool(data.get("found", false))
	first_find_message = found

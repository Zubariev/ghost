## The attic spider (sprint 001, phase F, 2026-11-26; user brief items 8 to 11): it trades the
## flies the ghost has found for spider nests, and a nest dropped on the ghost makes the room it
## is in dirty again. Data: [code]assets/data/ghost/spider.json[/code] (give, get).
##
## [br]- The trade is all or nothing: the price is paid and the nest given together, or nothing
##   moves; paying with the last flies frees their slot for the nest.
## [br]- A nest works through the room's own cleanliness ([method HouseState.set_room_cleanliness]),
##   so the family's usual cleaning tasks take the room on again; no new room state.
##
## [codeblock]
## var spider := SpiderTrade.new(JsonData.read(SpiderTrade.SPIDER_PATH), loot)
## if not spider.trade(): hud.add_log(tr("SPIDER_NEEDS") % spider.missing())
## SpiderTrade.dirty_room(house, "kitchen")
## [/codeblock]
class_name SpiderTrade
extends RefCounted

const SPIDER_PATH: String = "res://assets/data/ghost/spider.json"

## A trade went through.
signal traded()

var _give: Dictionary = {}
var _get: Dictionary = {}
var _loot: GhostLoot


func _init(config: Dictionary, loot: GhostLoot) -> void:
	_give = config.get("give", {})
	_get = config.get("get", {})
	_loot = loot


## What the spider asks for: item -> units.
func price() -> Dictionary:
	return _give.duplicate()


## What it gives: item -> units.
func offer() -> Dictionary:
	return _get.duplicate()


## Units still missing to pay the price (all items together); 0 when the ghost can pay.
func missing() -> int:
	var short: int = 0
	for item: String in _give:
		short += maxi(0, int(_give[item]) - _loot.count(item))
	return short


## True when the ghost can pay and what it gets will fit (counting slots the payment frees).
func can_trade() -> bool:
	if missing() > 0:
		return false
	var freed: int = 0
	for item: String in _give:
		if _loot.uses_slot(item) and _loot.count(item) == int(_give[item]):
			freed += 1
	var needed: int = 0
	for item: String in _get:
		if _loot.uses_slot(item) and not _loot.inventory.has(item):
			needed += 1
	return _loot.slot_items().size() - freed + needed <= _loot.slot_count()


## Pays the price and takes the nests; false, and nothing moves, when it cannot.
func trade() -> bool:
	if not can_trade():
		return false
	for item: String in _give:
		_loot.remove(item, int(_give[item]))
	for item: String in _get:
		_loot.add(item, int(_get[item]))
	traded.emit()
	return true


## A nest in [param room_id]: the room becomes dirty. Refused (false) for an unknown room, one
## that is already dirty, or open air (there is nothing to clean in a yard).
static func dirty_room(house: HouseState, room_id: String) -> bool:
	if not house.rooms.has(room_id):
		return false
	var room: RoomState = house.rooms[room_id]
	if room.outdoor or room.cleanliness == RoomState.Cleanliness.DIRTY:
		return false
	return house.set_room_cleanliness(room_id, RoomState.Cleanliness.DIRTY)

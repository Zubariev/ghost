## Being seen (GDD §6.7, §12.1a; Demo Specification §8.5, §8.8 — approved 2026-11-13).
##
## [br]- Deep zone: full contact at once — −10 morale for that person, a short fright, the
##   ghost back to its start point, and the deep energy penalty.
## [br]- Peripheral zone: registered at once (peripheral energy penalty only). The person
##   finishes the current game minute, is held with the activity's progress kept, turns to the
##   last sighting point and inspects it. Then: contact if the ghost is in view, a search if it
##   is hidden in this room, otherwise release.
## [br]- Search: limited to this room; spots near the sighting first, then random ones with
##   repeats (seeded). Walking counts toward the limit. A walk or check running when time
##   runs out is finished and its result processed. Checking the spot the ghost is in means a
##   fright, then contact. No spots: the search ends at once. Afterwards the incident is
##   forgotten.
## [br]- Someone sitting in or using the spot the ghost hides in finds it: fright, contact.
## [br]- Asleep, Broken, held or already in an incident: no new detections.
## [br]- Energy: the ghost energy system is not built yet; every penalty is still emitted
##   ([signal ghost_energy_penalty]) and recorded in [member energy_ledger], with no effect.
##
## Call [method observe] every frame and [method on_minute] after each simulated minute.
class_name StealthSystem
extends RefCounted

enum Phase { NONE, REACTING, INSPECTING, SEARCH_WALK, SEARCH_CHECK, FRIGHT }

signal ghost_energy_penalty(zone: String, amount: int)
signal noticed(npc_id: String)
signal search_started(npc_id: String)
signal search_ended(npc_id: String)
## [param how]: "deep" (seen up close), "found" (spot checked) or "used" (spot sat in).
signal contact(npc_id: String, how: String)
signal ghost_returned()

## The hiding spot the ghost is in, or "".
var hidden_in: String = ""
var hidden_room: String = ""
## Every energy penalty so far: {zone, amount, minute}. Read by the energy system once built.
var energy_ledger: Array[Dictionary] = []
var energy_spent: int = 0

var _cfg: Dictionary
var _house: HouseState
var _routines: Array[NpcRoutine]
var _morale: MoraleSystem
var _layout: RoomLayout
var _nav: GhostNavigator
var _start_room: String
var _start_uv: Vector2
var _incidents: Dictionary[String, Dictionary] = {}
var _rng := RandomNumberGenerator.new()
var _minute: int = 0


func _init(config: Dictionary, house: HouseState, routines: Array[NpcRoutine], morale: MoraleSystem,
		layout: RoomLayout, navigator: GhostNavigator, start_room: String, start_uv: Vector2) -> void:
	_cfg = config
	_house = house
	_routines = routines
	_morale = morale
	_layout = layout
	_nav = navigator
	_start_room = start_room
	_start_uv = start_uv
	_rng.seed = int(config.get("seed", 1))
	for routine: NpcRoutine in routines:
		_incidents[routine.schedule.npc_id] = _empty()
		routine.activity_started.connect(_on_activity_started.bind(routine))


func phase_of(npc_id: String) -> Phase:
	return _incidents[npc_id]["phase"]


## Where the person looks during an incident (toward the last sighting or the spot being
## searched), or Vector2.ZERO when not in one. For the view.
func incident_focus(npc_id: String) -> Vector2:
	var incident: Dictionary = _incidents[npc_id]
	match int(incident["phase"]):
		Phase.SEARCH_WALK, Phase.SEARCH_CHECK:
			return incident["spot_uv"]
		Phase.NONE:
			return Vector2.ZERO
	return incident["last_seen"]


## True when this person can notice the ghost right now.
func can_notice(routine: NpcRoutine) -> bool:
	if routine.is_broken() or routine.is_held():
		return false
	if phase_of(routine.schedule.npc_id) != Phase.NONE:
		return false
	return not is_sleeping(routine)


static func is_sleeping(routine: NpcRoutine) -> bool:
	return routine.state == NpcRoutine.State.PERFORMING and routine.current != null and routine.current.animation == "sleep"


## Search length: base × (1 + anxiety × (100 − morale) / 100), at least one minute.
func search_minutes_for(npc_id: String) -> int:
	var routine: NpcRoutine = _routine(npc_id)
	var morale: float = float(_morale.get_morale(npc_id))
	var base: float = float(_cfg.get("search_base_minutes", 10))
	return maxi(1, roundi(base * (1.0 + routine.schedule.anxiety * (100.0 - morale) / 100.0)))


## Hides the ghost in a spot in its room. Refused when the spot is not there or someone is
## using it right now.
func hide(spot_id: String) -> bool:
	for spot: Dictionary in _layout.hiding_spots(_nav.room_id):
		if String(spot["id"]) != spot_id:
			continue
		for routine: NpcRoutine in _routines:
			if routine.room_id == _nav.room_id and routine.state == NpcRoutine.State.PERFORMING \
					and routine.current != null and routine.current.target_object_id == spot_id:
				return false
		hidden_in = spot_id
		hidden_room = _nav.room_id
		_nav.place(_nav.room_id, spot["uv"])
		return true
	return false


func unhide() -> void:
	hidden_in = ""
	hidden_room = ""


## Checks every person who could see the ghost; call every frame.
func observe() -> void:
	if not hidden_in.is_empty():
		return
	var room_id: String = _nav.room_id
	for i: int in _routines.size():
		var routine: NpcRoutine = _routines[i]
		if not can_notice(routine):
			continue
		var where: Dictionary = _layout.person(routine, i, room_id, _routines)
		if where.is_empty():
			continue
		match RoomLayout.sight_zone(where["uv"], where["facing"], _nav.uv, _cfg, _layout.occluders(room_id)):
			RoomLayout.Zone.DEEP:
				_contact(routine, "deep")
				return
			RoomLayout.Zone.PERIPHERAL:
				_notice(routine, _nav.uv, room_id)


## Advances every incident by the game minute [param minute_of_day] just spent.
func on_minute(minute_of_day: int) -> void:
	_minute = minute_of_day
	for routine: NpcRoutine in _routines:
		var npc_id: String = routine.schedule.npc_id
		var incident: Dictionary = _incidents[npc_id]
		match int(incident["phase"]):
			Phase.REACTING:
				# The current minute (the atomic segment) is over: suspend and inspect.
				if routine.hold():
					incident["phase"] = Phase.INSPECTING
					incident["left"] = int(_cfg.get("inspect_minutes", 1))
				else:
					_incidents[npc_id] = _empty()
			Phase.INSPECTING:
				incident["left"] = int(incident["left"]) - 1
				if int(incident["left"]) <= 0:
					_decide(routine)
			Phase.SEARCH_WALK:
				incident["search_left"] = int(incident["search_left"]) - 1
				incident["left"] = int(incident["left"]) - 1
				if int(incident["left"]) <= 0:
					if int(incident["search_left"]) <= 0:
						_end_search(routine)
					else:
						_start_check(routine)
			Phase.SEARCH_CHECK:
				incident["search_left"] = int(incident["search_left"]) - 1
				incident["left"] = int(incident["left"]) - 1
				if int(incident["left"]) <= 0:
					if int(incident["search_left"]) <= 0:
						_end_search(routine)
					else:
						_next_spot(routine)
			Phase.FRIGHT:
				incident["left"] = int(incident["left"]) - 1
				if int(incident["left"]) <= 0:
					_finish(routine)


## Starts searching [param room_id]'s hiding spots for [param npc_id], nearest to
## [param last_seen] first. Public for tests; normally started by an inspection.
func begin_search(npc_id: String, room_id: String, last_seen: Vector2) -> void:
	var routine: NpcRoutine = _routine(npc_id)
	var incident: Dictionary = _incidents[npc_id]
	incident["room"] = room_id
	incident["last_seen"] = last_seen
	var spots: Array[Dictionary] = _layout.hiding_spots(room_id)
	if spots.is_empty():
		_finish(routine)
		return
	var radius: float = float(_cfg.get("nearby_spot_radius", 0.35))
	var nearby: Array[Dictionary] = []
	for spot: Dictionary in spots:
		if Vector2(spot["uv"]).distance_to(last_seen) <= radius:
			nearby.append(spot)
	nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(a["uv"]).distance_to(last_seen) < Vector2(b["uv"]).distance_to(last_seen))
	incident["queue"] = nearby
	incident["spots"] = spots
	incident["search_left"] = search_minutes_for(npc_id)
	search_started.emit(npc_id)
	_next_spot(routine)


func _decide(routine: NpcRoutine) -> void:
	var npc_id: String = routine.schedule.npc_id
	var incident: Dictionary = _incidents[npc_id]
	var room_id: String = String(incident["room"])
	if hidden_in.is_empty() and _nav.room_id == room_id:
		var index: int = _routines.find(routine)
		var where: Dictionary = _layout.person(routine, index, room_id, _routines)
		if not where.is_empty():
			var look: Vector2 = Vector2(incident["last_seen"]) - Vector2(where["uv"])
			if look.length() < 0.0001:
				look = where["facing"]
			if RoomLayout.sight_zone(where["uv"], look, _nav.uv, _cfg, _layout.occluders(room_id)) != RoomLayout.Zone.NONE:
				_contact(routine, "deep")
				return
	if not hidden_in.is_empty() and hidden_room == room_id:
		begin_search(npc_id, room_id, incident["last_seen"])
		return
	_finish(routine)


func _next_spot(routine: NpcRoutine) -> void:
	var incident: Dictionary = _incidents[routine.schedule.npc_id]
	var queue: Array = incident["queue"]
	var spot: Dictionary
	if not queue.is_empty():
		spot = queue.pop_front()
	else:
		var spots: Array = incident["spots"]
		spot = spots[_rng.randi_range(0, spots.size() - 1)]
	incident["spot"] = String(spot["id"])
	incident["spot_uv"] = spot["uv"]
	incident["phase"] = Phase.SEARCH_WALK
	incident["left"] = int(_cfg.get("search_walk_minutes", 1))


func _start_check(routine: NpcRoutine) -> void:
	var incident: Dictionary = _incidents[routine.schedule.npc_id]
	incident["phase"] = Phase.SEARCH_CHECK
	incident["left"] = int(_cfg.get("check_minutes", 2))
	if hidden_in == String(incident["spot"]) and hidden_room == String(incident["room"]):
		_contact(routine, "found")


func _end_search(routine: NpcRoutine) -> void:
	search_ended.emit(routine.schedule.npc_id)
	_finish(routine)


## Ends the incident: forgotten, and the person returns to their current schedule.
func _finish(routine: NpcRoutine) -> void:
	_incidents[routine.schedule.npc_id] = _empty()
	if routine.is_held():
		routine.release((_minute + 1) % GameClock.MINUTES_PER_DAY)


func _notice(routine: NpcRoutine, at: Vector2, room_id: String) -> void:
	var incident: Dictionary = _incidents[routine.schedule.npc_id]
	incident["phase"] = Phase.REACTING
	incident["last_seen"] = at
	incident["room"] = room_id
	_spend("peripheral")
	noticed.emit(routine.schedule.npc_id)


func _contact(routine: NpcRoutine, how: String) -> void:
	var npc_id: String = routine.schedule.npc_id
	_spend("deep")
	contact.emit(npc_id, how)
	_respawn()
	var incident: Dictionary = _incidents[npc_id]
	incident["phase"] = Phase.FRIGHT
	incident["left"] = int(_cfg.get("fright_minutes", 1))
	if not routine.is_held():
		routine.hold()
	_morale.apply_penalty(npc_id, int(_cfg.get("contact_morale_penalty", 10)), "contact")
	if routine.is_broken():
		_incidents[npc_id] = _empty()


func _on_activity_started(activity: Activity, routine: NpcRoutine) -> void:
	if hidden_in.is_empty() or routine.is_broken():
		return
	if activity.target_object_id == hidden_in and routine.room_id == hidden_room:
		_contact(routine, "used")


func _respawn() -> void:
	unhide()
	_nav.place(_start_room, _start_uv)
	ghost_returned.emit()


func _spend(zone: String) -> void:
	var amount: int = int(_cfg.get("energy_penalty", {}).get(zone, 0))
	energy_ledger.append({"zone": zone, "amount": amount, "minute": _minute})
	energy_spent += amount
	ghost_energy_penalty.emit(zone, amount)


func _routine(npc_id: String) -> NpcRoutine:
	for routine: NpcRoutine in _routines:
		if routine.schedule.npc_id == npc_id:
			return routine
	return null


static func _empty() -> Dictionary:
	return {"phase": Phase.NONE, "left": 0, "last_seen": Vector2.ZERO, "room": "", "search_left": 0,
		"spot": "", "spot_uv": Vector2.ZERO, "queue": [], "spots": []}

## How worn a room looks (art Phase 2, 2026-11-15; docs/art/environments/ENVIRONMENT_GUIDELINES.md
## §4): dirt (dull surfaces, dust and stains, cobwebs, dust motes in the light), polish on a
## clean room, breath in a cold room, embers dying after the fire goes out. Presentation only:
## it reads room state and never changes it. Numbers: `assets/art/visual_style.json` → `wear`.
##
## [codeblock]
## var wear := RoomWear.new(JsonData.read(PropVisuals.STYLE_PATH).get("wear", {}))
## shown_dirt = wear.ease(shown_dirt, RoomWear.dirt_target(room), delta)
## [/codeblock]
class_name RoomWear
extends RefCounted

var _fade: float
var _patches: int
var _door_clear: float
var _margin: float
var _ember_seconds: float
var _breath_period: float
var _breath_alpha: float
var _motes: int


func _init(config: Dictionary) -> void:
	_fade = float(config.get("fade_per_second", 1.0))
	_patches = int(config.get("dust_patches", 7))
	_door_clear = float(config.get("door_clear", 0.14))
	_margin = float(config.get("floor_margin", 0.05))
	_ember_seconds = float(config.get("ember_seconds", 25.0))
	_breath_period = float(config.get("breath_period", 3.5))
	_breath_alpha = float(config.get("breath_alpha", 0.45))
	_motes = int(config.get("motes", 12))


## 1 for a dirty room, else 0.
static func dirt_target(room: RoomState) -> float:
	return 1.0 if room.cleanliness == RoomState.Cleanliness.DIRTY else 0.0


## 1 for a clean (polished) room, else 0; a normal room shows neither dirt nor polish.
static func polish_target(room: RoomState) -> float:
	return 1.0 if room.cleanliness == RoomState.Cleanliness.CLEAN else 0.0


## 1 for a cold room (breath shows), else 0.
static func cold_target(room: RoomState) -> float:
	return 1.0 if room.temperature == RoomState.Temperature.COLD else 0.0


## Moves [param shown] toward [param target] at the configured rate over [param delta] seconds.
func ease(shown: float, target: float, delta: float) -> float:
	return move_toward(shown, target, _fade * delta)


## Dust patches and stains for [param room_id]: (u, v, size 0..1), always the same for a room,
## inside the floor margin and at least door_clear away from every door in [param doors].
func dust_patches(room_id: String, doors: Array[Vector2]) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room_id)
	var out: Array[Vector3] = []
	var tries: int = 0
	while out.size() < _patches and tries < _patches * 40:
		tries += 1
		var at := Vector2(rng.randf_range(_margin, 1.0 - _margin), rng.randf_range(_margin, 1.0 - _margin))
		var clear: bool = true
		for door: Vector2 in doors:
			if at.distance_to(door) < _door_clear:
				clear = false
				break
		var size: float = rng.randf_range(0.4, 1.0)
		if clear:
			out.append(Vector3(at.x, at.y, size))
	return out


## Ember glow 1..0 [param seconds] after the fire went out; 0 when never seen burning (< 0).
func ember_glow(seconds: float) -> float:
	if seconds < 0.0 or _ember_seconds <= 0.0:
		return 0.0
	return clampf(1.0 - seconds / _ember_seconds, 0.0, 1.0)


## Opacity of person [param index]'s breath puff at [param time]: a short puff each period,
## people out of step with one another.
func breath_alpha(time: float, index: int) -> float:
	var phase: float = fposmod(time / _breath_period + float(index) * 0.37, 1.0)
	if phase > 0.4:
		return 0.0
	return sin(phase / 0.4 * PI) * _breath_alpha


## Where the dust motes in one light are at [param time]: offsets in -1..1 (scaled to the
## light by the caller), slowly drifting; [param seed] separates lights.
func mote_offsets(time: float, seed: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i: int in _motes:
		var k: float = seed * 13.1 + float(i) * 2.17
		var x: float = sin(time * (0.11 + 0.05 * fposmod(k, 1.0)) + k * 1.7)
		var y: float = sin(time * (0.07 + 0.04 * fposmod(k * 0.7, 1.0)) + k * 2.3)
		out.append(Vector2(x, y))
	return out

## The ghost's visual state machine (Phase 3, 2026-11-21; docs/art/characters/GHOST.md §7). It only
## reads what the game already decides — how the ghost actually moved this frame (from the
## navigator's floor position), whether he is hidden, whether a harm is being cast and toward
## what, and the moments he is noticed or caught — and picks a clip of his [CharacterRig]. It never
## changes gameplay: no speed, energy, detection or hiding rule reads it.
##
## The ghost never walks: he always floats, legs hanging, boots limp. On top of each clip the
## animator adds secondary motion from his real speed: the body leans into the drift, the legs and
## arms trail behind on a soft, slightly under-damped spring, so a stop lets them swing on and
## settle instead of freezing. Clip changes blend over [constant BLEND] s; a change of view (front,
## side, back) narrows and widens the figure ([constant TURN] s) instead of snapping.
##
## State table (first match wins):
##   fright:  caught or noticed (a timed event)        → "fright" (front)
##   reach:   a harm is being cast                     → "reach_side" / "reach_front" / "reach_back"
##                                                       by the direction to the object
##   glide:   drifting faster than [constant MOVE_MIN] → "glide_side" / "glide_front" / "glide_back"
##                                                       by the direction of drift
##   float:   anything else                           → "float_<last view>"; after [constant FACE_FRONT_AFTER]
##                                                       s still he turns to face the room ("float_front")
## Hiding is a fade, not a clip: [method presence] eases to 0 when he hides (he shrinks a little and
## sinks into the spot) and back to 1 when he comes out.
##
## [codeblock]
## var anim := GhostAnimator.new(CharacterRig.load_for("ghost"))
## anim.update(delta, {"velocity": metres_per_second, "hidden": false, "casting": false})
## var pose: Dictionary = anim.current_pose()
## [/codeblock]
class_name GhostAnimator
extends RefCounted

const BLEND: float = 0.4
const TURN: float = 0.22
## Drift (m/s, smoothed) above which he glides rather than hovers.
const MOVE_MIN: float = 0.18
## A facing counts as sideways when its sideways share is at least this.
const SIDEWAYS: float = 0.55
## Seconds of hovering before he turns to face the room.
const FACE_FRONT_AFTER: float = 2.2
## How long a fright plays: caught (contact) and noticed (a glimpse).
const FRIGHT_CAUGHT: float = 1.6
const FRIGHT_NOTICED: float = 0.7
## Hiding fade: seconds to vanish into a spot and to come out of it.
const HIDE_SECONDS: float = 0.35
const EMERGE_SECONDS: float = 0.45
## A jump longer than this in one frame (metres) is a teleport (respawn, a new room): no motion.
const TELEPORT_M: float = 0.6
## Velocity smoothing (1/s): the drift the animation follows eases toward the real one.
const DRIFT_EASE: float = 6.0
## Secondary motion (degrees per m/s of sideways drift on screen, and limits).
const LEAN_PER_MPS: float = 4.5
const LEAN_MAX: float = 9.0
const TRAIL_PER_MPS: float = 7.0
const TRAIL_MAX: float = 20.0
## Spring for the trailing legs: stiffness and damping (under-damped: a little swing on a stop).
const TRAIL_K: float = 26.0
const TRAIL_C: float = 5.5
const LEAN_K: float = 40.0
const LEAN_C: float = 11.0

var rig: CharacterRig
var clip: String = ""
var view: String = "front"
var flip: bool = false
## Smoothed drift on the floor, metres per second (x: right, y: toward the camera).
var drift: Vector2 = Vector2.ZERO
## Secondary motion state (screen sense: + leans / trails as when drifting right).
var lean: float = 0.0
var trail: float = 0.0
var _lean_v: float = 0.0
var _trail_v: float = 0.0
var _time: float = 0.0
var _still: float = 0.0
var _last_dir: String = "toward"
var _fright_left: float = 0.0
var _presence: float = 1.0
var _from_pose: Dictionary = {}
var _blend_left: float = 0.0
var _turn_left: float = 0.0


func _init(ghost_rig: CharacterRig) -> void:
	rig = ghost_rig


## A fright: [param caught] (contact: the full jolt) or only noticed (a short start).
func startle(caught: bool) -> void:
	_fright_left = maxf(_fright_left, FRIGHT_CAUGHT if caught else FRIGHT_NOTICED)


## 1 when fully shown, 0 when hidden; eased through hiding and emerging.
func presence() -> float:
	return _presence


## The clip and whether it is mirrored for this moment (pure: see the state table above).
## [param state]: {casting: bool, target: Vector2 (metres to the object, x right, y toward the camera),
## frightened: bool, drift: Vector2 (m/s), still: float (seconds hovering), last_dir: String}.
func choose(state: Dictionary) -> Array:
	if bool(state.get("frightened", false)) and rig.has_clip("fright"):
		return ["fright", false]
	if bool(state.get("casting", false)):
		var to: String = direction(state.get("target", Vector2(0, 1)))
		return [_by_direction("reach", to), to == "left"]
	var moving: Vector2 = state.get("drift", Vector2.ZERO)
	if moving.length() > MOVE_MIN:
		var dir: String = direction(moving)
		return [_by_direction("glide", dir), dir == "left"]
	var last: String = String(state.get("last_dir", "toward"))
	if float(state.get("still", 0.0)) >= FACE_FRONT_AFTER:
		last = "toward"
	return [_by_direction("float", last), last == "left"]


## Advances by [param delta] real seconds. [param state]: {velocity: Vector2 (m/s on the floor, this
## frame's real move), hidden, casting, target}.
func update(delta: float, state: Dictionary) -> void:
	_time += delta
	var velocity: Vector2 = state.get("velocity", Vector2.ZERO)
	if velocity.length() * delta > TELEPORT_M:
		velocity = Vector2.ZERO
		drift = Vector2.ZERO
	drift = drift.lerp(velocity, 1.0 - exp(-DRIFT_EASE * delta))
	if drift.length() > MOVE_MIN:
		_last_dir = direction(drift)
		_still = 0.0
	else:
		_still += delta
	_fright_left = maxf(0.0, _fright_left - delta)
	var hidden: bool = bool(state.get("hidden", false))
	var rate: float = (1.0 / HIDE_SECONDS) if hidden else (1.0 / EMERGE_SECONDS)
	_presence = move_toward(_presence, 0.0 if hidden else 1.0, rate * delta)
	_spring(delta)
	var choice: Array = choose({"casting": state.get("casting", false), "target": state.get("target", Vector2(0, 1)),
		"frightened": _fright_left > 0.0, "drift": drift, "still": _still, "last_dir": _last_dir})
	var next: String = choice[0]
	var next_flip: bool = choice[1]
	if next != clip or next_flip != flip:
		var next_view: String = rig.clip_view(next)
		if clip.is_empty():
			_blend_left = 0.0
		elif next_view != view or next_flip != flip:
			_turn_left = TURN
			_blend_left = 0.0
		else:
			_from_pose = current_pose()
			_blend_left = BLEND
		var keep_phase: bool = not clip.is_empty() and clip.get_slice("_", 0) == next.get_slice("_", 0)
		clip = next
		flip = next_flip
		view = next_view
		if not keep_phase:
			_time = 0.0   # a new kind of motion starts at its beginning; a turn keeps the bob's phase
	_blend_left = maxf(0.0, _blend_left - delta)
	_turn_left = maxf(0.0, _turn_left - delta)


## The pose being shown: the clip (blended while a change settles) plus lean and trailing.
func current_pose() -> Dictionary:
	if clip.is_empty():
		return {}
	var pose: Dictionary = rig.sample(clip, _time)
	if _blend_left > 0.0 and not _from_pose.is_empty():
		pose = CharacterRig.blend(_from_pose, pose, 1.0 - _blend_left / BLEND)
	return _with_secondary(pose)


## How wide the figure is drawn (narrower through a turn between views).
func squeeze() -> float:
	if _turn_left <= 0.0:
		return 1.0
	return lerpf(0.6, 1.0, 1.0 - _turn_left / TURN)


## "left" / "right" when [param m] (metres, x right, y toward the camera) is mostly sideways,
## else "toward" (the camera) or "away".
static func direction(m: Vector2) -> String:
	if m.length() < 0.0001:
		return "toward"
	var n: Vector2 = m.normalized()
	if absf(n.x) >= SIDEWAYS:
		return "left" if n.x < 0.0 else "right"
	return "toward" if n.y > 0.0 else "away"


# Lean and trail follow the sideways drift on screen through springs: lean quickly and well
# damped, the legs slower and a little under-damped, so they lag behind a start and swing on
# after a stop.
func _spring(delta: float) -> void:
	var lean_target: float = clampf(drift.x * LEAN_PER_MPS, -LEAN_MAX, LEAN_MAX)
	var trail_target: float = clampf(drift.x * TRAIL_PER_MPS, -TRAIL_MAX, TRAIL_MAX)
	var steps: int = maxi(1, ceili(delta / 0.01))
	var h: float = delta / float(steps)
	for i: int in steps:
		_lean_v += (LEAN_K * (lean_target - lean) - LEAN_C * _lean_v) * h
		lean += _lean_v * h
		_trail_v += (TRAIL_K * (trail_target - trail) - TRAIL_C * _trail_v) * h
		trail += _trail_v * h


# Adds lean and trailing to [param pose] in the rig's own sense: the side view is painted facing
# right, so a mirrored figure takes the opposite sign. Toward or away from the camera the legs
# trail into depth: a little shorter.
func _with_secondary(pose: Dictionary) -> Dictionary:
	var sign_x: float = -1.0 if flip else 1.0
	var l: float = lean * sign_x
	var t: float = trail * sign_x
	var depth: float = clampf(absf(drift.y) / 1.75, 0.0, 1.0)
	var out: Dictionary = pose.duplicate()
	out["body"] = _add(out.get("body", []), l, 0.0)
	out["head"] = _add(out.get("head", []), -l * 0.45, 0.0)
	for part: String in ["arm", "arm_l", "arm_r"]:
		if rig.views.get(view, {}).get("parts", {}).has(part):
			out[part] = _add(out.get(part, []), t * 0.45, 0.0)
	for part: String in ["legs", "leg_l", "leg_r"]:
		if rig.views.get(view, {}).get("parts", {}).has(part):
			out[part] = _add(out.get(part, []), t, -0.05 * depth)
	return out


static func _add(p: Array, rot: float, sy: float) -> Array:
	var base: Array = p if p.size() >= 4 else [p[0] if p.size() > 0 else 0.0, p[1] if p.size() > 1 else 0.0,
		p[2] if p.size() > 2 else 0.0, 1.0]
	return [float(base[0]) + rot, float(base[1]), float(base[2]), float(base[3]) + sy]


func _by_direction(prefix: String, dir: String) -> String:
	var name: String = prefix + ("_side" if dir == "left" or dir == "right" else ("_front" if dir == "toward" else "_back"))
	return name if rig.has_clip(name) else prefix + "_front"

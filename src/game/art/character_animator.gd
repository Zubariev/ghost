## The visual state machine of one painted family member (character pipeline pilot, 2026-11-20).
## It only reads what the game already decides — the pose from FamilyMotion (walk, stand, sit,
## sleep, broken), the schedule's activity animation, the stealth marker ("?" noticing or
## searching, "!" fright), the facing direction and the floor position — and picks a clip of the
## character's [CharacterRig]; it never changes gameplay. Clip changes blend over BLEND seconds;
## switching between views (front, side, back, sit) narrows the figure and widens it again
## (a turn) instead of snapping. The walk cycle advances by the metres actually walked, so the
## feet keep pace with the floor whatever the walking speed.
##
## State table (state: chosen when → clip):
##   fright:  marker "!"                          → "fright" (front)
##   anxious: marker "?"                          → "anxious" (front)
##   broken:  pose "broken"                       → "slump" (front)
##   sit:     pose "sit", eating, seat faces sideways (a table end) → "sit_side" (painted profile,
##            mirrored for left; by the seat's direction, not a glance)
##   sit:     pose "sit" at the computer or eating, the seat facing away (a desk, the near side of the
##            table) → "sit_back" (resting in an armchair faces the chair but keeps the front pose)
##   sit:     pose "sit" otherwise                → "sit" (painted seated view, facing the camera)
##   sleep:   pose "sleep"                        → drawn by the code on the bed (not rigged yet)
##   walk:    pose "walk"                         → "walk_side" / "walk_front" / "walk_back" by facing
##   <activity>: standing in an activity with a clip of that name (e.g. "cook"; a board task is
##            "repair" or "clean") → that clip
##   idle:    anything else                       → "idle_front" / "idle_side" / "idle_back" by facing
##
## [codeblock]
## var anim := CharacterAnimator.new(rig, 0.55)
## anim.update(delta, {"pose": "walk", "uv": uv, "facing": facing, "room_size": size})
## anim.draw(canvas, foot, RoomGeometry.scale_at(uv.y))
## [/codeblock]
class_name CharacterAnimator
extends RefCounted

const BLEND: float = 0.25
const TURN: float = 0.16
## A facing counts as sideways when its sideways share (in metres) is at least this.
const SIDEWAYS: float = 0.55
## A seat counts as a table end (eat side-on) when its sideways share is at least this.
const TABLE_END: float = 0.85

var rig: CharacterRig
## Metres covered by one full walk cycle (two steps).
var stride_m: float = 1.1
var clip: String = ""
var view: String = "front"
var flip: bool = false
var _time: float = 0.0
var _walk_phase: float = 0.0
var _from_pose: Dictionary = {}
var _blend_left: float = 0.0
var _turn_left: float = 0.0
var _last_uv := Vector2(-99, -99)


func _init(character_rig: CharacterRig, stride: float = 1.1) -> void:
	rig = character_rig
	stride_m = stride


## The clip and view for this moment of the game (pure: see the state table above).
## [param state]: {pose, activity?, marker?, facing (floor units, includes glances), seat_facing (where
## the place itself faces, toward the object in use), room_size (metres)}.
func choose(state: Dictionary) -> Array:
	var pose: String = String(state.get("pose", "stand"))
	var marker: String = String(state.get("marker", ""))
	var dir: String = _direction(state.get("facing", Vector2(0, 1)), state.get("room_size", Vector2.ONE))
	if marker == "!" and rig.has_clip("fright"):
		return ["fright", false]
	if marker == "?" and rig.has_clip("anxious"):
		return ["anxious", false]
	if pose == "broken" and rig.has_clip("slump"):
		return ["slump", false]
	var activity: String = String(state.get("activity", ""))
	if pose == "sit" and (activity == "computer" or activity == "eat") and rig.has_clip("sit_back"):
		# seated facing away from the camera (at the computer desk, in front of the dining table)
		# any seat turned toward the back of the room (the desk, the table behind) — also when it is
		# off to one side (2026-11-20: his place at the desk faces up and to the left)
		var sm: Vector2 = Vector2(state.get("seat_facing", Vector2(0, 1))) * Vector2(state.get("room_size", Vector2.ONE))
		if sm.y < 0.0 and absf(sm.normalized().x) < TABLE_END:
			return ["sit_back", false]
	if pose == "sit" and activity == "eat" and rig.has_clip("sit_side"):
		# eating at a table end, turned toward the table: by where her seat faces, never by a glance
		# only a seat at a table end faces it squarely sideways; a place behind the table, even off to
		# one side, faces the camera (2026-11-20: the father behind the table was shown side-on)
		var sm: Vector2 = Vector2(state.get("seat_facing", Vector2(0, 1))) * Vector2(state.get("room_size", Vector2.ONE))
		var seat: String = ("left" if sm.x < 0.0 else "right") if sm.length() > 0.0001 and absf(sm.normalized().x) >= TABLE_END else ""
		if seat == "left" or seat == "right":
			return ["sit_side", seat == "left"]
	if pose == "sit" and rig.has_clip("sit"):
		return ["sit", false]
	if pose == "walk":
		return [_by_direction("walk", dir), dir == "left"]
	if not activity.is_empty() and rig.has_clip(activity):
		return [activity, false]
	return [_by_direction("idle", dir), dir == "left"]


## Advances by [param delta] real seconds for this frame's game [param state] (also needs "uv").
func update(delta: float, state: Dictionary) -> void:
	_time += delta
	var uv: Vector2 = state.get("uv", Vector2.ZERO)
	if _last_uv.x > -90.0 and String(state.get("pose", "")) == "walk":
		var size: Vector2 = state.get("room_size", Vector2.ONE)
		_walk_phase += ((uv - _last_uv) * size).length() / maxf(0.1, stride_m)
	_last_uv = uv
	var choice: Array = choose(state)
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
		clip = next
		flip = next_flip
		view = next_view
		if not clip.begins_with("walk"):
			_time = 0.0
	_blend_left = maxf(0.0, _blend_left - delta)
	_turn_left = maxf(0.0, _turn_left - delta)


## The pose being shown (blended while a clip change settles).
func current_pose() -> Dictionary:
	if clip.is_empty():
		return {}
	var t: float = _walk_phase * rig.clip_length(clip) if clip.begins_with("walk") else _time
	var pose: Dictionary = rig.sample(clip, t)
	if _blend_left > 0.0 and not _from_pose.is_empty():
		pose = CharacterRig.blend(_from_pose, pose, 1.0 - _blend_left / BLEND)
	return pose


## How wide the figure is drawn (narrower through a turn between views).
func squeeze() -> float:
	if _turn_left <= 0.0:
		return 1.0
	return lerpf(0.55, 1.0, 1.0 - _turn_left / TURN)


func draw(canvas: CanvasItem, foot: Vector2, s: float, tint: Color = Color.WHITE) -> void:
	rig.draw(canvas, view, current_pose(), foot, s, flip, squeeze(), tint)


## Screen point of the head (floats, breath).
func head_point(foot: Vector2, s: float) -> Vector2:
	return rig.part_point(view, current_pose(), "head" if view != "sit" else "body", foot, s, flip) + Vector2(0, -6.0 * s)


# "left" / "right" when the facing is mostly sideways in metres, else "toward" (the camera) or "away".
static func _direction(facing: Vector2, room_size: Vector2) -> String:
	var m: Vector2 = facing * room_size
	if m.length() < 0.0001:
		return "toward"
	m = m.normalized()
	if absf(m.x) >= SIDEWAYS:
		return "left" if m.x < 0.0 else "right"
	return "toward" if m.y > 0.0 else "away"


func _by_direction(prefix: String, dir: String) -> String:
	var name: String = prefix + ("_side" if dir == "left" or dir == "right" else ("_front" if dir == "toward" else "_back"))
	return name if rig.has_clip(name) else prefix + "_front"

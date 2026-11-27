## The attic spider's rig (sprint 002, P4, task S2-05; user brief B2): where each part is at one
## moment. Pure; pixels at depth 1 from the spider piece's floor point (y up is negative).
## Parts: the thread's top, the abdomen ("body"), the head, the mouth, and eight legs as
## {hip, knee, foot}; legs 0 and 1 are the front pair that eats. A painted spider later draws its
## part images with the same points; until then [SpiderArt] draws them in code.
##
## [br]- idle: small out-of-step leg and body sway; hostile: the same, faster and wider.
## [br]- feed: the front pair folds in to the mouth and works it.
## [br]- telegraph: the head rears back, the front legs lift (the web's wind-up).
## [br]- [param drop] (0..1, eased) lowers the body by up to [param drop_px] on a longer thread.
## [br]- [param size] scales the body and legs (the spider grows with calories).
class_name SpiderPose
extends RefCounted

const THREAD_TOP := Vector2(0, -330)
## The body's place at rest, high on the thread.
const BODY_REST := Vector2(0, -150)
const HEAD_OFFSET: float = -46.0


## The pose for animation [param anim] ("idle", "hostile", "feed" or "telegraph") at time [param t]
## seconds: [param size] scales it, [param drop] (0..1) lowers it by up to [param drop_px].
## Returns {thread_top, body, head, mouth, legs: 8 × {hip, knee, foot}}, pixels at depth 1 from the floor point.
static func compute(anim: String, t: float, size: float, drop: float, drop_px: float) -> Dictionary:
	var eased: float = smoothstep(0.0, 1.0, clampf(drop, 0.0, 1.0))
	var sway: float = (2.0 if anim == "hostile" else 1.0)
	var speed: float = (2.2 if anim == "hostile" else 1.0)
	var body: Vector2 = BODY_REST + Vector2(sin(t * 0.9 * speed) * 1.5 * sway, eased * drop_px + sin(t * 1.3 * speed) * 2.0)
	var head: Vector2 = body + Vector2(0, HEAD_OFFSET * size)
	if anim == "telegraph":
		head += Vector2(0, -14.0 * size)
	var mouth: Vector2 = head + Vector2(0, 12.0 * size)
	var legs: Array[Dictionary] = []
	for k: int in 4:
		for side: float in [-1.0, 1.0]:
			var phase: float = float(k) * 1.3 + (0.5 if side > 0.0 else 0.0)
			var wobble: float = sin(t * 2.0 * speed + phase) * 3.0 * sway
			var hip: Vector2 = Vector2(side * 10.0 * size, body.y - 40.0 * size + float(k) * 9.0 * size)
			var knee: Vector2 = hip + Vector2(side * (30.0 + float(k) * 4.0), -26.0 + float(k) * 6.0) * size + Vector2(0, wobble * 0.5)
			var foot: Vector2 = hip + Vector2(side * (52.0 + float(k) * 6.0), 24.0 + float(k) * 10.0) * size + Vector2(0, wobble)
			if k == 0 and anim == "feed":
				# the front pair folds in to the mouth and works it
				knee = hip + Vector2(side * 22.0, -18.0) * size
				foot = mouth + Vector2(side * 5.0 * size, -2.0 + sin(t * 12.0 + phase) * 2.0)
			elif k == 0 and anim == "telegraph":
				knee = hip + Vector2(side * 26.0, -40.0) * size
				foot = hip + Vector2(side * 40.0, -62.0) * size
			legs.append({"hip": hip, "knee": knee, "foot": foot})
	return {"thread_top": THREAD_TOP, "body": body, "head": head, "mouth": mouth, "legs": legs}

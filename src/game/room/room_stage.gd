## Draws the room the ghost is in, Hamlet-style (stage 5a, GDD §13.2): walls, floor, doors
## where the family's doors are, furniture from `assets/data/house/furniture.json`, the
## family members who are in the room, and the ghost — all sorted by depth. A wall the ghost
## is inside fades. Presentation only: it reads the simulation and never changes it.
##
## Rooms listed in `assets/art/visual_style.json` are drawn in the Whimsical Gothic
## Storybook style (art test, 2026-11-15): [StorybookArt] props and characters, a wallpapered
## and panelled shell, firelight / lamplight / moonlight pools, the paper shader, and an eased
## warm-to-haunted mood ([RoomMood]) that the game's colour grade reads. Any prop with a
## painted sprite in that file is drawn from the image instead ([PropVisuals]).
##
## Room wear (art Phase 2, every room): a dirty room is duller, with dust and stains on the floor,
## cobwebs in the corners and on tall furniture, and dust motes in its light; a clean room has a
## faint sheen; a cold room shows people's breath; cold or dark rooms gather dusk-blue shadow in
## the corners; embers fade after the fire goes out ([RoomWear]). Drawn under furniture and
## people, so wear never covers them (breath belongs to the person).
class_name RoomStage
extends Node2D

const WALL_FADE_ALPHA: float = 0.45
const WALL_FADE_SPEED: float = 6.0
## Harm in progress (stage 5d): the ring over the object and the ghost's effort.
const RING_RADIUS: float = 22.0
const RING_WIDTH: float = 6.0
const RING_HEIGHT: float = 150.0
const RING_COLOR := Color(0.72, 0.9, 1.0)
const WISP_COLOR := Color(0.75, 0.92, 1.0)

var sim: HouseSim
var navigator: GhostNavigator
## Where everything is inside rooms (shared with the stealth system).
var layout: RoomLayout
## Object id the ghost targets (highlighted), or "".
var target_object: String = ""
## Detection and hiding (stage 5b); may be null before it is set up.
var stealth: StealthSystem
## Where the family is shown walking (stage 5c).
var motion: FamilyMotion
## The ghost action in progress (stage 5d); may be null.
var casting: GhostCasting
## Searching hiding spots (2026-11-15); may be null.
var loot: GhostLoot
## Sight zones are drawn on the floor (Q, after the monocle is found).
var show_cones: bool = false
## The monocle has been taken from the dresser.
var monocle_taken: bool = false
## Sight zone sizes from stealth.json (for drawing the cones).
var sight_config: Dictionary = {}
## Which rooms are storybook, and painted sprites replacing code-drawn props; may be null.
var visuals: PropVisuals
## Painted walls, floors, rugs and cobwebs (2026-11-20); may be null.
var surfaces: RoomSurfaces
## Painted cutout rigs by family member id (character pipeline pilot, 2026-11-20); people without
## one are drawn in code.
var rigs: Dictionary = {}
## person index -> CharacterAnimator (visual only: never saved, never read by gameplay)
var _animators: Dictionary = {}
## Paper grain material used in storybook rooms; may be null.
var paper_material: Material

const PAPER_SHADER_PATH: String = "res://assets/shaders/canvas_art_storybook_paper.gdshader"
## Shadows stretch this much more when a storybook room is fully haunted.
const HAUNTED_SHADOW_STRETCH: float = 1.3
## How quickly the night look comes and goes, per real second.
const NIGHT_EASE_PER_SECOND: float = 0.8

var _time: float = 0.0
var _walk_phase: float = 0.0
var _wall_alpha: Dictionary = {"left": 1.0, "right": 1.0, "back": 1.0}
var _warmth: float = 1.0
var _night: float = 0.0
var _mood_room: String = ""
## Room wear shown now (eased): dirt, polish, cold 0..1.
var _dirt: float = 0.0
var _polish: float = 0.0
var _cold: float = 0.0
var _wear: RoomWear
## room id -> seconds (of _time) when its fire went out while on screen; absent = no embers.
var _fire_out_at: Dictionary = {}
var _fire_was_burning: Dictionary = {}
## Short texts floating above people (HUD decision 2026-11-15: a person's morale change shows
## above them for a moment instead of in a log): {npc, text, color, born}.
var _floats: Array[Dictionary] = []

## How long a floating text stays, in real seconds; it rises and fades out.
const FLOAT_SECONDS: float = 1.6
const FLOAT_RISE: float = 22.0
const FLOATS_PER_PERSON: int = 2


## True when the room on screen is drawn in the storybook style.
func is_storybook() -> bool:
	return visuals != null and visuals.is_storybook(navigator.room_id)


## The warm-to-haunted mood shown now, 1 cozy .. 0 haunted (eased).
func shown_warmth() -> float:
	return _warmth


## How much of the night look is shown now, 0..1 (eased).
func shown_night() -> float:
	return _night


## Jumps the mood straight to the room's state (on entering a room, and for captures).
func settle_mood() -> void:
	_mood_room = navigator.room_id
	_warmth = RoomMood.warmth(sim.house.rooms[navigator.room_id])
	_night = 0.0 if sim.house.is_day else 1.0
	var room: RoomState = sim.house.rooms[navigator.room_id]
	_dirt = RoomWear.dirt_target(room)
	_polish = RoomWear.polish_target(room)
	_cold = RoomWear.cold_target(room)


## Notices the fire on screen going out (embers then fade); called every frame, and by captures.
func track_fire() -> void:
	var burning: bool = RoomMood.fire_burning(sim.house.rooms[navigator.room_id])
	if bool(_fire_was_burning.get(navigator.room_id, false)) and not burning:
		_fire_out_at[navigator.room_id] = _time
	if burning:
		_fire_out_at.erase(navigator.room_id)
	_fire_was_burning[navigator.room_id] = burning


func _process(delta: float) -> void:
	_time += delta
	_floats.assign(_floats.filter(func(f: Dictionary) -> bool: return _time - float(f["born"]) < FLOAT_SECONDS))
	_walk_phase += delta * 9.0
	_update_animators(delta)
	if _mood_room != navigator.room_id:
		settle_mood()
	_warmth = RoomMood.approach(_warmth, RoomMood.warmth(sim.house.rooms[navigator.room_id]), delta)
	_night = move_toward(_night, 0.0 if sim.house.is_day else 1.0, NIGHT_EASE_PER_SECOND * delta)
	var room: RoomState = sim.house.rooms[navigator.room_id]
	_dirt = _wear_model().ease(_dirt, RoomWear.dirt_target(room), delta)
	_polish = _wear_model().ease(_polish, RoomWear.polish_target(room), delta)
	_cold = _wear_model().ease(_cold, RoomWear.cold_target(room), delta)
	track_fire()
	if paper_material == null and ResourceLoader.exists(PAPER_SHADER_PATH):
		var paper := ShaderMaterial.new()
		paper.shader = load(PAPER_SHADER_PATH)
		paper_material = paper
	material = paper_material if is_storybook() else null
	var inside: String = navigator.wall()
	for wall: String in _wall_alpha:
		var target: float = WALL_FADE_ALPHA if wall == inside else 1.0
		_wall_alpha[wall] = move_toward(float(_wall_alpha[wall]), target, WALL_FADE_SPEED * delta)
	queue_redraw()


func _draw() -> void:
	var room_id: String = navigator.room_id
	var room: RoomState = sim.house.rooms[room_id]
	var storybook: bool = is_storybook()
	FamilyArt.storybook = storybook
	FamilyArt.shadow_stretch = 1.0 + (1.0 - _warmth) * HAUNTED_SHADOW_STRETCH
	var painted: bool = surfaces != null and surfaces.has_room(room_id)
	if storybook:
		draw_rect(Rect2(-200, -200, 1680, 1120), Palette.SB_CHARCOAL.darkened(0.35))
		if painted:
			surfaces.draw_room(self, room_id, _wall_alpha)
		else:
			StorybookShell.draw_floor(self)
			StorybookShell.draw_back_wall(self, float(_wall_alpha["back"]))
			StorybookShell.draw_side_wall(self, true, float(_wall_alpha["left"]))
			StorybookShell.draw_side_wall(self, false, float(_wall_alpha["right"]))
		StorybookShell.draw_wall_portraits(self, visuals.wall_portraits(room_id), _wall_alpha)
		StorybookShell.draw_doors(self, sim.house, room_id, _wall_alpha)
		_draw_wear_surfaces(room_id)
		_draw_storybook_light(room_id)
	else:
		draw_rect(Rect2(-200, -200, 1680, 1120), Palette.BACKGROUND)
		if painted:
			surfaces.draw_room(self, room_id, _wall_alpha)
		else:
			_draw_floor()
			_draw_back_wall(float(_wall_alpha["back"]))
			_draw_side_wall(true, float(_wall_alpha["left"]))
			_draw_side_wall(false, float(_wall_alpha["right"]))
		_draw_doors(room_id)
		_draw_wear_surfaces(room_id)
		_draw_lamp_glow(room_id)
	_draw_cold_corners()
	_draw_motes(room_id)
	# Depth-sorted content: [screen y, callable]
	var items: Array = []
	for piece: Dictionary in layout.pieces(room_id):
		var kind: String = String(piece["kind"])
		if bool(piece.get("decor", false)) and not storybook \
				and (visuals == null or visuals.texture_for(kind, String(piece.get("variant", "")), &"", room_id) == null):
			continue   # decor is drawn in the storybook look, or anywhere it has a painting (Phase B, 2026-11-20)
		var uv := Vector2(float(piece["u"]), float(piece["v"]))
		var object_id: String = String(piece.get("object", ""))
		var state: StringName = sim.house.get_object_state(object_id) if not object_id.is_empty() else &""
		if piece.has("pickup") and monocle_taken:
			state = &"taken"
		if kind == "fireplace":
			state = &"burning" if RoomMood.fire_burning(sim.house.rooms[room_id]) else &"out"
		var y: float = RoomGeometry.to_screen(uv).y
		if FurnitureArt.is_flat(kind):
			y = -10000.0
		elif FurnitureArt.is_wall(kind) or (storybook and StorybookArt.is_wall(kind)):
			y = -5000.0
		var target_key: String = object_id if not object_id.is_empty() else String(piece.get("pickup", piece.get("hide_id", "")))
		var highlighted: bool = target_key == target_object and not target_key.is_empty()
		items.append([y, _draw_piece.bind(piece, uv, state, highlighted, not target_key.is_empty(), storybook)])
		var web_tops: Dictionary = _wear_config().get("web_tops", {})
		if _dirt > 0.01 and web_tops.has(kind):
			var corner: Array = web_tops[kind]
			var s: float = RoomGeometry.scale_at(uv.y)
			items.append([y + 0.01, _draw_web.bind(RoomGeometry.to_screen(uv) + Vector2(float(corner[0]), float(corner[1])) * s,
				Vector2.RIGHT, Vector2.DOWN, 0.5 * s)])
	var markers: Array = []
	for i: int in sim.routines.size():
		var routine: NpcRoutine = sim.routines[i]
		var placed: Dictionary = motion.person(i, room_id)
		if placed.is_empty():
			continue
		var uv: Vector2 = placed["uv"]
		var facing_left: bool = Vector2(placed["facing"]).x < 0.0
		if _animators.has(i) and String(placed["pose"]) != "sleep":
			items.append([RoomGeometry.to_screen(uv).y, _draw_rigged.bind(i, RoomGeometry.to_screen(uv), RoomGeometry.scale_at(uv.y))])
		else:
			items.append([RoomGeometry.to_screen(uv).y, FamilyArt.draw_person.bind(self, routine.schedule.npc_id,
				RoomGeometry.to_screen(uv), RoomGeometry.scale_at(uv.y), String(placed["pose"]), _walk_phase, facing_left)])
		if placed.has("marker"):
			markers.append([RoomGeometry.to_screen(uv) + Vector2(-6, -150 * RoomGeometry.scale_at(uv.y)), String(placed["marker"])])
	var ghost_uv: Vector2 = navigator.uv
	var hidden: bool = stealth != null and not stealth.hidden_in.is_empty()
	var over_floor: bool = ghost_uv.x >= 0.0 and ghost_uv.x <= 1.0 and ghost_uv.y >= 0.0 and ghost_uv.y <= 1.0
	var harm_uv: Vector2 = _harm_uv(room_id)
	var effort: float = casting.progress() if harm_uv.x > -1.0 else 0.0
	if not hidden:
		# Acting: the ghost trembles harder as the harm builds.
		var shake := Vector2(sin(_time * 47.0), cos(_time * 39.0)) * (1.5 + 3.5 * effort) if harm_uv.x > -1.0 else Vector2.ZERO
		items.append([RoomGeometry.to_screen(ghost_uv).y if over_floor else 100000.0, FamilyArt.draw_ghost.bind(self,
			RoomGeometry.to_screen(ghost_uv) + shake, RoomGeometry.scale_at(ghost_uv.y), _time, over_floor)])
	if show_cones:
		_draw_cones(room_id)
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for item: Array in items:
		(item[1] as Callable).call()
	if hidden:
		_draw_hidden_glint(ghost_uv)
		if loot != null and loot.is_searching():
			for spot: Dictionary in layout.hiding_spots(room_id):
				if String(spot["id"]) == loot.searching_spot():
					_draw_ring(spot["uv"], loot.search_progress())
	if harm_uv.x > -1.0:
		_draw_wisps(ghost_uv, harm_uv, effort)
		_draw_ring(harm_uv, effort)
	if _cold > 0.01:
		for i: int in sim.routines.size():
			var placed: Dictionary = motion.person(i, room_id)
			if not placed.is_empty() and String(placed["pose"]) != "sleep":
				_draw_breath(i, sim.routines[i].schedule.npc_id, placed)
	for marker: Array in markers:
		draw_string(ThemeDB.fallback_font, marker[0], marker[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
			Color("e0735f") if marker[1] == "!" else Color("f0c36a"))
	if room.temperature == RoomState.Temperature.COLD and not storybook:
		draw_rect(Rect2(0, 0, 1280, 720), Palette.COLD_OVERLAY)
	FamilyArt.storybook = false


## One furniture piece: its painted sprite if it has one (with the code-drawn animation —
## fire, smoke, glow — on top at the sprite's effects point, art Phase 3), else the code
## drawing for the room's look.
func _draw_piece(piece: Dictionary, uv: Vector2, state: StringName, highlighted: bool, interactive: bool, storybook: bool) -> void:
	var kind: String = String(piece["kind"])
	var variant: String = String(piece.get("variant", ""))
	var hearth: Vector2 = RoomGeometry.to_screen(uv)
	var painted: bool = false
	if kind == "rug" and surfaces != null:
		var size: Array = piece.get("size_m", [2.5, 1.8])
		if surfaces.draw_rug(self, uv, Vector2(float(size[0]), float(size[1]))):
			return
	if visuals != null:
		var wall: bool = StorybookArt.is_wall(kind)
		# wall pieces hang on the back wall: its depth (perspective, 2026-11-20; was 1.0)
		var depth: float = RoomGeometry.scale_at(0.0) if wall else RoomGeometry.scale_at(uv.y)
		var room: String = navigator.room_id
		var glass: Texture2D = visuals.glass_mask(kind, variant, state, room)
		if glass != null:
			StorybookArt.draw_painted_glass(self, glass, visuals.sprite_rect(kind, variant, state, hearth, depth, room), state, sim.house.is_day)
		if visuals.draw_sprite(self, kind, variant, state, hearth, depth, highlighted, room, bool(piece.get("flip", false))):
			painted = true
			var points: Dictionary = visuals.effect_points(kind, variant, room)
			for name: String in points:
				points[name] = hearth + Vector2(points[name]) * depth
			StorybookArt.draw_sprite_parts(self, kind, state, points, depth, _time)
			hearth += visuals.effects_offset(kind, variant, room) * depth
			var layer: Dictionary = visuals.effect_layer(kind, variant, state, room)
			StorybookArt.draw_effects(self, kind, state, hearth, depth * visuals.effects_scale(kind, variant, room), _time, layer.is_empty())
			if not layer.is_empty():
				_draw_effect_layer(layer, hearth, depth)
	if not painted:
		if storybook:
			StorybookArt.draw(self, piece, uv, state, highlighted, sim.house.is_day, interactive, _time)
		else:
			FurnitureArt.draw(self, kind, uv, state, highlighted, sim.house.is_day)
	if kind == "fireplace" and state == &"out" and _fire_out_at.has(navigator.room_id):
		_draw_embers(hearth, _wear_model().ember_glow(_time - float(_fire_out_at[navigator.room_id])))


# --- Painted family members (character pipeline pilot, 2026-11-20) ---------------------------

## Feeds each painted family member's animator this frame's game state (pose and facing from
## FamilyMotion, the schedule's activity, the stealth marker). Visual only.
func _update_animators(delta: float) -> void:
	if motion == null or sim == null:
		return
	var room_id: String = navigator.room_id
	for i: int in sim.routines.size():
		var routine: NpcRoutine = sim.routines[i]
		var npc_id: String = routine.schedule.npc_id
		if not rigs.has(npc_id):
			continue
		var placed: Dictionary = motion.person(i, room_id)
		if placed.is_empty():
			_animators.erase(i)   # out of sight: start afresh when seen again
			continue
		if not _animators.has(i):
			_animators[i] = CharacterAnimator.new(rigs[npc_id], (rigs[npc_id] as CharacterRig).stride_m)
		var activity: String = ""
		if routine.state == NpcRoutine.State.PERFORMING and routine.current != null and routine.current_task == null:
			activity = routine.current.animation
		(_animators[i] as CharacterAnimator).update(delta, {"pose": String(placed["pose"]), "uv": placed["uv"],
			"facing": placed["facing"], "marker": String(placed.get("marker", "")), "activity": activity,
			"room_size": layout.size(room_id) if layout != null else Vector2.ONE})


func _draw_rigged(index: int, foot: Vector2, s: float) -> void:
	var anim: CharacterAnimator = _animators[index]
	var shadow := Color(Palette.SB_CONTOUR if FamilyArt.storybook else Palette.INK, 0.22)
	draw_colored_polygon(Ink.ellipse(foot, 26.0 * s, 7.0 * s, 20), shadow)
	anim.draw(self, foot, s)


## The head of person [param index]: from their rig when painted, else the code figure's.
func _head_point(index: int, npc_id: String, foot: Vector2, s: float, pose: String) -> Vector2:
	if _animators.has(index) and pose != "sleep":
		return (_animators[index] as CharacterAnimator).head_point(foot, s)
	return FamilyArt.head_point(npc_id, foot, s, pose)


## A painted effects layer (e.g. burning logs and flames) at [param at], with a gentle flicker:
## it stretches up and down and sways about its anchor (the logs barely move, the tips most).
func _draw_effect_layer(layer: Dictionary, at: Vector2, depth: float) -> void:
	var tex: Texture2D = layer["texture"]
	var size: Vector2 = tex.get_size() * float(layer["scale"]) * depth
	var f: float = float(layer["flicker"])
	var stretch: float = 1.0 + f * (0.6 * sin(_time * 7.3) + 0.4 * sin(_time * 11.1 + 1.3))
	var sway: float = f * 0.6 * sin(_time * 3.1 + 0.7)
	draw_set_transform_matrix(Transform2D(Vector2(1.0 - (stretch - 1.0) * 0.4, 0.0), Vector2(sway, stretch), at))
	draw_texture_rect(tex, Rect2(-Vector2(layer["anchor"]) * size, size), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


# --- Room wear (art Phase 2) ------------------------------------------------------------

func _wear_config() -> Dictionary:
	return visuals.wear_config() if visuals != null else {}


func _wear_model() -> RoomWear:
	if _wear == null:
		_wear = RoomWear.new(_wear_config())
	return _wear


## Dirt and polish on the room's surfaces, under all furniture: a dull wash over floor and
## walls, dust patches and stains, cobwebs in the top corners; a clean room's floor sheen.
func _draw_wear_surfaces(room_id: String) -> void:
	var cfg: Dictionary = _wear_config()
	if _dirt > 0.01:
		var dull := Color(Palette.SB_BROWN_GREY, float(cfg.get("dull_alpha", 0.2)) * _dirt)
		draw_colored_polygon(RoomGeometry.floor_polygon(), dull)
		draw_colored_polygon(RoomGeometry.back_wall_polygon(), Color(dull, dull.a * float(_wall_alpha["back"])))
		draw_colored_polygon(RoomGeometry.left_wall_polygon(), Color(dull, dull.a * float(_wall_alpha["left"])))
		draw_colored_polygon(RoomGeometry.right_wall_polygon(), Color(dull, dull.a * float(_wall_alpha["right"])))
		var dust_alpha: float = float(cfg.get("dust_alpha", 0.3)) * _dirt
		var patches: Array[Vector3] = _wear_model().dust_patches(room_id, _door_uvs(room_id))
		for i: int in patches.size():
			var p: Vector3 = patches[i]
			var at: Vector2 = RoomGeometry.to_screen(Vector2(p.x, p.y))
			var s: float = RoomGeometry.scale_at(p.y) * p.z
			var stain: bool = i % 3 == 2
			var shape: PackedVector2Array = Ink.wobble(Ink.ellipse(at, (34.0 if stain else 62.0) * s, (10.0 if stain else 17.0) * s, 18), float(i) * 3.7, 3.0 * s)
			var color: Color = Color(Palette.SB_WALNUT_DARK, dust_alpha * 0.8) if stain else Color(Palette.SB_ASH, dust_alpha)
			for piece: PackedVector2Array in floor_pieces(shape):
				draw_colored_polygon(piece, color)
		var web_radius: float = float(cfg.get("web_radius", 46))
		var top_left: Vector2 = RoomGeometry.BACK_LEFT + Vector2(0, -RoomGeometry.BACK_WALL_HEIGHT)
		var top_right: Vector2 = RoomGeometry.BACK_RIGHT + Vector2(0, -RoomGeometry.BACK_WALL_HEIGHT)
		var front_left: Vector2 = RoomGeometry.FRONT_LEFT + Vector2(0, -RoomGeometry.SIDE_WALL_FRONT_HEIGHT)
		var front_right: Vector2 = RoomGeometry.FRONT_RIGHT + Vector2(0, -RoomGeometry.SIDE_WALL_FRONT_HEIGHT)
		_draw_web(top_left, Vector2.RIGHT, Vector2.DOWN, web_radius / 46.0 * float(_wall_alpha["back"]))
		_draw_web(top_right, Vector2.LEFT, Vector2.DOWN, web_radius / 46.0 * float(_wall_alpha["back"]))
		_draw_web(front_left, (top_left - front_left).normalized(), Vector2.DOWN, web_radius / 46.0 * 1.2 * float(_wall_alpha["left"]))
		_draw_web(front_right, (top_right - front_right).normalized(), Vector2.DOWN, web_radius / 46.0 * 1.2 * float(_wall_alpha["right"]))
	if _polish > 0.01:
		var sheen := Color(Palette.SB_CREAM, float(cfg.get("polish_alpha", 0.07)) * _polish)
		for u0: float in [0.22, 0.48, 0.74]:
			var band := PackedVector2Array([RoomGeometry.to_screen(Vector2(u0, 0.0)), RoomGeometry.to_screen(Vector2(u0 + 0.07, 0.0)),
				RoomGeometry.to_screen(Vector2(u0 - 0.1, 1.0)), RoomGeometry.to_screen(Vector2(u0 - 0.19, 1.0))])
			for piece: PackedVector2Array in floor_pieces(band):
				draw_colored_polygon(piece, sheen)


## A cobweb fanned between two directions from [param corner]; [param size] 1 = web_radius px.
func _draw_web(corner: Vector2, along_a: Vector2, along_b: Vector2, size: float) -> void:
	var cfg: Dictionary = _wear_config()
	var radius: float = float(cfg.get("web_radius", 46)) * size
	var painted_web: Texture2D = surfaces.web_texture() if surfaces != null else null
	if painted_web != null:   # the painted web, its corner at [param corner], spread along both directions
		draw_set_transform_matrix(Transform2D(along_a.normalized() * radius * 1.6, along_b.normalized() * radius * 1.6, corner))
		draw_texture_rect(painted_web, Rect2(0, 0, 1, 1), false, Color(1, 1, 1, float(cfg.get("web_alpha", 0.55)) * _dirt * 1.4))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var color := Color(Palette.SB_CREAM, float(cfg.get("web_alpha", 0.55)) * _dirt)
	var a0: float = along_a.angle()
	var a1: float = along_b.angle()
	var span: float = wrapf(a1 - a0, -PI, PI)
	var threads: int = 5
	for k: int in threads:
		var dir := Vector2.from_angle(a0 + span * float(k) / float(threads - 1))
		draw_line(corner, corner + dir * radius, color, 1.0, true)
	for ring: int in 3:
		var r: float = radius * (0.3 + 0.27 * float(ring))
		var points := PackedVector2Array()
		for k: int in threads:
			var t: float = float(k) / float(threads - 1)
			var sag: float = 1.0 - 0.12 * sin(t * PI)   # threads sag a little between spokes
			points.append(corner + Vector2.from_angle(a0 + span * t) * r * (sag if k > 0 and k < threads - 1 else 1.0))
		draw_polyline(points, color, 1.0, true)


## Dusk-blue shadow gathering in the corners as the room turns cold or dark.
func _draw_cold_corners() -> void:
	var amount: float = (1.0 - _warmth) * float(_wear_config().get("cold_corner_alpha", 0.4))
	if amount <= 0.01:
		return
	var shade := Color(Palette.SB_DUSK_BLUE.darkened(0.45), amount)
	for corner: Vector2 in [RoomGeometry.BACK_LEFT, RoomGeometry.BACK_RIGHT, RoomGeometry.FRONT_LEFT, RoomGeometry.FRONT_RIGHT]:
		_floor_glow(corner, Vector2(230, 90), shade)
	for corner: Vector2 in [RoomGeometry.BACK_LEFT + Vector2(0, -RoomGeometry.BACK_WALL_HEIGHT), RoomGeometry.BACK_RIGHT + Vector2(0, -RoomGeometry.BACK_WALL_HEIGHT)]:
		Ink.glow(self, corner, Vector2(120, 110), Color(shade, shade.a * 0.6), 5)


## Dust specks drifting in the room's light (window, lit lamps, burning fire) while dirty.
func _draw_motes(room_id: String) -> void:
	if _dirt <= 0.01:
		return
	var alpha: float = float(_wear_config().get("mote_alpha", 0.55)) * _dirt
	var lights: Array = []
	var room: RoomState = sim.house.rooms[room_id]
	for piece: Dictionary in layout.pieces(room_id):
		var kind: String = String(piece["kind"])
		var uv := Vector2(float(piece["u"]), float(piece["v"]))
		var foot: Vector2 = RoomGeometry.to_screen(uv)
		var object_id: String = String(piece.get("object", ""))
		var obj: ObjectState = sim.house.objects.get(object_id) if not object_id.is_empty() else null
		if kind == "window":
			lights.append([foot.lerp(RoomGeometry.to_screen(uv + Vector2(0.04, 0.3)), 0.4) + Vector2(0, -40), Vector2(90, 70)])
		elif obj != null and obj.kind == "lamp" and obj.state == &"lit":
			lights.append([foot + Vector2(0, -95) * RoomGeometry.scale_at(uv.y), Vector2(60, 60)])
		elif kind == "fireplace" and RoomMood.fire_burning(room):
			lights.append([foot + Vector2(0, -45), Vector2(80, 45)])
	for li: int in lights.size():
		var centre: Vector2 = lights[li][0]
		var radius: Vector2 = lights[li][1]
		var offsets: Array[Vector2] = _wear_model().mote_offsets(_time, float(li) + 1.0)
		for i: int in offsets.size():
			var twinkle: float = 0.55 + 0.45 * sin(_time * 1.3 + float(i) * 2.1)
			draw_circle(centre + offsets[i] * radius, 1.4, Color(Palette.SB_CREAM, alpha * twinkle), true, -1.0, true)


## Shows [param text] above [param npc_id] for FLOAT_SECONDS (drawn only while they are in
## the room on screen).
## At most FLOATS_PER_PERSON show above one person; a new one pushes out the oldest (fast
## game speeds would otherwise stack them into a column).
func float_text(npc_id: String, text: String, color: Color) -> void:
	var mine: Array = _floats.filter(func(f: Dictionary) -> bool: return f["npc"] == npc_id)
	while mine.size() >= FLOATS_PER_PERSON:
		_floats.erase(mine.pop_front())
	_floats.append({"npc": npc_id, "text": text, "color": color, "born": _time})


## The floating texts to show now, for the HUD to draw (on its own layer, so the room's
## darkness and colour grade never dim them): {at (screen, text baseline centre), text,
## color, alpha}, newest lowest above each person; only people in the room on screen.
func visible_floats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _floats.is_empty():
		return out
	var room_id: String = navigator.room_id
	var stacked: Dictionary = {}
	for k: int in range(_floats.size() - 1, -1, -1):
		var f: Dictionary = _floats[k]
		for i: int in sim.routines.size():
			if sim.routines[i].schedule.npc_id != String(f["npc"]):
				continue
			var placed: Dictionary = motion.person(i, room_id)
			if placed.is_empty():
				break
			var uv: Vector2 = placed["uv"]
			var s: float = RoomGeometry.scale_at(uv.y)
			var t: float = clampf((_time - float(f["born"])) / FLOAT_SECONDS, 0.0, 1.0)
			var row: int = int(stacked.get(f["npc"], 0))
			stacked[f["npc"]] = row + 1
			var head: Vector2 = _head_point(i, String(f["npc"]), RoomGeometry.to_screen(uv), s, String(placed["pose"]))
			out.append({"at": RoomGeometry.to_display(head + Vector2(0.0, -30.0 * s - FLOAT_RISE * t - 16.0 * float(row))), "text": f["text"],
				"color": f["color"], "alpha": 1.0 - maxf(0.0, t - 0.6) / 0.4})
			break
	return out


## Small puffs of breath in front of a person's face in a cold room.
func _draw_breath(index: int, npc_id: String, placed: Dictionary) -> void:
	var a: float = _wear_model().breath_alpha(_time, index) * _cold
	if a <= 0.01:
		return
	var uv: Vector2 = placed["uv"]
	var s: float = RoomGeometry.scale_at(uv.y)
	var side: float = -1.0 if Vector2(placed["facing"]).x < 0.0 else 1.0
	var mouth: Vector2 = _head_point(index, npc_id, RoomGeometry.to_screen(uv), s, String(placed["pose"])) + Vector2(side * 12.0, 4.0) * s
	var rise: float = (1.0 - a / maxf(float(_wear_config().get("breath_alpha", 0.45)), 0.01)) * 6.0 * s
	for k: int in 3:
		var at: Vector2 = mouth + Vector2(side * (5.0 + 6.0 * float(k)), -rise - 2.0 * float(k)) * Vector2(s, 1.0)
		draw_circle(at, (2.5 + 1.6 * float(k)) * s, Color(Palette.SB_CREAM, a * (1.0 - 0.25 * float(k))), true, -1.0, true)


## Embers glowing in the grate after the fire went out, fading by [param glow] 1..0.
func _draw_embers(hearth: Vector2, glow: float) -> void:
	if glow <= 0.01:
		return
	for k: int in 6:
		var flicker: float = 0.6 + 0.4 * sin(_time * (2.0 + float(k) * 0.7) + float(k))
		var at: Vector2 = hearth + Vector2(-24.0 + 10.0 * float(k), -6.0 - 3.0 * float(k % 2))
		draw_circle(at, 2.2, Color(Palette.SB_EMBER.lightened(0.35), glow * flicker), true, -1.0, true)
	Ink.glow(self, hearth + Vector2(0, -8), Vector2(40, 12), Color(Palette.SB_EMBER, 0.35 * glow), 4)


## Floor positions of this room's doors (dust stays clear of them).
func _door_uvs(room_id: String) -> Array[Vector2]:
	var doors: Array[Vector2] = []
	for other: String in sim.house.rooms:
		if other != room_id and sim.house.walk_minutes(room_id, other) > 0:
			doors.append(layout.door_uv(room_id, other))
	return doors


## Storybook light pools on the floor and walls: firelight in front of a burning fireplace,
## lamplight under a lit lamp, moonlight (night) or daylight through the window. Warm pools
## fade as the room turns haunted; moonlight grows.
func _draw_storybook_light(room_id: String) -> void:
	var room: RoomState = sim.house.rooms[room_id]
	var flicker: float = 0.85 + 0.15 * sin(_time * 7.3) * sin(_time * 3.1)
	for piece: Dictionary in layout.pieces(room_id):
		var kind: String = String(piece["kind"])
		var uv := Vector2(float(piece["u"]), float(piece["v"]))
		if kind == "fireplace" and RoomMood.fire_burning(room):
			var hearth: Vector2 = RoomGeometry.to_screen(uv)
			_floor_glow(RoomGeometry.to_screen(uv + Vector2(0, 0.16)), Vector2(270, 80), Color(Palette.SB_CANDLELIGHT, 0.45 * flicker * maxf(_warmth, 0.4)))
			Ink.glow(self, hearth + Vector2(0, -70), Vector2(150, 110), Color(Palette.SB_CANDLELIGHT, 0.22 * flicker), 6)
		elif kind == "floor_lamp" and sim.house.get_object_state(String(piece.get("object", ""))) == &"lit":
			var lamp_foot: Vector2 = RoomGeometry.to_screen(uv)
			_floor_glow(lamp_foot, Vector2(260, 85), Color(Palette.SB_CANDLELIGHT, 0.5))
			Ink.glow(self, lamp_foot + Vector2(0, -130 * RoomGeometry.scale_at(uv.y)), Vector2(120, 90), Color(Palette.SB_CANDLELIGHT, 0.28), 6)
		elif kind == "window":
			var sill: Vector2 = RoomGeometry.to_screen(uv)
			var patch: Vector2 = RoomGeometry.to_screen(uv + Vector2(0.04, 0.3))
			var light: Color = Color(Palette.SB_MOON, 0.10 + 0.12 * (1.0 - _warmth)) if not sim.house.is_day else Color(Palette.SB_CREAM, 0.12)
			var beam := PackedVector2Array([sill + Vector2(-52, -60), sill + Vector2(52, -60), patch + Vector2(110, 0), patch + Vector2(-90, 0)])
			draw_colored_polygon(beam, Color(light, light.a * 0.45))
			_floor_glow(patch, Vector2(130, 34), light)
			if sim.house.get_object_state(String(piece.get("object", ""))) == &"open":
				_draw_draught(uv)


## Art Phase 2: a cold draught spreading over the floor from an open window — pale wavy
## streaks drifting into the room.
func _draw_draught(window_uv: Vector2) -> void:
	for k: int in 4:
		var points := PackedVector2Array()
		var drift: float = fposmod(_time * 0.12 + float(k) * 0.25, 1.0)
		for i: int in 14:
			var t: float = float(i) / 13.0
			var v: float = 0.03 + t * 0.3
			var u: float = window_uv.x + (float(k) - 1.5) * 0.045 * (1.0 + t) + sin(t * 7.0 + _time * 1.6 + float(k)) * 0.012
			points.append(RoomGeometry.to_screen(Vector2(u, v)))
		var fade: float = sin(drift * PI)
		draw_polyline(points, Color(Palette.SB_MOON, 0.22 * fade), 2.0, true)


func _floor_glow(centre: Vector2, radius: Vector2, color: Color) -> void:
	for ring: int in 6:
		var t: float = 1.0 - float(ring) / 6.0
		for piece: PackedVector2Array in floor_pieces(Ink.ellipse(centre, radius.x * t, radius.y * t, 32)):
			draw_colored_polygon(piece, Color(color, color.a / 6.0))


## Peripheral (wide, faint) and deep (narrow, strong) sight zones on the floor for everyone
## in the room who could notice the ghost; clipped to the floor.
func _draw_cones(room_id: String) -> void:
	for i: int in sim.routines.size():
		var routine: NpcRoutine = sim.routines[i]
		if stealth != null and not stealth.can_notice(routine):
			continue
		var placed: Dictionary = motion.person(i, room_id)
		if placed.is_empty():
			continue
		var size: Vector2 = layout.size(room_id)
		_draw_fan(placed["uv"], placed["facing"], float(sight_config.get("peripheral_angle_deg", 120)),
			float(sight_config.get("peripheral_range", 0.5)), Color(1.0, 0.9, 0.4, 0.16), size)
		_draw_fan(placed["uv"], placed["facing"], float(sight_config.get("deep_angle_deg", 40)),
			float(sight_config.get("deep_range", 0.33)), Color(1.0, 0.45, 0.25, 0.30), size)


## A sight cone: [param reach] in metres on a floor of [param size] metres (2026-11-20).
func _draw_fan(origin: Vector2, look: Vector2, angle_deg: float, reach: float, color: Color, size: Vector2) -> void:
	var points := PackedVector2Array([RoomGeometry.to_screen(origin)])
	var half: float = deg_to_rad(angle_deg) * 0.5
	for step: int in 19:
		var direction: Vector2 = (look * size).normalized().rotated(-half + 2.0 * half * float(step) / 18.0)
		points.append(RoomGeometry.to_screen(origin + direction * reach / size))
	for piece: PackedVector2Array in floor_pieces(points):
		draw_colored_polygon(piece, color)
		_outline(piece, Color(color, minf(color.a * 2.5, 0.8)), 2.0)


## The parts of screen polygon [param polygon] that lie on the floor and can be filled.
## Clipping a cone that starts on the floor's edge and looks outward leaves a zero-area
## sliver; it is dropped (drawing it fails with "triangulation failed").
static func floor_pieces(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(polygon, RoomGeometry.floor_polygon()):
		if not Geometry2D.triangulate_polygon(piece).is_empty():
			pieces.append(piece)
	return pieces


## Floor position of the object the ghost is harming in this room, or (-1, -1).
func _harm_uv(room_id: String) -> Vector2:
	if casting == null or not casting.is_casting():
		return Vector2(-1, -1)
	return layout.object_uv(room_id, casting.object_id)


## Wavy strands from the ghost to the object it is harming, stronger as the harm builds.
func _draw_wisps(ghost_uv: Vector2, harm_uv: Vector2, effort: float) -> void:
	var from: Vector2 = RoomGeometry.to_screen(ghost_uv) + Vector2(0, -70 * RoomGeometry.scale_at(ghost_uv.y))
	var to: Vector2 = RoomGeometry.to_screen(harm_uv) + Vector2(0, -60 * RoomGeometry.scale_at(harm_uv.y))
	var across: Vector2 = (to - from).orthogonal().normalized()
	for strand: int in 3:
		var points := PackedVector2Array()
		for step: int in 17:
			var t: float = float(step) / 16.0
			var wave: float = sin(t * 9.0 - _time * 7.0 + float(strand) * 2.1) * 9.0 * sin(t * PI)
			points.append(from.lerp(to, t) + across * wave)
		draw_polyline(points, Color(WISP_COLOR, 0.15 + 0.45 * effort), 2.0 + float(strand == 1), true)


## The ring over the object being harmed: fills clockwise from the top as the action runs.
func _draw_ring(harm_uv: Vector2, progress: float) -> void:
	var s: float = RoomGeometry.scale_at(harm_uv.y)
	var centre: Vector2 = RoomGeometry.to_screen(harm_uv) - Vector2(0, RING_HEIGHT * s)
	draw_circle(centre, (RING_RADIUS + RING_WIDTH) * s, Color(0.05, 0.05, 0.1, 0.65))
	draw_arc(centre, RING_RADIUS * s, 0.0, TAU, 48, Color(RING_COLOR, 0.25), RING_WIDTH * s, true)
	if progress > 0.0:
		# Screen y points down, so a growing angle from -90° runs clockwise.
		draw_arc(centre, RING_RADIUS * s, -PI * 0.5, -PI * 0.5 + TAU * progress, maxi(4, int(48 * progress)), RING_COLOR, RING_WIDTH * s, true)


## The hidden ghost: only a faint pair of eyes glinting at its hiding spot.
func _draw_hidden_glint(uv: Vector2) -> void:
	var at: Vector2 = RoomGeometry.to_screen(uv) + Vector2(0, -40)
	var glow: float = 0.55 + 0.35 * sin(_time * 2.5)
	for side: float in [-7.0, 7.0]:
		draw_colored_polygon(FurnitureArt._ellipse(at + Vector2(side, 0), 3.5, 5.0, 10), Color(0.75, 0.95, 1.0, glow))


# --- Room shell ------------------------------------------------------------------

func _draw_floor() -> void:
	var edge := Vector2(0, RoomGeometry.FLOOR_EDGE)
	draw_colored_polygon(PackedVector2Array([RoomGeometry.FRONT_LEFT, RoomGeometry.FRONT_RIGHT, RoomGeometry.FRONT_RIGHT + edge, RoomGeometry.FRONT_LEFT + edge]), Palette.FLOOR_EDGE)
	draw_colored_polygon(RoomGeometry.floor_polygon(), Palette.FLOOR)
	for i: int in range(1, 14):
		var t: float = float(i) / 14.0
		draw_line(RoomGeometry.to_screen(Vector2(t, 0)), RoomGeometry.to_screen(Vector2(t, 1)), Palette.FLOOR_LINE, 2.0, true)
	for v: float in [0.1, 0.23, 0.38, 0.56, 0.77]:
		draw_line(RoomGeometry.to_screen(Vector2(0, v)), RoomGeometry.to_screen(Vector2(1, v)), Palette.FLOOR_LINE, 1.5, true)
	_outline(RoomGeometry.floor_polygon(), Palette.INK, 3.0)


func _draw_back_wall(alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.back_wall_polygon()
	draw_colored_polygon(poly, _a(Palette.WALL_BACK, alpha))
	var wainscot_y: float = RoomGeometry.BACK_LEFT.y - RoomGeometry.BACK_WALL_HEIGHT * 0.38
	var x: float = RoomGeometry.BACK_LEFT.x + 14.0
	while x < RoomGeometry.BACK_RIGHT.x:
		draw_line(Vector2(x, poly[0].y), Vector2(x, wainscot_y), _a(Palette.WALL_STRIPE, alpha), 6.0)
		x += 28.0
	draw_colored_polygon(FurnitureArt._rect(RoomGeometry.BACK_LEFT.x, wainscot_y, RoomGeometry.BACK_RIGHT.x, RoomGeometry.BACK_LEFT.y), _a(Palette.WAINSCOT, alpha))
	_outline(poly, _a(Palette.INK, alpha), 3.0)
	draw_line(poly[0], poly[1], _a(Palette.WALL_CAP, alpha), 7.0)


func _draw_side_wall(left: bool, alpha: float) -> void:
	var poly: PackedVector2Array = RoomGeometry.left_wall_polygon() if left else RoomGeometry.right_wall_polygon()
	draw_colored_polygon(poly, _a(Palette.WALL_SIDE, alpha))
	var band := PackedVector2Array([
		RoomGeometry.side_wall_point(left, 1.0, 0.38), RoomGeometry.side_wall_point(left, 0.0, 0.38),
		RoomGeometry.side_wall_point(left, 0.0, 0.0), RoomGeometry.side_wall_point(left, 1.0, 0.0)])
	draw_colored_polygon(band, _a(Palette.WAINSCOT_SIDE, alpha))
	_outline(poly, _a(Palette.INK, alpha), 3.0)
	draw_line(poly[0], poly[1], _a(Palette.WALL_CAP, alpha), 7.0)


func _draw_doors(room_id: String) -> void:
	for other: String in sim.house.rooms:
		if sim.house.walk_minutes(room_id, other) <= 0:
			continue
		var here: RoomState = sim.house.rooms[room_id]
		var there: RoomState = sim.house.rooms[other]
		if here.floor_level != there.floor_level:
			continue   # stairs are furniture
		var step: Vector2i = there.grid - here.grid
		if step.x != 0:
			var left: bool = step.x < 0
			var alpha: float = float(_wall_alpha["left" if left else "right"])
			var frame := PackedVector2Array([
				RoomGeometry.side_wall_point(left, 0.40, 0.62), RoomGeometry.side_wall_point(left, 0.60, 0.62),
				RoomGeometry.side_wall_point(left, 0.60, 0.0), RoomGeometry.side_wall_point(left, 0.40, 0.0)])
			var inner := PackedVector2Array([
				RoomGeometry.side_wall_point(left, 0.43, 0.56), RoomGeometry.side_wall_point(left, 0.57, 0.56),
				RoomGeometry.side_wall_point(left, 0.57, 0.0), RoomGeometry.side_wall_point(left, 0.43, 0.0)])
			draw_colored_polygon(frame, _a(Palette.WOOD_DARK, alpha))
			draw_colored_polygon(inner, _a(Palette.DOORWAY, alpha))
			_outline(frame, _a(Palette.INK, alpha), 2.5)
		elif step.y < 0:
			var alpha_back: float = float(_wall_alpha["back"])
			var frame_back: PackedVector2Array = FurnitureArt._rect(
				RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U - 0.07, 0.0).x, RoomGeometry.back_wall_point(0, 0.8).y,
				RoomGeometry.back_wall_point(RoomLayout.BACK_DOOR_U + 0.07, 0.0).x, RoomGeometry.BACK_LEFT.y)
			var inner_back: PackedVector2Array = FurnitureArt._rect(frame_back[0].x + 10, frame_back[0].y + 10, frame_back[1].x - 10, RoomGeometry.BACK_LEFT.y)
			draw_colored_polygon(frame_back, _a(Palette.WOOD_DARK, alpha_back))
			draw_colored_polygon(inner_back, _a(Palette.DOORWAY, alpha_back))
			_outline(frame_back, _a(Palette.INK, alpha_back), 2.5)
		else:
			var a: Vector2 = RoomGeometry.to_screen(Vector2(0.44, 1.0))
			var b: Vector2 = RoomGeometry.to_screen(Vector2(0.56, 1.0))
			draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, RoomGeometry.FLOOR_EDGE), a + Vector2(0, RoomGeometry.FLOOR_EDGE)]), Palette.DOORWAY)


func _draw_lamp_glow(room_id: String) -> void:
	for piece: Dictionary in layout.pieces(room_id):
		if String(piece["kind"]) != "floor_lamp":
			continue
		if sim.house.get_object_state(String(piece.get("object", ""))) != &"lit":
			continue
		var at: Vector2 = RoomGeometry.to_screen(Vector2(float(piece["u"]), float(piece["v"])))
		for ring: int in 4:
			var glow: PackedVector2Array = FurnitureArt._ellipse(at, 260.0 - ring * 55.0, 80.0 - ring * 17.0, 32)
			# Light falls on the floor only, never past the room's edge.
			for clipped: PackedVector2Array in floor_pieces(glow):
				draw_colored_polygon(clipped, Color(1.0, 0.85, 0.5, 0.05))


func _outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, color, width, true)


static func _a(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)

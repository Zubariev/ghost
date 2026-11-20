## How the painted ghost is put on screen (Phase 3, 2026-11-21; docs/art/characters/GHOST.md §7).
## His cutout parts overlap (arms over the body, legs under it), so fading each part on its own
## would show darker seams where they overlap. Instead the whole figure is drawn, opaque, into a
## small offscreen [SubViewport]; a second one holds his halo (his silhouette in one soft colour,
## spread by a few px). [RoomStage] then draws both textures inside its own depth-sorted pass,
## like any other piece of the room, with the opacity, tint and glow from the rig's "look" — so
## furniture in front of him still covers him and the halo, and changing how ghostly he looks
## needs no repainting. Presentation only.
##
## [codeblock]
## var visual := GhostVisual.new(rig, animator)
## stage.add_child(visual)              # the viewports render each frame
## visual.draw_on(stage, foot, scale, glow_boost)   # inside the stage's _draw, at his depth
## [/codeblock]
class_name GhostVisual
extends Node

## Offscreen canvas size (rig canvas px after the build's scale) and where his foot point sits in it.
const CANVAS := Vector2i(480, 500)
const FOOT := Vector2(240, 470)
## Halo: rings of copies of the silhouette (directions per ring).
const HALO_DIRECTIONS: int = 12
const SILHOUETTE_SHADER: String = """
shader_type canvas_item;
uniform vec4 glow : source_color = vec4(0.8, 0.92, 1.0, 1.0);
uniform float strength = 0.22;
void fragment() {
	COLOR = vec4(glow.rgb, texture(TEXTURE, UV).a * strength);
}
"""

var rig: CharacterRig
var animator: GhostAnimator
var look: Dictionary = {}
var _body: SubViewport
var _halo: SubViewport


func _init(ghost_rig: CharacterRig, ghost_animator: GhostAnimator) -> void:
	rig = ghost_rig
	animator = ghost_animator
	look = rig.look if rig != null else {}
	_body = _viewport(false)
	_halo = _viewport(true)


## A setting from the rig's "look" (opacity, glow_alpha, hover_m, …).
func setting(key: String, fallback: float) -> float:
	return float(look.get(key, fallback))


func colour(key: String, fallback: Color) -> Color:
	var c: Array = look.get(key, [])
	return Color(float(c[0]), float(c[1]), float(c[2])) if c.size() >= 3 else fallback


func body_texture() -> Texture2D:
	return _body.get_texture()


func halo_texture() -> Texture2D:
	return _halo.get_texture()


## Screen px per offscreen px at room scale [param s] in the current view.
func screen_scale(s: float) -> float:
	return rig.screen_scale(animator.view, s)


## Where his figure is drawn: [param foot] is his floor point; he hangs [code]hover_m[/code] above
## it. Hiding shrinks him a little toward the spot and sinks him.
func figure_rect(foot: Vector2, s: float) -> Rect2:
	var k: float = screen_scale(s)
	var p: float = animator.presence()
	var shrink: float = lerpf(0.72, 1.0, p)
	var lift: float = setting("hover_m", 0.28) * RoomGeometry.ART_PX_PER_M * s * lerpf(0.3, 1.0, p)
	var anchor: Vector2 = foot - Vector2(0, lift)
	return Rect2(anchor - FOOT * k * shrink, Vector2(CANVAS) * k * shrink)


## Draws his floor shadow, halo and body on [param canvas] at [param foot], room scale [param s];
## [param glow_boost] (0..1) strengthens the halo (a dark room); [param shadow]: a floor under him.
## Call from the canvas's _draw.
func draw_on(canvas: CanvasItem, foot: Vector2, s: float, glow_boost: float = 0.0, shadow: bool = true) -> void:
	var p: float = animator.presence()
	if p <= 0.001:
		return
	var shadow_a: float = setting("shadow_alpha", 0.13) * p if shadow else 0.0
	if shadow_a > 0.0:
		canvas.draw_colored_polygon(Ink.ellipse(foot, 24.0 * s, 6.0 * s, 20), Color(Palette.SB_DUSK_BLUE, shadow_a))
	var rect: Rect2 = figure_rect(foot, s)
	var glow_a: float = setting("glow_alpha", 0.34) * (1.0 + setting("glow_dark_boost", 0.35) * clampf(glow_boost, 0.0, 1.0))
	canvas.draw_texture_rect(_halo.get_texture(), rect, false, Color(1, 1, 1, clampf(glow_a * p, 0.0, 1.0)))
	var tint: Color = colour("tint", Color.WHITE)
	canvas.draw_texture_rect(_body.get_texture(), rect, false, Color(tint, setting("opacity", 0.84) * p))


## Screen point of his chest (wisps toward the object he harms start here).
func chest_point(foot: Vector2, s: float) -> Vector2:
	var rect: Rect2 = figure_rect(foot, s)
	return rect.position + rect.size * Vector2(0.5, 0.36)


func _viewport(halo: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = CANVAS
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	var drawer := _Drawer.new()
	drawer.visual = self
	drawer.halo = halo
	if halo:
		var mat := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = SILHOUETTE_SHADER
		mat.shader = shader
		var g: Color = colour("glow_color", Color(0.8, 0.92, 1.0))
		mat.set_shader_parameter("glow", g)
		drawer.material = mat
	vp.add_child(drawer)
	add_child(vp)
	return vp


## Draws the posed rig into its viewport each frame: opaque (the body) or as rings of silhouettes
## (the halo, coloured by the shader).
class _Drawer:
	extends Node2D

	var visual: GhostVisual
	var halo: bool = false

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var anim: GhostAnimator = visual.animator
		if anim == null or anim.clip.is_empty():
			return
		var pose: Dictionary = anim.current_pose()
		# room scale at which one rig px is one offscreen px
		var s: float = float(visual.rig.views[anim.view].get("px_per_m", 204.0)) / RoomGeometry.ART_PX_PER_M
		if not halo:
			visual.rig.draw(self, anim.view, pose, GhostVisual.FOOT, s, anim.flip, anim.squeeze())
			return
		var r: float = visual.setting("glow_px", 7.0)
		for ring: float in [r, r * 0.5]:
			for i: int in GhostVisual.HALO_DIRECTIONS:
				var off := Vector2.from_angle(TAU * float(i) / float(GhostVisual.HALO_DIRECTIONS)) * ring
				visual.rig.draw(self, anim.view, pose, GhostVisual.FOOT + off, s, anim.flip, anim.squeeze())

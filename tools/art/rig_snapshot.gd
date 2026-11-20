## Renders a rig pose to a PNG without a window (dev tool, 2026-11-20): software compositing of the
## parts with CharacterRig's own transforms, so a pose can be checked headless.
## -- <npc_id> <clip> <t seconds> <out.png> [scale=1]
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var rig: CharacterRig = CharacterRig.load_for(a[0])
	var view: String = rig.clip_view(a[1])
	var pose: Dictionary = rig.sample(a[1], float(a[2]))
	var k: float = float(a[4]) if a.size() > 4 else 1.0
	var v: Dictionary = rig.views[view]
	var parts: Dictionary = v["parts"]
	var out := Image.create(int(500 * k), int(450 * k), false, Image.FORMAT_RGBA8)
	out.fill(Color(0.42, 0.42, 0.42))
	var shift := Vector2(250, 420) * k - Vector2(float(v["foot"][0]), float(v["foot"][1])) * k
	var names: Array = parts.keys()
	names.sort_custom(func(x: String, y: String) -> bool: return int(parts[x]["z"]) < int(parts[y]["z"]))
	var cache: Dictionary = {}
	for name: String in names:
		var p: Dictionary = parts[name]
		var tex := Image.load_from_file(ProjectSettings.globalize_path(String(p["texture"])))
		tex.convert(Image.FORMAT_RGBA8)
		var world: Transform2D = rig._world(parts, name, pose, cache)
		var to_out := Transform2D(0.0, Vector2(k, k), 0.0, shift) * world * Transform2D(0.0, Vector2(float(p["origin"][0]), float(p["origin"][1])))
		var inv: Transform2D = to_out.affine_inverse()
		var corners := [Vector2.ZERO, Vector2(tex.get_width(), 0), Vector2(tex.get_size()), Vector2(0, tex.get_height())]
		var box := Rect2(to_out * corners[0], Vector2.ZERO)
		for c: Vector2 in corners:
			box = box.expand(to_out * c)
		for y: int in range(maxi(0, int(box.position.y)), mini(out.get_height(), int(box.end.y) + 1)):
			for x: int in range(maxi(0, int(box.position.x)), mini(out.get_width(), int(box.end.x) + 1)):
				var src: Vector2 = inv * Vector2(x + 0.5, y + 0.5)
				if src.x < 0 or src.y < 0 or src.x >= tex.get_width() or src.y >= tex.get_height():
					continue
				var c: Color = tex.get_pixel(int(src.x), int(src.y))
				if c.a > 0.01:
					out.set_pixel(x, y, out.get_pixel(x, y).lerp(Color(c, 1.0), c.a))
	out.save_png(a[3])
	quit()

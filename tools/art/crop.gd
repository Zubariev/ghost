## Enlarged crop for reviewing edges (dev tool): -- <in.png> <out.png> <x> <y> <w> <h> <zoom> [bg r,g,b]
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var r := img.get_region(Rect2i(int(a[2]), int(a[3]), int(a[4]), int(a[5])))
	var bg := Image.create(r.get_width(), r.get_height(), false, Image.FORMAT_RGBA8)
	var c: PackedStringArray = (a[7] if a.size() > 7 else "0.2,0.6,0.25").split(",")
	bg.fill(Color(float(c[0]), float(c[1]), float(c[2])))
	bg.blend_rect(r, Rect2i(Vector2i.ZERO, r.get_size()), Vector2i.ZERO)
	bg.resize(bg.get_width() * int(a[6]), bg.get_height() * int(a[6]), Image.INTERPOLATE_NEAREST)
	bg.save_png(a[1])
	quit()

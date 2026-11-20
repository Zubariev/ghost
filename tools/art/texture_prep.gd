## Prepares a generated texture for the game (dev tool, 2026-11-20):
## -- <in.png> <out.png> <size px> [luma_alpha=0] [inset=0]
## [inset] (0..0.3) first crops that fraction off every side (a generated swatch with a light margin).
## Scales to size × size. With luma_alpha 1 (a cobweb painted white on black), brightness becomes
## transparency and the colour pale cream.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var size: int = int(a[2])
	var inset: float = float(a[4]) if a.size() > 4 else 0.0
	if inset > 0.0:
		var m := Vector2i(int(img.get_width() * inset), int(img.get_height() * inset))
		img = img.get_region(Rect2i(m, img.get_size() - m * 2))
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	if a.size() > 3 and a[3] == "1":
		for y: int in size:
			for x: int in size:
				var c: Color = img.get_pixel(x, y)
				var alpha: float = clampf((c.get_luminance() - 0.12) / 0.6, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.93, 0.9, 0.82, alpha))
	img.save_png(a[1])
	print("wrote ", a[1])
	quit()

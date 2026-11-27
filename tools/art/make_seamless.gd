## Makes a texture tile seamlessly with plain (wrapped) repeat (dev tool, sprint 002, 2026-11-27):
## -- <in.png> <out.png> [band=0.25]
## Blends the image with itself shifted by half its size, the shifted copy weighted toward the edges
## (within [band] of the size), so the wrapped edges meet the shifted copy's continuous middle.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var band: float = float(a[2]) if a.size() > 2 else 0.25
	var w: int = img.get_width()
	var h: int = img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		for x: int in w:
			var ex: float = minf(float(x), float(w - 1 - x)) / (float(w) * band)
			var ey: float = minf(float(y), float(h - 1 - y)) / (float(h) * band)
			var keep: float = clampf(minf(ex, ey), 0.0, 1.0)
			keep = keep * keep * (3.0 - 2.0 * keep)
			var shifted: Color = img.get_pixel((x + w / 2) % w, (y + h / 2) % h)
			out.set_pixel(x, y, shifted.lerp(img.get_pixel(x, y), keep))
	out.save_png(a[1])
	print("wrote ", a[1])
	quit()

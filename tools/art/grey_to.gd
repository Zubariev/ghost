## Recolours grey areas of a part (dev tool, character pipeline 2026-11-20): -- <in.png> <out.png> <r,g,b>
## Low-saturation pixels (grey tights that drifted in a generated pose) take the given colour at
## their own brightness, so shading and knit texture stay; coloured pixels (shoes, skirt) stay.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var c: PackedStringArray = a[2].split(",")
	var target := Color(float(c[0]), float(c[1]), float(c[2]))
	var changed: int = 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			var p: Color = img.get_pixel(x, y)
			if p.a < 0.05 or p.s > 0.3 or p.v < 0.04:
				continue
			var k: float = clampf(p.get_luminance() / 0.34, 0.25, 1.35)
			img.set_pixel(x, y, Color(target.r * k, target.g * k, target.b * k, p.a).clamp())
			changed += 1
	img.save_png(a[1])
	print("recoloured %d px" % changed)
	quit()

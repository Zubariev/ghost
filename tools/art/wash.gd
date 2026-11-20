## Washes a painted part toward a pale colour, leaving its ink alone (dev tool, ghost production
## 2026-11-21): -- <in.png> <out.png> <r,g,b> <amount> [ink_max=0.3]
## Every opaque pixel lighter than [ink_max] moves [amount] of the way to the colour; the dark
## contour and alpha are kept. Used per view when one generated view came out greyer or darker
## than the canonical front (the ghost's back and side views), so all views read equally pale.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var rgb: PackedStringArray = a[2].split(",")
	var to := Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
	var amount: float = float(a[3])
	var ink_max: float = float(a[4]) if a.size() > 4 else 0.3
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var lum: float = c.get_luminance()
			if lum < ink_max:
				continue
			# ease in above the ink so the contour's soft edge is not washed into a halo
			var k: float = amount * clampf((lum - ink_max) / 0.12, 0.0, 1.0)
			var w: Color = c.lerp(to, k)
			img.set_pixel(x, y, Color(w, c.a))
	img.save_png(a[1])
	print("washed ", a[1].get_file())
	quit()

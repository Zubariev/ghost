## Grid overlay for reading pixel positions in an image (dev tool): -- <in.png> <out.png> [step=50]
## Thin lines every step px, stronger every 100 px (red), so joints and cut lines can be measured.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var step: int = int(a[2]) if a.size() > 2 else 50
	for x: int in range(0, img.get_width(), step):
		var c := Color(0.85, 0.1, 0.1, 0.8) if x % 100 == 0 else Color(0.2, 0.4, 0.9, 0.45)
		for y: int in img.get_height():
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, c.a))
	for y: int in range(0, img.get_height(), step):
		var c := Color(0.85, 0.1, 0.1, 0.8) if y % 100 == 0 else Color(0.2, 0.4, 0.9, 0.45)
		for x: int in img.get_width():
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, c.a))
	img.save_png(a[1])
	quit()

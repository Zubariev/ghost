## Builds a calm, evenly spread texture from a painted one (dev tool, sprint 002, 2026-11-27):
## -- <in.png> <out.png> <size> <patch px> <patches> <max dark share> [seed=7]
## Scatters soft-edged patches cut from the source's low-contrast parts (few very dark pixels), so
## big features (dark tufts, leaves) are left out. The room stage tiles floors mirrored: a texture
## with strong shapes near its edges turns into kaleidoscope "stars" there; this one has none.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0])
	src.convert(Image.FORMAT_RGBA8)
	var size: int = int(a[2])
	var patch: int = int(a[3])
	var count: int = int(a[4])
	var max_dark: float = float(a[5])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(a[6]) if a.size() > 6 else 7
	# calm source patches: few pixels darker than the threshold
	var calm: Array[Vector2i] = []
	var tries: int = 0
	while calm.size() < 60 and tries < 4000:
		tries += 1
		var at := Vector2i(rng.randi_range(0, src.get_width() - patch), rng.randi_range(0, src.get_height() - patch))
		var dark: int = 0
		for y: int in range(0, patch, 3):
			for x: int in range(0, patch, 3):
				if src.get_pixel(at.x + x, at.y + y).get_luminance() < 0.2:
					dark += 1
		if float(dark) / float((patch / 3) * (patch / 3)) <= max_dark:
			calm.append(at)
	print("calm patches: ", calm.size(), " of ", tries, " tries")
	# base: the calm patches' mean colour
	var mean := Color(0, 0, 0)
	for at: Vector2i in calm:
		var c: Color = src.get_region(Rect2i(at, Vector2i(patch, patch))).get_pixel(patch / 2, patch / 2)
		mean += c / float(calm.size())
	var out := Image.create(size, size, false, Image.FORMAT_RGBA8)
	out.fill(Color(mean.r, mean.g, mean.b, 1.0))
	for i: int in count:
		var from: Vector2i = calm[rng.randi_range(0, calm.size() - 1)]
		var to := Vector2i(rng.randi_range(-patch / 2, size - patch / 2), rng.randi_range(-patch / 2, size - patch / 2))
		for y: int in patch:
			for x: int in patch:
				var p := Vector2i(to.x + x, to.y + y)
				if p.x < 0 or p.y < 0 or p.x >= size or p.y >= size:
					continue
				var d: float = Vector2(x, y).distance_to(Vector2(patch, patch) * 0.5) / (patch * 0.5)
				var w: float = clampf(1.0 - d, 0.0, 1.0)
				w = w * w * (3.0 - 2.0 * w)
				if w <= 0.0:
					continue
				var c: Color = src.get_pixel(from.x + x, from.y + y)
				out.set_pixel(p.x, p.y, out.get_pixel(p.x, p.y).lerp(Color(c.r, c.g, c.b, 1.0), w))
	out.save_png(a[1])
	print("wrote ", a[1])
	quit()

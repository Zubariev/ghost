## Removes a light fringe left around a cut-out (user review 2026-11-20: the main menu room's
## white edge): -- <in.png> <out.png> [passes=3] [light=0.55] [speck_px=40] [grey=0.3] [hard=0]
## [hard] 1 first clears every pixel under half opacity (faint dotted lines along a straight cut).
## Then halo pixels go: an edge pixel more than 0.2 lighter than the pixel just inside it,
## opposite the transparent side (two passes). Last, thin stray lines go: any opaque pixel with transparency on both sides (above and below,
## or left and right) is cleared, repeated until none is left.
## Each pass clears opaque pixels that touch transparency and are whitish (every channel over
## [light] and nearly grey — warm or coloured edges stay);
## then any opaque island smaller than [speck_px] pixels (stray specks) is cleared too.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var passes: int = int(a[2]) if a.size() > 2 else 3
	var light: float = float(a[3]) if a.size() > 3 else 0.55
	var speck: int = int(a[4]) if a.size() > 4 else 40
	var grey: float = float(a[5]) if a.size() > 5 else 0.3   # how far from grey a fringe pixel may be
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var cleared: int = 0
	if a.size() > 6 and a[6] == "1":
		for y: int in h:
			for x: int in w:
				var c: Color = img.get_pixel(x, y)
				if c.a > 0.0 and c.a < 0.5:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
					cleared += 1
	for p: int in passes:
		var kill: Array[Vector2i] = []
		for y: int in h:
			for x: int in w:
				var c: Color = img.get_pixel(x, y)
				if c.a < 0.1 or minf(c.r, minf(c.g, c.b)) < light or maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) > grey:
					continue
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var q := Vector2i(x, y) + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or img.get_pixelv(q).a < 0.1:
						kill.append(Vector2i(x, y))
						break
		for k: Vector2i in kill:
			img.set_pixelv(k, Color(0, 0, 0, 0))
		cleared += kill.size()
	var seen := PackedByteArray()
	seen.resize(w * h)
	for y: int in h:
		for x: int in w:
			if seen[y * w + x] == 1 or img.get_pixel(x, y).a < 0.1:
				continue
			var island: Array[Vector2i] = []
			var q: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			while not q.is_empty():   # the whole island, so a big one is never mistaken for a speck
				var p: Vector2i = q.pop_back()
				island.append(p)
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var n := p + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and seen[n.y * w + n.x] == 0 and img.get_pixelv(n).a >= 0.1:
						seen[n.y * w + n.x] = 1
						q.append(n)
			if island.size() <= speck:
				for p: Vector2i in island:
					img.set_pixelv(p, Color(0, 0, 0, 0))
				cleared += island.size()
	for p: int in 2:
		var halo: Array[Vector2i] = []
		for y: int in h:
			for x: int in w:
				var c: Color = img.get_pixel(x, y)
				if c.a < 0.1:
					continue
				var lighter: bool = false
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var outer := Vector2i(x, y) + d
					var inner := Vector2i(x, y) - d
					if inner.x < 0 or inner.y < 0 or inner.x >= w or inner.y >= h:
						continue
					var outside: bool = outer.x < 0 or outer.y < 0 or outer.x >= w or outer.y >= h or img.get_pixelv(outer).a < 0.1
					if outside and img.get_pixelv(inner).a >= 0.1 and c.get_luminance() - img.get_pixelv(inner).get_luminance() > 0.2:
						lighter = true
				if lighter:
					halo.append(Vector2i(x, y))
		for k: Vector2i in halo:
			img.set_pixelv(k, Color(0, 0, 0, 0))
		cleared += halo.size()
	var thinned: int = -1
	while thinned != 0:
		thinned = 0
		var kill: Array[Vector2i] = []
		for y: int in h:
			for x: int in w:
				if img.get_pixel(x, y).a < 0.1:
					continue
				var up: bool = y == 0 or img.get_pixel(x, y - 1).a < 0.1
				var down: bool = y == h - 1 or img.get_pixel(x, y + 1).a < 0.1
				var left: bool = x == 0 or img.get_pixel(x - 1, y).a < 0.1
				var right: bool = x == w - 1 or img.get_pixel(x + 1, y).a < 0.1
				if (up and down) or (left and right):
					kill.append(Vector2i(x, y))
		for k: Vector2i in kill:
			img.set_pixelv(k, Color(0, 0, 0, 0))
		thinned = kill.size()
		cleared += thinned
	img.save_png(a[1])
	print("cleared %d px" % cleared)
	quit()

## Cuts one body part out of a transparent full canvas (dev tool, character pipeline 2026-11-20):
## -- <canvas.png> <out.png> <scale> <offset px> poly "x,y;x,y;..."   (canvas px before the offset)
## -- <canvas.png> <out.png> <scale> <offset px> comp <left|right|all> (a whole connected piece)
## Keeps only what lies inside the polygon (or the chosen connected piece), crops to it, scales
## it and prints "origin x y size w h" in canvas px × scale (offset removed), so the rig places
## the part exactly where it was painted.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var k: float = float(a[2])
	var off: int = int(a[3])
	var w: int = img.get_width()
	var h: int = img.get_height()
	var keep := PackedByteArray()
	keep.resize(w * h)
	if a[4] == "poly":
		var poly := PackedVector2Array()
		for pair: String in a[5].split(";"):
			var xy: PackedStringArray = pair.split(",")
			poly.append(Vector2(float(xy[0]) + off, float(xy[1]) + off))
		for y: int in h:
			for x: int in w:
				if img.get_pixel(x, y).a > 0.05 and Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
					keep[y * w + x] = 1
	else:
		var pieces: Array = _pieces(img, w, h)
		pieces.sort_custom(func(p: Array, q: Array) -> bool: return p.size() > q.size())
		var chosen: Array = []
		if a[5] == "all":
			for p: Array in pieces:
				if p.size() > 200:
					chosen.append_array(p)
		else:
			var big: Array = pieces.slice(0, 2)
			big.sort_custom(func(p: Array, q: Array) -> bool: return _cx(p) < _cx(q))
			chosen = big[0] if a[5] == "left" else big[big.size() - 1]
		for p: Vector2i in chosen:
			keep[p.y * w + p.x] = 1
	var box := Rect2i()
	var first: bool = true
	for y: int in h:
		for x: int in w:
			if keep[y * w + x] == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif first:
				box = Rect2i(x, y, 1, 1)
				first = false
			else:
				box = box.expand(Vector2i(x, y))
	box.size += Vector2i.ONE
	box = box.grow(2).intersection(Rect2i(0, 0, w, h))
	var cut: Image = img.get_region(box)
	cut.resize(maxi(1, roundi(box.size.x * k)), maxi(1, roundi(box.size.y * k)), Image.INTERPOLATE_LANCZOS)
	cut.save_png(a[1])
	print("origin %.2f %.2f size %d %d" % [(box.position.x - off) * k, (box.position.y - off) * k, cut.get_width(), cut.get_height()])
	quit()


func _pieces(img: Image, w: int, h: int) -> Array:
	var seen := PackedByteArray()
	seen.resize(w * h)
	var out: Array = []
	for y: int in h:
		for x: int in w:
			if seen[y * w + x] == 1 or img.get_pixel(x, y).a <= 0.1:
				continue
			var piece: Array = []
			var q: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			while not q.is_empty():
				var p: Vector2i = q.pop_back()
				piece.append(p)
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var n := p + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and seen[n.y * w + n.x] == 0 and img.get_pixelv(n).a > 0.1:
						seen[n.y * w + n.x] = 1
						q.append(n)
			out.append(piece)
	return out


func _cx(p: Array) -> float:
	var s: float = 0.0
	for v: Vector2i in p:
		s += v.x
	return s / maxf(1.0, float(p.size()))

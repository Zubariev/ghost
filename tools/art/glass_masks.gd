## Glass masks for a painted window's states (SPRITE_SPEC §1): -- <closed.png> <open.png> ...
## Transparent pixels the outside cannot reach, in pockets at least 6 px tall and wide (panes, not
## slivers under a rod); the first image's pane area clips the others (an open sash shows the
## wall below the sill too). Writes <name>_glass.png beside each.
extends SceneTree


func _initialize() -> void:
	var clip := Rect2i()
	for path: String in OS.get_cmdline_user_args():
		var img := Image.load_from_file(path)
		img.convert(Image.FORMAT_RGBA8)
		var w: int = img.get_width()
		var h: int = img.get_height()
		var seen := PackedByteArray()
		seen.resize(w * h)
		var q: Array[Vector2i] = []
		for x: int in w:
			q.append(Vector2i(x, 0))
			q.append(Vector2i(x, h - 1))
		for y: int in h:
			q.append(Vector2i(0, y))
			q.append(Vector2i(w - 1, y))
		_fill(img, seen, q, w, h)
		var mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var box := Rect2i()
		var first: bool = true
		for y: int in h:
			for x: int in w:
				if seen[y * w + x] != 0 or img.get_pixel(x, y).a >= 0.5:
					continue
				var pocket: Array[Vector2i] = _fill(img, seen, [Vector2i(x, y)] as Array[Vector2i], w, h)
				var pb := Rect2i(pocket[0], Vector2i.ONE)
				for p: Vector2i in pocket:
					pb = pb.expand(p)
				pb.size += Vector2i.ONE
				if pb.size.x < 6 or pb.size.y < 6:
					continue
				for p: Vector2i in pocket:
					if clip.has_area() and not clip.grow(2).has_point(p):
						continue
					for dy: int in range(-1, 2):
						for dx: int in range(-1, 2):
							var d := p + Vector2i(dx, dy)
							if d.x >= 0 and d.y >= 0 and d.x < w and d.y < h:
								mask.set_pixelv(d, Color.WHITE)
				if first:
					box = pb
					first = false
				else:
					box = box.merge(pb)
		if not clip.has_area():
			clip = box
		mask.save_png(path.get_basename() + "_glass.png")
		print("%s panes %s" % [path.get_file(), box])
	quit()


func _fill(img: Image, seen: PackedByteArray, q: Array[Vector2i], w: int, h: int) -> Array[Vector2i]:
	var got: Array[Vector2i] = []
	var i: int = 0
	while i < q.size():
		var p: Vector2i = q[i]
		i += 1
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x] == 1:
			continue
		if img.get_pixelv(p).a > 0.5:
			continue
		seen[p.y * w + p.x] = 1
		got.append(p)
		q.append(p + Vector2i.LEFT)
		q.append(p + Vector2i.RIGHT)
		q.append(p + Vector2i.UP)
		q.append(p + Vector2i.DOWN)
	return got

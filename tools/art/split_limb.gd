## Splits a limb off a full pose in place (dev tool, character pipeline 2026-11-20):
## -- <pose.png> <limb_out.png> <body_out.png> <limb poly "x,y;..."> <fill poly "x,y;...">
## The limb image keeps only the pixels inside the limb polygon (white elsewhere); the body image
## is the pose with the limb removed: inside the fill polygon (the part of the body the limb
## covered) it is painted with the body's own colour, sampled just beside it, so a moving limb
## never opens a hole; the rest of the limb becomes white background.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var pose := Image.load_from_file(a[0])
	pose.convert(Image.FORMAT_RGBA8)
	var limb := _poly(a[3])
	var fill := _poly(a[4])
	var w: int = pose.get_width()
	var h: int = pose.get_height()
	var part := Image.create(w, h, false, Image.FORMAT_RGBA8)
	part.fill(Color.WHITE)
	var body: Image = pose.duplicate()
	var box: Rect2 = Rect2(fill[0], Vector2.ZERO)
	for p: Vector2 in fill:
		box = box.expand(p)
	# the body's colour: the average of the pose in a strip just left of the fill area
	var sum := Color(0, 0, 0, 0)
	var n: int = 0
	for y: int in range(int(box.position.y), int(box.end.y)):
		for x: int in range(int(box.position.x) - 22, int(box.position.x) - 4):
			var c: Color = pose.get_pixel(x, y)
			if minf(c.r, minf(c.g, c.b)) < 0.85 and c.get_luminance() > 0.25:
				sum += c
				n += 1
	var cardigan: Color = sum / float(maxi(1, n))
	cardigan.a = 1.0
	for y: int in h:
		for x: int in w:
			var p := Vector2(x, y)
			if not Geometry2D.is_point_in_polygon(p, limb):
				continue
			part.set_pixel(x, y, pose.get_pixel(x, y))
			body.set_pixel(x, y, cardigan if Geometry2D.is_point_in_polygon(p, fill) else Color.WHITE)
	part.save_png(a[1])
	body.save_png(a[2])
	print("body colour ", cardigan, " from ", n, " px")
	quit()


func _poly(s: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pair: String in s.split(";"):
		var xy: PackedStringArray = pair.split(",")
		out.append(Vector2(float(xy[0]), float(xy[1])))
	return out

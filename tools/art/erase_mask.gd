## Erases a part from a full pose (dev tool, character pipeline 2026-11-20):
## -- <pose.png> <part.png> <out.png> [grow px=2]
## Wherever the part image (same canvas layout, white background) is painted, the pose becomes
## white background, grown by a few px — the body without that limb, for the limb to move on top.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var pose := Image.load_from_file(a[0])
	var part := Image.load_from_file(a[1])
	pose.convert(Image.FORMAT_RGBA8)
	part.convert(Image.FORMAT_RGBA8)
	var grow: int = int(a[3]) if a.size() > 3 else 2
	var w: int = pose.get_width()
	var h: int = pose.get_height()
	var erased: int = 0
	for y: int in h:
		for x: int in w:
			var c: Color = part.get_pixel(x, y)
			if minf(c.r, minf(c.g, c.b)) > 0.9:
				continue   # white: not the part
			for dy: int in range(-grow, grow + 1):
				for dx: int in range(-grow, grow + 1):
					var q := Vector2i(x + dx, y + dy)
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
						pose.set_pixelv(q, Color.WHITE)
						erased += 1
	pose.save_png(a[2])
	print("erased %d px" % erased)
	quit()

## Turns a painted prop on a plain light background into a game sprite (art Phase 3,
## 2026-11-15; docs/art/SPRITE_SPEC.md §3): the background becomes transparent (flood fill from
## the image border, so light areas inside the inked outline stay solid), edge pixels are
## un-blended from the background, enclosed near-white pockets cleared too, the image is cropped (optionally cut at [crop_top]), scaled
## by [resize] and padded with 4 transparent pixels. Fully transparent pixels carry the ink
## colour so filtering never bleeds a white fringe. Verification output: the size and the
## mapping from source to sprite pixels, to set the anchor.
##
## Run: godot --headless --path . -s res://tools/sprite_cutout.gd -- <in> <out.png> [crop_top] [resize] [bg_min] [box] [islands]
## [bg_min] (default 0.86): how light a background pixel is at least; lower it for a painted
## grey-and-white checkerboard (menu sheet, 2026-11-15: 0.80).
## [box] "x,y,w,h" (source px): crop to this box instead of the object's own bounds, so the
## images of one prop's states share one frame and line up (2026-11-20).
## [islands] (default 1): 0 keeps enclosed near-white pockets — for white objects (a tablecloth,
## a bathtub) whose light areas are not background (2026-11-20).
extends SceneTree

var BG_MIN: float = 0.86          # a background pixel: every channel at least this light…
const BG_SPREAD: float = 0.06     # …and nearly grey
const ISLAND_MIN: float = 0.96   # enclosed pockets (a handle loop, gaps between leaves) this
const ISLAND_SPREAD: float = 0.03 # white and grey are background too, though the fill can't reach them
const PAD: int = 4
const INK := Color(0.24, 0.19, 0.15, 0.0)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <in> <out.png> [crop_top] [resize]")
		quit(1)
		return
	var crop_top: int = int(args[2]) if args.size() > 2 else 0
	var resize: float = float(args[3]) if args.size() > 3 else 1.0
	if args.size() > 4:
		BG_MIN = float(args[4])
	var fixed_box: PackedStringArray = args[5].split(",") if args.size() > 5 and not args[5].is_empty() else PackedStringArray()
	var islands: bool = args.size() <= 6 or args[6] != "0"
	var img := Image.load_from_file(args[0])
	if img == null:
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var bg := PackedByteArray()
	bg.resize(w * h)
	var queue: Array[Vector2i] = []
	for x: int in w:
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y: int in h:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
	var head: int = 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or bg[p.y * w + p.x] == 1:
			continue
		if not _is_bg(img.get_pixelv(p)):
			continue
		bg[p.y * w + p.x] = 1
		queue.append(p + Vector2i.LEFT)
		queue.append(p + Vector2i.RIGHT)
		queue.append(p + Vector2i.UP)
		queue.append(p + Vector2i.DOWN)
	for y: int in h:
		for x: int in w:
			var c: Color = img.get_pixel(x, y)
			if islands and bg[y * w + x] == 0 and minf(c.r, minf(c.g, c.b)) >= ISLAND_MIN and maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) <= ISLAND_SPREAD:
				bg[y * w + x] = 1
	var box := Rect2i()
	var first: bool = true
	for y: int in h:
		for x: int in w:
			if bg[y * w + x] == 1:
				img.set_pixel(x, y, INK)
				continue
			if _touches_bg(bg, w, h, x, y):
				img.set_pixel(x, y, _unblend(img.get_pixel(x, y)))
			if y < crop_top:
				continue
			if first:
				box = Rect2i(x, y, 1, 1)
				first = false
			else:
				box = box.expand(Vector2i(x, y))
	box.size += Vector2i.ONE
	if fixed_box.size() == 4:
		box = Rect2i(int(fixed_box[0]), int(fixed_box[1]), int(fixed_box[2]), int(fixed_box[3])).intersection(Rect2i(0, 0, w, h))
	var cut: Image = img.get_region(box)
	var size := Vector2i(roundi(box.size.x * resize), roundi(box.size.y * resize))
	cut.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(size.x + PAD * 2, size.y + PAD * 2, false, Image.FORMAT_RGBA8)
	out.fill(INK)
	out.blit_rect(cut, Rect2i(Vector2i.ZERO, size), Vector2i(PAD, PAD))
	out.save_png(args[1])
	print("wrote %s %dx%d; source box %s; sprite px = (source px - %s) * %.4f + %d" % [
		args[1], out.get_width(), out.get_height(), box, box.position, resize, PAD])
	quit()


func _is_bg(c: Color) -> bool:
	return minf(c.r, minf(c.g, c.b)) >= BG_MIN and maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) <= BG_SPREAD


func _touches_bg(bg: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var q := Vector2i(x, y) + d
		if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and bg[q.y * w + q.x] == 1:
			return true
	return false


## An edge pixel partly mixed with the white background: alpha from how light it is, colour
## with the white taken back out.
func _unblend(c: Color) -> Color:
	var light: float = minf(c.r, minf(c.g, c.b))
	var a: float = clampf((1.0 - light) / (1.0 - 0.55), 0.0, 1.0)
	if a >= 1.0:
		return c
	if a <= 0.02:
		return INK
	return Color((c.r - (1.0 - a)) / a, (c.g - (1.0 - a)) / a, (c.b - (1.0 - a)) / a, a).clamp()

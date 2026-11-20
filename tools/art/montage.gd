## Contact sheet for reviewing art (dev tool): -- <out.png> <cell px> <cols> <files...>;
## transparent areas show on mid grey.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var cell: int = int(a[1])
	var cols: int = int(a[2])
	var files: PackedStringArray = a.slice(3)
	var rows: int = ceili(files.size() / float(cols))
	var out := Image.create(cell * cols, cell * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.45, 0.42, 0.4))
	for i: int in files.size():
		var img := Image.load_from_file(files[i])
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var k: float = (cell - 6) / float(maxi(img.get_width(), img.get_height()))
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_BILINEAR)
		var at := Vector2i((i % cols) * cell + (cell - img.get_width()) / 2, (i / cols) * cell + (cell - img.get_height()) / 2)
		out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
	out.save_png(a[0])
	quit()

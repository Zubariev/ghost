## Puts a concept image and in-game screenshots side by side for art review (art Phase 1,
## 2026-11-15): concept on the left, screenshot on the right, both scaled to 1280 × 720.
## Verification only; reads files, writes PNGs, changes nothing in the game.
##
## Run: godot --headless --path . -s res://tools/art_compare.gd -- <concept> <out_dir> <shot>...
## Each output is <out_dir>/compare-<shot name>.png.
extends SceneTree

const SIZE := Vector2i(1280, 720)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: -- <concept> <out_dir> <shot>...")
		quit(1)
		return
	var concept: Image = _fit(args[0])
	for i: int in range(2, args.size()):
		var shot: Image = _fit(args[i])
		if concept == null or shot == null:
			quit(1)
			return
		var out := Image.create(SIZE.x * 2 + 16, SIZE.y, false, Image.FORMAT_RGBA8)
		out.fill(Color("1b1a22"))
		out.blit_rect(concept, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
		out.blit_rect(shot, Rect2i(Vector2i.ZERO, SIZE), Vector2i(SIZE.x + 16, 0))
		var path: String = args[1].path_join("compare-" + args[i].get_file().get_basename() + ".png")
		out.save_png(path)
		print("wrote ", path)
	quit()


## Loads [param path] and scales it to fill 1280 × 720, cropping the overflow evenly.
func _fit(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null:
		push_error("cannot load " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	var scale: float = maxf(float(SIZE.x) / image.get_width(), float(SIZE.y) / image.get_height())
	image.resize(ceili(image.get_width() * scale), ceili(image.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var offset := Vector2i((image.get_width() - SIZE.x) / 2, (image.get_height() - SIZE.y) / 2)
	return image.get_region(Rect2i(offset, SIZE))

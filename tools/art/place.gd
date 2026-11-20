## Re-places a generated part on the 1024 canvas (dev tool, character pipeline 2026-11-20):
## -- <in.png> <out.png> <scale> <dx> <dy>   new px = old px × scale + (dx, dy); white elsewhere.
## For a part the generator painted at the wrong size (the father's side arm came out 2.3× too big):
## measure the part's box and where it belongs on the rig pose, then fit it there.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var k: float = float(a[2])
	img.resize(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	var out := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(a[3]), int(a[4])))
	out.save_png(a[1])
	quit()

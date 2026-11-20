## Mirrors an image left to right (dev tool): -- <in.png> <out.png>. A side view painted facing
## left becomes the rig's convention (facing right), so walk clips keep one set of signs.
extends SceneTree


func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.flip_x()
	img.save_png(a[1])
	quit()

## Font trial (2026-11-15): shows candidate fonts at the game's real size (1280 × 720) with the
## game's own Ukrainian text — title, story text, HUD labels and numbers, small item names —
## over the dark HUD panel and the cream storybook paper, and reports which Ukrainian letters each
## font lacks. Verification only: reads font files from a folder, writes a PNG, changes nothing.
##
## Run (windowed, from the user's terminal):
##   godot --path . --resolution 1280x720 -s res://tools/font_specimen.gd -- <fonts_dir> <out.png>
## The fonts_dir holds the candidates; each is matched by a name fragment (see ROLES).
extends SceneTree

## role -> [file-name fragment, caption, sample lines (size, text)]. The brief's Atkinson
## Hyperlegible Next and IM Fell English have no Cyrillic, so Cyrillic-capable stand-ins are shown.
const ROLES: Array = [
	["AlegreyaSC-Bold", "Title · Alegreya SC Bold", [[34, "Привид проти людей"]]],
	["Kurale", "Title · Kurale", [[34, "Привид проти людей"]]],
	["YesevaOne", "Title · Yeseva One", [[34, "Привид проти людей"]]],
	["Alegreya[", "Story · Alegreya", [[20, "Будинок довго стояв порожнім — це ваш дім. Тепер сюди в'їхала сім'я з шести людей."],
		[16, "«Любий Матвію, ключі лишаю під ґанком. Не вмикай світла на горищі — воно не любить світла.»"]]],
	["AlegreyaSans-Medium", "Interface · Alegreya Sans Medium", [[22, "День 1  22:10 · Ніч  ×1"], [15, "Енергія 75 / 100 · Рішучість сім'ї 42 · поїдуть на 20"],
		[12, "Недогарок свічки ×3 · WASD — рух крізь стіни · E (утримувати) — дія · Їжак, ґанок, Єва"]]],
	["PT_Sans", "Interface · PT Sans", [[22, "День 1  22:10 · Ніч  ×1"], [15, "Енергія 75 / 100 · Рішучість сім'ї 42 · поїдуть на 20"],
		[12, "Недогарок свічки ×3 · WASD — рух крізь стіни · E (утримувати) — дія · Їжак, ґанок, Єва"]]],
	["Rubik", "Interface · Rubik", [[22, "День 1  22:10 · Ніч  ×1"], [15, "Енергія 75 / 100 · Рішучість сім'ї 42 · поїдуть на 20"],
		[12, "Недогарок свічки ×3 · WASD — рух крізь стіни · E (утримувати) — дія · Їжак, ґанок, Єва"]]],
]
const UKRAINIAN: String = "АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯабвгґдеєжзиіїйклмнопрстуфхцчшщьюя'’«»—×·"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <fonts_dir> <out.png>")
		quit(1)
		return
	var root := Control.new()
	root.size = Vector2(1280, 720)
	get_root().add_child(root)
	var dark := ColorRect.new()
	dark.color = Color(0.07, 0.06, 0.09)
	dark.size = Vector2(640, 720)
	root.add_child(dark)
	var paper := ColorRect.new()
	paper.color = Palette.SB_PARCHMENT if ClassDB.class_exists("Palette") else Color("e9dcc0")
	paper.position = Vector2(640, 0)
	paper.size = Vector2(640, 720)
	root.add_child(paper)
	var y: float = 12.0
	for role: Array in ROLES:
		var font: FontFile = _find(args[0], String(role[0]))
		var missing: String = _missing(font)
		print("%s: %s" % [role[1], "not found" if font == null else ("all Ukrainian letters present" if missing.is_empty() else "MISSING " + missing)])
		for side: int in 2:
			var ink: Color = Color(0.95, 0.9, 0.8) if side == 0 else Color(0.18, 0.13, 0.1)
			var caption := _label(ThemeDB.fallback_font, 11, String(role[1]) + ("" if missing.is_empty() else "  — missing: " + missing), Color(ink, 0.6))
			caption.position = Vector2(16 + side * 640, y)
			root.add_child(caption)
		y += 18.0
		for line: Array in role[2]:
			var size: int = int(line[0])
			for side: int in 2:
				var ink: Color = Color(0.95, 0.9, 0.8) if side == 0 else Color(0.18, 0.13, 0.1)
				var label := _label(font if font != null else ThemeDB.fallback_font, size, String(line[1]), ink)
				label.position = Vector2(16 + side * 640, y)
				label.size = Vector2(608, 0)
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				root.add_child(label)
			y += size * (2.7 if size >= 15 and String(line[1]).length() > 55 else 1.45)
		y += 4.0
	for i: int in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(args[1])
	print("wrote ", args[1])
	quit()


func _find(dir: String, fragment: String) -> FontFile:
	for file: String in DirAccess.get_files_at(dir):
		if file.contains(fragment) and (file.ends_with(".ttf") or file.ends_with(".otf")):
			var font := FontFile.new()
			if font.load_dynamic_font(dir.path_join(file)) == OK:
				return font
	return null


## Ukrainian letters and punctuation the font does not have ("" = all there).
func _missing(font: FontFile) -> String:
	if font == null:
		return ""
	var out: String = ""
	for i: int in UKRAINIAN.length():
		if not font.has_char(UKRAINIAN.unicode_at(i)):
			out += UKRAINIAN[i]
	return out


func _label(font: Font, size: int, text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label

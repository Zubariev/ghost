## The game's fonts (user decision 2026-11-15, assets/fonts/README.md): each loads, draws every
## Ukrainian letter and the punctuation the strings use, and ships with its OFL licence text.
## Guards against swapping in a font without Cyrillic (the trial's first picks had none).
extends GdUnitTestSuite

const UKRAINIAN: String = "АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯабвгґдеєжзиіїйклмнопрстуфхцчшщьюя'’«»—×·…0123456789%"
const LICENCES: Dictionary = {
	UiFonts.TITLE_PATH: "res://assets/fonts/YesevaOne-OFL.txt",
	UiFonts.UI_PATH: "res://assets/fonts/PTSans-OFL.txt",
	UiFonts.STORY_PATH: "res://assets/fonts/Alegreya-OFL.txt",
}


func test_every_font_loads_and_draws_all_ukrainian_letters() -> void:
	for path: String in LICENCES:
		var font := load(path) as Font
		assert_object(font).override_failure_message("cannot load " + path).is_not_null()
		var missing: String = ""
		for i: int in UKRAINIAN.length():
			if not font.has_char(UKRAINIAN.unicode_at(i)):
				missing += UKRAINIAN[i]
		assert_str(missing).override_failure_message(path + " lacks: " + missing).is_empty()


func test_every_font_ships_with_its_open_font_licence() -> void:
	for path: String in LICENCES:
		var licence: String = FileAccess.get_file_as_string(String(LICENCES[path]))
		assert_str(licence).override_failure_message("no licence for " + path).contains("SIL Open Font License, Version 1.1")


func test_a_label_without_its_own_font_uses_the_interface_font() -> void:
	# Regression (2026-11-16 capture): UiFonts.apply() set only ThemeDB.fallback_font, which
	# controls do not use when the engine's default theme has its own font — settings labels and
	# the HUD clock showed the engine font instead of PT Sans.
	UiFonts.apply()
	var label: Label = auto_free(Label.new())
	get_tree().root.add_child(label)
	var font: Font = label.get_theme_font(&"font")
	get_tree().root.remove_child(label)
	assert_str(font.get_font_name()).is_equal(UiFonts.ui().get_font_name())

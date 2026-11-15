## The game's three fonts (user decision 2026-11-15; `assets/fonts/README.md`): Yeseva One for
## titles, PT Sans for the interface (the default for every label and for text drawn on canvases),
## Alegreya for story text. All cover the Ukrainian alphabet; SIL OFL 1.1.
##
## [codeblock]
## UiFonts.apply()                       # once, before building any UI
## label.add_theme_font_override(&"font", UiFonts.title())
## [/codeblock]
class_name UiFonts
extends RefCounted

const TITLE_PATH: String = "res://assets/fonts/YesevaOne-Regular.ttf"
const UI_PATH: String = "res://assets/fonts/PTSans-Regular.ttf"
const STORY_PATH: String = "res://assets/fonts/Alegreya-Variable.ttf"


## Makes the interface font the default: Controls without a font of their own (through the
## engine's default theme, which has a font of its own — setting only the fallback missed them,
## 2026-11-16) and every [code]draw_string(ThemeDB.fallback_font, …)[/code] use it.
static func apply() -> void:
	var font: Font = ui()
	if font == null:
		return
	ThemeDB.fallback_font = font
	var theme: Theme = ThemeDB.get_default_theme()
	if theme != null:
		theme.default_font = font


static func title() -> Font:
	return load(TITLE_PATH) as Font


static func ui() -> Font:
	return load(UI_PATH) as Font


static func story() -> Font:
	return load(STORY_PATH) as Font


## Gives [param label] the font for [param role] ("title", "story"; anything else: interface).
static func use(label: Control, role: String) -> void:
	var font: Font = title() if role == "title" else story() if role == "story" else ui()
	if font != null:
		label.add_theme_font_override(&"font", font)

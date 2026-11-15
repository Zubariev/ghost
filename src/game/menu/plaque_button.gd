## A menu button drawn as an aged parchment plaque (main menu, 2026-11-15; art from the user's
## sheet `art/references/Вікторіанська вітальня та кнопки UI.png`, cut out to
## `assets/art/ui/menu/`). Normal: muted parchment; hover and keyboard focus: the warm, glowing
## plaque; pressed: the warm plaque darkened; disabled: muted and faded. The ornamented ends keep
## their shape (nine-patch margins) whatever the width. Alegreya label, dark brown ink.
## Hovering with the mouse moves the keyboard focus here, so only one plaque is ever lit.
class_name PlaqueButton
extends Button

const NORMAL_PATH: String = "res://assets/art/ui/menu/plaque_normal.png"
const HOVER_PATH: String = "res://assets/art/ui/menu/plaque_hover.png"
## Width of the ornamented ends in the plaque images (px), kept unstretched.
const END_MARGIN: float = 30.0
const INK := Color("3a2614")
const INK_DISABLED := Color(0.23, 0.15, 0.08, 0.45)


## A plaque labelled [param text], [param width] wide, with [param font_size] text.
static func create(text: String, width: float = 300.0, font_size: int = 24) -> PlaqueButton:
	var button := PlaqueButton.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 58)
	button.add_theme_font_size_override(&"font_size", font_size)
	return button


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	var normal: StyleBox = _plaque(NORMAL_PATH, Color.WHITE)
	var lit: StyleBox = _plaque(HOVER_PATH, Color.WHITE)
	add_theme_stylebox_override(&"normal", normal)
	add_theme_stylebox_override(&"hover", lit)
	add_theme_stylebox_override(&"focus", lit)
	add_theme_stylebox_override(&"hover_pressed", _plaque(HOVER_PATH, Color(0.78, 0.7, 0.6)))
	add_theme_stylebox_override(&"pressed", _plaque(HOVER_PATH, Color(0.78, 0.7, 0.6)))
	add_theme_stylebox_override(&"disabled", _plaque(NORMAL_PATH, Color(0.6, 0.58, 0.55, 0.55)))
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		add_theme_color_override(state, INK)
	add_theme_color_override(&"font_disabled_color", INK_DISABLED)
	var font: Font = UiFonts.story()
	if font != null:
		add_theme_font_override(&"font", font)
	mouse_entered.connect(func() -> void:
		if not disabled:
			grab_focus())


## A plaque style from [param path]; falls back to a flat parchment box if the image is missing.
static func _plaque(path: String, tint: Color) -> StyleBox:
	var tex := load(path) as Texture2D if ResourceLoader.exists(path) else null
	if tex == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Palette.SB_PARCHMENT * tint
		flat.set_corner_radius_all(6)
		return flat
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = END_MARGIN
	box.texture_margin_right = END_MARGIN
	box.modulate_color = tint
	box.content_margin_left = END_MARGIN
	box.content_margin_right = END_MARGIN
	box.content_margin_top = 4
	box.content_margin_bottom = 8
	return box

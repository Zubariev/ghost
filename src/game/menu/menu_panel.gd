## A main-menu sub-screen (Load Game, Settings, Credits, confirmations; 2026-11-15): a dark
## walnut panel with a thin antique-gold border, a Yeseva One title over a small ornamental
## divider, its content, and a row of plaque buttons. Reusable: the menu builds every sub-screen
## from it.
##
## [codeblock]
## var panel := MenuPanel.create(tr("CREDITS_TITLE"), Vector2(620, 0))
## panel.body.add_child(some_label)
## panel.add_button(PlaqueButton.create(tr("MENU_BACK")))
## [/codeblock]
class_name MenuPanel
extends PanelContainer

const BG := Color(0.13, 0.09, 0.07, 0.94)
const BORDER := Color(0.71, 0.54, 0.31, 0.85)

## Where the panel's content goes.
var body: VBoxContainer
## Width of the content (panel width minus its margins): wrapped text needs it, or a label with
## no width wraps after every letter and the panel grows past the screen.
var content_width: float = 548.0
## The plaque buttons along the bottom.
var buttons: HBoxContainer


## A panel titled [param title], at least [param min_size].
static func create(title: String, min_size: Vector2 = Vector2(600, 0)) -> MenuPanel:
	var panel := MenuPanel.new()
	panel.custom_minimum_size = min_size
	panel.content_width = maxf(200.0, min_size.x - 52.0)
	panel._build(title)
	return panel


func _build(title: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(26)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override(&"font_size", 32)
	heading.add_theme_color_override(&"font_color", Palette.SB_CANDLELIGHT)
	UiFonts.use(heading, "title")
	column.add_child(heading)
	column.add_child(MenuPanel.divider(260.0))
	body = VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 12)
	column.add_child(body)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 16)
	column.add_child(buttons)


## Adds [param button] to the bottom row and returns it.
func add_button(button: Button) -> Button:
	buttons.add_child(button)
	return button


## A text line in the panel's content: [param role] "story" (Alegreya) or interface (PT Sans).
func add_text(text: String, font_size: int = 17, color: Color = Palette.SB_CREAM, role: String = "ui") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(content_width, 0)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	UiFonts.use(label, role)
	body.add_child(label)
	return label


## A small ornamental divider: a thin gold line with a diamond in the middle, [param width] wide.
static func divider(width: float) -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(width, 12)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.draw.connect(func() -> void:
		var mid := Vector2(line.size.x * 0.5, 6.0)
		line.draw_line(Vector2(0, 6), mid - Vector2(10, 0), Color(BORDER, 0.7), 1.0, true)
		line.draw_line(mid + Vector2(10, 0), Vector2(line.size.x, 6), Color(BORDER, 0.7), 1.0, true)
		line.draw_colored_polygon(PackedVector2Array([mid + Vector2(0, -5), mid + Vector2(6, 0), mid + Vector2(0, 5), mid + Vector2(-6, 0)]), BORDER))
	return line

## Small code-drawn icons for collectable items (loot grid, journal), in the storybook style.
## Placeholder art like the rest: an icon key from loot.json picks the drawing; unknown keys
## get a plain token.
class_name ItemArt
extends RefCounted


## Draws icon [param icon] centred at [param c], fitting a square of [param size] px.
static func draw(canvas: CanvasItem, icon: String, c: Vector2, size: float) -> void:
	var s: float = size / 40.0
	match icon:
		"dust":
			for p: Vector2 in [Vector2(-7, 3), Vector2(4, -2), Vector2(8, 7), Vector2(-2, -8)]:
				canvas.draw_colored_polygon(Ink.ellipse(c + p * s, 6 * s, 5 * s, 12), Color(Palette.SB_ASH, 0.8))
		"cobweb":
			for k: int in 6:
				var a: float = TAU * float(k) / 6.0
				canvas.draw_line(c, c + Vector2(cos(a), sin(a)) * 15 * s, Palette.SB_CREAM, 1.2, true)
			for r: float in [5.0, 10.0, 15.0]:
				canvas.draw_arc(c, r * s, 0, TAU, 12, Color(Palette.SB_CREAM, 0.8), 1.0, true)
		"candle":
			var body := StorybookArt._rect(c.x - 5 * s, c.y - 4 * s, c.x + 5 * s, c.y + 14 * s)
			Ink.shape(canvas, body, Palette.SB_CREAM, Ink.Tier.INTERACTIVE, 1.0)
			canvas.draw_colored_polygon(Ink.ellipse(c + Vector2(0, -10) * s, 3 * s, 5 * s, 10), Palette.SB_CANDLELIGHT)
		"nail":
			canvas.draw_line(c + Vector2(-10, 10) * s, c + Vector2(9, -9) * s, Palette.SB_TERRACOTTA.darkened(0.3), 3.0 * s, true)
			canvas.draw_line(c + Vector2(5, -13) * s, c + Vector2(13, -5) * s, Palette.SB_BROWN_GREY, 4.0 * s, true)
		"thread":
			var pts := PackedVector2Array()
			for i: int in 14:
				var t: float = float(i) / 13.0
				pts.append(c + Vector2(lerpf(-14, 14, t), sin(t * 9.0) * 6) * s)
			canvas.draw_polyline(pts, Palette.SB_ROSE, 2.5 * s, true)
		"key":
			canvas.draw_arc(c + Vector2(-8, 0) * s, 6 * s, 0, TAU, 14, Palette.SB_GOLD, 3.0 * s, true)
			canvas.draw_line(c + Vector2(-2, 0) * s, c + Vector2(14, 0) * s, Palette.SB_GOLD, 3.0 * s, true)
			canvas.draw_line(c + Vector2(10, 0) * s, c + Vector2(10, 5) * s, Palette.SB_GOLD, 3.0 * s, true)
			canvas.draw_line(c + Vector2(14, 0) * s, c + Vector2(14, 6) * s, Palette.SB_GOLD, 3.0 * s, true)
		"letter", "page":
			var sheet := PackedVector2Array([c + Vector2(-11, -14) * s, c + Vector2(11, -13) * s, c + Vector2(12, 14) * s, c + Vector2(-12, 13) * s])
			Ink.shape(canvas, sheet, Palette.SB_CREAM, Ink.Tier.INTERACTIVE, 2.0)
			for k: int in 4:
				var y: float = (-7.0 + 6.0 * float(k)) * s
				canvas.draw_line(c + Vector2(-7 * s, y), c + Vector2(7 * s - (4.0 * s if k == 3 else 0.0), y), Color(Palette.SB_BROWN_GREY, 0.7), 1.2, true)
			if icon == "letter":
				canvas.draw_colored_polygon(Ink.ellipse(c + Vector2(6, 9) * s, 3.5 * s, 3.5 * s, 10), Palette.SB_TERRACOTTA)
		"photo":
			Ink.shape(canvas, StorybookArt._rect(c.x - 13 * s, c.y - 11 * s, c.x + 13 * s, c.y + 11 * s), Palette.SB_GOLD, Ink.Tier.INTERACTIVE, 3.0)
			canvas.draw_rect(Rect2(c - Vector2(9, 7) * s, Vector2(18, 14) * s), Palette.SB_BROWN_GREY.lightened(0.3))
			for x: float in [-5.0, 0.0, 5.0]:
				canvas.draw_colored_polygon(Ink.ellipse(c + Vector2(x, -1) * s, 2 * s, 2 * s, 8), Palette.SB_CHARCOAL)
		"horse":
			var horse := PackedVector2Array([c + Vector2(-12, 8) * s, c + Vector2(-10, -2) * s, c + Vector2(4, -2) * s, c + Vector2(8, -12) * s,
				c + Vector2(14, -10) * s, c + Vector2(12, -6) * s, c + Vector2(10, 8) * s, c + Vector2(6, 8) * s, c + Vector2(5, 2) * s,
				c + Vector2(-6, 2) * s, c + Vector2(-7, 8) * s])
			Ink.shape(canvas, horse, Palette.SB_WALNUT_LIGHT, Ink.Tier.INTERACTIVE, 4.0)
		_:
			canvas.draw_colored_polygon(Ink.ellipse(c, 9 * s, 9 * s, 14), Palette.SB_GOLD)

# PROTOTYPE - NOT FOR PRODUCTION
#
## Placeholder furniture drawn as flat, ink-outlined shapes. Each builder returns
## parts in back-to-front order; local origin is the object's front foot on the floor.
extends RefCounted

const Config := preload("res://prototypes/ghost-house-spike-2026-11-12/config.gd")


static func part(poly: PackedVector2Array, color: Color) -> Dictionary:
	return {"poly": poly, "color": color}


static func rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c, d])


static func ellipse(center: Vector2, rx: float, ry: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in segments:
		var angle: float = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


static func bed() -> Array[Dictionary]:
	return [
		part(rect(-72, -188, 72, -128), Config.WOOD_DARK),
		part(quad(Vector2(-80, -40), Vector2(80, -40), Vector2(70, -132), Vector2(-70, -132)), Config.BLANKET),
		part(quad(Vector2(-56, -112), Vector2(56, -112), Vector2(50, -134), Vector2(-50, -134)), Config.PILLOW),
		part(quad(Vector2(-80, -40), Vector2(80, -40), Vector2(78, -54), Vector2(-78, -54)), Config.BLANKET_FOLD),
		part(rect(-84, -40, 84, 0), Config.WOOD),
	]


static func wardrobe() -> Array[Dictionary]:
	return [
		part(quad(Vector2(-58, -212), Vector2(58, -212), Vector2(50, -226), Vector2(-50, -226)), Config.WOOD),
		part(rect(-58, -212, 58, 0), Config.WOOD_DARK),
		part(rect(-62, -218, 62, -206), Config.WOOD),
		part(rect(-1.5, -200, 1.5, -14), Config.INK),
		part(rect(-10, -112, -4, -104), Config.BRASS),
		part(rect(4, -112, 10, -104), Config.BRASS),
	]


static func stove() -> Array[Dictionary]:
	return [
		part(rect(-9, -300, 9, -118), Config.IRON),
		part(quad(Vector2(-62, -92), Vector2(62, -92), Vector2(54, -122), Vector2(-54, -122)), Config.IRON_TOP),
		part(ellipse(Vector2(-24, -107), 16, 6), Config.IRON_DARK),
		part(ellipse(Vector2(24, -107), 16, 6), Config.IRON_DARK),
		part(rect(-62, -92, 62, -12), Config.IRON),
		part(rect(-40, -76, 40, -26), Config.IRON_TOP),
		part(rect(-26, -64, 26, -40), Color("5a3422")),
		part(rect(-20, -84, 20, -80), Config.BRASS),
		part(rect(-58, -12, -48, 0), Config.IRON),
		part(rect(48, -12, 58, 0), Config.IRON),
	]


static func table() -> Array[Dictionary]:
	return [
		part(rect(-74, -62, -66, -22), Config.WOOD_DARK),
		part(rect(66, -62, 74, -22), Config.WOOD_DARK),
		part(quad(Vector2(-96, -60), Vector2(96, -60), Vector2(82, -112), Vector2(-82, -112)), Config.WOOD_LIGHT),
		part(ellipse(Vector2(-30, -88), 18, 6), Config.PILLOW),
		part(ellipse(Vector2(34, -80), 18, 6), Config.PILLOW),
		part(rect(-96, -60, 96, -46), Config.WOOD),
		part(rect(-90, -46, -80, 0), Config.WOOD),
		part(rect(80, -46, 90, 0), Config.WOOD),
	]


static func chair() -> Array[Dictionary]:
	return [
		part(rect(-18, -108, -13, -58), Config.WOOD_DARK),
		part(rect(13, -108, 18, -58), Config.WOOD_DARK),
		part(rect(-18, -108, 18, -98), Config.WOOD),
		part(quad(Vector2(-22, -42), Vector2(22, -42), Vector2(18, -60), Vector2(-18, -60)), Config.WOOD),
		part(rect(-20, -42, -15, 0), Config.WOOD_DARK),
		part(rect(15, -42, 20, 0), Config.WOOD_DARK),
	]


static func lamp(lit: bool) -> Array[Dictionary]:
	var shade: Color = Config.LAMP_SHADE_LIT if lit else Config.LAMP_SHADE_OUT
	return [
		part(ellipse(Vector2(0, -4), 22, 7), Config.BRASS),
		part(rect(-3, -126, 3, -6), Config.BRASS_DARK),
		part(rect(-3, -176, 3, -166), Config.BRASS_DARK),
		part(quad(Vector2(-36, -118), Vector2(36, -118), Vector2(22, -168), Vector2(-22, -168)), shade),
	]


static func window() -> Array[Dictionary]:
	return [
		part(rect(-56, -168, 56, -64), Config.WOOD),
		part(rect(-46, -158, 46, -72), Config.GLASS),
		part(rect(-2, -158, 2, -72), Config.WOOD),
		part(rect(-46, -117, 46, -113), Config.WOOD),
		part(rect(-62, -66, 62, -58), Config.WOOD_LIGHT),
	]

## Colours for the code-drawn house. Two sets: the original placeholder set (rooms not yet
## restyled) and the Whimsical Gothic Storybook set (SB_*, art direction approved
## 2026-11-15; rooms listed in assets/art/visual_style.json). Every colour used by the art
## comes from here, so the palette is adjusted in one place.
class_name Palette
extends RefCounted

const INK := Color("1d1612")
const BACKGROUND := Color("121019")
const WALL_BACK := Color("4f6b5f")
const WALL_SIDE := Color("3c5248")
const WAINSCOT := Color("5a3d2b")
const WAINSCOT_SIDE := Color("47301f")
const WALL_STRIPE := Color(1, 1, 1, 0.06)
const WALL_CAP := Color("2a1c13")
const FLOOR := Color("7a5536")
const FLOOR_LINE := Color(0.18, 0.11, 0.07, 0.55)
const FLOOR_EDGE := Color("3a2618")
const DOORWAY := Color("0c0a10")
const WOOD_DARK := Color("4b3020")
const WOOD := Color("6e4a2e")
const WOOD_LIGHT := Color("9a7148")
const FABRIC_RED := Color("7d3b3b")
const FABRIC_RED_LIGHT := Color("944c47")
const FABRIC_GREEN := Color("4f6a46")
const FABRIC_BLUE := Color("3f5573")
const LINEN := Color("d8cdb4")
const IRON := Color("2e2e33")
const IRON_TOP := Color("3e3e46")
const IRON_DARK := Color("232327")
const BRASS := Color("b48a3c")
const BRASS_DARK := Color("8a6a2e")
const SHADE_LIT := Color("f0c36a")
const SHADE_OUT := Color("5e5040")
const GLASS_DAY := Color("9fb6c4")
const GLASS_NIGHT := Color("26304a")
const PORCELAIN := Color("e3e1d8")
const RUG := Color("6d3434")
const RUG_BORDER := Color("a46a3c")
const BOOK_COLORS: Array[Color] = [Color("7d3b3b"), Color("3f5573"), Color("4f6a46"), Color("8a6a2e"), Color("5c3049")]
const HIGHLIGHT := Color(0.72, 0.95, 1.0, 0.95)
const SHADOW := Color(0, 0, 0, 0.22)
# --- Whimsical Gothic Storybook palette (art direction 2026-11-15) -------------------
const SB_PARCHMENT := Color("c99a60")      ## Old parchment: warm surfaces, decorative details
const SB_WALNUT := Color("79503c")         ## Walnut wood: furniture, floors, doors
const SB_TERRACOTTA := Color("a94f42")     ## Terracotta: upholstery, accents
const SB_DUSK_BLUE := Color("59677a")      ## Dusk blue: cool elements, shadows
const SB_OLIVE := Color("777c65")          ## Muted olive: plants, fabrics, secondary objects
const SB_CANDLELIGHT := Color("d9b878")    ## Candlelight: fire, lamps, warm highlights
const SB_CHARCOAL := Color("343747")       ## Night charcoal: deep shadows, night
const SB_GHOST := Color("a8d5d9")          ## Ghost cyan: the ghost, supernatural effects
const SB_CREAM := Color("e6d7b8")          ## Aged cream: walls, curtains, light fabrics
const SB_ROSE := Color("b77c75")           ## Dusty rose: decorative textiles
const SB_GREEN := Color("687b68")          ## Faded green: interior details
const SB_GOLD := Color("b58a50")           ## Antique gold: frames, handles, ornaments
const SB_BROWN_GREY := Color("62564d")     ## Muted brown-grey: contours, secondary shadows
## Contours: dark muted brown / charcoal, never pure black. Characters strongest.
const SB_CONTOUR := Color("3b2c25")
const SB_CONTOUR_SOFT := Color(0.384, 0.337, 0.302, 0.75)
## Derived tones (mixed from the palette above).
const SB_WALNUT_DARK := Color("5a3a2c")
const SB_WALNUT_LIGHT := Color("9a6c4e")
const SB_WALL := Color("d9c6a0")
const SB_WALL_SIDE := Color("c4ae88")
const SB_WALLPAPER_MOTIF := Color(0.718, 0.486, 0.459, 0.22)
const SB_FLOOR := Color("8a5f44")
const SB_FLOOR_DARK := Color("6c4734")
const SB_SKIN := Color("e9cfae")
const SB_SHADOW := Color(0.204, 0.216, 0.278, 0.30)
const SB_FIRE_CORE := Color("f2d99a")
const SB_EMBER := Color("8a3a2c")
const SB_ASH := Color("8b8a86")
const SB_GLASS_DAY := Color("b9c7c4")
const SB_GLASS_NIGHT := Color("3e4a5e")
const SB_MOON := Color("dfe6e0")
const SB_HIGHLIGHT := Color(0.85, 0.96, 0.97, 0.9)
## Book spines on shelves.
const SB_BOOKS: Array[Color] = [Color("a94f42"), Color("59677a"), Color("777c65"), Color("b58a50"), Color("b77c75"), Color("687b68"), Color("79503c")]
## Family clothing in the storybook rooms (npc id -> main, secondary).
const SB_CLOTHES: Dictionary = {
	"father": [Color("59677a"), Color("79503c")], "mother": [Color("687b68"), Color("e6d7b8")],
	"grandma": [Color("b77c75"), Color("62564d")], "grandpa": [Color("777c65"), Color("c99a60")],
	"son": [Color("a94f42"), Color("e6d7b8")], "daughter": [Color("d9b878"), Color("a94f42")],
}

## Light tints for the whole room (CanvasModulate), by room light and day/night.
const TINT_BRIGHT_DAY := Color(1.0, 0.97, 0.92)
const TINT_BRIGHT_NIGHT := Color(0.82, 0.76, 0.70)
const TINT_DIM := Color(0.60, 0.60, 0.68)
const TINT_DARK := Color(0.30, 0.32, 0.46)
const COLD_OVERLAY := Color(0.55, 0.75, 1.0, 0.14)

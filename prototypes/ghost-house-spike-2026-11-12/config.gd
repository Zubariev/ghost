# PROTOTYPE - NOT FOR PRODUCTION
# Spike question: can Godot 4.7 2D present a Hamlet-style room interior so that walls,
# floor, doors, furniture, a wall-passing ghost, a walking NPC and object highlighting
# all read clearly?
# Date: 2026-11-12
#
## Every tuning value of the room spike, in one place.
extends RefCounted

# --- View -------------------------------------------------------------------
const VIEW_SIZE := Vector2i(1280, 720)

# --- Room geometry (screen space; back wall on top, slanted side walls, no front wall)
const FLOOR_BACK_LEFT := Vector2(330, 260)
const FLOOR_BACK_RIGHT := Vector2(950, 260)
const FLOOR_FRONT_RIGHT := Vector2(1170, 650)
const FLOOR_FRONT_LEFT := Vector2(110, 650)
const BACK_WALL_HEIGHT := 175.0
const SIDE_WALL_FRONT_HEIGHT := 300.0
const WAINSCOT_FRACTION := 0.38
const FLOOR_EDGE_THICKNESS := 22.0
const FLOOR_PLANKS := 14
const WALL_FADE_ALPHA := 0.45
const WALL_FADE_SPEED := 6.0

# --- Ghost -------------------------------------------------------------------
const GHOST_START := Vector2(980, 610)
const GHOST_SPEED := 260.0              # px per real second (not scaled by time speed)
const GHOST_BOUNDS := Rect2(30, 120, 1220, 590)
const GHOST_BODY_OFFSET := Vector2(0, -50)
const GHOST_BOB_SPEED := 3.0
const GHOST_BOB_HEIGHT := 5.0

# --- Interaction --------------------------------------------------------------
const INTERACT_RANGE := 85.0            # px: ghost body to interact point, or ghost floor point to object foot
const NOTICE_RANGE := 230.0             # interactables inside this show a softer outline
const HIGHLIGHT_WIDTH := 9.0
const NOTICE_WIDTH := 6.0

# --- Test NPC -----------------------------------------------------------------
const NPC_SPEED := 70.0                 # px per game second at x1
const NPC_STEP_RATE := 9.0

# --- Sight cones (visual only; detection is not part of this spike) -----------
const SIGHT_PERIPHERAL_ANGLE_DEG := 120.0
const SIGHT_PERIPHERAL_LENGTH := 330.0
const SIGHT_DEEP_ANGLE_DEG := 42.0
const SIGHT_DEEP_LENGTH := 200.0
const FLOOR_Y_SQUASH := 0.62            # cones lie on the tilted floor

# --- Time (agreed: 1 game minute = 1 real second at x1) -----------------------
const GAME_MINUTES_PER_SECOND := 1.0
const START_MINUTES := 8 * 60
const DAY_START_MINUTES := 6 * 60
const NIGHT_START_MINUTES := 22 * 60
const SPEEDS: Array[int] = [1, 2, 4]

# --- Lighting -----------------------------------------------------------------
const AMBIENT_LAMP_LIT := Color(0.86, 0.82, 0.78)
const AMBIENT_LAMP_OUT := Color(0.42, 0.44, 0.58)
const LAMP_LIGHT_COLOR := Color(1.0, 0.82, 0.5)
const LAMP_LIGHT_ENERGY := 1.1
const LAMP_LIGHT_SCALE := 3.2

# --- Palette (muted, inky, cute-creepy) ---------------------------------------
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
const BLANKET := Color("7d3b3b")
const BLANKET_FOLD := Color("944c47")
const PILLOW := Color("d8cdb4")
const IRON := Color("2e2e33")
const IRON_TOP := Color("3e3e46")
const IRON_DARK := Color("232327")
const BRASS := Color("b48a3c")
const BRASS_DARK := Color("8a6a2e")
const LAMP_SHADE_LIT := Color("f0c36a")
const LAMP_SHADE_OUT := Color("6b5b45")
const GLASS := Color("9fb6c4")
const RUG := Color("6d3434")
const RUG_BORDER := Color("a46a3c")
const PAINTING := Color("4a5a3a")
const HIGHLIGHT_COLOR := Color(0.72, 0.95, 1.0, 0.95)
const NOTICE_COLOR := Color(0.72, 0.95, 1.0, 0.6)
const SIGHT_PERIPHERAL_COLOR := Color(1.0, 0.9, 0.4, 0.16)
const SIGHT_DEEP_COLOR := Color(1.0, 0.45, 0.25, 0.32)
const GHOST_FILL := Color(0.93, 0.96, 1.0, 0.84)
const GHOST_INK := Color(0.16, 0.18, 0.32, 0.9)
const NPC_DRESS := Color("5c3049")
const NPC_APRON := Color("d6ccb2")
const NPC_SKIN := Color("ecd2b4")
const NPC_HAIR := Color("b9b5b0")
const NPC_LABEL := Color(1, 1, 1, 0.85)

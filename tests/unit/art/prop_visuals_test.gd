## Painted sprites can replace code-drawn props without touching gameplay (art direction
## 2026-11-15): which rooms are storybook, and which image (if any) a prop uses per state.
## Textures come from an injected loader (no file I/O).
extends GdUnitTestSuite

const LAMP_PATH: String = "res://fake/lamp.png"
const LAMP_OUT_PATH: String = "res://fake/lamp_out.png"
const OLIVE_CHAIR_PATH: String = "res://fake/armchair_olive.png"

var _loaded: Array[String] = []


func _config() -> Dictionary:
	return {
		"storybook_rooms": ["living_room"],
		"sprites": {
			"floor_lamp": {"sprite": LAMP_PATH, "states": {"out": LAMP_OUT_PATH}, "anchor": [0.5, 0.9], "scale": 0.5,
				"effects": {"offset": [3, -8], "scale": 0.6}},
			"armchair:olive": {"sprite": OLIVE_CHAIR_PATH},
			"sofa": {"sprite": ""},
		},
		"wall_portraits": {
			"living_room": [{"wall": "left", "v": [0.1, 0.3], "h": [0.46, 0.84], "variant": "lady"}],
		},
	}


func _visuals() -> PropVisuals:
	_loaded = []
	return PropVisuals.new(_config(), func(path: String) -> Texture2D:
		_loaded.append(path)
		return ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))


func test_only_listed_rooms_are_storybook() -> void:
	var visuals: PropVisuals = _visuals()
	assert_bool(visuals.is_storybook("living_room")).is_true()
	assert_bool(visuals.is_storybook("kitchen")).is_false()


func test_a_prop_without_a_sprite_is_drawn_in_code() -> void:
	var visuals: PropVisuals = _visuals()
	assert_object(visuals.texture_for("fireplace", "", &"burning")).is_null()
	assert_object(visuals.texture_for("sofa", "", &"")).is_null()
	assert_array(_loaded).is_empty()


func test_a_state_can_have_its_own_sprite() -> void:
	var visuals: PropVisuals = _visuals()
	assert_str(visuals.sprite_path("floor_lamp", "", &"lit")).is_equal(LAMP_PATH)
	assert_str(visuals.sprite_path("floor_lamp", "", &"out")).is_equal(LAMP_OUT_PATH)


func test_a_variant_sprite_is_used_for_that_variant_only() -> void:
	var visuals: PropVisuals = _visuals()
	assert_str(visuals.sprite_path("armchair", "olive", &"")).is_equal(OLIVE_CHAIR_PATH)
	assert_str(visuals.sprite_path("armchair", "", &"free")).is_empty()


func test_sprites_are_loaded_once_and_carry_anchor_and_scale() -> void:
	var visuals: PropVisuals = _visuals()
	var first: Texture2D = visuals.texture_for("floor_lamp", "", &"lit")
	var again: Texture2D = visuals.texture_for("floor_lamp", "", &"lit")
	assert_object(first).is_not_null()
	assert_object(again).is_same(first)
	assert_array(_loaded).is_equal([LAMP_PATH])
	assert_vector(visuals.anchor("floor_lamp", "")).is_equal(Vector2(0.5, 0.9))
	assert_float(visuals.scale("floor_lamp", "")).is_equal(0.5)
	assert_vector(visuals.anchor("sofa", "")).is_equal(Vector2(0.5, 1.0))


func test_a_missing_sprite_file_falls_back_to_code() -> void:
	# Arrange: the real loader, a path that does not exist
	var visuals := PropVisuals.new({"sprites": {"sofa": {"sprite": "res://nowhere/sofa.png"}}})
	# Act / Assert
	assert_object(visuals.texture_for("sofa", "", &"")).is_null()


func test_wall_portraits_are_listed_per_room() -> void:
	# Arrange
	var visuals: PropVisuals = _visuals()
	# Act
	var here: Array = visuals.wall_portraits("living_room")
	var elsewhere: Array = visuals.wall_portraits("kitchen")
	# Assert
	assert_int(here.size()).is_equal(1)
	assert_str(String(here[0]["variant"])).is_equal("lady")
	assert_array(elsewhere).is_empty()


func test_a_painted_prop_says_where_its_code_drawn_animation_goes() -> void:
	# Art Phase 3 (2026-11-15): e.g. the fire inside a painted fireplace's firebox.
	var visuals: PropVisuals = _visuals()
	assert_vector(visuals.effects_offset("floor_lamp", "")).is_equal(Vector2(3, -8))
	assert_float(visuals.effects_scale("floor_lamp", "")).is_equal(0.6)
	# No effects entry: the animation sits at the floor point, unscaled
	assert_vector(visuals.effects_offset("armchair", "olive")).is_equal(Vector2.ZERO)
	assert_float(visuals.effects_scale("armchair", "olive")).is_equal(1.0)

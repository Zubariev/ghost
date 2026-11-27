## Item icons (sprint 002, P6, task S2-07): a painted image per icon key under
## assets/art/items/<key>.png when one exists, the code drawing otherwise; no item logic involved.
extends GdUnitTestSuite


func test_every_shipped_icon_has_a_code_drawing_to_fall_back_on() -> void:
	var items: Dictionary = JsonData.read(GhostLoot.LOOT_PATH)["items"]
	for id: String in items:
		var icon: String = String(items[id].get("icon", ""))
		assert_bool(ItemArt.has_code_drawing(icon)).override_failure_message("%s: no drawing for '%s'" % [id, icon]).is_true()


func test_the_painted_image_of_an_icon_lives_at_its_key() -> void:
	assert_str(ItemArt.painted_path("fly")).is_equal("res://assets/art/items/fly.png")


func test_an_icon_with_no_painted_image_has_none() -> void:
	assert_object(ItemArt.painted("no_such_icon_xyz")).is_null()


func test_a_painted_image_fits_the_slot_keeping_its_shape() -> void:
	var wide: Rect2 = ItemArt.fit_rect(Vector2(256, 128), Vector2(100, 100), 40.0)
	assert_vector(wide.size).is_equal(Vector2(40, 20))
	assert_vector(wide.get_center()).is_equal(Vector2(100, 100))
	var square: Rect2 = ItemArt.fit_rect(Vector2(256, 256), Vector2(0, 0), 52.0)
	assert_vector(square.size).is_equal(Vector2(52, 52))

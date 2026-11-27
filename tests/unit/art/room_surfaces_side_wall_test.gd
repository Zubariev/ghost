## A room may give its side walls their own texture (sprint 002, P7, task S2-08: the yards' side
## walls had the back wall's texture). Without "side_wall" every wall keeps the "wall" texture.
extends GdUnitTestSuite


func test_side_walls_use_their_own_texture_when_given() -> void:
	var cfg: Dictionary = {"wall": "res://a.png", "wall_tile_m": [2, 2], "side_wall": "res://b.png", "side_wall_tile_m": [3, 2]}
	assert_str(RoomSurfaces.wall_key(cfg, true)).is_equal("side_wall")
	assert_str(RoomSurfaces.wall_key(cfg, false)).is_equal("wall")


func test_without_a_side_texture_every_wall_uses_the_wall_texture() -> void:
	var cfg: Dictionary = {"wall": "res://a.png"}
	assert_str(RoomSurfaces.wall_key(cfg, true)).is_equal("wall")
	assert_str(RoomSurfaces.wall_key(cfg, false)).is_equal("wall")

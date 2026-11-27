## The yards' gameplay geometry stays as it was before the yard art pass (sprint 002, P7, task
## S2-08; plan: "improve the art without redesigning the gameplay space"). Room size, grid and
## flags, every piece's kind, place, hiding spot and object, and the footprints of the yard kinds
## must equal the snapshot taken on 2026-11-27. Changing them needs a decision, not an art task.
extends GdUnitTestSuite

const SNAPSHOT: String = "res://tests/unit/fixtures/yard_geometry_snapshot.json"


func _snap() -> Dictionary:
	return JsonData.read(SNAPSHOT)


func test_the_yards_rooms_are_unchanged() -> void:
	var now: Dictionary = {}
	for r: Dictionary in JsonData.read("res://assets/data/house/rooms.json")["rooms"]:
		now[String(r["id"])] = r
	var snap: Dictionary = _snap()["rooms"]
	for id: String in snap:
		assert_dict(now.get(id, {})).override_failure_message("room %s changed" % id).is_equal(snap[id])


## Decor added by the yard art (sprint 002: clothesline, sandbox, mailbox, …) is not gameplay: it is
## skipped here, and the next test checks it carries nothing that could act in the game.
func test_the_yards_pieces_and_hiding_spots_are_unchanged() -> void:
	var furniture: Dictionary = JsonData.read("res://assets/data/house/furniture.json")["rooms"]
	var snap: Dictionary = _snap()["pieces"]
	for id: String in snap:
		var gameplay: Array = (furniture.get(id, []) as Array).filter(func(p: Dictionary) -> bool: return not bool(p.get("decor", false)))
		assert_array(gameplay).override_failure_message("pieces of %s changed" % id).is_equal(snap[id])


const DECOR_FIELDS: Array[String] = ["kind", "u", "v", "decor", "flip"]


func test_yard_decor_is_only_drawn_never_an_obstacle_spot_or_object() -> void:
	var furniture: Dictionary = JsonData.read("res://assets/data/house/furniture.json")["rooms"]
	for id: String in _snap()["pieces"]:
		for piece: Dictionary in furniture.get(id, []):
			if not bool(piece.get("decor", false)):
				continue
			for field: String in piece:
				assert_bool(DECOR_FIELDS.has(field)).override_failure_message("%s decor %s has '%s'" % [id, piece["kind"], field]).is_true()


func test_the_yard_kinds_footprints_are_unchanged() -> void:
	var footprints: Dictionary = JsonData.read("res://assets/data/house/movement.json")["footprints"]
	var snap: Dictionary = _snap()["footprints"]
	for kind: String in snap:
		assert_that(footprints.get(kind)).override_failure_message("footprint of %s changed" % kind).is_equal(snap[kind])

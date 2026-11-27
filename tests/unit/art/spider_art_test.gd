## The painted spider body follows the rig (sprint 002, P4, task S2-05): the image's abdomen sits on
## the pose's body point and it scales with the spider's size and the depth; the painted head then
## sits where the pose's head is.
extends GdUnitTestSuite

const FOOT := Vector2(600, 500)
const TEX := Vector2(176, 257)


func test_the_painted_abdomen_sits_on_the_pose_body_point() -> void:
	var pose: Dictionary = SpiderPose.compute("idle", 0.0, 1.0, 0.0, 110.0)
	var rect: Rect2 = SpiderArt.body_rect(pose, 1.0, 1.0, FOOT, TEX)
	var abdomen: Vector2 = rect.position + SpiderArt.BODY_ABDOMEN * (rect.size.x / TEX.x)
	assert_vector(abdomen).is_equal_approx(FOOT + Vector2(pose["body"]), Vector2(0.01, 0.01))


func test_the_painted_head_lands_on_the_pose_head() -> void:
	var pose: Dictionary = SpiderPose.compute("idle", 0.0, 1.3, 0.0, 110.0)
	var rect: Rect2 = SpiderArt.body_rect(pose, 1.3, 1.0, FOOT, TEX)
	var head: Vector2 = rect.position + SpiderArt.BODY_HEAD * (rect.size.x / TEX.x)
	assert_vector(head).is_equal_approx(FOOT + Vector2(pose["head"]), Vector2(1.0, 1.0))


func test_the_body_grows_with_size_and_depth() -> void:
	var pose: Dictionary = SpiderPose.compute("idle", 0.0, 1.0, 0.0, 110.0)
	var small: Rect2 = SpiderArt.body_rect(pose, 1.0, 1.0, FOOT, TEX)
	assert_float(SpiderArt.body_rect(pose, 1.6, 1.0, FOOT, TEX).size.x).is_equal_approx(small.size.x * 1.6, 0.01)
	assert_float(SpiderArt.body_rect(pose, 1.0, 0.5, FOOT, TEX).size.x).is_equal_approx(small.size.x * 0.5, 0.01)

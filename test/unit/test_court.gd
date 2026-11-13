extends GutTest
## Court geometry: dimensions, line calls and service boxes.


func test_net_is_lower_in_the_middle_than_at_the_posts() -> void:
	assert_almost_eq(Court.net_height_at(0.0), 0.914, 0.0001)
	assert_almost_eq(Court.net_height_at(Court.NET_POST_X), 1.07, 0.0001)
	assert_almost_eq(Court.net_height_at(-Court.NET_POST_X), 1.07, 0.0001)
	assert_gt(Court.net_height_at(3.0), Court.net_height_at(1.0))


func test_lines_are_in() -> void:
	assert_true(Court.is_in_singles(Vector3(Court.HALF_WIDTH, 0, Court.HALF_LENGTH)))
	assert_true(Court.is_in_singles(Vector3(-Court.HALF_WIDTH, 0, -Court.HALF_LENGTH)))


func test_just_past_the_lines_is_out() -> void:
	assert_false(Court.is_in_singles(Vector3(Court.HALF_WIDTH + 0.01, 0, 0)))
	assert_false(Court.is_in_singles(Vector3(0, 0, -Court.HALF_LENGTH - 0.01)))


## Each case: [server, deuce_court, a point inside the correct box].
func test_serves_go_diagonally(
	p = use_parameters(
		[
			[Side.NEAR, true, Vector3(-2, 0, -3)],
			[Side.NEAR, false, Vector3(2, 0, -3)],
			[Side.FAR, true, Vector3(2, 0, 3)],
			[Side.FAR, false, Vector3(-2, 0, 3)],
		]
	)
) -> void:
	var server: int = p[0]
	var deuce: bool = p[1]
	var inside: Vector3 = p[2]
	assert_true(Court.is_in_service_box(inside, server, deuce), "inside the box")
	# Mirroring X lands in the wrong box; mirroring Z lands on the server's side.
	assert_false(Court.is_in_service_box(Vector3(-inside.x, 0, inside.z), server, deuce))
	assert_false(Court.is_in_service_box(Vector3(inside.x, 0, -inside.z), server, deuce))
	# Server stands on the opposite X side to the box: that's the diagonal.
	var stand := Court.serve_position(server, deuce)
	assert_lt(signf(stand.x) * signf(inside.x), 0.0, "diagonal")
	assert_eq(Side.of_z(stand.z), server, "behind own baseline")


func test_service_line_is_in_and_beyond_is_out() -> void:
	assert_true(Court.is_in_service_box(Vector3(-1, 0, -Court.SERVICE_LINE), Side.NEAR, true))
	assert_false(
		Court.is_in_service_box(Vector3(-1, 0, -Court.SERVICE_LINE - 0.01), Side.NEAR, true)
	)

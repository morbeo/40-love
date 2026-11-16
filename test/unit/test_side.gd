extends GutTest
## The first test in the project: tiny on purpose. It proves the test
## runner, class_name lookup and CI all work before any real logic exists.


func test_other_side_flips() -> void:
	assert_eq(Side.other(Side.NEAR), Side.FAR)
	assert_eq(Side.other(Side.FAR), Side.NEAR)


func test_near_is_positive_z() -> void:
	assert_eq(Side.of_z(5.0), Side.NEAR)
	assert_eq(Side.of_z(-5.0), Side.FAR)
	assert_eq(Side.sign_of(Side.NEAR), 1.0)
	assert_eq(Side.sign_of(Side.FAR), -1.0)


func test_the_net_plane_belongs_to_near() -> void:
	assert_eq(Side.of_z(0.0), Side.NEAR)


func test_names_for_logs() -> void:
	assert_eq(Side.name_of(Side.NEAR), "NEAR")
	assert_eq(Side.name_of(Side.NONE), "NONE")


func test_values_index_arrays() -> void:
	var points := [0, 0]
	points[Side.FAR] += 1
	assert_eq(points, [0, 1])


func test_an_invalid_value_is_named_as_such() -> void:
	# Only a deliberate cast can produce one; a bare 7 is a parse error
	# (see the int_as_enum_without_cast setting in project.godot).
	assert_eq(Side.name_of(7 as Side.Id), "INVALID(7)")

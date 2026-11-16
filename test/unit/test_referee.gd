extends GutTest
## The rules of a point, driven by hand-made events (no physics needed).

const R := Referee.Ruling.Kind
## NEAR serving from the deuce court aims at -X, -Z.
const IN_BOX := Vector3(-2, 0, -4)
const LONG := Vector3(-2, 0, -8)

var ref: Referee


func before_each() -> void:
	ref = Referee.new()
	ref.start_point(Side.NEAR, true)


func _cross(to: int) -> Referee.Ruling:
	return ref.on_ball_event(BallEvent.make(BallEvent.Type.NET_CROSS, 0, Vector3.ZERO, to))


func _bounce(at: Vector3) -> Referee.Ruling:
	var e := BallEvent.make(BallEvent.Type.BOUNCE, 0, at, Side.of_z(at.z))
	return ref.on_ball_event(e)


func _net() -> Referee.Ruling:
	return ref.on_ball_event(BallEvent.make(BallEvent.Type.NET_HIT, 0, Vector3.ZERO, Side.NEAR))


func _good_serve() -> void:
	ref.on_hit(Side.NEAR)
	_cross(Side.FAR)
	_bounce(IN_BOX)


func test_only_the_server_can_hit_first() -> void:
	assert_true(ref.can_hit(Side.NEAR))
	assert_false(ref.can_hit(Side.FAR))


func test_serve_in_the_box_is_good() -> void:
	ref.on_hit(Side.NEAR)
	_cross(Side.FAR)
	assert_eq(_bounce(IN_BOX).kind, R.NONE)
	assert_true(ref.can_hit(Side.FAR), "receiver may now return it")


func test_long_serve_is_a_fault_then_a_double_fault() -> void:
	ref.on_hit(Side.NEAR)
	_cross(Side.FAR)
	var first := _bounce(LONG)
	assert_eq(first.kind, R.FAULT)
	assert_eq(ref.serve_number, 2)
	ref.on_hit(Side.NEAR)
	_cross(Side.FAR)
	var second := _bounce(LONG)
	assert_eq(second.kind, R.POINT)
	assert_eq(second.winner, Side.FAR)
	assert_eq(second.reason, Referee.Reason.DOUBLE_FAULT)


func test_serve_into_the_net_is_a_fault() -> void:
	ref.on_hit(Side.NEAR)
	_net()
	var r := _bounce(Vector3(0, 0, 0.3))
	assert_eq(r.kind, R.FAULT)
	assert_eq(r.reason, Referee.Reason.NET)


func test_net_cord_serve_that_lands_in_is_a_let() -> void:
	ref.on_hit(Side.NEAR)
	_net()
	_cross(Side.FAR)
	assert_eq(_bounce(IN_BOX).kind, R.LET)
	assert_eq(ref.serve_number, 1, "a let replays the same serve")


func test_ace_wins_the_point_for_the_server() -> void:
	_good_serve()
	var r := _bounce(Vector3(-2, 0, -12))
	assert_eq(r.kind, R.POINT)
	assert_eq(r.winner, Side.NEAR)
	assert_eq(r.reason, Referee.Reason.DOUBLE_BOUNCE)


func test_receiver_may_not_volley_the_serve() -> void:
	ref.on_hit(Side.NEAR)
	_cross(Side.FAR)
	var r := ref.on_hit(Side.FAR)
	assert_eq(r.winner, Side.NEAR)
	assert_eq(r.reason, Referee.Reason.SERVE_VOLLEYED)


func test_rally_shot_out_loses_the_point() -> void:
	_good_serve()
	ref.on_hit(Side.FAR)
	_cross(Side.NEAR)
	var r := _bounce(Vector3(Court.HALF_WIDTH + 0.3, 0, 8))
	assert_eq(r.winner, Side.NEAR, "FAR hit it out")
	assert_eq(r.reason, Referee.Reason.OUT)


func test_rally_ball_into_the_net_loses_the_point() -> void:
	_good_serve()
	ref.on_hit(Side.FAR)
	_net()
	var r := _bounce(Vector3(0, 0, -0.5))
	assert_eq(r.winner, Side.NEAR)
	assert_eq(r.reason, Referee.Reason.NET)


func test_volleys_are_legal_in_a_rally() -> void:
	_good_serve()
	ref.on_hit(Side.FAR)
	_cross(Side.NEAR)
	assert_true(ref.can_hit(Side.NEAR), "before the bounce")
	assert_eq(ref.on_hit(Side.NEAR).kind, R.NONE)


func test_cannot_hit_twice_in_a_row() -> void:
	_good_serve()
	ref.on_hit(Side.FAR)
	assert_false(ref.can_hit(Side.FAR))
	var r := ref.on_hit(Side.FAR)
	assert_eq(r.winner, Side.NEAR)
	assert_eq(r.reason, Referee.Reason.DOUBLE_HIT)


func test_nothing_counts_after_the_point_is_over() -> void:
	_good_serve()
	_bounce(Vector3(-2, 0, -12))
	assert_eq(_bounce(Vector3(-2, 0, -12)).kind, R.NONE)
	assert_false(ref.can_hit(Side.FAR))

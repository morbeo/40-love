extends GutTest
## Ball flight and bounce. These tests pin down the *feel* of the ball:
## if a tuning change breaks one, the change altered how shots behave.

var cfg: PhysicsConfig


func before_each() -> void:
	cfg = PhysicsConfig.new()


func _ball(pos: Vector3, vel: Vector3, spin := Vector3.ZERO) -> Ball:
	var b := Ball.new()
	b.position = pos
	b.velocity = vel
	b.spin = spin
	return b


## Steps until the first event of `type`, returning it (or null).
func _until(b: Ball, type: BallEvent.Type, max_ticks := 600) -> BallEvent:
	for t in max_ticks:
		for e in BallPhysics.step(b, cfg, t):
			if e.type == type:
				return e
	return null


func test_free_fall_matches_textbook_gravity() -> void:
	cfg.drag = 0.0
	var b := _ball(Vector3(0, 10, 5), Vector3.ZERO)
	for i in 60:
		BallPhysics.step(b, cfg, i)
	# Semi-implicit Euler slightly overshoots 0.5*g*t^2; within 2% is fine.
	assert_almost_eq(10.0 - b.position.y, 0.5 * 9.81, 0.1)


func test_held_ball_does_not_move() -> void:
	var b := _ball(Vector3(1, 2.6, 12), Vector3(5, 5, 5))
	b.held = true
	BallPhysics.step(b, cfg, 0)
	assert_eq(b.position, Vector3(1, 2.6, 12))


func test_bounce_keeps_restitution_share_of_vertical_speed() -> void:
	var b := _ball(Vector3(0, 0.0, 5), Vector3(0, -10, 0))
	BallPhysics.bounce(b, cfg)
	assert_almost_eq(b.velocity.y, 10.0 * cfg.restitution, 0.0001)


func test_flat_ball_slows_down_on_the_bounce() -> void:
	var b := _ball(Vector3(0, 0, 5), Vector3(0, -6, -20))
	BallPhysics.bounce(b, cfg)
	assert_lt(absf(b.velocity.z), 20.0)
	assert_gt(b.topspin(), 0.0, "friction starts it rolling forward, i.e. topspin")


func test_topspin_kicks_but_flat_and_slice_lose_the_same_pace() -> void:
	var v := Vector3(0, -6, -20)
	var top := _ball(Vector3.ZERO, v, Ball.make_spin(v, 300, 0))
	var flat := _ball(Vector3.ZERO, v)
	var slice := _ball(Vector3.ZERO, v, Ball.make_spin(v, -200, 0))
	for b in [top, flat, slice]:
		BallPhysics.bounce(b, cfg)
	assert_gt(absf(top.velocity.z), absf(flat.velocity.z), "topspin keeps more pace")
	# Flat and slice both slide for the whole contact, so Coulomb friction
	# brakes them equally. What differs is the spin they leave with.
	assert_almost_eq(absf(slice.velocity.z), absf(flat.velocity.z), 0.001)
	# Friction spins every ball "forwards". Slice started with backspin, so
	# it ends further from rolling than the flat ball: it is still skidding.
	assert_gt(flat.topspin(), 0.0, "flat ball picks up topspin from the court")
	assert_lt(slice.topspin(), flat.topspin(), "slice is further from rolling")


func test_topspin_dips_and_backspin_floats() -> void:
	var v := Vector3(0, 4, -18)
	var landing := func(top: float) -> float:
		var b := _ball(Vector3(0, 1, 11), v, Ball.make_spin(v, top, 0))
		return _until(b, BallEvent.Type.BOUNCE).position.z
	# Z is negative towards the far baseline: "longer" means more negative.
	assert_gt(landing.call(250.0), landing.call(0.0), "topspin lands shorter")
	assert_lt(landing.call(-200.0), landing.call(0.0), "backspin carries longer")


func test_positive_sidespin_curves_left() -> void:
	var v := Vector3(0, 4, -18)
	var b := _ball(Vector3(0, 1, 11), v, Ball.make_spin(v, 0, 150))
	var e := _until(b, BallEvent.Type.BOUNCE)
	# Travelling towards -Z, "left" is -X.
	assert_lt(e.position.x, -0.2)


func test_ball_over_the_net_reports_a_crossing() -> void:
	var b := _ball(Vector3(0, 2, 2), Vector3(0, 0, -10))
	var e := _until(b, BallEvent.Type.NET_CROSS)
	assert_not_null(e)
	assert_eq(e.side, Side.FAR)


func test_low_ball_hits_the_net_and_drops_back() -> void:
	var b := _ball(Vector3(0, 0.5, 2), Vector3(0, 0, -10))
	var e := _until(b, BallEvent.Type.NET_HIT)
	assert_not_null(e)
	assert_eq(e.side, Side.NEAR, "came from NEAR")
	var bounce := _until(b, BallEvent.Type.BOUNCE)
	assert_eq(bounce.side, Side.NEAR, "falls on the hitter's side")


func test_ball_passing_outside_the_posts_never_hits_the_net() -> void:
	var b := _ball(Vector3(Court.NET_POST_X + 0.5, 0.5, 2), Vector3(0, 0, -10))
	assert_not_null(_until(b, BallEvent.Type.NET_CROSS))


func test_same_input_gives_bit_identical_output() -> void:
	var run := func() -> int:
		var v := Vector3(1.3, 5.2, -21.7)
		var b := _ball(Vector3(0.4, 1.1, 11), v, Ball.make_spin(v, 213.0, -17.0))
		for i in 300:
			BallPhysics.step(b, cfg, i)
		return b.state_hash()
	assert_eq(run.call(), run.call())

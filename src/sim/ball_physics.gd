class_name BallPhysics
extends RefCounted
## Advances a Ball by one fixed tick. Deterministic: same input state, same
## config, same output, every time. No engine physics involved.
##
## Order of work in a tick:
##   1. air forces (gravity, drag, Magnus) -> semi-implicit Euler step
##   2. net: did the ball's centre cross z = 0 below the tape?
##   3. ground: did the ball reach the court? -> bounce impulse with spin


## Moves `ball` forward by one tick and returns the events that happened.
static func step(ball: Ball, cfg: PhysicsConfig, tick: int) -> Array[BallEvent]:
	var events: Array[BallEvent] = []
	if ball.held:
		return events
	var dt := cfg.dt()
	var prev := ball.position

	integrate_air(ball, cfg, dt)
	_resolve_net(ball, prev, cfg, tick, events)
	_resolve_ground(ball, cfg, tick, events)
	return events


## Acceleration in flight. Kept separate so the ShotSolver can reuse it.
static func air_acceleration(ball: Ball, cfg: PhysicsConfig) -> Vector3:
	var v := ball.velocity
	var a := Vector3(0.0, -cfg.gravity, 0.0)
	a -= v * v.length() * cfg.drag
	a += ball.spin.cross(v) * cfg.magnus
	return a


## Semi-implicit (symplectic) Euler: update velocity first, then move with
## the NEW velocity. Same cost as plain Euler but much more stable for
## bouncing and orbiting things.
static func integrate_air(ball: Ball, cfg: PhysicsConfig, dt: float) -> void:
	ball.velocity += air_acceleration(ball, cfg) * dt
	ball.position += ball.velocity * dt
	ball.spin *= maxf(0.0, 1.0 - cfg.spin_decay * dt)


static func _resolve_net(
	ball: Ball, prev: Vector3, cfg: PhysicsConfig, tick: int, events: Array[BallEvent]
) -> void:
	var from_side := Side.of_z(prev.z)
	var to_side := Side.of_z(ball.position.z)
	if from_side == to_side:
		return
	# Find where the centre crossed the net plane by linear interpolation
	# between the old and new positions.
	var t := prev.z / (prev.z - ball.position.z)
	var hit := prev.lerp(ball.position, t)
	var under_tape := hit.y - cfg.ball_radius < Court.net_height_at(hit.x)
	var between_posts := absf(hit.x) <= Court.NET_POST_X
	if under_tape and between_posts and hit.y > 0.0:
		# Clipped the net: knock the ball back to the side it came from and
		# kill most of its energy. It drops and bounces on the hitter's side.
		ball.position = Vector3(hit.x, hit.y, Side.sign_of(from_side) * cfg.ball_radius)
		ball.velocity = Vector3(
			ball.velocity.x * cfg.net_damping,
			minf(ball.velocity.y, 0.0) * cfg.net_damping,
			-ball.velocity.z * cfg.net_damping
		)
		ball.spin *= cfg.net_damping
		events.append(BallEvent.make(BallEvent.Type.NET_HIT, tick, hit, from_side))
		return
	events.append(BallEvent.make(BallEvent.Type.NET_CROSS, tick, hit, to_side))


static func _resolve_ground(
	ball: Ball, cfg: PhysicsConfig, tick: int, events: Array[BallEvent]
) -> void:
	var r := cfg.ball_radius
	if ball.position.y > r or ball.velocity.y >= 0.0:
		return
	var impact_speed := -ball.velocity.y
	ball.position.y = r
	if impact_speed < cfg.rest_speed:
		# Rolling: no more bounces, just let horizontal motion bleed off.
		ball.velocity.y = 0.0
		ball.velocity *= 0.98
		return
	bounce(ball, cfg)
	events.append(
		BallEvent.make(
			BallEvent.Type.BOUNCE,
			tick,
			Vector3(ball.position.x, 0.0, ball.position.z),
			Side.of_z(ball.position.z)
		)
	)


## The bounce impulse. Vertical: lose energy by the restitution factor.
## Horizontal: friction acts on the SLIP of the contact patch, which is the
## ball's velocity plus the surface speed from spin (spin x contact_offset).
##   - Topspin makes the bottom of the ball move backwards, so slip is
##     smaller and friction can even push the ball forwards: it "kicks".
##   - Backspin increases slip, so friction brakes the ball: it "skids" low.
## Friction cannot do more than bring the ball to pure rolling. For a hollow
## sphere (I = 2/3 m r^2) that cap is 2/5 of the slip speed.
static func bounce(ball: Ball, cfg: PhysicsConfig) -> void:
	var r := cfg.ball_radius
	var vy := ball.velocity.y
	var contact := Vector3(0.0, -r, 0.0)
	var v_t := Vector3(ball.velocity.x, 0.0, ball.velocity.z)
	var slip := v_t + ball.spin.cross(contact)
	slip.y = 0.0

	var dv_t := Vector3.ZERO
	var slip_speed := slip.length()
	if slip_speed > 1e-6:
		var max_friction := cfg.friction * (1.0 + cfg.restitution) * absf(vy)
		var to_rolling := 0.4 * slip_speed
		dv_t = -slip / slip_speed * minf(max_friction, to_rolling)

	ball.velocity = Vector3(v_t.x + dv_t.x, -vy * cfg.restitution, v_t.z + dv_t.z)
	# The same friction impulse also changes spin: d_omega = (r x J) / I
	# with J = m * dv_t and I = 2/3 m r^2  ->  (contact x dv_t) * 3 / (2 r^2).
	ball.spin += contact.cross(dv_t) * (1.5 / (r * r))

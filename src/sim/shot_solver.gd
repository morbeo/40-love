class_name ShotSolver
extends RefCounted
## Works out the launch velocity that lands a ball on a target.
##
## With drag and Magnus there is no neat closed-form answer, so we use
## "shooting": guess a velocity, simulate the flight with the real air
## model, see where it lands, correct the guess, repeat. A dozen rounds
## gets within a few centimetres. Because the simulation is deterministic,
## so is the answer.

const ITERATIONS := 12
const MAX_FLIGHT := 6.0


## Velocity that sends a ball from `from` with `spin` to land on `target`
## (y ignored, landing is on the ground) after roughly `flight_time` seconds.
static func solve(
	from: Vector3, target: Vector3, flight_time: float, spin: Vector3, cfg: PhysicsConfig
) -> Vector3:
	var t := maxf(flight_time, 0.1)
	var land_y := cfg.ball_radius
	# Starting guess: vacuum ballistics, which ignore drag and spin.
	var v := Vector3(
		(target.x - from.x) / t,
		(land_y - from.y + 0.5 * cfg.gravity * t * t) / t,
		(target.z - from.z) / t
	)
	for i in ITERATIONS:
		var landing := simulate_landing(from, v, spin, cfg)
		var miss := Vector3(target.x - landing.x, 0.0, target.z - landing.z)
		var time_error: float = t - landing.y  # landing.y carries flight time
		if miss.length() < 0.005 and absf(time_error) < 0.005:
			break
		v.x += miss.x / t
		v.z += miss.z / t
		v.y += time_error * cfg.gravity * 0.5
	return v


## Flies a ball through the air only (no net, no bounce) until its centre
## comes down to ball height. Returns (x, flight_time, z) packed into a
## Vector3 to avoid allocating a result object.
static func simulate_landing(
	from: Vector3, velocity: Vector3, spin: Vector3, cfg: PhysicsConfig
) -> Vector3:
	var ball := Ball.new()
	ball.position = from
	ball.velocity = velocity
	ball.spin = spin
	var dt := cfg.dt()
	var time := 0.0
	var prev := ball.position
	while time < MAX_FLIGHT:
		prev = ball.position
		BallPhysics.integrate_air(ball, cfg, dt)
		time += dt
		if ball.velocity.y < 0.0 and ball.position.y <= cfg.ball_radius:
			# Interpolate inside the last tick for a smooth answer.
			var span := prev.y - ball.position.y
			var f := 1.0 if span <= 0.0 else (prev.y - cfg.ball_radius) / span
			var p := prev.lerp(ball.position, f)
			return Vector3(p.x, time - dt + dt * f, p.z)
	return Vector3(ball.position.x, time, ball.position.z)

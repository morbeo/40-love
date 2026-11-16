class_name Ball
extends RefCounted
## Plain data for the ball. All behaviour lives in BallPhysics so the state
## is easy to copy, compare and hash (handy for determinism tests and, one
## day, rollback netcode).

var position := Vector3.ZERO
var velocity := Vector3.ZERO
## Angular velocity in rad/s (axis = direction, length = rate).
var spin := Vector3.ZERO
## While held (the server's toss) physics does not move the ball.
var held := false


func copy() -> Ball:
	var b := Ball.new()
	b.position = position
	b.velocity = velocity
	b.spin = spin
	b.held = held
	return b


func state_hash() -> int:
	return [position, velocity, spin, held].hash()


## Topspin rate in rad/s for the current direction of travel. Positive is
## topspin, negative is backspin (slice).
func topspin() -> float:
	var d := Vector3(velocity.x, 0.0, velocity.z)
	if d.length_squared() < 1e-8:
		return 0.0
	return spin.dot(Vector3.UP.cross(d.normalized()))


## Sidespin rate in rad/s. Positive curves the ball to the left of its
## direction of travel (counter-clockwise seen from above).
func sidespin() -> float:
	return spin.y


## Builds a spin vector from topspin/sidespin rates and a travel direction.
static func make_spin(direction: Vector3, top: float, side: float) -> Vector3:
	var d := Vector3(direction.x, 0.0, direction.z)
	if d.length_squared() < 1e-8:
		return Vector3(0.0, side, 0.0)
	return Vector3.UP.cross(d.normalized()) * top + Vector3.UP * side

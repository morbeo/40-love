class_name Court
extends RefCounted
## Court geometry and line calls. Pure functions, no state.
##
## World axes (Godot convention): X = across the court, Y = up, Z = along
## the court. The net sits on the plane z = 0 and the court is centred on
## the origin. Units are metres, using real ITF singles dimensions.
## Line dimensions are measured to the outer edge of the lines, so a ball
## whose centre is exactly on a boundary is IN.

const LENGTH := 23.77
const HALF_LENGTH := LENGTH * 0.5
const SINGLES_WIDTH := 8.23
const HALF_WIDTH := SINGLES_WIDTH * 0.5
## Distance from the net to each service line.
const SERVICE_LINE := 6.40
const NET_HEIGHT_CENTER := 0.914
const NET_HEIGHT_POST := 1.07
## Singles sticks stand 0.914 m outside the singles sideline.
const NET_POST_X := HALF_WIDTH + 0.914
const LINE_WIDTH := 0.05
## Vector3 stores 32-bit floats while constants are 64-bit, so a point placed
## exactly on a line can land a hair outside it. One millimetre of slack.
const EPSILON := 0.001


## Height of the top of the net tape at a given X. The real net sags; a
## straight line from centre to post is close enough for gameplay.
static func net_height_at(x: float) -> float:
	var t := clampf(absf(x) / NET_POST_X, 0.0, 1.0)
	return lerpf(NET_HEIGHT_CENTER, NET_HEIGHT_POST, t)


## True if a ground contact at `p` is inside the singles court.
static func is_in_singles(p: Vector3) -> bool:
	return absf(p.x) <= HALF_WIDTH + EPSILON and absf(p.z) <= HALF_LENGTH + EPSILON


## The box a serve from `server` must land in. Returns a Rect2 in the
## ground plane, using (x, z) as (x, y).
##
## The deuce court is the server's right-hand side. NEAR faces -Z, so its
## right is +X; it serves diagonally into the box at -X. FAR is mirrored.
static func service_box(server: int, deuce_court: bool) -> Rect2:
	var receiver := Side.other(server)
	var x_sign := (-1.0 if deuce_court else 1.0) * Side.sign_of(server)
	var x0 := 0.0 if x_sign > 0.0 else -HALF_WIDTH
	var z0 := 0.0 if Side.sign_of(receiver) > 0.0 else -SERVICE_LINE
	return Rect2(x0, z0, HALF_WIDTH, SERVICE_LINE)


static func is_in_service_box(p: Vector3, server: int, deuce_court: bool) -> bool:
	var box := service_box(server, deuce_court)
	# Rect2.has_point excludes the far edges; lines are IN, so test by hand.
	return (
		p.x >= box.position.x - EPSILON
		and p.x <= box.end.x + EPSILON
		and p.z >= box.position.y - EPSILON
		and p.z <= box.end.y + EPSILON
	)


## Where a server stands: just behind their baseline, beside the centre mark
## on the side matching the court they serve from.
static func serve_position(server: int, deuce_court: bool) -> Vector3:
	var s := Side.sign_of(server)
	var x := (1.0 if deuce_court else -1.0) * s * 0.8
	return Vector3(x, 0.0, s * (HALF_LENGTH + 0.3))

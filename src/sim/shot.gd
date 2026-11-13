class_name Shot
extends RefCounted
## A request to strike the ball: where to send it, how fast, with what spin.
## Strikers (bots now, players later) produce these; MatchSim executes them.

var target := Vector3.ZERO
## Seconds until the ball should land. Lower = harder, flatter shot.
var flight_time := 1.0
## rad/s, positive = topspin, negative = slice.
var topspin := 0.0
## rad/s, positive curves left of the direction of travel.
var sidespin := 0.0


static func make(
	p_target: Vector3, p_flight_time: float, p_topspin := 0.0, p_sidespin := 0.0
) -> Shot:
	var s := Shot.new()
	s.target = p_target
	s.flight_time = p_flight_time
	s.topspin = p_topspin
	s.sidespin = p_sidespin
	return s

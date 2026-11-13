class_name AutoHitter
extends RefCounted
## A "ball machine with opinions": a bot that strikes the ball from wherever
## it is, with no body to move. It exists to exercise the sim core end to
## end before real players exist (step 2), and to generate demo footage.
##
## All randomness comes from the sim's seeded RNG, so a match between two
## AutoHitters replays identically for the same seed.

## Chance a rally shot is aimed outside the court.
var error_rate := 0.12
## Chance a first serve is aimed outside the service box.
var serve_fault_rate := 0.3
## Height at which the bot swings at a falling ball after its bounce.
var strike_height := 1.0


func decide(sim: MatchSim, side: int) -> Shot:
	var ref := sim.referee
	var ball := sim.ball
	if ref.phase == Referee.Phase.SERVE and ref.last_hitter == Side.NONE:
		return _serve(sim, side)
	# Rally: wait for the bounce, then hit the ball on the way down.
	if ref.bounces != 1 or ball.velocity.y > 0.0 or ball.position.y > strike_height:
		return null
	return _rally_shot(sim, side)


func _serve(sim: MatchSim, side: int) -> Shot:
	var box := Court.service_box(side, sim.referee.deuce_court)
	var rng := sim.rng
	var fault_rate := serve_fault_rate if sim.referee.serve_number == 1 else serve_fault_rate * 0.3
	var x := rng.randf_range(box.position.x + 0.3, box.end.x - 0.3)
	# Aim for the back half of the box: short serves from 2.6 m up would
	# need to dip so steeply that they clip the net.
	var away := Side.sign_of(Side.other(side))
	var z := away * rng.randf_range(Court.SERVICE_LINE * 0.6, Court.SERVICE_LINE - 0.4)
	if rng.randf() < fault_rate:
		# Long: push the target past the service line.
		z = away * (Court.SERVICE_LINE + rng.randf_range(0.3, 1.5))
	var first := sim.referee.serve_number == 1
	return Shot.make(
		Vector3(x, 0.0, z),
		rng.randf_range(0.55, 0.7) if first else rng.randf_range(0.8, 1.0),
		rng.randf_range(0.0, 60.0) if first else rng.randf_range(120.0, 200.0),
		rng.randf_range(-40.0, 40.0)
	)


func _rally_shot(sim: MatchSim, side: int) -> Shot:
	var rng := sim.rng
	var away := Side.sign_of(Side.other(side))
	var x := rng.randf_range(-Court.HALF_WIDTH + 0.4, Court.HALF_WIDTH - 0.4)
	var depth := rng.randf_range(Court.SERVICE_LINE * 0.6, Court.HALF_LENGTH - 0.5)
	if rng.randf() < error_rate:
		if rng.randf() < 0.5:
			x = signf(rng.randf() - 0.5) * (Court.HALF_WIDTH + rng.randf_range(0.2, 1.2))
		else:
			depth = Court.HALF_LENGTH + rng.randf_range(0.2, 1.5)
	# Pick a shot "style": topspin, flat or slice.
	var spin: float
	var time: float
	match rng.randi_range(0, 2):
		0:
			spin = rng.randf_range(150.0, 300.0)
			time = rng.randf_range(1.0, 1.4)
		1:
			spin = rng.randf_range(-20.0, 20.0)
			time = rng.randf_range(0.8, 1.1)
		_:
			spin = -rng.randf_range(100.0, 220.0)
			time = rng.randf_range(1.2, 1.6)
	return Shot.make(Vector3(x, 0.0, away * depth), time, spin, rng.randf_range(-30.0, 30.0))

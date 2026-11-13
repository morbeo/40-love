class_name MatchSim
extends RefCounted
## The whole simulation of one match, advanced one fixed tick at a time.
##
## This is the "fighting game" core: given the same seed and the same
## inputs on the same ticks, it always produces the same match. It owns no
## nodes and draws nothing; a view reads its state after each step().
##
## Strikers are anything with `func decide(sim: MatchSim, side: int) -> Shot`
## (return null to do nothing this tick). In step 1 both sides are
## AutoHitter bots; human and CPU players plug into the same slot later.

## Ticks to wait between points / after a fault, so the view can breathe.
const PAUSE_TICKS := 45
## How high the server tosses the ball.
const TOSS_HEIGHT := 2.6

var cfg: PhysicsConfig
var rng := RandomNumberGenerator.new()
var ball := Ball.new()
var referee := Referee.new()
var score: MatchScore
var strikers: Array = [null, null]
var tick := 0
var pause := 0
## Events from the most recent step, for views and tests.
var last_events: Array[BallEvent] = []
var last_ruling: Referee.Ruling = Referee.Ruling.none()
## Every point result in order, as [winner, reason].
var history: Array = []


func _init(
	p_seed: int,
	p_format: MatchFormat = null,
	p_cfg: PhysicsConfig = null,
) -> void:
	rng.seed = p_seed
	cfg = p_cfg if p_cfg else PhysicsConfig.new()
	score = MatchScore.new(p_format if p_format else MatchFormat.quick_tiebreak())
	_setup_point()


func set_striker(side: int, striker: Object) -> void:
	strikers[side] = striker


func is_over() -> bool:
	return score.is_over()


func step() -> void:
	last_events.clear()
	last_ruling = Referee.Ruling.none()
	if is_over():
		return
	if pause > 0:
		pause -= 1
		if pause == 0:
			_setup_point()
		tick += 1
		return

	for side in [Side.NEAR, Side.FAR]:
		if strikers[side] == null or not referee.can_hit(side):
			continue
		var shot: Shot = strikers[side].decide(self, side)
		if shot:
			_strike(side, shot)
			break

	if referee.phase != Referee.Phase.OVER and pause == 0:
		for e in BallPhysics.step(ball, cfg, tick):
			last_events.append(e)
			if not _handle(referee.on_ball_event(e)):
				break
	tick += 1


## Runs until the match ends or `max_ticks` pass. Returns ticks simulated.
func run(max_ticks: int) -> int:
	var start := tick
	while not is_over() and tick - start < max_ticks:
		step()
	return tick - start


## One number that changes if anything about the match state changes.
func state_hash() -> int:
	return (
		[
			tick,
			ball.state_hash(),
			score.points,
			score.games,
			score.sets,
			referee.phase,
			referee.serve_number,
			history.size(),
		]
		. hash()
	)


func _strike(side: int, shot: Shot) -> void:
	var ruling := referee.on_hit(side)
	ball.held = false
	var dir := shot.target - ball.position
	ball.spin = Ball.make_spin(dir, shot.topspin, shot.sidespin)
	ball.velocity = ShotSolver.solve(ball.position, shot.target, shot.flight_time, ball.spin, cfg)
	_handle(ruling)


## Reacts to a referee ruling. Returns true if play continues.
func _handle(ruling: Referee.Ruling) -> bool:
	if ruling.kind == Referee.Ruling.Kind.NONE:
		return true
	last_ruling = ruling
	match ruling.kind:
		Referee.Ruling.Kind.POINT:
			history.append([ruling.winner, ruling.reason])
			score.point_won(ruling.winner)
		Referee.Ruling.Kind.FAULT, Referee.Ruling.Kind.LET:
			pass
	pause = PAUSE_TICKS
	return false


func _setup_point() -> void:
	if is_over():
		return
	# After a fault or let the referee has already reset itself for the next
	# serve (keeping the serve number); otherwise start a fresh point.
	if referee.phase != Referee.Phase.SERVE:
		referee.start_point(score.server, score.deuce_court())
	ball = Ball.new()
	ball.position = Court.serve_position(score.server, score.deuce_court())
	ball.position.y = TOSS_HEIGHT
	ball.held = true

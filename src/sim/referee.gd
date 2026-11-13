class_name Referee
extends RefCounted
## The rules of a single point, as a small state machine.
##
## It knows nothing about physics or players. It is fed two kinds of input:
##   - on_hit(side): a player struck the ball
##   - on_ball_event(event): the ball bounced, crossed or clipped the net
## and answers each with a Ruling (nothing yet, fault, let, or point over).

enum Phase { IDLE, SERVE, RALLY, OVER }
enum Reason { NONE, OUT, NET, DOUBLE_BOUNCE, DOUBLE_FAULT, SERVE_VOLLEYED, DOUBLE_HIT }


class Ruling:
	enum Kind { NONE, FAULT, LET, POINT }
	var kind := Kind.NONE
	var winner := Side.NONE
	var reason := Reason.NONE

	static func none() -> Ruling:
		return Ruling.new()

	static func make(p_kind: Kind, p_winner := Side.NONE, p_reason := Reason.NONE) -> Ruling:
		var r := Ruling.new()
		r.kind = p_kind
		r.winner = p_winner
		r.reason = p_reason
		return r

	func is_point() -> bool:
		return kind == Kind.POINT


var phase := Phase.IDLE
var server := Side.NEAR
var deuce_court := true
## 1 for a first serve, 2 for a second serve.
var serve_number := 1
var last_hitter := Side.NONE
## Has the ball crossed into the opponent's half since the last hit?
var crossed := false
## Bounces in the opponent's half since the last hit.
var bounces := 0
var touched_net := false


func start_point(p_server: int, p_deuce_court: bool) -> void:
	server = p_server
	deuce_court = p_deuce_court
	serve_number = 1
	_start_serve()


func receiver() -> int:
	return Side.other(server)


## Sides that may legally strike the ball right now.
func can_hit(side: int) -> bool:
	match phase:
		Phase.SERVE:
			if last_hitter == Side.NONE:
				return side == server
			return side == receiver() and crossed and bounces == 1
		Phase.RALLY:
			return side != last_hitter and crossed and bounces <= 1
	return false


func on_hit(side: int) -> Ruling:
	if phase == Phase.OVER or phase == Phase.IDLE:
		return Ruling.none()
	if side == last_hitter and not crossed:
		return _point(Side.other(side), Reason.DOUBLE_HIT)
	if phase == Phase.SERVE and last_hitter != Side.NONE:
		if bounces == 0:
			# The receiver must let the serve bounce first.
			return _point(server, Reason.SERVE_VOLLEYED)
		phase = Phase.RALLY
	last_hitter = side
	crossed = false
	bounces = 0
	touched_net = false
	return Ruling.none()


func on_ball_event(e: BallEvent) -> Ruling:
	if phase == Phase.OVER or phase == Phase.IDLE or last_hitter == Side.NONE:
		return Ruling.none()
	match e.type:
		BallEvent.Type.NET_HIT:
			touched_net = true
		BallEvent.Type.NET_CROSS:
			if e.side == Side.other(last_hitter):
				crossed = true
		BallEvent.Type.BOUNCE:
			return _on_bounce(e)
	return Ruling.none()


func _on_bounce(e: BallEvent) -> Ruling:
	var opponent := Side.other(last_hitter)
	if bounces >= 1:
		# Landed in, and the opponent did not get it back before the second
		# bounce (wherever that second bounce is).
		return _point(last_hitter, Reason.DOUBLE_BOUNCE)
	if not crossed or e.side != opponent:
		return _fault_or_point(opponent, Reason.NET)
	var serving := phase == Phase.SERVE
	var is_in := (
		Court.is_in_service_box(e.position, server, deuce_court)
		if serving
		else Court.is_in_singles(e.position)
	)
	if not is_in:
		return _fault_or_point(opponent, Reason.OUT)
	if serving and touched_net:
		_start_serve()
		return Ruling.make(Ruling.Kind.LET)
	bounces = 1
	return Ruling.none()


func _fault_or_point(winner: int, reason: Reason) -> Ruling:
	if phase != Phase.SERVE:
		return _point(winner, reason)
	if serve_number == 1:
		serve_number = 2
		_start_serve()
		return Ruling.make(Ruling.Kind.FAULT, Side.NONE, reason)
	return _point(receiver(), Reason.DOUBLE_FAULT)


func _point(winner: int, reason: Reason) -> Ruling:
	phase = Phase.OVER
	return Ruling.make(Ruling.Kind.POINT, winner, reason)


func _start_serve() -> void:
	phase = Phase.SERVE
	last_hitter = Side.NONE
	crossed = false
	bounces = 0
	touched_net = false

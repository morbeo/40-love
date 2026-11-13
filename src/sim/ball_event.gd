class_name BallEvent
extends RefCounted
## Something notable that happened to the ball during one tick.
## The Referee turns these into tennis rulings; the view turns them into
## sounds and particles.

enum Type { BOUNCE, NET_HIT, NET_CROSS }

var type: Type
var tick: int
var position: Vector3
## For BOUNCE: the half of the court it bounced on.
## For NET_CROSS: the half it crossed into. For NET_HIT: the half it came from.
var side: int


static func make(p_type: Type, p_tick: int, p_position: Vector3, p_side: int) -> BallEvent:
	var e := BallEvent.new()
	e.type = p_type
	e.tick = p_tick
	e.position = p_position
	e.side = p_side
	return e


func _to_string() -> String:
	return "%s@%d %s %v" % [Type.keys()[type], tick, Side.name_of(side), position]

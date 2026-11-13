class_name MatchFormat
extends Resource
## How long a match is. v1 defaults to a quick tiebreak; presets cover
## proper sets.

enum Kind { TIEBREAK, SETS }

@export var kind := Kind.SETS
@export var display_name := "One set"

@export_group("Tiebreak match")
## For Kind.TIEBREAK: first to this many points...
@export var points_target := 7
## ...and must lead by two.
@export var win_by_two := true

@export_group("Sets")
@export var sets_to_win := 1
@export var games_per_set := 6
## false = no-ad scoring: at deuce the next point wins the game.
@export var advantage := true
## Games-all score that triggers a tiebreak. Negative = never (advantage set).
@export var tiebreak_at := 6
@export var tiebreak_points := 7


static func quick_tiebreak() -> MatchFormat:
	return first_to(7)


static func first_to(points: int) -> MatchFormat:
	var f := MatchFormat.new()
	f.kind = Kind.TIEBREAK
	f.points_target = points
	f.display_name = "First to %d" % points
	return f


static func one_set() -> MatchFormat:
	return best_of(1)


## Best of 1, 3 or 5 sets.
static func best_of(sets: int) -> MatchFormat:
	var f := MatchFormat.new()
	f.kind = Kind.SETS
	f.sets_to_win = (sets + 1) / 2
	f.display_name = "One set" if sets == 1 else "Best of %d sets" % sets
	return f


static func presets() -> Array[MatchFormat]:
	return [quick_tiebreak(), one_set(), best_of(3), best_of(5)]

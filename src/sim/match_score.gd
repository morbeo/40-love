class_name MatchScore
extends RefCounted
## Tennis scoring: points -> games -> sets -> match, plus who serves next
## and from which side of the centre mark.
##
## Feed it point_won(side) and read the rest. Plain ints in arrays indexed
## by Side, so the whole score is trivially copyable.

const POINT_NAMES := ["0", "15", "30", "40"]

var format: MatchFormat
## Indexed by Side.NEAR / Side.FAR.
var points := [0, 0]
var games := [0, 0]
var sets := [0, 0]
## Finished sets as [near_games, far_games] pairs.
var set_history: Array = []
var in_tiebreak := false
var server := Side.NEAR
## Who served the first point of the current tiebreak.
var tiebreak_first_server := Side.NEAR
var winner := Side.NONE


func _init(p_format: MatchFormat = null, first_server := Side.NEAR) -> void:
	format = p_format if p_format else MatchFormat.quick_tiebreak()
	server = first_server
	if format.kind == MatchFormat.Kind.TIEBREAK:
		_begin_tiebreak()


func is_over() -> bool:
	return winner != Side.NONE


## Points played in the current game or tiebreak.
func points_played() -> int:
	return points[0] + points[1]


## Serve from the deuce (right) court on even point counts.
func deuce_court() -> bool:
	return points_played() % 2 == 0


func point_won(side: int) -> void:
	if is_over():
		return
	points[side] += 1
	if in_tiebreak:
		_after_tiebreak_point(side)
	else:
		_after_game_point(side)


func _after_game_point(side: int) -> void:
	var me: int = points[side]
	var them: int = points[Side.other(side)]
	var won := false
	if me >= 4:
		if not format.advantage:
			won = true
		else:
			won = me - them >= 2
	if won:
		_win_game(side)


func _after_tiebreak_point(side: int) -> void:
	var target: int = (
		format.points_target if format.kind == MatchFormat.Kind.TIEBREAK else format.tiebreak_points
	)
	var me: int = points[side]
	var them: int = points[Side.other(side)]
	var need_two := format.kind != MatchFormat.Kind.TIEBREAK or format.win_by_two
	if me >= target and (not need_two or me - them >= 2):
		if format.kind == MatchFormat.Kind.TIEBREAK:
			winner = side
			return
		games[side] += 1
		in_tiebreak = false
		# The player who received first in the tiebreak serves next set.
		server = Side.other(tiebreak_first_server)
		_win_set(side)
		return
	server = _tiebreak_server(points_played())


## Tiebreak serving: the first server takes one point, then players
## alternate every two points (A, BB, AA, BB, ...).
func _tiebreak_server(points_so_far: int) -> int:
	var block := (points_so_far + 1) / 2
	return tiebreak_first_server if block % 2 == 0 else Side.other(tiebreak_first_server)


func _win_game(side: int) -> void:
	games[side] += 1
	points = [0, 0]
	server = Side.other(server)
	var me: int = games[side]
	var them: int = games[Side.other(side)]
	var g := format.games_per_set
	if me >= g and me - them >= 2:
		_win_set(side)
	elif format.tiebreak_at >= 0 and me == format.tiebreak_at and them == format.tiebreak_at:
		_begin_tiebreak()


func _begin_tiebreak() -> void:
	in_tiebreak = true
	points = [0, 0]
	tiebreak_first_server = server


func _win_set(side: int) -> void:
	set_history.append([games[0], games[1]])
	sets[side] += 1
	games = [0, 0]
	points = [0, 0]
	if sets[side] >= format.sets_to_win:
		winner = side


## "15-30", "Deuce", "Ad NEAR", or tiebreak numbers. Server's score first,
## as an umpire would call it.
func point_text() -> String:
	var s := server
	var r := Side.other(server)
	if in_tiebreak:
		return "%d-%d" % [points[s], points[r]]
	var ps: int = points[s]
	var pr: int = points[r]
	if ps >= 3 and pr >= 3 and format.advantage:
		if ps == pr:
			return "Deuce"
		return "Ad %s" % Side.name_of(s if ps > pr else r)
	return "%s-%s" % [POINT_NAMES[mini(ps, 3)], POINT_NAMES[mini(pr, 3)]]


func copy() -> MatchScore:
	var m := MatchScore.new(format, server)
	m.points = points.duplicate()
	m.games = games.duplicate()
	m.sets = sets.duplicate()
	m.set_history = set_history.duplicate(true)
	m.in_tiebreak = in_tiebreak
	m.tiebreak_first_server = tiebreak_first_server
	m.winner = winner
	return m

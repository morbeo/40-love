extends GutTest
## Tennis scoring, from a single point up to a best-of-five match.


func _win(score: MatchScore, side: int, n: int) -> void:
	for i in n:
		score.point_won(side)


func _games(score: MatchScore, side: int, n: int) -> void:
	for i in n:
		_win(score, side, 4)


func test_love_game() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	_win(s, Side.NEAR, 4)
	assert_eq(s.games, [1, 0])
	assert_eq(s.points, [0, 0])
	assert_eq(s.server, Side.FAR, "serve alternates each game")


func test_calls_follow_umpire_conventions() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	assert_eq(s.point_text(), "0-0")
	s.point_won(Side.NEAR)
	assert_eq(s.point_text(), "15-0")
	s.point_won(Side.FAR)
	s.point_won(Side.FAR)
	assert_eq(s.point_text(), "15-30")
	s.point_won(Side.NEAR)
	s.point_won(Side.NEAR)
	s.point_won(Side.FAR)
	assert_eq(s.point_text(), "Deuce")
	s.point_won(Side.FAR)
	assert_eq(s.point_text(), "Ad FAR")


func test_deuce_needs_two_clear_points() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	_win(s, Side.NEAR, 3)
	_win(s, Side.FAR, 3)
	s.point_won(Side.NEAR)
	s.point_won(Side.FAR)
	assert_eq(s.games, [0, 0], "back to deuce")
	_win(s, Side.FAR, 2)
	assert_eq(s.games, [0, 1])


func test_no_ad_scoring_ends_at_the_deciding_point() -> void:
	var f := MatchFormat.one_set()
	f.advantage = false
	var s := MatchScore.new(f)
	_win(s, Side.NEAR, 3)
	_win(s, Side.FAR, 3)
	s.point_won(Side.FAR)
	assert_eq(s.games, [0, 1])


func test_deuce_court_alternates_every_point() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	assert_true(s.deuce_court())
	s.point_won(Side.NEAR)
	assert_false(s.deuce_court())
	s.point_won(Side.NEAR)
	assert_true(s.deuce_court())


func test_set_is_won_six_four() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	_games(s, Side.FAR, 4)
	_games(s, Side.NEAR, 5)
	assert_false(s.is_over())
	_games(s, Side.NEAR, 1)
	assert_eq(s.set_history, [[6, 4]])
	assert_eq(s.winner, Side.NEAR)


func test_five_all_goes_to_seven_five() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	_games(s, Side.NEAR, 5)
	_games(s, Side.FAR, 5)
	_games(s, Side.NEAR, 1)
	assert_false(s.is_over(), "6-5 is not enough")
	_games(s, Side.NEAR, 1)
	assert_eq(s.set_history, [[7, 5]])


func test_six_all_plays_a_tiebreak() -> void:
	var s := MatchScore.new(MatchFormat.one_set())
	_games(s, Side.NEAR, 5)
	_games(s, Side.FAR, 6)
	_games(s, Side.NEAR, 1)
	assert_true(s.in_tiebreak)
	assert_eq(s.point_text(), "0-0")
	_win(s, Side.FAR, 6)
	_win(s, Side.NEAR, 6)
	assert_false(s.is_over(), "6-6 in the tiebreak needs two clear")
	_win(s, Side.FAR, 2)
	assert_eq(s.set_history, [[6, 7]])
	assert_eq(s.winner, Side.FAR)


func test_tiebreak_serve_order_is_a_bb_aa_bb() -> void:
	var s := MatchScore.new(MatchFormat.quick_tiebreak(), Side.NEAR)
	var order := []
	for i in 7:
		order.append(s.server)
		# Alternate winners so the tiebreak doesn't end early.
		s.point_won(i % 2)
	var a := Side.NEAR
	var b := Side.FAR
	assert_eq(order, [a, b, b, a, a, b, b])


func test_receiver_of_tiebreak_serves_the_next_set() -> void:
	var s := MatchScore.new(MatchFormat.best_of(3), Side.NEAR)
	for i in 6:
		_games(s, Side.NEAR, 1)
		_games(s, Side.FAR, 1)
	assert_true(s.in_tiebreak)
	var first := s.tiebreak_first_server
	_win(s, Side.NEAR, 7)
	assert_eq(s.server, Side.other(first))


func test_best_of_three_needs_two_sets() -> void:
	var s := MatchScore.new(MatchFormat.best_of(3))
	_games(s, Side.NEAR, 6)
	assert_false(s.is_over())
	_games(s, Side.FAR, 6)
	_games(s, Side.NEAR, 6)
	assert_eq(s.set_history, [[6, 0], [0, 6], [6, 0]])
	assert_eq(s.winner, Side.NEAR)


func test_quick_tiebreak_is_first_to_seven_by_two() -> void:
	var s := MatchScore.new(MatchFormat.quick_tiebreak())
	_win(s, Side.NEAR, 6)
	_win(s, Side.FAR, 6)
	s.point_won(Side.NEAR)
	assert_false(s.is_over())
	s.point_won(Side.NEAR)
	assert_eq(s.winner, Side.NEAR)


func test_first_to_n_without_win_by_two() -> void:
	var f := MatchFormat.first_to(5)
	f.win_by_two = false
	var s := MatchScore.new(f)
	_win(s, Side.FAR, 4)
	_win(s, Side.NEAR, 4)
	s.point_won(Side.NEAR)
	assert_eq(s.winner, Side.NEAR)


func test_points_after_the_match_are_ignored() -> void:
	var f := MatchFormat.first_to(1)
	f.win_by_two = false
	var s := MatchScore.new(f)
	s.point_won(Side.FAR)
	s.point_won(Side.NEAR)
	assert_eq(s.points, [0, 1])


func test_presets_cover_tiebreak_through_five_sets() -> void:
	var names := MatchFormat.presets().map(func(f: MatchFormat) -> String: return f.display_name)
	assert_eq(names, ["First to 7", "One set", "Best of 3 sets", "Best of 5 sets"])

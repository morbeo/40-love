extends GutTest
## Whole-match tests: two AutoHitter bots play real points through the real
## physics, referee and scoring. This is the determinism contract.

const MAX_TICKS := 60 * 60 * 60  # an hour of match time


func _bot_match(seed: int, format: MatchFormat = null) -> MatchSim:
	var sim := MatchSim.new(seed, format)
	sim.set_striker(Side.NEAR, AutoHitter.new())
	sim.set_striker(Side.FAR, AutoHitter.new())
	return sim


func test_a_bot_match_finishes() -> void:
	var sim := _bot_match(1)
	sim.run(MAX_TICKS)
	assert_true(sim.is_over())
	assert_ne(sim.score.winner, Side.NONE)


func test_same_seed_replays_identically() -> void:
	var a := _bot_match(42)
	var b := _bot_match(42)
	# Compare every tick, not just the end: divergence is caught where it starts.
	for i in 3000:
		a.step()
		b.step()
		if a.state_hash() != b.state_hash():
			fail_test("diverged at tick %d" % i)
			return
	pass_test("identical for 3000 ticks")


func test_different_seeds_play_different_matches() -> void:
	var a := _bot_match(1)
	var b := _bot_match(2)
	a.run(2000)
	b.run(2000)
	assert_ne(a.state_hash(), b.state_hash())


func test_every_point_has_a_winner_and_a_reason() -> void:
	var sim := _bot_match(7)
	sim.run(MAX_TICKS)
	assert_gt(sim.history.size(), 0)
	for entry in sim.history:
		assert_true(entry[0] == Side.NEAR or entry[0] == Side.FAR)
		assert_ne(entry[1], Referee.Reason.NONE)


func test_points_in_history_match_the_score() -> void:
	var sim := _bot_match(3)
	sim.run(MAX_TICKS)
	var replay := MatchScore.new(sim.score.format)
	for entry in sim.history:
		replay.point_won(entry[0])
	assert_eq(replay.winner, sim.score.winner)
	assert_eq(replay.points, sim.score.points)


## Golden master: if this changes, ball physics, rules or the bot changed.
## That can be fine; update the expected values on purpose, never by accident.
func test_golden_match_seed_42() -> void:
	var sim := _bot_match(42, MatchFormat.one_set())
	sim.run(MAX_TICKS)
	var summary := [sim.score.set_history, sim.history.size(), sim.tick]
	gut.p("seed 42: sets %s, %d points, %d ticks" % summary)
	assert_eq(sim.score.set_history, [[4, 6]])
	assert_eq(sim.history.size(), 75)

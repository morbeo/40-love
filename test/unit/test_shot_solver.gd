extends GutTest
## The solver must put the ball where the striker asked, for every style.

var cfg := PhysicsConfig.new()


## [from, target, flight_time, topspin, sidespin]
func test_lands_on_target(
	p = use_parameters(
		[
			[Vector3(0.8, 2.6, 12.2), Vector3(-2, 0, -5), 0.6, 30.0, 0.0],
			[Vector3(0, 1, 11), Vector3(3, 0, -10), 1.2, 250.0, 0.0],
			[Vector3(-3, 0.6, 12), Vector3(3.5, 0, -11), 1.0, 0.0, 0.0],
			[Vector3(2, 0.8, -12), Vector3(-3, 0, 9), 1.5, -200.0, 0.0],
			[Vector3(0, 1, 11), Vector3(-2, 0, -8), 1.1, 100.0, 120.0],
		]
	)
) -> void:
	var from: Vector3 = p[0]
	var target: Vector3 = p[1]
	var spin := Ball.make_spin(target - from, p[3], p[4])
	var v := ShotSolver.solve(from, target, p[2], spin, cfg)
	var landing := ShotSolver.simulate_landing(from, v, spin, cfg)
	assert_almost_eq(landing.x, target.x, 0.02, "x")
	assert_almost_eq(landing.z, target.z, 0.02, "z")
	assert_almost_eq(landing.y, p[2], 0.05, "flight time")


func test_shorter_flight_time_means_a_harder_shot() -> void:
	var from := Vector3(0, 1, 11)
	var target := Vector3(0, 0, -9)
	var fast := ShotSolver.solve(from, target, 0.7, Vector3.ZERO, cfg)
	var slow := ShotSolver.solve(from, target, 1.4, Vector3.ZERO, cfg)
	assert_gt(fast.length(), slow.length())

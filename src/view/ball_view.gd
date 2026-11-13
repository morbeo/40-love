class_name BallView
extends Node3D
## Draws the sim's Ball: the ball itself, a shadow straight below it (the
## most important depth cue in any 3D sports game) and a fading trail.

const TRAIL_LENGTH := 36

var radius := 0.033
var _ball: MeshInstance3D
var _shadow: MeshInstance3D
var _trail: MeshInstance3D
var _trail_mesh := ImmediateMesh.new()
var _trail_points: Array[Vector3] = []


func _ready() -> void:
	# Drawn larger than life (x2.2) so it reads at broadcast distance,
	# like every tennis game does.
	var sphere := SphereMesh.new()
	sphere.radius = radius * 2.2
	sphere.height = radius * 4.4
	sphere.material = Palette.material(Palette.BALL)
	_ball = MeshInstance3D.new()
	_ball.mesh = sphere
	add_child(_ball)

	var disc := CylinderMesh.new()
	disc.top_radius = radius * 2.4
	disc.bottom_radius = radius * 2.4
	disc.height = 0.001
	disc.material = Palette.material(Palette.SHADOW, true)
	_shadow = MeshInstance3D.new()
	_shadow.mesh = disc
	add_child(_shadow)

	_trail = MeshInstance3D.new()
	_trail.mesh = _trail_mesh
	var m := Palette.material(Palette.TRAIL, true)
	m.vertex_color_use_as_albedo = true
	_trail.material_override = m
	# The trail is rebuilt in world space every frame; interpolating its
	# transform would smear it.
	_trail.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_trail.top_level = true
	add_child(_trail)


## Call once per physics tick with the latest sim state.
func sync(ball: Ball) -> void:
	_ball.position = ball.position
	_shadow.position = Vector3(ball.position.x, 0.004, ball.position.z)
	# Shadow shrinks a little as the ball rises.
	var s := clampf(1.2 - ball.position.y * 0.12, 0.5, 1.2)
	_shadow.scale = Vector3(s, 1.0, s)
	if ball.held:
		_trail_points.clear()
	else:
		_trail_points.append(ball.position)
		if _trail_points.size() > TRAIL_LENGTH:
			_trail_points.pop_front()
	_draw_trail()


## Teleports without interpolation, e.g. when a new point starts.
func snap(ball: Ball) -> void:
	sync(ball)
	_ball.reset_physics_interpolation()
	_shadow.reset_physics_interpolation()


func _draw_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := _trail_points.size()
	for i in n:
		var c := Palette.TRAIL
		c.a *= float(i) / float(n - 1)
		_trail_mesh.surface_set_color(c)
		_trail_mesh.surface_add_vertex(_trail_points[i])
	_trail_mesh.surface_end()

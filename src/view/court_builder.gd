class_name CourtBuilder
extends RefCounted
## Builds the court out of primitive meshes at runtime: no models, no
## textures. Every size comes from the Court constants the sim uses, so
## what you see is exactly what the referee rules on.

const DOUBLES_HALF_WIDTH := 10.97 * 0.5
## A whisker above the ground to avoid z-fighting between stacked planes.
const LIFT := 0.002


static func build(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Court"
	parent.add_child(root)

	_plane(root, "Surround", Vector2(30.0, 44.0), 0.0, Palette.SURROUND)
	var court_size := Vector2(DOUBLES_HALF_WIDTH * 2.0 + 2.0, Court.LENGTH + 4.0)
	_plane(root, "Surface", court_size, LIFT, Palette.COURT)
	_lines(root)
	_net(root)
	return root


static func _plane(parent: Node3D, name: String, size: Vector2, y: float, color: Color) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.material = Palette.material(color)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position.y = y
	parent.add_child(mi)


## A court line is a very flat box. Lines sit inside the court boundary,
## matching the rule that line dimensions are to the outer edge.
static func _line(parent: Node3D, from: Vector2, to: Vector2) -> void:
	var w := Court.LINE_WIDTH
	var mesh := BoxMesh.new()
	var size := (to - from).abs()
	mesh.size = Vector3(maxf(size.x, w), LIFT, maxf(size.y, w))
	mesh.material = Palette.material(Palette.LINE)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mid := (from + to) * 0.5
	mi.position = Vector3(mid.x, LIFT * 2.0, mid.y)
	parent.add_child(mi)


static func _lines(parent: Node3D) -> void:
	var lines := Node3D.new()
	lines.name = "Lines"
	parent.add_child(lines)
	var hw := Court.HALF_WIDTH - Court.LINE_WIDTH * 0.5
	var dw := DOUBLES_HALF_WIDTH - Court.LINE_WIDTH * 0.5
	var hl := Court.HALF_LENGTH - Court.LINE_WIDTH * 0.5
	var sl := Court.SERVICE_LINE - Court.LINE_WIDTH * 0.5
	for s in [-1.0, 1.0]:
		_line(lines, Vector2(-dw, s * hl), Vector2(dw, s * hl))  # baseline
		_line(lines, Vector2(s * hw, -hl), Vector2(s * hw, hl))  # singles sideline
		_line(lines, Vector2(s * dw, -hl), Vector2(s * dw, hl))  # doubles sideline
		_line(lines, Vector2(-hw, s * sl), Vector2(hw, s * sl))  # service line
		_line(lines, Vector2(0.0, s * hl), Vector2(0.0, s * (hl - 0.1)))  # centre mark
	_line(lines, Vector2(0.0, -sl), Vector2(0.0, sl))  # centre service line


static func _net(parent: Node3D) -> void:
	var net := Node3D.new()
	net.name = "Net"
	parent.add_child(net)
	var span := Court.NET_POST_X * 2.0
	# The sim's net sags from 1.07 m at the posts to 0.914 m in the middle.
	# Draw it as two halves, each a box tilted to follow that slope.
	for s in [-1.0, 1.0]:
		var half := BoxMesh.new()
		half.size = Vector3(Court.NET_POST_X, 1.0, 0.02)
		half.material = Palette.material(Palette.NET)
		var mi := MeshInstance3D.new()
		mi.mesh = half
		var avg_h := (Court.NET_HEIGHT_CENTER + Court.NET_HEIGHT_POST) * 0.5
		mi.position = Vector3(s * Court.NET_POST_X * 0.5, avg_h * 0.5, 0.0)
		mi.scale.y = avg_h
		net.add_child(mi)
		var tape := BoxMesh.new()
		var rise := Court.NET_HEIGHT_POST - Court.NET_HEIGHT_CENTER
		tape.size = Vector3(Vector2(Court.NET_POST_X, rise).length(), 0.05, 0.03)
		tape.material = Palette.material(Palette.NET_TAPE)
		var ti := MeshInstance3D.new()
		ti.mesh = tape
		ti.position = Vector3(s * Court.NET_POST_X * 0.5, Court.NET_HEIGHT_CENTER + rise * 0.5, 0.0)
		ti.rotation.z = s * atan2(rise, Court.NET_POST_X)
		net.add_child(ti)
		var post := CylinderMesh.new()
		post.top_radius = 0.04
		post.bottom_radius = 0.04
		post.height = Court.NET_HEIGHT_POST + 0.03
		post.material = Palette.material(Palette.POST)
		var pi := MeshInstance3D.new()
		pi.mesh = post
		pi.position = Vector3(s * span * 0.5, post.height * 0.5, 0.0)
		net.add_child(pi)

extends SceneTree
## Renders side-view trajectory charts of the real ball sim to SVG files.
## No plotting library: SVG is just text, so we write it ourselves.
##
## Usage:
##   godot --headless --path . -s res://tools/plot_trajectories.gd -- --out=docs/devlog/media/auto

const W := 960.0
const H := 340.0
const PAD := 56.0
## Court span shown on the X axis (world Z, near baseline on the left).
const Z_MIN := -14.0
const Z_MAX := 13.0
const Y_MAX := 4.5
const INK := "#1d2430"
const MUTED := "#8a94a6"

var cfg := PhysicsConfig.new()


func _init() -> void:
	var out := "docs/devlog/media/auto"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	_write(out.path_join("spin-trajectories.svg"), _spin_chart())
	quit()


func _spin_chart() -> String:
	var from := Vector3(0.0, 1.0, 11.5)
	var v := Vector3(0.0, 4.4, -19.0)
	var series := [
		["Topspin 250 rad/s", "#d1495b", _fly(from, v, Ball.make_spin(v, 250.0, 0.0))],
		["Flat", "#2e86ab", _fly(from, v, Vector3.ZERO)],
		["Slice 180 rad/s", "#3b9a5b", _fly(from, v, Ball.make_spin(v, -180.0, 0.0))],
	]
	return _chart("Same swing, different spin", series)


## Runs the real BallPhysics until the second bounce. Returns the points
## plus the bounce positions so the chart can mark them.
func _fly(from: Vector3, v: Vector3, spin: Vector3) -> Dictionary:
	var b := Ball.new()
	b.position = from
	b.velocity = v
	b.spin = spin
	var pts: Array[Vector2] = [Vector2(from.z, from.y)]
	var bounces: Array[Vector2] = []
	for t in 400:
		for e in BallPhysics.step(b, cfg, t):
			if e.type == BallEvent.Type.BOUNCE:
				bounces.append(Vector2(e.position.z, 0.0))
		pts.append(Vector2(b.position.z, b.position.y))
		if bounces.size() >= 2 or b.position.z < Z_MIN:
			break
	return {"points": pts, "bounces": bounces}


func _chart(title: String, series: Array) -> String:
	var s := PackedStringArray()
	s.append(
		(
			(
				'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
				+ 'font-family="system-ui, sans-serif" font-size="13">'
			)
			% [W, H]
		)
	)
	s.append('<rect width="100%" height="100%" fill="#ffffff"/>')
	s.append(
		(
			'<text x="%d" y="26" fill="%s" font-size="16" font-weight="600">%s</text>'
			% [PAD, INK, title]
		)
	)
	# Ground, net and court markings.
	var g0 := _pt(Vector2(Z_MIN, 0.0))
	var g1 := _pt(Vector2(Z_MAX, 0.0))
	s.append(_line(g0, g1, INK, 1.5))
	s.append(_line(_pt(Vector2(0, 0)), _pt(Vector2(0, Court.NET_HEIGHT_CENTER)), INK, 3.0))
	for z in [Court.HALF_LENGTH, -Court.HALF_LENGTH, Court.SERVICE_LINE, -Court.SERVICE_LINE]:
		var p := _pt(Vector2(z, 0.0))
		s.append(_line(p, p + Vector2(0, 8), MUTED, 1.0))
	for label in [
		[Court.HALF_LENGTH, "near baseline"],
		[-Court.SERVICE_LINE, "service line"],
		[-Court.HALF_LENGTH, "far baseline"],
		[0.0, "net"],
	]:
		var p := _pt(Vector2(label[0], 0.0))
		s.append(
			(
				'<text x="%.1f" y="%.1f" fill="%s" text-anchor="middle">%s</text>'
				% [p.x, p.y + 22, MUTED, label[1]]
			)
		)
	# Height gridlines every metre.
	for m in range(1, int(Y_MAX) + 1):
		var p := _pt(Vector2(Z_MAX, m))
		s.append(_line(p, _pt(Vector2(Z_MIN, m)), "#eef1f5", 1.0))
		s.append(
			(
				'<text x="%.1f" y="%.1f" fill="%s" text-anchor="end">%d m</text>'
				% [p.x - 6, p.y + 4, MUTED, m]
			)
		)
	# Series.
	for i in series.size():
		var label: String = series[i][0]
		var color: String = series[i][1]
		var data: Dictionary = series[i][2]
		var poly := PackedStringArray()
		for q in data["points"]:
			var p := _pt(q)
			poly.append("%.1f,%.1f" % [p.x, p.y])
		s.append(
			(
				'<polyline points="%s" fill="none" stroke="%s" stroke-width="2.5"/>'
				% [" ".join(poly), color]
			)
		)
		for bq in data["bounces"]:
			var p := _pt(bq)
			s.append('<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>' % [p.x, p.y, color])
		var ly := 52 + i * 20
		s.append(_line(Vector2(W - 250, ly - 4), Vector2(W - 226, ly - 4), color, 3.0))
		s.append('<text x="%d" y="%d" fill="%s">%s</text>' % [W - 218, ly, INK, label])
	s.append("</svg>")
	return "\n".join(s)


## World (z, height) -> SVG pixels. Near baseline on the left.
func _pt(q: Vector2) -> Vector2:
	var x := PAD + (Z_MAX - q.x) / (Z_MAX - Z_MIN) * (W - 2.0 * PAD)
	var y := H - PAD - q.y / Y_MAX * (H - 2.0 * PAD - 20.0)
	return Vector2(x, y)


func _line(a: Vector2, b: Vector2, color: String, width: float) -> String:
	return (
		'<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%.1f"/>'
		% [a.x, a.y, b.x, b.y, color, width]
	)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	print("wrote ", path)

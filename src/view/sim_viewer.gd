extends Node3D
## Debug viewer: watch two AutoHitter bots play a match through the real
## sim. Everything on screen is generated at runtime.
##
## Command-line options (after a lone `--`):
##   --seed=N          RNG seed (default 42)
##   --format=NAME     tiebreak | one_set | best_of_3 | best_of_5 (default tiebreak)
##   --camera=NAME     broadcast | side | high (default broadcast)
##
## The sim advances in _physics_process at a fixed 60 ticks per second.
## Rendering happens at whatever rate the screen runs; Godot's physics
## interpolation smooths node positions between ticks.

## name -> [camera position, look-at point, field of view]
const CAMERAS := {
	"broadcast": [Vector3(0.0, 8.0, 24.5), Vector3(0.0, 0.0, -1.0), 42.0],
	"side": [Vector3(16.0, 3.5, 0.0), Vector3(0.0, 1.0, 0.0), 50.0],
	"high": [Vector3(0.0, 30.0, 8.0), Vector3(0.0, 0.0, 0.0), 50.0],
}

var sim: MatchSim
var seed_value := 42
var format_name := "tiebreak"
var _ball_view: BallView
var _hud: Label
var _call: Label
var _call_timer := 0


func _ready() -> void:
	var args := parse_args(OS.get_cmdline_user_args())
	seed_value = int(args.get("seed", "42"))
	format_name = args.get("format", "tiebreak")
	_build_world(args.get("camera", "broadcast"))
	CourtBuilder.build(self)
	_ball_view = BallView.new()
	add_child(_ball_view)
	_build_hud()
	_new_match()


func _physics_process(_delta: float) -> void:
	var ball_before := sim.ball
	sim.step()
	if sim.ball != ball_before:
		# MatchSim swaps in a fresh Ball for each new point: teleport.
		_ball_view.snap(sim.ball)
	else:
		_ball_view.sync(sim.ball)
	_show_call(sim.last_ruling)
	_update_hud()
	if sim.is_over():
		seed_value += 1
		_new_match()


func _new_match() -> void:
	sim = MatchSim.new(seed_value, make_format(format_name))
	sim.set_striker(Side.NEAR, AutoHitter.new())
	sim.set_striker(Side.FAR, AutoHitter.new())
	_ball_view.snap(sim.ball)


static func make_format(name: String) -> MatchFormat:
	match name:
		"one_set":
			return MatchFormat.one_set()
		"best_of_3":
			return MatchFormat.best_of(3)
		"best_of_5":
			return MatchFormat.best_of(5)
	return MatchFormat.quick_tiebreak()


## Turns ["--seed=7", "--camera=side"] into {"seed": "7", "camera": "side"}.
static func parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	for a in raw:
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1]
	return out


func _build_world(camera_name: String) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Palette.SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.light_energy = 0.9
	add_child(sun)

	var cam_def: Array = CAMERAS.get(camera_name, CAMERAS["broadcast"])
	var cam := Camera3D.new()
	cam.fov = cam_def[2]
	add_child(cam)
	cam.look_at_from_position(cam_def[0], cam_def[1])
	cam.current = true


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.HUD_PANEL
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(16, 16)
	layer.add_child(panel)
	_hud = Label.new()
	_hud.add_theme_color_override("font_color", Palette.HUD_TEXT)
	_hud.add_theme_font_size_override("font_size", 20)
	panel.add_child(_hud)

	_call = Label.new()
	_call.add_theme_color_override("font_color", Palette.HUD_TEXT)
	_call.add_theme_font_size_override("font_size", 40)
	_call.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_call.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_call.position.y = 24
	layer.add_child(_call)


func _update_hud() -> void:
	var s := sim.score
	# Plain ASCII: the default font on the web build has no bullet glyphs.
	var mark := func(side: int) -> String: return "(serving)" if s.server == side else ""
	var lines := PackedStringArray()
	lines.append("%s · seed %d" % [s.format.display_name, seed_value])
	for side in [Side.NEAR, Side.FAR]:
		var row := "%-4s %s" % [Side.name_of(side), mark.call(side)]
		if s.format.kind == MatchFormat.Kind.SETS:
			row += "  sets %d  games %d" % [s.sets[side], s.games[side]]
		lines.append(row)
	lines.append(("Winner: %s" % Side.name_of(s.winner)) if s.is_over() else s.point_text())
	_hud.text = "\n".join(lines)


func _show_call(r: Referee.Ruling) -> void:
	var text := ""
	match r.kind:
		Referee.Ruling.Kind.FAULT:
			text = "Fault"
		Referee.Ruling.Kind.LET:
			text = "Let"
		Referee.Ruling.Kind.POINT:
			text = Referee.Reason.keys()[r.reason].capitalize()
	if text != "":
		_call.text = text
		_call_timer = MatchSim.PAUSE_TICKS
	elif _call_timer > 0:
		_call_timer -= 1
		if _call_timer == 0:
			_call.text = ""

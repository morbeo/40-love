class_name Palette
extends RefCounted
## Every colour in the game, in one place. No textures: the whole look is
## flat colours on generated meshes. Light, high-contrast and readable.

const SKY := Color("#e9f0f6")
const SURROUND := Color("#5f8f74")
const COURT := Color("#3e6fb0")
const LINE := Color("#f7f7f2")
const NET := Color(0.12, 0.13, 0.15, 0.55)
const NET_TAPE := Color("#f7f7f2")
const POST := Color("#2b2d31")
const BALL := Color("#d9ef3c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.35)
const TRAIL := Color(1.0, 1.0, 1.0, 0.8)
const HUD_TEXT := Color("#1d2430")
const HUD_PANEL := Color(1.0, 1.0, 1.0, 0.85)


static func material(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

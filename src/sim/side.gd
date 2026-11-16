class_name Side
extends RefCounted
## The two ends of the court, plus "nobody".
##
## NEAR is the +Z half (where the camera sits, the human player in v1).
## FAR is the -Z half (the CPU in v1). NONE means "no side yet": no hitter
## before the serve, no winner before the match ends.
##
## `Side.Id` is a named enum, so it can be used as a type:
## `func point_won(side: Side.Id)`. Under the hood the values are still ints,
## so they index arrays directly (`points[side]`).

enum Id { NONE = -1, NEAR = 0, FAR = 1 }

## Shorthands, so callers write Side.NEAR instead of Side.Id.NEAR.
const NONE := Id.NONE
const NEAR := Id.NEAR
const FAR := Id.FAR


static func other(side: Id) -> Id:
	return FAR if side == NEAR else NEAR


## Which half of the court a Z coordinate is on. The net plane (z == 0)
## counts as NEAR so every point has exactly one owner.
static func of_z(z: float) -> Id:
	return NEAR if z >= 0.0 else FAR


## +1 for NEAR, -1 for FAR. Multiply a "towards my baseline" distance by this
## to get a world Z coordinate.
static func sign_of(side: Id) -> float:
	return 1.0 if side == NEAR else -1.0


## "NEAR", "FAR" or "NONE", for logs and the HUD.
static func name_of(side: Id) -> String:
	var key: Variant = Id.find_key(side)
	return key if key != null else "INVALID(%d)" % side

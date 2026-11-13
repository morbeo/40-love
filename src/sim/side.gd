class_name Side
extends RefCounted
## The two ends of the court.
##
## NEAR is the +Z half (where the camera sits, the human player in v1).
## FAR is the -Z half (the CPU in v1). Plain ints keep sim state trivially
## copyable and hashable.

const NONE := -1
const NEAR := 0
const FAR := 1


static func other(side: int) -> int:
	return 1 - side


## Which half of the court a Z coordinate is on. The net plane (z == 0)
## counts as NEAR so every point has exactly one owner.
static func of_z(z: float) -> int:
	return NEAR if z >= 0.0 else FAR


## +1 for NEAR, -1 for FAR. Multiply a "towards my baseline" distance by this
## to get a world Z coordinate.
static func sign_of(side: int) -> float:
	return 1.0 if side == NEAR else -1.0


static func name_of(side: int) -> String:
	match side:
		NEAR:
			return "NEAR"
		FAR:
			return "FAR"
	return "NONE"

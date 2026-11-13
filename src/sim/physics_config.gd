class_name PhysicsConfig
extends Resource
## Every tunable number of the ball simulation, in one place.
##
## Because this is a Resource, a configured copy can be saved as a .tres
## file and tweaked in the Inspector without touching code. Defaults are
## close to a real tennis ball on a hard court, nudged towards "arcade".

## Simulation ticks per second. Must match the project's physics tick rate.
@export var tick_rate: int = 60
@export var gravity: float = 9.81
@export var ball_radius: float = 0.033

@export_group("Air")
## Quadratic drag: a = -drag * |v| * v. Real ball is about 0.02.
@export var drag: float = 0.012
## Magnus lift: a = magnus * (spin x v). Topspin pushes the ball down,
## backspin holds it up, sidespin curves it.
@export var magnus: float = 0.0006
## Fraction of spin lost per second in flight.
@export var spin_decay: float = 0.05

@export_group("Bounce")
## Vertical speed kept after a bounce (coefficient of restitution).
@export var restitution: float = 0.75
## Coulomb friction between ball and court during the bounce impulse.
## Higher means spin "grabs" more: topspin kicks, backspin skids and dies.
@export var friction: float = 0.6
## Below this vertical speed a bounce is treated as rolling.
@export var rest_speed: float = 0.25

@export_group("Net")
## How much velocity survives when the ball clips the net.
@export var net_damping: float = 0.15


func dt() -> float:
	return 1.0 / float(tick_rate)

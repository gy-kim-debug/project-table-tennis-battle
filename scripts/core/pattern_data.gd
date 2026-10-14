extends Resource

@export var display_name: String = "BASIC RETURN"
@export_range(0, 100) var pattern_difficulty: float = 10.0
@export var strong_attack: bool = false
@export_range(0.3, 3.0) var travel_exponent: float = 1.0
@export_range(-0.5, 0.5) var lateral_sway: float = 0.0
@export var pattern_id: String = "pattern_01"
@export_range(0.3, 5.0) var incoming_seconds: float = 1.25
@export_range(0.3, 5.0) var return_seconds: float = 0.85
@export_range(0.1, 0.9) var bounce_fraction: float = 0.62
@export var start_point: Vector3 = Vector3(1.0, 0.0, 40.0)
@export var hit_point: Vector3 = Vector3(-1.0, 1.0, 16.0)
@export var arc_height: float = 34.0

# Logical coordinates: x across table [-1, 1], z depth [0, 1], h pixels high.
func sample(progress: float, returning: bool = false, return_origin: Vector3 = Vector3.ZERO) -> Vector3:
	var u: float = clampf(progress, 0.0, 1.2 if not returning else 1.0)
	var from: Vector3 = return_origin if returning else start_point
	var to: Vector3 = start_point if returning else hit_point
	var travel: float = u if returning else pow(u, travel_exponent)
	var point: Vector3 = from.lerp(to, travel)
	# x returns to the same fixed racket position for every pattern.
	point.x += sin(minf(u, 1.0) * PI) * lateral_sway
	var b: float = bounce_fraction
	if u <= b:
		var local: float = u / b
		point.z = lerpf(from.z, 0.0, local) + sin(local * PI) * arc_height
	else:
		var local: float = (u - b) / (1.0 - b)
		point.z = maxf(0.0, lerpf(0.0, to.z, local) + sin(minf(local, 1.0) * PI) * arc_height * 0.5)
	return point

func is_valid() -> bool:
	return incoming_seconds > 0 and return_seconds > 0 and bounce_fraction > 0 and bounce_fraction < 1 and arc_height >= 0 and travel_exponent > 0 and pattern_difficulty >= 0 and pattern_difficulty <= 100

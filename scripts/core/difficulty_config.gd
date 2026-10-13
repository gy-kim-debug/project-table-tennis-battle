extends Resource

@export var difficulty_id: String = "normal"
@export var display_name: String = "NORMAL"
@export var defense_ability: float = 65.0
@export_range(0.5, 2.0) var flight_multiplier: float = 1.0
@export var pattern_weights: PackedFloat32Array = PackedFloat32Array([28, 22, 20, 20, 10])

func is_valid(pattern_count: int = 5) -> bool:
	if not is_finite(flight_multiplier) or flight_multiplier <= 0 or pattern_weights.size() != pattern_count:
		return false
	var total: float = 0.0
	for weight in pattern_weights:
		if weight < 0 or not is_finite(weight):
			return false
		total += weight
	return total > 0 and is_finite(defense_ability)

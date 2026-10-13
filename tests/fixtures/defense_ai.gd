extends RefCounted

# Deterministic fixture only; the normal scene uses EnemyAI.
var difficulty: Resource
var pattern_index: int = 0
var grade: int = 1
var last_power: int = -1
var calls: int = 0

func reset() -> void:
	last_power = -1
	calls = 0

func defend(power: int, _pressure: int = 0, _pattern_difficulty: float = 0.0) -> int:
	last_power = power
	calls += 1
	return grade

func select_pattern(patterns: Array[Resource], _profile: Resource) -> Resource:
	return patterns[pattern_index]

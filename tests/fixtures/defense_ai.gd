extends RefCounted

# Deterministic fixture only; the normal scene uses EnemyAI.
var grade: int = 1
var last_power: int = -1
var calls: int = 0

func reset() -> void:
	last_power = -1
	calls = 0

func defend(power: int) -> int:
	last_power = power
	calls += 1
	return grade

extends Resource

# Initial balance values, not direct damage on a successful hit.
@export_range(1, 999) var max_hp: int = 100
@export_range(1, 999) var normal_damage: int = 12
@export_range(1, 999) var strong_damage: int = 18
@export var attack_power: PackedInt32Array = PackedInt32Array([100, 65, 30, 0])
# Phase 2 baseline: no pressure, pattern weighting or difficulty presets yet.
@export var defense_ability: float = 60.0
@export var random_min: float = -45.0
@export var random_max: float = 45.0
@export var attack_weight: float = 0.30
@export var perfect_score: float = 65.0
@export var good_score: float = 40.0
@export var bad_score: float = 15.0
@export var fixed_seed: bool = false
@export var seed_value: int = 20261013

func is_valid() -> bool:
	return max_hp > 0 and normal_damage > 0 and strong_damage > 0 and attack_power.size() == 4 and random_min <= random_max and bad_score <= good_score and good_score <= perfect_score

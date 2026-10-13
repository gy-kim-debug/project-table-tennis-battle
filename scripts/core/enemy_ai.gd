extends RefCounted

const Judge = preload("res://scripts/core/timing_judge.gd")
const Config = preload("res://scripts/core/battle_config.gd")
var config: Resource
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(settings: Resource = null) -> void:
	config = settings if settings != null else Config.new()
	assert(config.is_valid())
	reset()

func reset() -> void:
	if config.fixed_seed:
		rng.seed = config.seed_value
	else:
		rng.randomize()

func grade_for_score(score: float) -> int:
	if score >= config.perfect_score:
		return Judge.Grade.PERFECT
	if score >= config.good_score:
		return Judge.Grade.GOOD
	if score >= config.bad_score:
		return Judge.Grade.BAD
	return Judge.Grade.MISS

func defend(attack_power: int) -> int:
	var score: float = config.defense_ability + rng.randf_range(config.random_min, config.random_max) - attack_power * config.attack_weight
	return grade_for_score(score)

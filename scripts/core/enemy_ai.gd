extends RefCounted

const Judge = preload("res://scripts/core/timing_judge.gd")
const Config = preload("res://scripts/core/battle_config.gd")
var difficulty: Resource
var config: Resource
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(settings: Resource = null, profile: Resource = null) -> void:
	difficulty = profile
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

func defend(attack_power: int, pressure: int = 0, pattern_difficulty: float = 0.0) -> int:
	var ability: float = config.defense_ability if difficulty == null else difficulty.defense_ability
	var score: float = ability + rng.randf_range(config.random_min, config.random_max) - attack_power * config.attack_weight - pressure * config.pressure_weight - pattern_difficulty * config.pattern_weight
	return grade_for_score(score)

func select_pattern(patterns: Array[Resource], profile: Resource) -> Resource:
	assert(not patterns.is_empty())
	assert(profile.is_valid(patterns.size()))
	var total: float = 0.0
	for weight in profile.pattern_weights:
		total += weight
	var draw: float = rng.randf() * total
	var cumulative: float = 0.0
	var fallback: int = 0
	for i in range(patterns.size()):
		var weight: float = profile.pattern_weights[i]
		if weight > 0:
			fallback = i
		cumulative += weight
		if weight > 0 and draw < cumulative:
			return patterns[i]
	return patterns[fallback]

extends RefCounted

const Catalog = preload("res://scripts/core/pattern_catalog.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Balance = preload("res://scripts/core/battle_config.gd")
const Pressure = preload("res://scripts/core/pressure_system.gd")
const Enemy = preload("res://scripts/core/enemy_ai.gd")
const Judge = preload("res://scripts/core/timing_judge.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const Fixture = preload("res://tests/fixtures/defense_ai.gd")
var verify: Callable

func check(condition: bool, message: String) -> void:
	verify.call(condition, message)

func run(checker: Callable) -> void:
	verify = checker
	_test_pressure()
	_test_integration()
	_test_patterns()
	_test_ai()
	_test_campaigns()

func _test_pressure() -> void:
	var pressure: RefCounted = Pressure.new(Balance.new())
	pressure.player_judgement(Judge.Grade.PERFECT)
	check(pressure.value == 35, "Perfect pressure +35")
	pressure.player_judgement(Judge.Grade.GOOD)
	check(pressure.value == 50, "Good pressure +15")
	pressure.player_judgement(Judge.Grade.BAD)
	check(pressure.value == 35, "Bad pressure -15")
	pressure.enemy_defense(Judge.Grade.PERFECT)
	check(pressure.value == 10, "AI Perfect reduces 25")
	pressure.enemy_defense(Judge.Grade.GOOD)
	check(pressure.value == 0, "AI Good reduces 10")
	pressure.player_judgement(Judge.Grade.BAD)
	check(pressure.value == 0, "pressure lower clamp")
	for i in range(4):
		pressure.player_judgement(Judge.Grade.PERFECT)
	check(pressure.value == 100, "pressure upper clamp")
	pressure.enemy_defense(Judge.Grade.BAD)
	pressure.enemy_defense(Judge.Grade.MISS)
	check(pressure.value == 100, "AI Bad/Miss do not change pressure")
	pressure.player_judgement(Judge.Grade.MISS)
	check(pressure.value == 0, "player Miss resets pressure")

func _test_integration() -> void:
	var fixture: RefCounted = Fixture.new()
	var battle: RefCounted = Combat.new(null, null, null, fixture, Catalog.difficulties()[1], Catalog.all())
	battle.start(0)
	battle.advance(800000)
	var target: int = battle.rally.target_us
	battle.swing(target)
	check(battle.pressure.value == 35, "pressure increases once at accepted player hit")
	battle.swing(target + 1)
	check(battle.pressure.value == 35, "duplicate input cannot add pressure")
	battle.advance(target)
	battle.advance(target + 850000)
	check(battle.pressure.value == 25, "Good defense reduces pressure after calculation")
	fixture.grade = Judge.Grade.PERFECT
	target = battle.rally.target_us
	battle.swing(target)
	battle.advance(target)
	battle.advance(target + 850000)
	check(battle.pressure.value == 35 and battle.rally.incoming_strong, "Perfect defense reduces pressure and sends strong counter")
	battle.advance(battle.rally.target_us + 180001)
	check(battle.pressure.value == 0 and battle.player_hp == 82, "player strong Miss resets pressure and damages once")
	fixture.grade = Judge.Grade.MISS
	battle.advance(battle.rally.phase_start_us + 800000)
	target = battle.rally.target_us
	battle.swing(target)
	battle.advance(target)
	battle.advance(target + 850000)
	check(battle.pressure.value == 35 and battle.enemy_hp == 82, "enemy Miss damages but keeps pressure")
	battle.advance(battle.rally.phase_start_us + 800000)
	check(battle.pressure.value == 35, "new rally preserves pressure")
	battle.start(90000000)
	check(battle.pressure.value == 0, "new battle resets pressure")

func _test_patterns() -> void:
	var patterns: Array[Resource] = Catalog.all()
	var ids: Dictionary = {}
	var durations: Dictionary = {}
	for pattern in patterns:
		ids[pattern.pattern_id] = true
		durations[pattern.incoming_seconds] = true
		check(pattern.is_valid(), "valid pattern " + pattern.pattern_id)
		check(pattern.sample(0).is_equal_approx(pattern.start_point), "pattern start " + pattern.pattern_id)
		check(pattern.sample(1).is_equal_approx(Vector3(0.15, 1, 16)), "every pattern reaches fixed racket")
		check(absf(pattern.sample(pattern.bounce_fraction).z) < 0.0001, "time-based bounce " + pattern.pattern_id)
		for progress in [0.1, 0.35, 0.5, 0.75, 0.9, 1.1, 1.2]:
			check(pattern.sample(progress).z >= 0 and absf(pattern.sample(progress).x) < 1, "trajectory remains reachable/readable")
		for difficulty in Catalog.difficulties():
			for fps in [30, 60, 120]:
				for error in [-180000, -120000, -50000, 50000, 120000, 180000]:
					var model: RefCounted = Rally.new(null, pattern)
					model.difficulty = difficulty
					model.start(0)
					model.advance(800000)
					var target: int = model.target_us
					check(target == 800000 + roundi(pattern.incoming_seconds * difficulty.flight_multiplier * 1000000), "profile scales true target time")
					var step: int = roundi(1000000.0 / fps)
					var now: int = 800000
					var input_time: int = target + error
					while now < input_time:
						model.advance(now)
						now += step
					var expected: int = Judge.Grade.PERFECT if absi(error) <= 50000 else (Judge.Grade.GOOD if absi(error) <= 120000 else Judge.Grade.BAD)
					check(model.swing(input_time) == expected, "pattern/profile/fps boundary judgement")
					model.advance(maxi(target, input_time))
					check(model.state == Rally.State.PLAYER_RETURN, "all pattern boundary hits can return")
				var timeout: RefCounted = Rally.new(null, pattern)
				timeout.difficulty = difficulty
				timeout.start(0)
				timeout.advance(800000)
				timeout.advance(timeout.target_us + 180001)
				check(timeout.state == Rally.State.RALLY_RESULT, "all patterns expire without input")
	check(ids.size() == 5 and durations.size() == 5, "five unique IDs and distinct tempos")
	check(patterns[1].strong_attack and not patterns[0].strong_attack, "smash attack strength is explicit data")
	check(patterns[2].arc_height > patterns[0].arc_height and patterns[3].arc_height < patterns[0].arc_height, "lob and drive height differences")
	check(patterns[4].sample(0.5).y > 0.5 and is_equal_approx(patterns[0].sample(0.5).y, 0.5), "tempo-change progress has a distinct rhythm")

func _test_ai() -> void:
	var config: Resource = Balance.new()
	config.fixed_seed = true
	config.seed_value = 333
	var patterns: Array[Resource] = Catalog.all()
	var profiles: Array[Resource] = Catalog.difficulties()
	for profile in profiles:
		check(profile.is_valid(), "valid difficulty " + profile.difficulty_id)
		var ai: RefCounted = Enemy.new(config, profile)
		var replay: RefCounted = Enemy.new(config, profile)
		var seen: Dictionary = {}
		for i in range(100):
			var pattern: Resource = ai.select_pattern(patterns, profile)
			seen[pattern.pattern_id] = true
			check(pattern == replay.select_pattern(patterns, profile), "seeded weighted selection")
			check(ai.defend(100, 40, pattern.pattern_difficulty) == replay.defend(100, 40, pattern.pattern_difficulty), "seeded selection/defense sequence")
		check(seen.size() == 5, "each profile can use all five patterns")
	var single: Resource = profiles[1].duplicate(true)
	single.pattern_weights = PackedFloat32Array([0, 0, 1, 0, 0])
	var chosen: RefCounted = Enemy.new(config, single)
	for i in range(20):
		check(chosen.select_pattern(patterns, single) == patterns[2], "zero-weight patterns are never selected")
	single.pattern_weights = PackedFloat32Array([0, 0, 0, 0, 0])
	check(not single.is_valid(), "reject all-zero weights")
	single.pattern_weights = PackedFloat32Array([-1, 1, 1, 1, 1])
	check(not single.is_valid(), "reject negative weights")
	var easy: RefCounted = Enemy.new(config, profiles[0])
	var hard: RefCounted = Enemy.new(config, profiles[2])
	var low_pressure: RefCounted = Enemy.new(config, profiles[1])
	var high_pressure: RefCounted = Enemy.new(config, profiles[1])
	var low_pattern: RefCounted = Enemy.new(config, profiles[1])
	var high_pattern: RefCounted = Enemy.new(config, profiles[1])
	var at_max_pressure: Dictionary = {}
	for i in range(100):
		check(hard.defend(100, 20, 30) <= easy.defend(100, 20, 30), "harder AI defends at least as well at same draw")
		check(high_pressure.defend(100, 100, 30) >= low_pressure.defend(100, 0, 30), "pressure cannot improve defense")
		check(high_pattern.defend(100, 0, 85) >= low_pattern.defend(100, 0, 10), "pattern difficulty raises defense burden")
		at_max_pressure[high_pressure.defend(100, 100, 30)] = true
		# Keep the two comparison RNGs aligned after the extra sample.
		low_pressure.defend(100, 0, 30)
	check(at_max_pressure.size() > 1, "max pressure alone does not force one outcome")
	check(profiles[0].flight_multiplier > profiles[1].flight_multiplier and profiles[1].flight_multiplier > profiles[2].flight_multiplier, "difficulty changes reaction time")
	check(profiles[0].pattern_weights != profiles[2].pattern_weights, "difficulty changes pattern mix")

func _test_campaigns() -> void:
	for profile in Catalog.difficulties():
		var expected: Array[String] = []
		for fps in [30, 60, 120]:
			var config: Resource = Balance.new()
			config.fixed_seed = true
			config.seed_value = 20261013
			var battle: RefCounted = Combat.new(config, null, null, null, profile, Catalog.all())
			battle.start(0)
			var sequence: Array[String] = []
			for i in range(100):
				if battle.state == Combat.State.BATTLE_END:
					break
				if battle.rally.state in [Rally.State.RALLY_START, Rally.State.RALLY_RESULT]:
					battle.advance(battle.rally.phase_start_us + 800000)
				var target: int = battle.rally.target_us
				var now: int = battle.rally.phase_start_us
				var step: int = roundi(1000000.0 / fps)
				while now < target:
					battle.advance(now)
					now += step
				check(battle.swing(target) == Judge.Grade.PERFECT, "full multi-pattern campaign input")
				sequence.append(battle.rally.pattern.pattern_id)
				battle.advance(target)
				var end: int = target + roundi(battle.rally.pattern.return_seconds * 1000000)
				now = target
				while now < end:
					battle.advance(now)
					now += step
				battle.advance(end)
				sequence.append("%d:%d" % [battle.enemy_hp, battle.pressure.value])
			check(battle.state == Combat.State.BATTLE_END and battle.winner == Combat.Side.PLAYER, "complete campaign " + profile.difficulty_id)
			if expected.is_empty():
				expected.assign(sequence)
			else:
				check(expected == sequence, "profile seeded combat is fps-independent")
			var pressure_at_end: int = battle.pressure.value
			battle.advance(999999999)
			battle.swing(999999999)
			check(battle.pressure.value == pressure_at_end, "terminal events cannot alter pressure")
			battle.start(999999999)
			check(battle.pressure.value == 0, "campaign restart clears pressure")

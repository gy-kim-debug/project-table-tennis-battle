extends RefCounted

const Combat = preload("res://scripts/core/battle_manager.gd")
const Balance = preload("res://scripts/core/battle_config.gd")
const Enemy = preload("res://scripts/core/enemy_ai.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const Judge = preload("res://scripts/core/timing_judge.gd")
const Fixture = preload("res://tests/fixtures/defense_ai.gd")
var verify: Callable

func run(check: Callable) -> void:
	verify = check
	_test_ai()
	_test_damage()
	_test_strong_counter()
	_test_terminal_states()
	_test_stale_events()
	_test_seeded_campaigns()

func battle_with_grade(grade: int) -> RefCounted:
	var ai: RefCounted = Fixture.new()
	ai.grade = grade
	var battle: RefCounted = Combat.new(null, null, null, ai)
	battle.start(0)
	battle.advance(800000)
	return battle

func check(condition: bool, message: String) -> void:
	verify.call(condition, message)

func hit_and_defend(battle: RefCounted, error_us: int = 0) -> void:
	var input_time: int = battle.rally.target_us + error_us
	battle.swing(input_time)
	battle.advance(maxi(input_time, battle.rally.target_us))
	battle.advance(battle.rally.phase_start_us + 850000)

func _test_ai() -> void:
	var config: Resource = Balance.new()
	config.fixed_seed = true
	config.seed_value = 12345
	var first: RefCounted = Enemy.new(config)
	var second: RefCounted = Enemy.new(config)
	for value in [[65.0, 0], [64.999, 1], [40.0, 1], [39.999, 2], [15.0, 2], [14.999, 3]]:
		check(first.grade_for_score(value[0]) == value[1], "AI defense threshold %s" % value[0])
	var grades: Dictionary = {}
	for i in range(80):
		var grade: int = first.defend(100)
		grades[grade] = true
		check(grade == second.defend(100), "seed replay %d" % i)
	check(grades.size() == 4, "baseline can produce all four defense grades")
	first.reset()
	second.reset()
	for i in range(40):
		check(first.defend(100) >= second.defend(30), "stronger attack cannot improve defense at same random draw")
	var custom: Resource = Balance.new()
	custom.max_hp = 0
	check(not custom.is_valid(), "reject invalid HP")

func _test_damage() -> void:
	for entry in [[0, 18, 100], [70000, 12, 65], [150000, 12, 30]]:
		var battle: RefCounted = battle_with_grade(Judge.Grade.MISS)
		check(battle.player_hp == 100 and battle.enemy_hp == 100, "start HP")
		var target: int = battle.rally.target_us
		battle.swing(target + entry[0])
		battle.advance(target + entry[0])
		check(battle.enemy_hp == 100 and battle.player_hp == 100, "successful player hit does not deal damage")
		battle.advance(battle.rally.phase_start_us + 850000)
		check(battle.enemy_hp == 100 - entry[1] and battle.player_hp == 100, "damage only on enemy miss")
		check(battle.enemy.last_power == entry[2], "attack power is defense burden")
		check(battle.rally.state == Rally.State.RALLY_RESULT, "enemy miss ends rally")
		check(not battle.resolve_miss(battle.battle_id, battle.rally.rally_id, Combat.Side.ENEMY, true), "duplicate miss rejected")
		battle.advance(battle.rally.phase_start_us + 800000)
		check(battle.rally.state == Rally.State.PLAYER_TIMING and not battle.rally.incoming_strong, "new rally begins with normal serve")
	for defense in [Judge.Grade.PERFECT, Judge.Grade.GOOD, Judge.Grade.BAD]:
		var battle: RefCounted = battle_with_grade(defense)
		hit_and_defend(battle)
		check(battle.enemy_hp == 100 and battle.player_hp == 100, "all successful defense grades avoid damage")
		check(battle.rally.state == Rally.State.PLAYER_TIMING, "successful AI defense continues rally")
		var count: int = battle.enemy.calls
		battle.advance(battle.rally.phase_start_us)
		check(battle.enemy.calls == count, "defense evaluated once")
	var normal: RefCounted = battle_with_grade(Judge.Grade.GOOD)
	normal.advance(normal.rally.target_us + 180001)
	check(normal.player_hp == 88 and normal.enemy_hp == 100, "no-input normal miss costs 12")
	check(normal.swing(normal.rally.target_us) == -1, "no retry after miss")
	var early: RefCounted = battle_with_grade(Judge.Grade.GOOD)
	early.swing(800001)
	check(early.player_hp == 88, "early miss immediately costs HP once")
	early.advance(early.rally.target_us + 180001)
	check(early.player_hp == 88, "early swing plus later timeout does not double damage")

func _test_strong_counter() -> void:
	var battle: RefCounted = battle_with_grade(Judge.Grade.PERFECT)
	hit_and_defend(battle, 70000)
	check(battle.rally.incoming_strong, "Perfect AI defense creates strong counter")
	battle.advance(battle.rally.target_us + 180001)
	check(battle.player_hp == 82, "missing strong counter costs 18")
	battle.advance(battle.rally.phase_start_us + 800000)
	check(not battle.rally.incoming_strong, "strength does not leak into next serve")

func _test_terminal_states() -> void:
	for loser in [Combat.Side.PLAYER, Combat.Side.ENEMY]:
		var battle: RefCounted = battle_with_grade(Judge.Grade.MISS)
		var events: Dictionary = {"end": 0, "final_damage": 0, "locked": false}
		battle.battle_ended.connect(func(_winner: int): events["end"] += 1)
		battle.damaged.connect(func(_side: int, damage: int, remaining: int):
			if remaining == 0:
				events["final_damage"] = damage
				events["locked"] = battle.state == Combat.State.BATTLE_END and battle.swing(999999999) == -1)
		var now: int = 800000
		for i in range(30):
			if battle.state == Combat.State.BATTLE_END:
				break
			if battle.rally.state == Rally.State.RALLY_RESULT:
				now = battle.rally.phase_start_us + 800000
				battle.advance(now)
			if loser == Combat.Side.PLAYER:
				now = battle.rally.target_us + 180001
				battle.advance(now)
			else:
				hit_and_defend(battle)
				now = battle.rally.phase_start_us
		check(battle.state == Combat.State.BATTLE_END, "whole battle reaches terminal state")
		check(battle.winner == (Combat.Side.ENEMY if loser == Combat.Side.PLAYER else Combat.Side.PLAYER), "winner matches HP loser")
		check((battle.player_hp if loser == Combat.Side.PLAYER else battle.enemy_hp) == 0, "HP clamps at zero")
		check((battle.enemy_hp if loser == Combat.Side.PLAYER else battle.player_hp) == 100, "successful side retains HP")
		check(events["end"] == 1 and events["locked"], "one end event and already locked inside damage callback")
		check(events["final_damage"] == (4 if loser == Combat.Side.PLAYER else 10), "final displayed damage equals actual HP lost")
		check(battle.rally.state == Rally.State.BATTLE_END and not battle.rally.ball_visible(), "terminal rally hides ball")
		var last_ball: int = battle.rally.ball_id
		battle.advance(999999999)
		check(battle.rally.ball_id == last_ball and events["end"] == 1 and battle.swing(999999999) == -1, "no updates after battle end")
		var old_session: int = battle.battle_id
		var old_rally: int = battle.rally.rally_id
		battle.start(now + 1000)
		check(battle.player_hp == 100 and battle.enemy_hp == 100 and battle.winner == -1, "restart restores full battle")
		check(battle.battle_id == old_session + 1, "restart changes session ID")
		check(not battle.resolve_miss(old_session, old_rally, loser, true), "stale result cannot damage restarted battle")
		# Disconnect closures holding the battle to avoid RefCounted cycles in tests.
		for link in battle.damaged.get_connections():
			battle.damaged.disconnect(link["callable"])

func _test_stale_events() -> void:
	var battle: RefCounted = battle_with_grade(Judge.Grade.GOOD)
	check(not battle.resolve_miss(battle.battle_id, battle.rally.rally_id, Combat.Side.PLAYER, true), "cannot damage an unresolved rally")
	var old_session: int = battle.battle_id
	var old_rally: int = battle.rally.rally_id
	battle.start(900000)
	battle.advance(1700000)
	check(not battle.resolve_miss(old_session, old_rally, Combat.Side.PLAYER, false), "old battle identity rejected")
	battle.rally.rally_resolved.emit(old_rally, Combat.Side.PLAYER, false)
	check(battle.player_hp == 100, "old rally signal rejected")
	battle.advance(battle.rally.target_us + 180001)
	check(not battle.resolve_miss(battle.battle_id, battle.rally.rally_id, 100, false), "invalid side rejected")
	check(not battle.resolve_miss(battle.battle_id, battle.rally.rally_id - 1, Combat.Side.PLAYER, false), "wrong rally identity rejected")

func _test_seeded_campaigns() -> void:
	var expected: Array[int] = []
	for fps in [30, 60, 120]:
		var config: Resource = Balance.new()
		config.fixed_seed = true
		config.seed_value = 20261013
		var battle: RefCounted = Combat.new(config)
		battle.start(0)
		battle.advance(800000)
		var history: Array[int] = []
		battle.rally.enemy_defended.connect(func(grade: int): history.append(grade))
		for i in range(100):
			if battle.state == Combat.State.BATTLE_END:
				break
			if battle.rally.state == Rally.State.RALLY_RESULT:
				battle.advance(battle.rally.phase_start_us + 800000)
			var target: int = battle.rally.target_us
			var step: int = roundi(1000000.0 / fps)
			var sample_time: int = battle.rally.phase_start_us
			while sample_time < target:
				battle.advance(sample_time)
				sample_time += step
			battle.swing(target)
			battle.advance(target)
			sample_time = target
			while sample_time < target + 850000:
				battle.advance(sample_time)
				sample_time += step
			battle.advance(target + 850000)
		check(battle.state == Combat.State.BATTLE_END and battle.winner == Combat.Side.PLAYER, "seeded full battle at %dfps" % fps)
		if expected.is_empty():
			expected.assign(history)
		else:
			check(history == expected, "frame rate cannot change seeded AI sequence")

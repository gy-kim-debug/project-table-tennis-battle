extends RefCounted

const Judge = preload("res://scripts/core/timing_judge.gd")
const Pattern = preload("res://scripts/core/pattern_data.gd")
const Config = preload("res://scripts/core/timing_config.gd")
enum State { RALLY_START, PLAYER_TIMING, HIT_PENDING, PLAYER_RETURN, RALLY_RESULT, STOPPED, ENEMY_ATTACK, ENEMY_DEFENSE, BATTLE_END }

signal judged(grade: int, error_ms: float)
signal returned(count: int)
signal bounced(returning: bool)
signal missed(previous_count: int)
signal enemy_defended(grade: int)
signal rally_resolved(rally_id: int, loser: int, strong: bool)

var pressure: RefCounted
var difficulty: Resource
var patterns: Array[Resource] = []
var incoming_duration: float = 1.25
var enemy: RefCounted
var combat_config: Resource
var incoming_strong: bool = false
var outgoing_grade: int = Judge.Grade.GOOD
var rally_id: int = 0
var config: Resource
var pattern: Resource
var judge: RefCounted
var state: int = State.STOPPED
var phase_start_us: int = 0
var target_us: int = 0
var contact_us: int = 0
var return_origin: Vector3
var rally_count: int = 0
var best_count: int = 0
var ball_id: int = 0
var bounce_sent: bool = false

func _init(settings: Resource = null, ball_pattern: Resource = null, enemy_ai: RefCounted = null, battle_settings: Resource = null) -> void:
	enemy = enemy_ai
	combat_config = battle_settings
	config = settings if settings != null else Config.new()
	pattern = ball_pattern if ball_pattern != null else Pattern.new()
	judge = Judge.new(config)

func start(now_us: int) -> void:
	rally_id += 1
	incoming_strong = false
	judge.consumed = true
	rally_count = 0
	state = State.RALLY_START
	phase_start_us = now_us
	bounce_sent = false

func stop() -> void:
	state = State.STOPPED
	judge.consumed = true

func finish_battle() -> void:
	state = State.BATTLE_END
	judge.consumed = true

func _launch(now_us: int, strong: bool = false) -> void:
	if state == State.RALLY_RESULT:
		rally_id += 1
	state = State.ENEMY_ATTACK
	if not patterns.is_empty() and enemy != null:
		pattern = enemy.select_pattern(patterns, difficulty)
	incoming_duration = pattern.incoming_seconds * (1.0 if difficulty == null else difficulty.flight_multiplier)
	incoming_strong = strong or pattern.strong_attack
	state = State.PLAYER_TIMING
	phase_start_us = now_us
	target_us = now_us + roundi(incoming_duration * 1000000.0)
	ball_id += 1
	bounce_sent = false
	judge.arm(target_us)

func swing(now_us: int) -> int:
	if state != State.PLAYER_TIMING:
		return -1
	var grade: int = judge.swing(now_us)
	if grade < 0:
		return -1
	if pressure != null:
		pressure.player_judgement(grade)
	var error_ms: float = float(now_us - config.input_offset_ms * 1000 - target_us) / 1000.0
	if grade == Judge.Grade.MISS:
		_miss(now_us)
	else:
		outgoing_grade = grade
		# Early successful input is latched until the ball reaches the racket.
		state = State.HIT_PENDING
		contact_us = maxi(now_us, target_us)
	judged.emit(grade, error_ms)
	return grade

func _miss(now_us: int) -> void:
	if pressure != null:
		pressure.reset()
	_end_rally(now_us, 0, incoming_strong)

func _end_rally(now_us: int, loser: int, strong: bool) -> void:
	var previous: int = rally_count
	state = State.RALLY_RESULT
	phase_start_us = now_us
	rally_count = 0
	rally_resolved.emit(rally_id, loser, strong)
	missed.emit(previous)

func advance(now_us: int) -> void:
	match state:
		State.RALLY_START, State.RALLY_RESULT:
			if now_us - phase_start_us >= roundi(config.serve_delay * 1000000.0):
				_launch(now_us)
		State.PLAYER_TIMING, State.HIT_PENDING:
			_check_bounce(now_us, incoming_duration, false)
			if state == State.HIT_PENDING and now_us >= contact_us:
				return_origin = pattern.sample(float(contact_us - phase_start_us) / (incoming_duration * 1000000.0))
				state = State.PLAYER_RETURN
				phase_start_us = contact_us
				bounce_sent = false
				rally_count += 1
				best_count = maxi(best_count, rally_count)
				returned.emit(rally_count)
			elif state == State.PLAYER_TIMING and judge.expire(now_us) == Judge.Grade.MISS:
				_miss(now_us)
				judged.emit(Judge.Grade.MISS, INF)
		State.PLAYER_RETURN:
			_check_bounce(now_us, pattern.return_seconds, true)
			if now_us - phase_start_us >= roundi(pattern.return_seconds * 1000000.0):
				state = State.ENEMY_DEFENSE
				var defense: int = Judge.Grade.GOOD
				# No AI is a test/practice loop preserving Phase 1 regression coverage.
				if enemy != null:
					defense = enemy.defend(combat_config.attack_power[outgoing_grade], 0 if pressure == null else pressure.value, pattern.pattern_difficulty)
				if pressure != null:
					pressure.enemy_defense(defense)
				if defense == Judge.Grade.MISS:
					_end_rally(now_us, 1, outgoing_grade == Judge.Grade.PERFECT)
				else:
					_launch(now_us, defense == Judge.Grade.PERFECT)
				enemy_defended.emit(defense)

func _check_bounce(now_us: int, seconds: float, returning: bool) -> void:
	if not bounce_sent and now_us - phase_start_us >= roundi(seconds * pattern.bounce_fraction * 1000000.0):
		bounce_sent = true
		bounced.emit(returning)

func ball_point(now_us: int) -> Vector3:
	if state == State.PLAYER_RETURN:
		return pattern.sample(float(now_us - phase_start_us) / (pattern.return_seconds * 1000000.0), true, return_origin)
	return pattern.sample(float(now_us - phase_start_us) / (incoming_duration * 1000000.0))

func ball_visible() -> bool:
	return state in [State.PLAYER_TIMING, State.HIT_PENDING, State.PLAYER_RETURN]

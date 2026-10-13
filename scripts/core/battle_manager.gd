extends RefCounted

const Pressure = preload("res://scripts/core/pressure_system.gd")
const Config = preload("res://scripts/core/battle_config.gd")
const Enemy = preload("res://scripts/core/enemy_ai.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
enum Side { PLAYER, ENEMY }
enum State { BATTLE_START, ACTIVE, BATTLE_END }

signal hp_changed(side: int, current: int, maximum: int)
signal damaged(side: int, amount: int, remaining: int)
signal battle_ended(winner: int)

var pressure: RefCounted
var difficulty: Resource
var config: Resource
var enemy: RefCounted
var rally: RefCounted
var player_hp: int = 0
var enemy_hp: int = 0
var state: int = State.BATTLE_START
var winner: int = -1
var battle_id: int = 0
var last_damaged_rally: int = -1

func _init(settings: Resource = null, timing: Resource = null, pattern: Resource = null, ai_override: RefCounted = null, profile: Resource = null, pattern_options: Array[Resource] = []) -> void:
	difficulty = profile
	config = settings if settings != null else Config.new()
	assert(config.is_valid())
	if not pattern_options.is_empty():
		assert(difficulty != null and difficulty.is_valid(pattern_options.size()))
		for entry in pattern_options:
			assert(entry.is_valid())
	enemy = ai_override if ai_override != null else Enemy.new(config, difficulty)
	rally = Rally.new(timing, pattern, enemy, config)
	pressure = Pressure.new(config)
	rally.pressure = pressure
	rally.difficulty = difficulty
	rally.patterns.assign(pattern_options)
	rally.rally_resolved.connect(_on_rally_resolved)

func start(now_us: int) -> void:
	rally.stop()
	battle_id += 1
	last_damaged_rally = -1
	winner = -1
	player_hp = config.max_hp
	enemy_hp = config.max_hp
	enemy.reset()
	pressure.reset()
	state = State.ACTIVE
	rally.start(now_us)
	hp_changed.emit(Side.PLAYER, player_hp, config.max_hp)
	hp_changed.emit(Side.ENEMY, enemy_hp, config.max_hp)

func advance(now_us: int) -> void:
	if state == State.ACTIVE:
		rally.advance(now_us)

func swing(now_us: int) -> int:
	if state != State.ACTIVE:
		return -1
	return rally.swing(now_us)

func _on_rally_resolved(rally_id: int, loser: int, strong: bool) -> void:
	resolve_miss(battle_id, rally_id, loser, strong)

# Ignore duplicate, stale and fabricated events outside a resolved active rally.
func resolve_miss(session_id: int, rally_id: int, loser: int, strong: bool) -> bool:
	if state != State.ACTIVE or session_id != battle_id or rally_id != rally.rally_id or rally_id == last_damaged_rally:
		return false
	if rally.state != Rally.State.RALLY_RESULT or loser not in [Side.PLAYER, Side.ENEMY]:
		return false
	last_damaged_rally = rally_id
	var requested: int = config.strong_damage if strong else config.normal_damage
	var previous: int = player_hp if loser == Side.PLAYER else enemy_hp
	var remaining: int = clampi(previous - requested, 0, config.max_hp)
	if loser == Side.PLAYER:
		player_hp = remaining
	else:
		enemy_hp = remaining
	# Enter the terminal state before emitting any final damage/UI callbacks.
	if remaining == 0:
		state = State.BATTLE_END
		winner = Side.ENEMY if loser == Side.PLAYER else Side.PLAYER
		rally.finish_battle()
	hp_changed.emit(loser, remaining, config.max_hp)
	damaged.emit(loser, previous - remaining, remaining)
	if state == State.BATTLE_END:
		battle_ended.emit(winner)
	return true

func set_difficulty(profile: Resource, now_us: int) -> bool:
	if profile == null or not profile.is_valid(rally.patterns.size()):
		return false
	difficulty = profile
	enemy.difficulty = profile
	rally.difficulty = profile
	start(now_us)
	return true

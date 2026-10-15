extends Node

const Catalog = preload("res://scripts/core/pattern_catalog.gd")
const Clock = preload("res://scripts/core/game_clock.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Balance = preload("res://resources/balance/battle.tres")
const Config = preload("res://resources/balance/timing.tres")

var clock: RefCounted = Clock.new()
var combat: RefCounted = Combat.new(Balance, Config, Catalog.all()[0], null, Catalog.difficulties()[1], Catalog.all())
var rally: RefCounted = combat.rally
var manually_paused: bool = false
var backgrounded: bool = false
var last_sounded_ball_id: int = -1
@onready var court: Node2D = $CourtView
@onready var ui: CanvasLayer = $BattleUI
@onready var sound: Node = $SoundController

func _ready() -> void:
	rally.judged.connect(_on_judged)
	rally.returned.connect(_on_returned)
	rally.bounced.connect(_on_bounced)
	rally.enemy_defended.connect(_on_enemy_defended)
	combat.damaged.connect(_on_damaged)
	combat.battle_ended.connect(_on_battle_ended)
	ui.pause_requested.connect(toggle_pause)
	ui.restart_requested.connect(restart)
	ui.difficulty_requested.connect(select_difficulty)
	ui.sound_requested.connect(_on_sound_requested)
	ui.set_sound_enabled(sound.enabled)
	combat.start(clock.now_us())
	_refresh()

func _process(_delta: float) -> void:
	if not clock.paused:
		combat.advance(clock.now_us())
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R:
			restart()
			get_viewport().set_input_as_handled()
			return
	# Godot maps touch to one mouse event so GUI buttons and gameplay share dispatch.
	# Do not also handle the raw touch event: that would swing through GUI controls.
	var swing: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
	swing = swing or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo)
	if swing:
		request_swing()
		get_viewport().set_input_as_handled()

func request_swing() -> int:
	if clock.paused:
		return -1
	return combat.swing(clock.now_us())

func toggle_pause() -> void:
	if combat.state == Combat.State.BATTLE_END:
		return
	manually_paused = not manually_paused
	_sync_pause()

func _sync_pause() -> void:
	clock.set_paused(manually_paused or backgrounded)
	if is_instance_valid(ui):
		ui.set_paused(clock.paused)

func restart() -> void:
	# No pending SceneTreeTimer callbacks: resetting the model replaces the rally.
	if combat.state == Combat.State.BATTLE_END:
		manually_paused = false
		_sync_pause()
	combat.start(clock.now_us())
	_reset_presentation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
		_sync_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
		_sync_pause()

func _on_judged(grade: int, error_ms: float) -> void:
	ui.show_judgement(grade, error_ms, float(clock.now_us()) / 1000000.0)
	if combat.state != Combat.State.BATTLE_END:
		court.swing_at = float(clock.now_us()) / 1000000.0
		court.animate_player(grade, court.swing_at, float(rally.contact_us) / 1000000.0, String(rally.pattern.player_swing_pose))
	sound.play_cue("miss" if grade == 3 else "swing")

func _on_returned(_count: int) -> void:
	court.show_return(rally.outgoing_grade, rally.phase_start_us)
	sound.play_cue("perfect" if rally.outgoing_grade == 0 else "good")

func _on_bounced(_returning: bool) -> void:
	court.bounce_at = float(clock.now_us()) / 1000000.0
	court.bounce_position = court.project_point(rally.ball_point(clock.now_us()), true)
	sound.play_cue("bounce")

func _refresh() -> void:
	var now: int = clock.now_us()
	court.update_state(rally, now)
	if rally.ball_visible() and rally.ball_id != last_sounded_ball_id:
		last_sounded_ball_id = rally.ball_id
		if rally.incoming_strong:
			sound.play_cue("smash")
	ui.update_state(rally, now, clock.paused, combat)

func _on_enemy_defended(grade: int) -> void:
	ui.show_enemy_defense(grade, float(clock.now_us()) / 1000000.0)
	court.enemy_swing_at = float(clock.now_us()) / 1000000.0
	court.animate_enemy(grade, court.enemy_swing_at, String(rally.pattern.enemy_swing_pose))
	sound.play_cue("good" if grade < 3 else "miss")

func _on_damaged(side: int, amount: int, _remaining: int) -> void:
	var now: float = float(clock.now_us()) / 1000000.0
	court.show_damage(side, amount, now)
	court.animate_damage(side, now)
	ui.show_damage(side, amount, now)
	sound.play_cue("damage")

func _on_battle_ended(winner: int) -> void:
	court.show_result(winner, float(clock.now_us()) / 1000000.0)
	ui.show_result(winner, rally.best_count)
	sound.play_cue("victory" if winner == Combat.Side.PLAYER else "defeat")

func _on_sound_requested(enabled: bool) -> void:
	sound.set_enabled(enabled)

func _exit_tree() -> void:
	rally.stop()

func _reset_presentation() -> void:
	ui.clear_feedback()
	court.clear_feedback()
	ui.reset_result()
	_refresh()

func select_difficulty(index: int) -> void:
	var profiles: Array[Resource] = Catalog.difficulties()
	if index < 0 or index >= profiles.size():
		return
	if combat.set_difficulty(profiles[index], clock.now_us()):
		_reset_presentation()

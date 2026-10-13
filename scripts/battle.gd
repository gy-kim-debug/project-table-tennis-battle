extends Node

const Clock = preload("res://scripts/core/game_clock.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Balance = preload("res://resources/balance/battle.tres")
const Config = preload("res://resources/balance/timing.tres")
const Pattern = preload("res://resources/patterns/basic_return.tres")

var clock: RefCounted = Clock.new()
var combat: RefCounted = Combat.new(Balance, Config, Pattern)
var rally: RefCounted = combat.rally
var manually_paused: bool = false
var backgrounded: bool = false
@onready var court: Node2D = $CourtView
@onready var ui: CanvasLayer = $BattleUI

func _ready() -> void:
	rally.judged.connect(_on_judged)
	rally.returned.connect(_on_returned)
	rally.bounced.connect(_on_bounced)
	rally.enemy_defended.connect(_on_enemy_defended)
	combat.damaged.connect(_on_damaged)
	combat.battle_ended.connect(_on_battle_ended)
	ui.pause_requested.connect(toggle_pause)
	ui.restart_requested.connect(restart)
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
	ui.clear_feedback()
	court.clear_feedback()
	ui.reset_result()
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		backgrounded = true
		_sync_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		backgrounded = false
		_sync_pause()

func _on_judged(grade: int, error_ms: float) -> void:
	ui.show_judgement(grade, error_ms, float(clock.now_us()) / 1000000.0)
	court.swing_at = float(clock.now_us()) / 1000000.0

func _on_returned(_count: int) -> void:
	court.contact_at = float(clock.now_us()) / 1000000.0

func _on_bounced(_returning: bool) -> void:
	court.bounce_at = float(clock.now_us()) / 1000000.0
	court.bounce_position = court.project_point(rally.ball_point(clock.now_us()), true)

func _refresh() -> void:
	var now: int = clock.now_us()
	court.update_state(rally, now)
	ui.update_state(rally, now, clock.paused, combat)

func _on_enemy_defended(grade: int) -> void:
	ui.show_enemy_defense(grade, float(clock.now_us()) / 1000000.0)
	court.enemy_swing_at = float(clock.now_us()) / 1000000.0

func _on_damaged(side: int, amount: int, _remaining: int) -> void:
	var now: float = float(clock.now_us()) / 1000000.0
	court.show_damage(side, amount, now)
	ui.show_damage(side, amount, now)

func _on_battle_ended(winner: int) -> void:
	ui.show_result(winner, rally.best_count)

func _exit_tree() -> void:
	rally.stop()

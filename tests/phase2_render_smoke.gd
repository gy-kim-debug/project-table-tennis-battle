extends SceneTree

const Scene = preload("res://scenes/battle/battle.tscn")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
var battle: Node
var capture_dir: String = "user://phase2-smoke"
var captured_enemy_damage: bool = false
var captured_strong: bool = false

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(capture_dir.path_join(name + ".png"))
	assert(result == OK)
	print("CAPTURE ", name)

# The test controls only the clock, not HP, damage, AI probabilities or outcomes.
func jump_to(game_us: int) -> void:
	battle.clock.origin_us = Time.get_ticks_usec() - game_us
	battle.clock.excluded_us = 0
	await process_frame
	await process_frame

func tap_ui(position: Vector2) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = root.get_screen_transform() * position
	Input.parse_input_event(touch)
	await process_frame
	var release: InputEventScreenTouch = touch.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

func swing() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	Input.parse_input_event(key)
	var release: InputEventKey = key.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This test requires a graphical display")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		capture_dir = args[0]
	DirAccess.make_dir_recursive_absolute(capture_dir)
	battle = Scene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.combat.enemy.rng.seed = 20261013
	await capture("phase2-ready")
	await tap_ui(Vector2(310, 40))
	assert(battle.clock.paused)
	await capture("phase2-paused")
	await tap_ui(Vector2(105, 335))
	assert(not battle.clock.paused)
	for i in range(100):
		if battle.combat.state == Combat.State.BATTLE_END:
			break
		if battle.rally.state in [Rally.State.RALLY_START, Rally.State.RALLY_RESULT]:
			await jump_to(battle.rally.phase_start_us + 800000)
		if battle.rally.incoming_strong and not captured_strong:
			await jump_to(battle.rally.phase_start_us + 500000)
			await capture("phase2-strong-counter")
			captured_strong = true
		await jump_to(battle.rally.target_us)
		await swing()
		assert(battle.rally.state == Rally.State.PLAYER_RETURN)
		await jump_to(battle.rally.phase_start_us + roundi(battle.rally.pattern.return_seconds * 1000000.0))
		if battle.combat.enemy_hp < 100 and not captured_enemy_damage:
			await capture("phase2-enemy-damage")
			captured_enemy_damage = true
	assert(battle.combat.winner == Combat.Side.PLAYER and battle.combat.enemy_hp == 0)
	assert(battle.ui.result_panel.visible)
	await capture("phase2-victory")
	var previous: int = battle.combat.battle_id
	await tap_ui(Vector2(180, 378))
	assert(battle.combat.battle_id == previous + 1 and battle.combat.player_hp == 100 and battle.combat.enemy_hp == 100)
	assert(not battle.ui.result_panel.visible)
	for i in range(9):
		await jump_to(battle.rally.phase_start_us + 800000)
		await jump_to(battle.rally.target_us + 180001)
		if i == 0:
			await capture("phase2-player-damage")
	assert(battle.combat.winner == Combat.Side.ENEMY and battle.combat.player_hp == 0)
	await capture("phase2-defeat")
	DisplayServer.window_set_size(Vector2i(540, 1170))
	await process_frame
	await process_frame
	await capture("phase2-tall-result")
	# Explicit fixture for the rare Perfect-defense counter's visual coverage.
	await tap_ui(Vector2(180, 378))
	var perfect_ai: RefCounted = preload("res://tests/fixtures/defense_ai.gd").new()
	perfect_ai.grade = 0
	battle.combat.enemy = perfect_ai
	battle.rally.enemy = perfect_ai
	await jump_to(battle.rally.phase_start_us + 800000)
	await jump_to(battle.rally.target_us)
	await swing()
	await jump_to(battle.rally.phase_start_us + roundi(battle.rally.pattern.return_seconds * 1000000.0))
	assert(battle.rally.incoming_strong)
	await jump_to(battle.rally.phase_start_us + 500000)
	await capture("phase2-strong-counter-fixture")
	await jump_to(battle.rally.target_us + 180001)
	assert(battle.combat.player_hp == 82)
	await capture("phase2-strong-damage-fixture")
	print("PHASE 2 RENDER PASS: seeded full victory, no-input defeat, touch retry, pause/resume, HP/damage UI")
	quit()

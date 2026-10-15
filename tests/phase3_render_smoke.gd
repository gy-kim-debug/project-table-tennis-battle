extends SceneTree

const Scene = preload("res://scenes/battle/battle.tscn")
const Catalog = preload("res://scripts/core/pattern_catalog.gd")
const Fixture = preload("res://tests/fixtures/defense_ai.gd")
const Enemy = preload("res://scripts/core/enemy_ai.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
var battle: Node
var capture_dir: String = "user://phase3-smoke"

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(capture_dir.path_join(name + ".png")) == OK)
	print("CAPTURE ", name)

func key_press(code: int) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = code
	key.pressed = true
	Input.parse_input_event(key)
	var release: InputEventKey = key.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func tap(position: Vector2) -> void:
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.position = root.get_screen_transform() * position
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventScreenTouch = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

func jump_to(game_us: int) -> void:
	battle.clock.origin_us = Time.get_ticks_usec() - game_us
	battle.clock.excluded_us = 0
	battle.combat.advance(game_us)
	battle._refresh()
	await process_frame
	await process_frame

func swing_at_target() -> void:
	battle.clock.origin_us = Time.get_ticks_usec() - battle.rally.target_us
	battle.clock.excluded_us = 0
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	battle._unhandled_input(key)
	battle.combat.advance(battle.rally.contact_us)
	battle._refresh()
	await process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render smoke requires a graphical display")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		capture_dir = args[0]
	DirAccess.make_dir_recursive_absolute(capture_dir)
	battle = Scene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	for profile_index in range(3):
		await tap(Vector2(310, 40))
		assert(battle.clock.paused)
		await tap(Vector2(180, 385))
		var popup: PopupMenu = battle.ui.difficulty_picker.get_popup()
		assert(popup.visible)
		popup.set_focused_item(profile_index)
		await key_press(KEY_ENTER)
		assert(battle.combat.difficulty == Catalog.difficulties()[profile_index])
		assert(battle.clock.paused and battle.combat.pressure.value == 0)
		await capture("phase3-menu-" + battle.combat.difficulty.difficulty_id)
		var fixture: RefCounted = Fixture.new()
		battle.combat.enemy = fixture
		battle.rally.enemy = fixture
		await tap(Vector2(105, 335))
		assert(not battle.clock.paused)
		for pattern_index in range(Catalog.all().size()):
			fixture.pattern_index = pattern_index
			battle.restart()
			await jump_to(battle.rally.phase_start_us + 800000)
			assert(battle.rally.pattern == Catalog.all()[pattern_index])
			assert(battle.rally.incoming_strong == (pattern_index == 1))
			await jump_to(battle.rally.phase_start_us + roundi(battle.rally.incoming_duration * 0.3 * 1000000))
			await capture("phase3-" + battle.combat.difficulty.difficulty_id + "-" + battle.rally.pattern.pattern_id)
			await swing_at_target()
			if battle.rally.state != Rally.State.PLAYER_RETURN or battle.combat.pressure.value != 35:
				push_error("pattern=%s profile=%s state=%s pressure=%d target=%d now=%d" % [battle.rally.pattern.pattern_id, battle.combat.difficulty.difficulty_id, battle.rally.state, battle.combat.pressure.value, battle.rally.target_us, battle.clock.now_us()])
			assert(battle.rally.state == Rally.State.PLAYER_RETURN and battle.combat.pressure.value == 35)
			await jump_to(battle.rally.phase_start_us + roundi(battle.rally.pattern.return_seconds * 1000000))
			assert(battle.combat.pressure.value == 25)
			assert(battle.combat.player_hp == 100 and battle.combat.enemy_hp == 100)
		await tap(Vector2(310, 40))
		await capture("phase3-pressure-" + battle.combat.difficulty.difficulty_id)
		assert(battle.ui.pressure_label.text == "ENEMY PRESSURE 25 / 100")
		await tap(Vector2(105, 335))
	# Full normal-difficulty match uses the real weighted EnemyAI, not the fixture.
	var native_ai: RefCounted = Enemy.new(battle.combat.config, Catalog.difficulties()[1])
	battle.combat.enemy = native_ai
	battle.rally.enemy = native_ai
	battle.select_difficulty(1)
	native_ai.rng.seed = 20261013
	for i in range(100):
		if battle.combat.state == Combat.State.BATTLE_END:
			break
		if battle.rally.state in [Rally.State.RALLY_START, Rally.State.RALLY_RESULT]:
			await jump_to(battle.rally.phase_start_us + 800000)
		await swing_at_target()
		assert(battle.rally.state == Rally.State.PLAYER_RETURN)
		await jump_to(battle.rally.phase_start_us + roundi(battle.rally.pattern.return_seconds * 1000000))
	assert(battle.combat.winner == Combat.Side.PLAYER and battle.ui.result_panel.visible)
	await capture("phase3-victory")
	await tap(Vector2(180, 378))
	assert(battle.combat.pressure.value == 0 and battle.combat.enemy_hp == 100)
	for i in range(9):
		if battle.combat.state == Combat.State.BATTLE_END:
			break
		await jump_to(battle.rally.phase_start_us + 800000)
		await jump_to(battle.rally.target_us + 180001)
	assert(battle.combat.winner == Combat.Side.ENEMY and battle.ui.result_panel.visible)
	DisplayServer.window_set_size(Vector2i(540, 1170))
	await process_frame
	await process_frame
	await capture("phase3-tall-defeat")
	battle.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	print("PHASE 3 RENDER PASS: %d patterns x %d profiles, actual dropdown routing, pressure, native-AI victory and defeat" % [Catalog.all().size(), Catalog.difficulties().size()])
	quit()

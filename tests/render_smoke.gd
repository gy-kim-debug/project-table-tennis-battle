extends SceneTree

const Battle = preload("res://scenes/battle/battle.tscn")
const Rally = preload("res://scripts/core/rally_manager.gd")
var battle: Node
var captured: bool = false
var launched_at: int
var capture_dir: String = "user://phase1-smoke"

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(capture_dir.path_join(name + ".png"))
	assert(result == OK)
	print("CAPTURE ", name)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render smoke requires a graphical display; use run_tests.gd for headless checks")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		capture_dir = args[0]
	DirAccess.make_dir_recursive_absolute(capture_dir)
	battle = Battle.instantiate()
	root.add_child(battle)
	await process_frame
	# Isolate the 12-return Phase 1 regression from Phase 2's stochastic defense.
	var fixture: RefCounted = preload("res://tests/fixtures/defense_ai.gd").new()
	battle.combat.enemy = fixture
	battle.rally.enemy = fixture
	launched_at = Time.get_ticks_usec()
	while battle.rally.rally_count < 12:
		await process_frame
		if Time.get_ticks_usec() - launched_at > 45000000:
			push_error("Timed out waiting for real-time continuous returns")
			quit(1)
			return
		var now: int = battle.clock.now_us()
		if battle.rally.state == Rally.State.PLAYER_TIMING:
			if not captured and now > battle.rally.phase_start_us + 550000:
				await capture("phase1-incoming")
				captured = true
			if now >= battle.rally.target_us:
				var event: InputEvent
				match battle.rally.rally_count % 3:
					0:
						var touch: InputEventScreenTouch = InputEventScreenTouch.new()
						touch.pressed = true
						touch.position = root.get_screen_transform() * Vector2(180, 480)
						event = touch
					1:
						var mouse: InputEventMouseButton = InputEventMouseButton.new()
						mouse.pressed = true
						mouse.button_index = MOUSE_BUTTON_LEFT
						mouse.position = root.get_screen_transform() * Vector2(180, 480)
						event = mouse
					2:
						var key: InputEventKey = InputEventKey.new()
						key.keycode = KEY_SPACE
						key.pressed = true
						event = key
				Input.parse_input_event(event)
				var release: InputEvent = event.duplicate()
				release.pressed = false
				Input.parse_input_event(release)
	assert(battle.rally.best_count == 12)
	await capture("phase1-12-returns")
	await tap_ui(Vector2(310, 40))
	assert(battle.clock.paused)
	await capture("phase1-paused")
	var frozen: int = battle.clock.now_us()
	await create_timer(0.1).timeout
	assert(battle.clock.now_us() == frozen)
	await tap_ui(Vector2(105, 335))
	assert(not battle.clock.paused)
	DisplayServer.window_set_size(Vector2i(540, 1170))
	await process_frame
	await process_frame
	await capture("phase1-tall-screen")
	print("RENDER SMOKE PASS: real-time 12 returns via touch/mouse/Space, touch pause/resume, 9:19.5 window, OpenGL")
	quit()

func tap_ui(logical_position: Vector2) -> void:
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.position = root.get_screen_transform() * logical_position
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventScreenTouch = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

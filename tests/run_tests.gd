extends SceneTree

const Judge = preload("res://scripts/core/timing_judge.gd")
const Config = preload("res://scripts/core/timing_config.gd")
const Clock = preload("res://scripts/core/game_clock.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const Pattern = preload("res://scripts/core/pattern_data.gd")
const CharacterTests = preload("res://tests/character_tests.gd")
const Phase3Tests = preload("res://tests/phase3_tests.gd")
const BattleTests = preload("res://tests/battle_tests.gd")
const BattleScene = preload("res://scenes/battle/battle.tscn")
var checks: int = 0
var failures: int = 0
var event_counts: Dictionary = {"miss": 0, "bounce": 0}

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func new_rally() -> RefCounted:
	var model: RefCounted = Rally.new()
	model.start(0)
	model.advance(800000)
	return model

func _run() -> void:
	_test_judge()
	_test_clock()
	_test_rally()
	_test_frame_rates()
	_test_pattern()
	BattleTests.new().run(check)
	Phase3Tests.new().run(check)
	CharacterTests.new().run(check)
	await _test_scene_inputs()
	await _test_scene_battle()
	await _test_scene_difficulty()
	print("CORE + BATTLE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_judge() -> void:
	var judge: RefCounted = Judge.new()
	judge.arm(1000000)
	for sign_value in [-1, 1]:
		for entry in [[0, Judge.Grade.PERFECT], [49999, Judge.Grade.PERFECT], [50000, Judge.Grade.PERFECT], [50001, Judge.Grade.GOOD], [119999, Judge.Grade.GOOD], [120000, Judge.Grade.GOOD], [120001, Judge.Grade.BAD], [179999, Judge.Grade.BAD], [180000, Judge.Grade.BAD], [180001, Judge.Grade.MISS], [500000, Judge.Grade.MISS]]:
			check(judge.classify(1000000 + sign_value * entry[0]) == entry[1], "signed microsecond boundary %s/%s" % [sign_value, entry[0]])
	check(judge.swing(500000) == Judge.Grade.MISS, "early swing fails")
	check(judge.swing(1000000) == -1, "early swing consumes ball")
	judge.arm(1000000)
	check(judge.expire(1180000) == -1, "exact late boundary still open")
	check(judge.swing(1180000) == Judge.Grade.BAD, "input on late boundary wins")
	check(judge.expire(1180001) == -1, "no second result after input")
	judge.arm(1000000)
	check(judge.expire(1180001) == Judge.Grade.MISS, "no-input timeout")
	check(judge.expire(2000000) == -1, "timeout only once")
	for offset in [-35, 35]:
		var config: Resource = Config.new()
		config.input_offset_ms = offset
		var compensated: RefCounted = Judge.new(config)
		compensated.arm(1000000)
		check(compensated.swing(1000000 + offset * 1000) == Judge.Grade.PERFECT, "compensated input")
		compensated.arm(1000000)
		check(compensated.expire(1180000 + offset * 1000) == -1, "compensated timeout inclusive")
		check(compensated.expire(1180001 + offset * 1000) == Judge.Grade.MISS, "compensated timeout")

func _test_clock() -> void:
	var clock: RefCounted = Clock.new(100)
	check(clock.now_us(500) == 400, "monotonic elapsed time")
	clock.set_paused(true, 600)
	check(clock.now_us(9000) == 500, "pause freezes clock")
	clock.set_paused(true, 10000)
	check(clock.now_us(11000) == 500, "duplicate pause is harmless")
	clock.set_paused(false, 1600)
	check(clock.now_us(1700) == 600, "resume excludes background time")
	clock.set_paused(true, 1800)
	clock.set_paused(false, 2800)
	check(clock.now_us(2900) == 800, "multiple pauses accumulate")

func _test_rally() -> void:
	var model: RefCounted = new_rally()
	model.missed.connect(func(_n: int): event_counts["miss"] += 1)
	model.bounced.connect(func(_r: bool): event_counts["bounce"] += 1)
	var target: int = model.target_us
	check(model.state == Rally.State.PLAYER_TIMING, "serve opens input during flight")
	check(model.swing(target - 120000) == Judge.Grade.GOOD, "early good input")
	check(model.state == Rally.State.HIT_PENDING, "early hit waits for contact")
	check(model.swing(target) == -1, "rapid second input ignored")
	model.advance(target - 1)
	check(model.rally_count == 0, "return not counted before contact")
	model.advance(target)
	check(model.rally_count == 1 and model.state == Rally.State.PLAYER_RETURN, "contact begins return")
	check(model.swing(target + 1) == -1, "return phase cannot swing")
	model.advance(target + 850000)
	check(model.ball_id == 2 and model.state == Rally.State.PLAYER_TIMING, "opponent returns naturally")
	check(event_counts["bounce"] == 2, "one bounce per completed leg")
	var second_target: int = model.target_us
	model.advance(second_target + 180000)
	check(model.state == Rally.State.PLAYER_TIMING, "late boundary remains playable")
	model.advance(second_target + 180001)
	check(model.state == Rally.State.RALLY_RESULT and model.rally_count == 0, "no input ends rally")
	model.advance(second_target + 190000)
	check(event_counts["miss"] == 1, "miss emitted once")
	check(model.best_count == 1, "best survives a miss")
	check(model.swing(second_target + 200000) == -1, "result phase blocks input")
	model.advance(second_target + 980001)
	check(model.state == Rally.State.PLAYER_TIMING, "miss automatically restarts")
	model.stop()
	model.advance(90000000)
	check(model.state == Rally.State.STOPPED and model.swing(90000000) == -1, "stop blocks stale events and input")
	model.start(91000000)
	check(model.rally_count == 0 and model.state == Rally.State.RALLY_START, "restart resets pending rally")
	var late: RefCounted = new_rally()
	var hit_time: int = late.target_us + 180000
	check(late.swing(hit_time) == Judge.Grade.BAD, "late edge accepted")
	var before: Vector3 = late.ball_point(hit_time)
	late.advance(hit_time)
	check(late.ball_point(hit_time).is_equal_approx(before), "late hit does not teleport")
	var early: RefCounted = new_rally()
	check(early.swing(800001) == Judge.Grade.MISS, "flight-start spam fails")
	check(early.swing(early.target_us) == -1, "cannot retry early miss")

func _test_frame_rates() -> void:
	for fps in [30, 60, 120]:
		var model: RefCounted = new_rally()
		var last_time: int = 800000
		for index in range(12):
			var target: int = model.target_us
			var step: int = roundi(1000000.0 / fps)
			var sample_time: int = last_time
			while sample_time < target:
				model.advance(sample_time)
				sample_time += step
			# Timestamp comes from the input callback, not the renderer's sampled frame.
			check(model.swing(target) == Judge.Grade.PERFECT, "%dfps exact input #%d" % [fps, index + 1])
			model.advance(target + step)
			check(model.rally_count == index + 1, "%dfps sequential count" % fps)
			var end: int = target + 850000
			sample_time = target + step
			while sample_time < end:
				model.advance(sample_time)
				sample_time += step
			model.advance(end)
			last_time = end
		check(model.best_count == 12 and model.ball_id == 13, "%dfps 12 continuous returns" % fps)
		for error_us in [-180000, -120000, -50000, 50000, 120000, 180000]:
			var trial: RefCounted = new_rally()
			var expected: int = Judge.Grade.PERFECT if absi(error_us) <= 50000 else (Judge.Grade.GOOD if absi(error_us) <= 120000 else Judge.Grade.BAD)
			check(trial.swing(trial.target_us + error_us) == expected, "%dfps boundary input" % fps)

func _test_pattern() -> void:
	var pattern: Resource = Pattern.new()
	check(pattern.sample(0).is_equal_approx(pattern.start_point), "pattern begins at opponent")
	check(pattern.sample(1).is_equal_approx(pattern.hit_point), "all balls reach fixed player")
	check(absf(pattern.sample(pattern.bounce_fraction).z) < 0.0001, "bounce height reaches table")
	check(pattern.sample(0, true, pattern.hit_point).is_equal_approx(pattern.hit_point), "return starts at contact")
	check(pattern.sample(1, true, pattern.hit_point).is_equal_approx(pattern.start_point), "return reaches opponent")
	for i in range(121):
		check(pattern.sample(float(i) / 100.0).z >= 0, "trajectory never below table")

func _test_scene_inputs() -> void:
	var battle: Node = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.backgrounded = false
	battle.manually_paused = false
	battle._sync_pause()
	for kind in ["touch", "mouse", "space"]:
		battle.rally.start(0)
		battle.rally.advance(800000)
		battle.clock.origin_us = Time.get_ticks_usec() - battle.rally.target_us
		battle.clock.excluded_us = 0
		var event: InputEvent
		if kind == "touch":
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.pressed = true
			touch.index = 0
			touch.position = Vector2(180, 480)
			event = touch
		elif kind == "mouse":
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.pressed = true
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = Vector2(180, 480)
			event = mouse
		else:
			var key: InputEventKey = InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_SPACE
			event = key
		# Full viewport dispatch, including GUI and _unhandled_input.
		Input.parse_input_event(event)
		await process_frame
		check(battle.rally.judge.consumed, "scene dispatch accepts " + kind)
		check(battle.rally.state == Rally.State.HIT_PENDING, "scene input returns " + kind)
		check(battle.request_swing() == -1, "second source cannot swing same ball")
		battle.rally.advance(battle.clock.now_us())
		check(battle.rally.rally_count == 1, "scene input produces one return")
		var release: InputEvent = event.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		await process_frame
	battle.rally.start(0)
	battle.rally.advance(800000)
	battle.clock.origin_us = Time.get_ticks_usec() - battle.rally.target_us
	# GUI clicks must pause, not also consume a swing behind the button.
	var gui_press: InputEventMouseButton = InputEventMouseButton.new()
	gui_press.button_index = MOUSE_BUTTON_LEFT
	gui_press.pressed = true
	gui_press.position = Vector2(310, 40)
	root.push_input(gui_press, true)
	await process_frame
	var gui_release: InputEventMouseButton = InputEventMouseButton.new()
	gui_release.button_index = MOUSE_BUTTON_LEFT
	gui_release.pressed = false
	gui_release.position = Vector2(310, 40)
	root.push_input(gui_release, true)
	await process_frame
	check(battle.clock.paused, "GUI pause button dispatch")
	check(not battle.rally.judge.consumed, "GUI click does not swing through")
	check(battle.clock.paused and battle.request_swing() == -1, "pause blocks swings")
	var frozen: int = battle.clock.now_us()
	battle._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	battle._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(battle.clock.paused and battle.clock.now_us() == frozen, "focus return preserves manual pause")
	battle.toggle_pause()
	check(not battle.clock.paused, "resume restores clock")
	battle.restart()
	check(battle.rally.state == Rally.State.RALLY_START and battle.rally.rally_count == 0, "scene restart resets rally")
	check(not battle.ui.overlay.visible, "scene resume hides pause overlay")
	battle.rally.start(0)
	battle.rally.advance(800000)
	battle.clock.origin_us = Time.get_ticks_usec() - battle.rally.target_us
	var touch_press: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_press.index = 0
	touch_press.position = root.get_screen_transform() * Vector2(310, 40)
	touch_press.pressed = true
	Input.parse_input_event(touch_press)
	await process_frame
	var touch_release: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_release.index = 0
	touch_release.position = root.get_screen_transform() * Vector2(310, 40)
	touch_release.pressed = false
	Input.parse_input_event(touch_release)
	await process_frame
	check(battle.clock.paused, "touch GUI pause button dispatch")
	check(not battle.rally.judge.consumed, "touch GUI does not swing through")
	check(battle.request_swing() == -1, "touch pause blocks gameplay")
	battle.queue_free()
	await process_frame

func _test_scene_battle() -> void:
	var battle: Node = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.backgrounded = false
	battle.manually_paused = false
	battle._sync_pause()
	var fixture: RefCounted = preload("res://tests/fixtures/defense_ai.gd").new()
	check(battle.ui.enemy_hp_bar.size.y <= 8 and battle.ui.player_hp_bar.size.y <= 8, "HP bars fit reserved 8px rows")
	var far_left: Vector2 = battle.court.project_point(Vector3(-1, 0, 0))
	var far_right: Vector2 = battle.court.project_point(Vector3(1, 0, 0))
	var near_left: Vector2 = battle.court.project_point(Vector3(-1, 1, 0))
	var near_right: Vector2 = battle.court.project_point(Vector3(1, 1, 0))
	check(far_left.x > 0 and far_right.x < 360, "far table edge fits behind opponent")
	check(near_left.x < 0 and near_right.x > 360, "near table edge fills portrait width")
	check(near_left.y > far_left.y + 250, "rear view gives the table visible depth")
	check(battle.court.project_point(Vector3(0, 0.5, 0)).y > 240 and battle.court.project_point(Vector3(0, 0.5, 0)).y < 310, "net falls between players")
	check(battle.court.player_contact.x > 200 and battle.court.player_contact.y > 400, "racket contact stays in near foreground")
	fixture.grade = Judge.Grade.MISS
	battle.combat.enemy = fixture
	battle.rally.enemy = fixture
	battle.combat.start(0)
	battle.combat.advance(800000)
	for i in range(6):
		if battle.rally.state == Rally.State.RALLY_RESULT:
			battle.combat.advance(battle.rally.phase_start_us + 800000)
		battle.clock.origin_us = Time.get_ticks_usec() - battle.rally.target_us
		battle.clock.excluded_us = 0
		var press: InputEventKey = InputEventKey.new()
		press.keycode = KEY_SPACE
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release: InputEventKey = press.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		battle.combat.advance(battle.clock.now_us())
		check(battle.combat.enemy_hp == maxi(100 - i * 18, 0), "scene successful hit has no immediate damage")
		battle.combat.advance(battle.rally.phase_start_us + 850000)
		battle._refresh()
		check(int(battle.ui.enemy_hp_bar.value) == battle.combat.enemy_hp, "scene HP UI matches enemy damage")
	check(battle.ui.result_panel.visible and battle.ui.result_title.text == "VICTORY", "scene shows victory result")
	check(battle.ui.pause_button.disabled and battle.request_swing() == -1, "result disables battle controls")
	var previous_session: int = battle.combat.battle_id
	# Touch outside the result panel cannot attack a finished battle.
	await _touch_at(Vector2(180, 480))
	check(battle.combat.battle_id == previous_session and battle.combat.enemy_hp == 0, "outside-result touch is harmless")
	await _touch_at(Vector2(180, 378))
	check(battle.combat.battle_id == previous_session + 1, "touch PLAY AGAIN starts exactly one new battle")
	check(battle.combat.enemy_hp == 100 and battle.combat.player_hp == 100, "result retry restores both HP")
	check(not battle.ui.result_panel.visible and int(battle.ui.enemy_hp_bar.value) == 100, "retry clears result and refreshes HP UI")
	fixture.grade = Judge.Grade.GOOD
	battle.combat.start(0)
	for i in range(9):
		battle.combat.advance(battle.rally.phase_start_us + 800000)
		battle.combat.advance(battle.rally.target_us + 180001)
	battle._refresh()
	check(battle.ui.result_panel.visible and battle.ui.result_title.text == "DEFEAT", "scene shows defeat result")
	check(int(battle.ui.player_hp_bar.value) == 0 and battle.combat.enemy_hp == 100, "scene defeat HP UI matches logic")
	var old_target: int = battle.rally.target_us
	battle.combat.advance(old_target + 99999999)
	check(battle.combat.player_hp == 0 and battle.rally.state == Rally.State.BATTLE_END, "delayed frame cannot restart ended battle")
	battle.queue_free()
	await process_frame

func _touch_at(position: Vector2) -> void:
	var press: InputEventScreenTouch = InputEventScreenTouch.new()
	press.position = root.get_screen_transform() * position
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventScreenTouch = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame

func _test_scene_difficulty() -> void:
	var battle: Node = BattleScene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.backgrounded = false
	battle.manually_paused = false
	battle._sync_pause()
	battle.combat.pressure.player_judgement(Judge.Grade.PERFECT)
	battle.toggle_pause()
	battle._refresh()
	check(battle.ui.pressure_label.text == "ENEMY PRESSURE 35 / 100", "pause UI shows current pressure")
	var previous: int = battle.combat.battle_id
	var old_rally: int = battle.rally.rally_id
	battle.ui.difficulty_picker.item_selected.emit(2)
	check(battle.combat.difficulty.difficulty_id == "hard", "difficulty selection reaches combat")
	check(battle.combat.battle_id == previous + 1 and battle.combat.pressure.value == 0, "difficulty change resets battle and pressure once")
	check(battle.combat.player_hp == 100 and battle.combat.enemy_hp == 100, "difficulty change restores HP")
	check(battle.clock.paused and battle.ui.overlay.visible, "difficulty selection keeps pause menu open")
	check(battle.ui.difficulty_picker.selected == 2 and battle.ui.subtitle.text.begins_with("HARD"), "UI reflects chosen difficulty")
	check(not battle.combat.resolve_miss(previous, old_rally, 0, true), "difficulty change rejects old results")
	battle.ui.difficulty_picker.item_selected.emit(0)
	check(battle.combat.difficulty.difficulty_id == "easy" and battle.ui.difficulty_picker.selected == 0, "easy difficulty selectable")
	previous = battle.combat.battle_id
	battle.select_difficulty(-1)
	battle.select_difficulty(3)
	check(battle.combat.battle_id == previous, "invalid difficulty index cannot reset battle")
	check(preload("res://resources/difficulty/normal.tres").defense_ability == 65, "difficulty switching does not mutate shared normal data")
	battle.queue_free()
	await process_frame

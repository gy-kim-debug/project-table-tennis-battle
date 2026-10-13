extends SceneTree

const Scene = preload("res://scenes/battle/battle.tscn")
const Fixture = preload("res://tests/fixtures/defense_ai.gd")
const Combat = preload("res://scripts/core/battle_manager.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
var battle: Node
var output: String = "user://phase5-smoke"

func _initialize() -> void:
	_run.call_deferred()

func at_time(now_us: int, advance: bool = true) -> void:
	battle.clock.origin_us = Time.get_ticks_usec() - now_us
	battle.clock.excluded_us = 0
	if advance:
		battle.combat.advance(now_us)
	battle._refresh()
	await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK)
	print("CAPTURE ", name)

func swing_at(target_us: int) -> int:
	battle.clock.origin_us = Time.get_ticks_usec() - target_us
	battle.clock.excluded_us = 0
	return battle.combat.swing(target_us)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 5 render test needs a display")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	DirAccess.make_dir_recursive_absolute(output)
	battle = Scene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.sound.set_enabled(true, false)
	battle.ui.set_sound_enabled(true)
	battle.toggle_pause()
	battle.ui.sound_button.pressed.emit()
	assert(not battle.sound.enabled and not battle.ui.sound_enabled)
	battle.ui.sound_button.pressed.emit()
	assert(battle.sound.enabled and battle.ui.sound_enabled)
	battle.toggle_pause()
	var fixture: RefCounted = Fixture.new()
	battle.combat.enemy = fixture
	battle.rally.enemy = fixture
	battle.restart()
	var start: int = battle.rally.phase_start_us
	await at_time(start + 800000)
	var target: int = battle.rally.target_us
	assert(swing_at(target - 100000) == 1)
	await at_time(target)
	assert(battle.rally.state == Rally.State.PLAYER_RETURN and battle.court.perfect_at < 0)
	await capture("phase5-good")
	await at_time(battle.rally.phase_start_us + 850000)
	target = battle.rally.target_us
	assert(swing_at(target) == 0)
	await at_time(target)
	assert(battle.court.freeze_until_us - battle.court.freeze_from_us == 45000)
	assert(battle.sound.cue_counts.get("perfect", 0) >= 1)
	await capture("phase5-perfect-contact")
	await at_time(target + 30000, false)
	assert(battle.court.time_seconds == float(target) / 1000000.0)
	await capture("phase5-perfect-freeze")
	await at_time(target + 75000, false)
	assert(battle.court.time_seconds > float(target) / 1000000.0)
	await capture("phase5-perfect-trail")
	fixture.grade = 0
	await at_time(battle.rally.phase_start_us + 850000)
	assert(battle.rally.incoming_strong)
	await at_time(battle.rally.phase_start_us + 350000)
	assert(battle.sound.cue_counts.get("smash", 0) >= 1)
	await capture("phase5-smash-incoming")
	await at_time(battle.rally.target_us + 180001)
	assert(battle.combat.player_hp == 82)
	await at_time(battle.rally.phase_start_us + 120000, false)
	await capture("phase5-damage")
	fixture.grade = 3
	battle.restart()
	for i in range(9):
		if battle.combat.state == Combat.State.BATTLE_END:
			break
		if battle.rally.state == Rally.State.RALLY_RESULT or battle.rally.state == Rally.State.RALLY_START:
			await at_time(battle.rally.phase_start_us + 800000)
		assert(swing_at(battle.rally.target_us) == 0)
		await at_time(battle.rally.target_us)
		await at_time(battle.rally.phase_start_us + roundi(battle.rally.pattern.return_seconds * 1000000.0))
	assert(battle.combat.winner == Combat.Side.PLAYER and battle.court.winner_side == Combat.Side.PLAYER)
	await capture("phase5-victory")
	battle.restart()
	for i in range(9):
		if battle.combat.state == Combat.State.BATTLE_END:
			break
		await at_time(battle.rally.phase_start_us + 800000)
		await at_time(battle.rally.target_us + 180001)
	assert(battle.combat.winner == Combat.Side.ENEMY and battle.court.winner_side == Combat.Side.ENEMY)
	await capture("phase5-defeat")
	print("PHASE 5 RENDER PASS: good/perfect/freeze/trail/smash/damage, sound toggle, victory/defeat")
	battle.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	quit()

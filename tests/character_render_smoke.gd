extends SceneTree

const Scene = preload("res://scenes/battle/battle.tscn")
const Fixture = preload("res://tests/fixtures/defense_ai.gd")
var battle: Node
var output: String = "user://character-smoke"

func _initialize() -> void:
	_run.call_deferred()

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK)
	print("CAPTURE ", name)

func at_time(now_us: int, advance: bool = true) -> void:
	battle.clock.origin_us = Time.get_ticks_usec() - now_us
	battle.clock.excluded_us = 0
	if advance:
		battle.combat.advance(now_us)
	battle._refresh()
	await process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Character render test requires a display")
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
	battle.backgrounded = false
	battle.manually_paused = false
	battle._sync_pause()
	var fixture: RefCounted = Fixture.new()
	battle.combat.enemy = fixture
	battle.rally.enemy = fixture
	battle.restart()
	assert(battle.court.player_actor.available() and battle.court.enemy_actor.available())
	var start: int = battle.rally.phase_start_us
	await at_time(start + 500000)
	await capture("character-idle")
	# The opaque table surface must hide the opponent's lower body. Previously
	# a fixed y=208 crop left red sprite pixels on top of this surface.
	var cover_point: Vector2i = Vector2i(110, 235)
	var rendered: Color = root.get_texture().get_image().get_pixelv(cover_point)
	assert(rendered.is_equal_approx(Color("168397")))
	var front: SpriteFrames = SpriteFrames.new()
	front.remove_animation(&"default")
	for entry in [[&"idle", 4, 4.0], [&"swing", 6, 20.0], [&"miss", 4, 10.0]]:
		front.add_animation(entry[0])
		front.set_animation_speed(entry[0], entry[2])
		for frame in range(entry[1]):
			var layer_image: Image = Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
			layer_image.fill(Color.TRANSPARENT)
			layer_image.fill_rect(Rect2i(31, 80, 6, 6), Color("54c7e6"))
			front.add_frame(entry[0], ImageTexture.create_from_image(layer_image))
	battle.court.enemy_actor.front_frames = front
	battle.court.queue_redraw()
	await RenderingServer.frame_post_draw
	var arm_scale: float = float(battle.court.layout["enemy_scale"])
	var arm_top_left: Vector2 = (battle.court._anchor(false) - battle.court.enemy_actor.pivot * arm_scale).round()
	var arm_sample: Vector2i = Vector2i((arm_top_left + Vector2(34, 83) * arm_scale).round())
	assert(root.get_texture().get_image().get_pixelv(arm_sample).is_equal_approx(Color("54c7e6")))
	battle.court.enemy_actor.front_frames = null
	battle.court.queue_redraw()
	await at_time(start + 800000)
	var target: int = battle.rally.target_us
	await at_time(target - 120000)
	battle.request_swing()
	await at_time(target - 100000, false)
	await capture("character-backswing")
	await at_time(target)
	assert(battle.court.player_actor.index_at(float(target) / 1000000) == 3)
	var scale_factor: float = float(battle.court.layout["player_scale"])
	var contact: Vector2 = battle.court._anchor(true) + (battle.court.player_actor.racket_contact - battle.court.player_actor.pivot) * scale_factor
	assert(contact.distance_to(battle.court.player_contact) < 0.001)
	assert(contact.x > battle.court._anchor(true).x)
	assert(battle.court.project_point(Vector3(-1, 0, 0)).y < battle.court.project_point(Vector3(-1, 1, 0)).y)
	assert(battle.court.project_point(Vector3(-1, 1, 0)).x > 0.0)
	assert(battle.court.player_contact.x > battle.court.project_point(Vector3(0, 1, 0)).x)
	await capture("character-contact")
	await at_time(target + 100000)
	await capture("character-follow-through")
	await at_time(battle.rally.phase_start_us + 850000)
	var enemy_scale: float = float(battle.court.layout["enemy_scale"])
	var enemy_contact: Vector2 = battle.court._anchor(false) + (battle.court.enemy_actor.racket_contact - battle.court.enemy_actor.pivot) * enemy_scale
	assert(enemy_contact.distance_to(battle.court.enemy_contact) < 0.001)
	assert(enemy_contact.x < battle.court._anchor(false).x)
	await capture("character-enemy-contact")
	var miss_time: int = battle.rally.target_us + 180001
	await at_time(miss_time)
	await at_time(miss_time + 100000, false)
	await capture("character-player-miss")
	battle.toggle_pause()
	battle._refresh()
	var paused_index: int = battle.court.player_actor.index_at(float(battle.clock.now_us()) / 1000000)
	await create_timer(0.2).timeout
	battle._refresh()
	assert(battle.court.player_actor.index_at(float(battle.clock.now_us()) / 1000000) == paused_index)
	await capture("character-paused")
	battle.restart()
	assert(battle.court.player_actor.animation == &"idle" and battle.court.enemy_actor.animation == &"idle")
	battle.toggle_pause()
	fixture.grade = 3
	start = battle.rally.phase_start_us
	await at_time(start + 800000)
	target = battle.rally.target_us
	await at_time(target)
	battle.request_swing()
	await at_time(target)
	await at_time(battle.rally.phase_start_us + 850000)
	await at_time(battle.rally.phase_start_us + 100000, false)
	await capture("character-enemy-miss")
	battle.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	print("CHARACTER RENDER PASS: idle/swing/contact/miss, pause freezes frames, restart clears actions")
	quit()

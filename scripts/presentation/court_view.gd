extends Node2D

const Animator = preload("res://scripts/presentation/character_animator.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const BACKGROUND = preload("res://assets/backgrounds/background_main.png")
const BALL = preload("res://assets/ball/ball_main.png")
const SHADOW = preload("res://assets/ball/ball_shadow.png")
const INK = Color("0b1020")
const LINE = Color("b9dfcb")
var layout: Dictionary
var player_actor: RefCounted = Animator.new()
var enemy_actor: RefCounted = Animator.new()
var last_ball_id: int = -1
var player_contact: Vector2
var enemy_contact: Vector2
var time_seconds: float = 0.0
var ball: Vector3 = Vector3.ZERO
var show_ball: bool = false
var swing_at: float = -10.0
var contact_at: float = -10.0
var bounce_at: float = -10.0
var bounce_position: Vector2
var waiting: bool = true
var strong_ball: bool = false
var enemy_swing_at: float = -10.0
var player_hit_at: float = -10.0
var enemy_hit_at: float = -10.0
var player_damage: int = 0
var enemy_damage: int = 0
var perfect_at: float = -10.0
var freeze_from_us: int = -1
var freeze_until_us: int = -1
var trail_points: Array[Vector2] = []
var trail_gold: bool = false
var result_at: float = -10.0
var winner_side: int = -1

# The table artwork and moving ball share this fixed, slightly raised rear view.
func project_point(point: Vector3, ground: bool = false) -> Vector2:
	var far: Array = layout["far_center"]
	var near: Array = layout["near_center"]
	var depth: float = point.y
	var center_x: float = lerpf(float(far[0]), float(near[0]), depth)
	var center_y: float = lerpf(float(far[1]), float(near[1]), pow(depth, float(layout["depth_power"])))
	var half_width: float = lerpf(float(layout["far_half_width"]), float(layout["near_half_width"]), depth)
	var skew: float = lerpf(float(layout["far_skew"]), float(layout["near_skew"]), depth)
	var court_position: Vector2 = Vector2(center_x + point.x * half_width, center_y + point.x * skew - (0.0 if ground else point.z))
	return _court_offset() + court_position * _court_scale()

func _court_scale() -> Vector2:
	var value: Array = layout["court_scale"]
	return Vector2(float(value[0]), float(value[1]))

func _court_offset() -> Vector2:
	var value: Array = layout["court_offset"]
	return Vector2(float(value[0]), float(value[1]))

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/table/layout.json"))
	player_actor.configure(String(layout["player_character"]))
	enemy_actor.configure(String(layout["enemy_character"]))

func update_state(model: RefCounted, now_us: int) -> void:
	var visual_us: int = freeze_from_us if now_us >= freeze_from_us and now_us < freeze_until_us else now_us
	time_seconds = float(visual_us) / 1000000.0
	player_contact = project_point(model.pattern.hit_point)
	enemy_contact = project_point(model.pattern.start_point)
	if model.ball_visible() and model.ball_id != last_ball_id:
		last_ball_id = model.ball_id
		enemy_actor.swing_at(float(model.phase_start_us) / 1000000.0)
	show_ball = model.ball_visible()
	strong_ball = model.incoming_strong and model.state != Rally.State.PLAYER_RETURN
	trail_gold = strong_ball or (model.state == Rally.State.PLAYER_RETURN and model.outgoing_grade == 0)
	waiting = not show_ball
	trail_points.clear()
	if show_ball:
		ball = model.ball_point(visual_us)
		if trail_gold:
			for lag in [20000, 40000, 60000, 80000]:
				var sample_us: int = maxi(model.phase_start_us, visual_us - lag)
				trail_points.append(project_point(model.ball_point(sample_us)).round())
	queue_redraw()

func clear_feedback() -> void:
	swing_at = -10.0
	contact_at = -10.0
	bounce_at = -10.0
	enemy_swing_at = -10.0
	player_hit_at = -10.0
	enemy_hit_at = -10.0
	perfect_at = -10.0
	freeze_from_us = -1
	freeze_until_us = -1
	result_at = -10.0
	winner_side = -1
	trail_points.clear()
	player_actor.reset()
	enemy_actor.reset()
	last_ball_id = -1

func _draw() -> void:
	draw_texture(BACKGROUND, Vector2.ZERO)
	# The opponent stands behind the table. The table surface masks their lower
	# body at its actual projected far edge; sprite sheets need no screen-y crop.
	_character(_anchor(false), false, time_seconds - enemy_swing_at < 0.22)
	_draw_table()
	_character_front(_anchor(false), false)
	if show_ball and ball.y < float(layout["net_depth"]):
		_draw_trail()
		_draw_ball()
	_draw_net()
	var hit: Vector2 = project_point(Vector3(0.15, 1, 16))
	# A quiet fixed contact marker teaches timing without another control.
	draw_arc(hit, 12, 0, TAU, 16, Color("b9dfcb"), 1, false)
	draw_line(hit + Vector2(-17, 0), hit + Vector2(-12, 0), LINE, 1)
	draw_line(hit + Vector2(12, 0), hit + Vector2(17, 0), LINE, 1)
	if time_seconds - bounce_at < 0.16:
		var r: float = 3.0 + (time_seconds - bounce_at) * 45.0
		draw_arc(bounce_position, r, 0, TAU, 12, Color("fff4d2"), 1)
	_character(_anchor(true), true, time_seconds - swing_at < 0.22)
	_character_front(_anchor(true), true)
	if show_ball and ball.y >= float(layout["net_depth"]):
		_draw_trail()
		_draw_ball()
	_draw_impact(hit)
	_draw_damage(true)
	_draw_damage(false)
	_draw_result()
	# A quiet HUD strip lets the lower HP read over the foreground player.
	draw_rect(Rect2(0, 530, 360, 110), Color(0.043, 0.063, 0.125, 0.78))

func _court_point(x: float, depth: float) -> Vector2:
	return project_point(Vector3(x, depth, 0)).round()

func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c, d]), color)

func _draw_table() -> void:
	var far_left: Vector2 = _court_point(-1.0, 0.0)
	var far_right: Vector2 = _court_point(1.0, 0.0)
	var near_left: Vector2 = _court_point(-1.0, 1.0)
	var near_right: Vector2 = _court_point(1.0, 1.0)
	# Geometry and moving ball share the same projection. The opaque surface
	# occludes the opponent exactly at the far edge, at any court scale.
	_quad(far_left, far_right, near_right, near_left, Color("0b1322"))
	_quad(near_left, near_right, near_right + Vector2(0, 17), near_left + Vector2(0, 17), Color("10283b"))
	for x in [-0.93, 0.93]:
		var leg: Vector2 = _court_point(x, 0.94)
		draw_rect(Rect2(leg + Vector2(-3, 5), Vector2(6, 38)), Color("101a2c"))
	_quad(far_left, far_right, near_right, near_left, Color("146d7a"))
	_quad(far_left, far_right, _court_point(1.0, 0.5), _court_point(-1.0, 0.5), Color("168397"))
	_quad(_court_point(-1.0, 0.5), _court_point(1.0, 0.5), near_right, near_left, Color("176f7e"))
	_quad(_court_point(-0.72, 0.03), _court_point(-0.58, 0.03), _court_point(-0.66, 0.98), _court_point(-0.87, 0.98), Color("187d89"))
	for edge in [[far_left, far_right], [far_right, near_right], [near_right, near_left], [near_left, far_left]]:
		draw_line(edge[0], edge[1], Color("e4f3d7"), 2.0, false)
	draw_line(_court_point(0.0, 0.0), _court_point(0.0, 1.0), Color("b8e8dc"), 2.0, false)
	draw_line(near_left + Vector2(0, 3), near_right + Vector2(0, 3), Color("14364b"), 3.0, false)

func _draw_net() -> void:
	var depth: float = float(layout["net_depth"])
	var left: Vector2 = _court_point(-1.04, depth)
	var right: Vector2 = _court_point(1.04, depth)
	var top_left: Vector2 = left - Vector2(0, 24)
	var top_right: Vector2 = right - Vector2(0, 24)
	_quad(top_left, top_right, right, left, Color("09263c"))
	for index in range(25):
		var t: float = float(index) / 24.0
		var top: Vector2 = top_left.lerp(top_right, t).round()
		var bottom: Vector2 = left.lerp(right, t).round()
		draw_line(top + Vector2(0, 4), bottom - Vector2(0, 2), Color("388ba3"), 1.0, false)
	for fraction in [0.28, 0.52, 0.76]:
		draw_line(top_left.lerp(left, fraction).round(), top_right.lerp(right, fraction).round(), Color("388ba3"), 1.0, false)
	draw_line(top_left, top_right, Color("e4f3d7"), 2.0, false)
	draw_line(left, right, Color("081b2d"), 2.0, false)
	draw_line(top_left - Vector2(0, 5), left + Vector2(0, 6), INK, 4.0, false)
	draw_line(top_right - Vector2(0, 5), right + Vector2(0, 6), INK, 4.0, false)

func _draw_trail() -> void:
	for index in range(trail_points.size()):
		var size: float = float(4 - index)
		var color: Color = Color("ffd166") if trail_gold else Color("fff4d2")
		color.a = 0.75 - float(index) * 0.15
		draw_rect(Rect2(trail_points[index] - Vector2.ONE * size * 0.5, Vector2.ONE * size), color)

func _draw_impact(hit: Vector2) -> void:
	var age: float = time_seconds - contact_at
	if age < 0.0 or age >= 0.24:
		return
	var perfect: bool = perfect_at == contact_at
	var radius: float = 8.0 + age * (110.0 if perfect else 55.0)
	var color: Color = Color("ffd166") if perfect else Color("fff4d2")
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)]:
		var point: Vector2 = (hit + direction * radius).round()
		draw_rect(Rect2(point, Vector2.ONE * (4.0 if perfect else 2.0)), color)
	if perfect:
		draw_arc(hit, radius * 0.7, 0, TAU, 20, Color("fff4d2"), 2, false)

func _draw_damage(player: bool) -> void:
	var started: float = player_hit_at if player else enemy_hit_at
	var age: float = time_seconds - started
	if age < 0.0 or age >= 0.45:
		return
	var center: Vector2 = (player_contact + Vector2(-25, -90)) if player else (enemy_contact + Vector2(105, -30))
	var amount: int = player_damage if player else enemy_damage
	draw_string(ThemeDB.fallback_font, center + Vector2(0, -age * 38.0), "-%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ff8a73"))
	for direction in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		draw_rect(Rect2((center + direction * (8.0 + age * 25.0)).round(), Vector2(4, 4)), Color("ff8a73"))

func _draw_result() -> void:
	if winner_side < 0:
		return
	var elapsed: float = time_seconds - result_at
	if elapsed < 0.0:
		return
	for index in range(14):
		var x: float = float((index * 79 + 13) % 350)
		var y: float = 105.0 + fmod(float(index * 47) + elapsed * 48.0, 375.0)
		var color: Color = Color("ffd166") if index % 2 == 0 else Color("54c7e6")
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(3, 5)), color)

func _draw_ball() -> void:
	var pos: Vector2 = project_point(ball).round()
	var shadow: Vector2 = project_point(ball, true).round()
	draw_texture(SHADOW, shadow - Vector2(8, 3))
	draw_texture_rect(BALL, Rect2(pos - Vector2(6, 6), Vector2(12, 12)), false, Color("ffd166") if strong_ball else Color.WHITE)

func _character(feet: Vector2, player: bool, swinging: bool) -> void:
	var color: Color = Color("54c7e6") if player else Color("ef7869")
	var hit_at: float = player_hit_at if player else enemy_hit_at
	if time_seconds - hit_at < 0.3:
		color = Color("fff4d2")
	var actor: RefCounted = player_actor if player else enemy_actor
	if actor.available():
		_draw_character_texture(feet, player, actor.texture_at(time_seconds))
		return
	draw_rect(Rect2(feet + Vector2(-19, -2), Vector2(38, 6)), INK)
	draw_rect(Rect2(feet + Vector2(-14, -20), Vector2(11, 20)), Color("26344b"))
	draw_rect(Rect2(feet + Vector2(5, -20), Vector2(11, 20)), Color("26344b"))
	draw_rect(Rect2(feet + Vector2(-17, -46), Vector2(36, 30)), INK)
	draw_rect(Rect2(feet + Vector2(-15, -44), Vector2(32, 26)), color)
	draw_rect(Rect2(feet + Vector2(-11, -64), Vector2(24, 22)), INK)
	draw_rect(Rect2(feet + Vector2(-9, -62), Vector2(20, 18)), Color("e6b997"))
	draw_rect(Rect2(feet + Vector2(-10, -64), Vector2(22, 8 if player else 6)), Color("27324a"))
	if not player:
		draw_rect(Rect2(feet + Vector2(-5, -54), Vector2(3, 3)), INK)
		draw_rect(Rect2(feet + Vector2(4, -54), Vector2(3, 3)), INK)
	else:
		draw_rect(Rect2(feet + Vector2(-6, -36), Vector2(12, 3)), Color("b7ecf2"))
	var hand: Vector2 = feet + (Vector2(39, -55) if swinging else Vector2(28, -40))
	draw_line(feet + Vector2(15, -38), hand, Color("e6b997"), 8, false)
	draw_line(hand, hand + Vector2(9, -7), Color("ba9c74"), 3, false)
	draw_rect(Rect2(hand + Vector2(6, -22), Vector2(17, 17)), INK)
	draw_rect(Rect2(hand + Vector2(8, -20), Vector2(13, 13)), Color("ef7869") if player else Color("54c7e6"))

func _character_front(feet: Vector2, player: bool) -> void:
	var actor: RefCounted = player_actor if player else enemy_actor
	if actor.has_front_layer():
		_draw_character_texture(feet, player, actor.front_texture_at(time_seconds))

func _draw_character_texture(feet: Vector2, player: bool, texture: Texture2D) -> void:
	if texture == null:
		return
	var actor: RefCounted = player_actor if player else enemy_actor
	var hit_at: float = player_hit_at if player else enemy_hit_at
	var tint: Color = Color("ff9380") if time_seconds - hit_at < 0.25 and int((time_seconds - hit_at) * 30.0) % 2 == 0 else Color.WHITE
	if winner_side >= 0 and (0 if player else 1) != winner_side:
		tint = Color(0.55, 0.62, 0.72)
	if time_seconds - hit_at < 0.25:
		feet.x += 4.0 if int((time_seconds - hit_at) * 30.0) % 2 == 0 else -4.0
	var scale_factor: float = float(layout["player_scale"] if player else layout["enemy_scale"])
	var top_left: Vector2 = (feet - actor.pivot * scale_factor).round()
	draw_texture_rect(texture, Rect2(top_left, Vector2.ONE * 128.0 * scale_factor), false, tint)

func show_damage(side: int, amount: int, now: float) -> void:
	if side == 0:
		player_hit_at = now
		player_damage = amount
	else:
		enemy_hit_at = now
		enemy_damage = amount

func show_return(grade: int, now_us: int) -> void:
	contact_at = float(now_us) / 1000000.0
	if grade == 0:
		perfect_at = contact_at
		freeze_from_us = now_us
		freeze_until_us = now_us + 45000
	else:
		perfect_at = -10.0
		freeze_from_us = -1
		freeze_until_us = -1

func show_result(winner: int, now: float) -> void:
	winner_side = winner
	result_at = now
	player_actor.finish_at(winner == 0, now)
	enemy_actor.finish_at(winner == 1, now)

func animate_damage(side: int, now: float) -> void:
	if side == 0:
		player_actor.miss_at(now)
	else:
		enemy_actor.miss_at(now)

func _anchor(player: bool) -> Vector2:
	var actor: RefCounted = player_actor if player else enemy_actor
	if actor.available():
		var scale_factor: float = float(layout["player_scale"] if player else layout["enemy_scale"])
		return (player_contact if player else enemy_contact) - (actor.racket_contact - actor.pivot) * scale_factor
	return Vector2(100, 487) if player else Vector2(213, 200)

func animate_player(grade: int, now: float, contact_time: float) -> void:
	if grade == 3:
		player_actor.miss_at(now)
	else:
		player_actor.swing_at(contact_time)

func animate_enemy(grade: int, now: float) -> void:
	if grade == 3:
		enemy_actor.miss_at(now)
	else:
		enemy_actor.swing_at(now)

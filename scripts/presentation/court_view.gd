extends Node2D

const Animator = preload("res://scripts/presentation/character_animator.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const BACKGROUND = preload("res://assets/backgrounds/background_main.png")
const TABLE = preload("res://assets/table/table_main.png")
const NET = preload("res://assets/table/table_net.png")
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

# The table artwork and moving ball share this fixed, slightly raised rear view.
func project_point(point: Vector3, ground: bool = false) -> Vector2:
	var far: Array = layout["far_center"]
	var near: Array = layout["near_center"]
	var depth: float = point.y
	var center_x: float = lerpf(float(far[0]), float(near[0]), depth)
	var center_y: float = lerpf(float(far[1]), float(near[1]), pow(depth, float(layout["depth_power"])))
	var half_width: float = lerpf(float(layout["far_half_width"]), float(layout["near_half_width"]), depth)
	var skew: float = lerpf(float(layout["far_skew"]), float(layout["near_skew"]), depth)
	return Vector2(center_x + point.x * half_width, center_y + point.x * skew - (0.0 if ground else point.z))

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/table/layout.json"))
	player_actor.configure("player")
	enemy_actor.configure("enemy")

func update_state(model: RefCounted, now_us: int) -> void:
	time_seconds = float(now_us) / 1000000.0
	player_contact = project_point(model.pattern.hit_point)
	enemy_contact = project_point(model.pattern.start_point)
	if model.ball_visible() and model.ball_id != last_ball_id:
		last_ball_id = model.ball_id
		enemy_actor.swing_at(float(model.phase_start_us) / 1000000.0)
	show_ball = model.ball_visible()
	strong_ball = model.incoming_strong and model.state != Rally.State.PLAYER_RETURN
	waiting = not show_ball
	if show_ball:
		ball = model.ball_point(now_us)
	queue_redraw()

func clear_feedback() -> void:
	swing_at = -10.0
	contact_at = -10.0
	bounce_at = -10.0
	enemy_swing_at = -10.0
	player_hit_at = -10.0
	enemy_hit_at = -10.0
	player_actor.reset()
	enemy_actor.reset()
	last_ball_id = -1

func _draw() -> void:
	draw_texture(BACKGROUND, Vector2.ZERO)
	draw_texture(TABLE, Vector2.ZERO)
	# Only the opponent's upper body reaches in front of the far table edge.
	_character(_anchor(false), false, time_seconds - enemy_swing_at < 0.22)
	if show_ball and ball.y < float(layout["net_depth"]):
		_draw_ball()
	draw_texture(NET, Vector2.ZERO)
	var hit: Vector2 = project_point(Vector3(0.15, 1, 16))
	# A quiet fixed contact marker teaches timing without another control.
	draw_arc(hit, 12, 0, TAU, 16, Color("b9dfcb"), 1, false)
	draw_line(hit + Vector2(-17, 0), hit + Vector2(-12, 0), LINE, 1)
	draw_line(hit + Vector2(12, 0), hit + Vector2(17, 0), LINE, 1)
	if time_seconds - bounce_at < 0.16:
		var r: float = 3.0 + (time_seconds - bounce_at) * 45.0
		draw_arc(bounce_position, r, 0, TAU, 12, Color("fff4d2"), 1)
	_character(_anchor(true), true, time_seconds - swing_at < 0.22)
	if show_ball and ball.y >= float(layout["net_depth"]):
		_draw_ball()
	if time_seconds - contact_at < 0.12:
		for offset in [Vector2(-18, -4), Vector2(17, -9), Vector2(8, 15)]:
			draw_rect(Rect2(hit + offset, Vector2(3, 3)), Color("ffd166"))
	# A quiet HUD strip lets the lower HP read over the foreground player.
	draw_rect(Rect2(0, 530, 360, 110), Color(0.043, 0.063, 0.125, 0.78))

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
	if time_seconds - hit_at < 0.75:
		var amount: int = player_damage if player else enemy_damage
		draw_string(ThemeDB.fallback_font, feet + Vector2(32, -65 - (time_seconds - hit_at) * 18.0), "-%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ef7869"))
	var actor: RefCounted = player_actor if player else enemy_actor
	if actor.available():
		var tint: Color = Color("ffd166") if time_seconds - hit_at < 0.3 else Color.WHITE
		var scale_factor: float = float(layout["player_scale"] if player else layout["enemy_scale"])
		var top_left: Vector2 = (feet - actor.pivot * scale_factor).round()
		if player:
			draw_texture_rect(actor.texture_at(time_seconds), Rect2(top_left, Vector2.ONE * 128.0 * scale_factor), false, tint)
		else:
			var visible_height: float = clampf(208.0 - top_left.y, 0.0, 128.0 * scale_factor)
			draw_texture_rect_region(actor.texture_at(time_seconds), Rect2(top_left, Vector2(128.0 * scale_factor, visible_height)), Rect2(Vector2.ZERO, Vector2(128.0, visible_height / scale_factor)), tint)
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

func show_damage(side: int, amount: int, now: float) -> void:
	if side == 0:
		player_hit_at = now
		player_damage = amount
	else:
		enemy_hit_at = now
		enemy_damage = amount

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

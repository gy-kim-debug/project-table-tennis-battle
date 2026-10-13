extends Node2D

const Rally = preload("res://scripts/core/rally_manager.gd")
const INK = Color("0b1020")
const LINE = Color("b9dfcb")
var time_seconds: float = 0.0
var ball: Vector3 = Vector3.ZERO
var show_ball: bool = false
var swing_at: float = -10.0
var contact_at: float = -10.0
var bounce_at: float = -10.0
var bounce_position: Vector2
var waiting: bool = true

# Fixed 2D skew: depth axis shifts left toward the viewer (20 degrees).
# Artwork/20-degree composition remains subject to the user's visual review.
func project_point(point: Vector3, ground: bool = false) -> Vector2:
	var center: Vector2 = Vector2(210, 233).lerp(Vector2(210.0 - 205.0 * tan(deg_to_rad(20.0)), 438), point.y)
	var half_width: float = lerpf(67.0, 125.0, point.y)
	return Vector2(center.x + point.x * half_width, center.y + point.x * lerpf(10.0, 20.0, point.y) - (0.0 if ground else point.z))

func update_state(model: RefCounted, now_us: int) -> void:
	time_seconds = float(now_us) / 1000000.0
	show_ball = model.ball_visible()
	waiting = not show_ball
	if show_ball:
		ball = model.ball_point(now_us)
	queue_redraw()

func clear_feedback() -> void:
	swing_at = -10.0
	contact_at = -10.0
	bounce_at = -10.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, 360, 640), Color("111b30"))
	# Simple flat geometric placeholders; no final art assets.
	for y in range(142, 545, 28):
		draw_line(Vector2(0, y), Vector2(360, y), Color("17243a"), 1)
	draw_rect(Rect2(16, 153, 328, 365), Color("1b2b40"), false, 2)
	draw_colored_polygon(PackedVector2Array([Vector2(34, 436), Vector2(273, 478), Vector2(302, 494), Vector2(39, 457)]), Color("0b1424"))
	# Opponent faces the player, fixed in place.
	_character(Vector2(213, 200), false, false)
	var corners: PackedVector2Array = PackedVector2Array([
		project_point(Vector3(-1, 0, 0)), project_point(Vector3(1, 0, 0)),
		project_point(Vector3(1, 1, 0)), project_point(Vector3(-1, 1, 0))])
	var apron: PackedVector2Array = PackedVector2Array([corners[3], corners[2], corners[2] + Vector2(0, 12), corners[3] + Vector2(0, 12)])
	draw_colored_polygon(apron, Color("174756"))
	draw_rect(Rect2(55, 434, 10, 66), Color("182436"))
	draw_rect(Rect2(246, 467, 10, 38), Color("182436"))
	draw_colored_polygon(corners, Color("287e83"))
	var border: PackedVector2Array = corners.duplicate()
	border.append(corners[0])
	draw_polyline(border, LINE, 3, false)
	draw_line(project_point(Vector3(0, 0, 0)), project_point(Vector3(0, 1, 0)), Color("71b7ae"), 2, false)
	var left: Vector2 = project_point(Vector3(-1, 0.5, 0))
	var right: Vector2 = project_point(Vector3(1, 0.5, 0))
	draw_colored_polygon(PackedVector2Array([left, right, right - Vector2(0, 22), left - Vector2(0, 22)]), Color("183e4b"))
	for i in range(13):
		var foot: Vector2 = left.lerp(right, float(i) / 12.0)
		draw_line(foot, foot - Vector2(0, 22), Color("518b94"), 1)
	for j in range(1, 4):
		draw_line(left - Vector2(0, j * 6), right - Vector2(0, j * 6), Color("518b94"), 1)
	draw_line(left - Vector2(0, 22), right - Vector2(0, 22), LINE, 3)
	draw_line(left + Vector2(0, 4), left - Vector2(0, 28), INK, 4)
	draw_line(right + Vector2(0, 4), right - Vector2(0, 28), INK, 4)
	var hit: Vector2 = project_point(Vector3(0.15, 1, 16))
	# A quiet fixed contact marker teaches timing without another control.
	draw_arc(hit, 12, 0, TAU, 16, Color("b9dfcb"), 1, false)
	draw_line(hit + Vector2(-17, 0), hit + Vector2(-12, 0), LINE, 1)
	draw_line(hit + Vector2(12, 0), hit + Vector2(17, 0), LINE, 1)
	if time_seconds - bounce_at < 0.16:
		var r: float = 3.0 + (time_seconds - bounce_at) * 45.0
		draw_arc(bounce_position, r, 0, TAU, 12, Color("fff4d2"), 1)
	_character(Vector2(100, 487), true, time_seconds - swing_at < 0.22)
	if show_ball:
		var pos: Vector2 = project_point(ball).round()
		var shadow: Vector2 = project_point(ball, true).round()
		var radius: float = roundf(lerpf(3.0, 5.0, clampf(ball.y, 0.0, 1.0)))
		draw_rect(Rect2(shadow - Vector2(radius + 2, 2), Vector2((radius + 2) * 2, 4)), Color("18515c"))
		draw_rect(Rect2(pos - Vector2(radius + 1, radius + 1), Vector2.ONE * (radius + 1) * 2), INK)
		draw_rect(Rect2(pos - Vector2(radius, radius), Vector2.ONE * radius * 2), Color("fff4d2"))
	if time_seconds - contact_at < 0.12:
		for offset in [Vector2(-18, -4), Vector2(17, -9), Vector2(8, 15)]:
			draw_rect(Rect2(hit + offset, Vector2(3, 3)), Color("ffd166"))

func _character(feet: Vector2, player: bool, swinging: bool) -> void:
	var color: Color = Color("54c7e6") if player else Color("ef7869")
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

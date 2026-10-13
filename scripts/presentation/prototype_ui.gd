extends CanvasLayer

const Rally = preload("res://scripts/core/rally_manager.gd")
const Judge = preload("res://scripts/core/timing_judge.gd")
signal pause_requested
signal restart_requested

var root: Control
var count_label: Label
var best_label: Label
var feedback: Label
var error_label: Label
var status_label: Label
var pause_button: Button
var resume_button: Button
var overlay: Panel
var feedback_until: float = -1.0
var safe_top: float = 0.0
var safe_bottom: float = 640.0

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_label("ONE TAP / RALLY", Vector2(22, 22), Vector2(220, 26), 22, Color("fff4d2"))
	_label("TIMING PROTOTYPE  ·  PHASE 01", Vector2(23, 53), Vector2(250, 20), 11, Color("829aae"))
	count_label = _label("00", Vector2(22, 89), Vector2(94, 47), 40, Color("fff4d2"))
	_label("RETURNS", Vector2(23, 133), Vector2(100, 18), 10, Color("829aae"))
	best_label = _label("BEST 00", Vector2(184, 112), Vector2(145, 20), 14, Color("b9dfcb"))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_button = _button("II", Rect2(284, 22, 52, 40))
	pause_button.pressed.connect(func(): pause_requested.emit())
	feedback = _label("GET READY", Vector2(30, 523), Vector2(300, 30), 25, Color("ffd166"))
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label = _label("", Vector2(30, 554), Vector2(300, 20), 12, Color("829aae"))
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _label("Tap once when the ball meets the ring", Vector2(15, 589), Vector2(330, 22), 13, Color("b9dfcb"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help: Label = _label("TAP / CLICK / SPACE     ·     P pause    R restart", Vector2(15, 616), Vector2(330, 18), 10, Color("829aae"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = Panel.new()
	overlay.position = Vector2(24, 244)
	overlay.size = Vector2(312, 154)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b1020")
	style.border_color = Color("54c7e6")
	style.set_border_width_all(2)
	overlay.add_theme_stylebox_override("panel", style)
	root.add_child(overlay)
	overlay.hide()
	var title: Label = Label.new()
	title.text = "PAUSED"
	title.position = Vector2(20, 16)
	title.size = Vector2(272, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	overlay.add_child(title)
	resume_button = _button("RESUME", Rect2(39, 308, 136, 54))
	resume_button.reparent(overlay)
	resume_button.position = Vector2(15, 64)
	resume_button.pressed.connect(func(): pause_requested.emit())
	var restart_button: Button = _button("RESTART", Rect2(185, 308, 136, 54))
	restart_button.reparent(overlay)
	restart_button.position = Vector2(161, 64)
	restart_button.pressed.connect(func(): restart_requested.emit())
	get_viewport().size_changed.connect(_layout_safe_area)
	_layout_safe_area()

func _label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _button(text: String, rect: Rect2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	root.add_child(button)
	return button

func _layout_safe_area() -> void:
	# The logical 9:16 court stays letterboxed. Transform device pixels to UI units.
	root.scale = Vector2.ONE
	root.position = Vector2.ZERO
	if OS.get_name() != "iOS":
		return
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window_origin: Vector2i = DisplayServer.window_get_position()
	var inverse: Transform2D = get_viewport().get_screen_transform().affine_inverse()
	var top_left: Vector2 = inverse * Vector2(safe.position - window_origin)
	var bottom_right: Vector2 = inverse * Vector2(safe.end - window_origin)
	safe_top = clampf(top_left.y, 0, 640)
	safe_bottom = clampf(bottom_right.y, 0, 640)
	var safe_left: float = clampf(top_left.x, 0, 360)
	var safe_right: float = clampf(bottom_right.x, 0, 360)
	var factor: float = minf((safe_bottom - safe_top) / 640.0, (safe_right - safe_left) / 360.0)
	root.scale = Vector2.ONE * factor
	root.position = Vector2(safe_left + (safe_right - safe_left - 360.0 * factor) / 2.0, safe_top)

func show_judgement(grade: int, error_ms: float, now: float) -> void:
	feedback.text = Judge.NAMES[grade]
	var colors: Array[Color] = [Color("ffd166"), Color("b9dfcb"), Color("efb176"), Color("ef7869")]
	feedback.add_theme_color_override("font_color", colors[grade])
	error_label.text = "NO SWING — next serve coming" if is_inf(error_ms) else "%+d ms" % roundi(error_ms)
	feedback_until = now + 0.75

func clear_feedback() -> void:
	feedback_until = -1.0
	error_label.text = ""

func set_paused(value: bool) -> void:
	overlay.visible = value
	pause_button.text = ">" if value else "II"

func update_state(model: RefCounted, now_us: int, paused: bool) -> void:
	count_label.text = "%02d" % model.rally_count
	best_label.text = "BEST %02d" % model.best_count
	set_paused(paused)
	var now: float = float(now_us) / 1000000.0
	if now > feedback_until:
		feedback.add_theme_color_override("font_color", Color("fff4d2"))
		error_label.text = ""
		match model.state:
			Rally.State.RALLY_START, Rally.State.RALLY_RESULT:
				feedback.text = "GET READY"
			Rally.State.PLAYER_RETURN:
				feedback.text = "RETURN"
			_:
				feedback.text = "WATCH THE BALL"
	status_label.text = "One swing per ball · early taps count" if model.state == Rally.State.PLAYER_RETURN else "Tap once when the ball meets the ring"
